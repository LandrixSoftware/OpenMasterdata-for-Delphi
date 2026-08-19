program LoginTest;

{
License OpenMasterdata-for-Delphi

Copyright (C) 2026 Landrix Software GmbH & Co. KG
Sven Harazim, info@landrix.de

Licensed to the Apache Software Foundation (ASF) under one
or more contributor license agreements.  See the NOTICE file
distributed with this work for additional information
regarding copyright ownership.  The ASF licenses this file
to you under the Apache License, Version 2.0 (the
"License"); you may not use this file except in compliance
with the License.  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing,
software distributed under the License is distributed on an
"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
KIND, either express or implied.  See the License for the
specific language governing permissions and limitations
under the License.
}

{$APPTYPE CONSOLE}

//Probiert fuer jeden Zugang aus Samples\configuration.ini einen Login samt
//einer vollstaendigen Artikelabfrage, liest die Antwort ein und meldet, was
//angekommen ist. Damit laesst sich vor einer Auslieferung pruefen, welche
//Zugaenge noch gelten und ob eine Aenderung an der Bibliothek einen
//Lieferanten bricht.
//
//Scheitert die Abfrage aller Datenpakete, grenzt das Programm die Ursache
//ein: es probiert den anderen DataPackageSendMode und danach jedes Paket
//einzeln. So wird sichtbar, ob der Lieferant den Sendemodus nicht versteht
//oder ob ein einzelnes Datenpaket den Fehler ausloest.
//
//Aufruf:
//  LoginTest.exe                     alle Zugaenge
//  LoginTest.exe Sonepar             nur Zugaenge, deren Name das enthaelt
//  LoginTest.exe Sonepar cc          zusaetzlich den Grant-Type uebersteuern
//                                    (cc = client_credentials, pw = password)
//
//Zugangsdaten und OAuth-Antworten werden bewusst nicht ausgegeben: die Antwort
//des Token-Endpunkts enthaelt das Zugriffs- und das Refresh-Token im Klartext.

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.StrUtils,
  System.IniFiles,
  intf.OpenMasterdata in '..\..\intf.OpenMasterdata.pas',
  intf.OpenMasterdata.Types in '..\..\intf.OpenMasterdata.Types.pas';

//Sucht die Konfiguration ausgehend vom Programm. Beim Start aus dem
//Ausgabeverzeichnis liegt sie einige Ebenen hoeher.
function LocateConfiguration : String;
var
  currentPath : String;
  i : Integer;
begin
  currentPath := ExtractFilePath(ParamStr(0));
  for i := 0 to 5 do
  begin
    if TFile.Exists(TPath.Combine(currentPath,'configuration.ini')) then
      exit(TPath.Combine(currentPath,'configuration.ini'));
    if TFile.Exists(TPath.Combine(currentPath,'Samples\configuration.ini')) then
      exit(TPath.Combine(currentPath,'Samples\configuration.ini'));
    currentPath := ExtractFilePath(ExcludeTrailingPathDelimiter(currentPath));
    if currentPath = '' then
      break;
  end;
  Result := '';
end;

//Baut eine Verbindung nach der Konfiguration auf. Die Bibliothek liest den
//Abschnitt selbst, damit hier und im GUI-Sample dieselbe Auslegung gilt.
//Der Verbindungsname muss je Versuch verschieden sein, sonst liefert die
//Bibliothek die zuvor angelegte Verbindung samt ihrer Einstellungen zurueck.
function CreateClient(_Ini : TMemIniFile; const _Section,_ConnectionName : String;
  _SendMode : TOpenMasterdataDataPackagesSendMode;
  _UnknownDataPackages : TStrings = nil) : IOpenMasterdataApiClient;
var
  configuration : TOpenMasterdataConfiguration;
begin
  configuration := TOpenMasterdataConfiguration.LoadFromIni(_Ini,_Section,
                     _UnknownDataPackages);
  configuration.DataPackagesSendMode := _SendMode;

  //Zur Fehlersuche laesst sich der Grant-Type uebersteuern, ohne die
  //Konfiguration zu aendern
  if SameText(ParamStr(2),'cc') then
    configuration.GrantType := omdgt_ClientCredentials
  else
  if SameText(ParamStr(2),'pw') then
    configuration.GrantType := omdgt_Password;

  //Manche Lieferanten drosseln hart. Die Wartezeit aus Retry-After wird bis zu
  //zwei Minuten mitgegangen, sonst waere die Eingrenzung unten nach wenigen
  //Anfragen nicht mehr moeglich.
  configuration.MaxRetries := 3;
  configuration.MaxRetryDelaySeconds := 120;

  TOpenMasterdataApiClient.RemoveOpenMasterdataConnection(_ConnectionName);
  Result := TOpenMasterdataApiClient.NewOpenMasterdataConnection(_ConnectionName,
              configuration);
end;

//Die Konfiguration eines Abschnitts, ohne eine Verbindung aufzubauen
function ReadConfiguration(_Ini : TMemIniFile; const _Section : String;
  _UnknownDataPackages : TStrings = nil) : TOpenMasterdataConfiguration;
begin
  Result := TOpenMasterdataConfiguration.LoadFromIni(_Ini,_Section,
              _UnknownDataPackages);
  if SameText(ParamStr(2),'cc') then
    Result.GrantType := omdgt_ClientCredentials
  else
  if SameText(ParamStr(2),'pw') then
    Result.GrantType := omdgt_Password;
end;

//In ArtNoAsCommatext stehen mehrere Artikelnummern, eine genuegt zur Pruefung
function FirstArtNo(const _Value : String) : String;
var
  p : Integer;
begin
  Result := Trim(_Value);
  p := Pos(',',Result);
  if p > 0 then
    Result := Trim(Copy(Result,1,p-1));
end;

//Servermeldungen sind teils mehrzeilig und sehr lang
function ShortMsg(const _Value : String) : String;
begin
  Result := StringReplace(_Value,#13,' ',[rfReplaceAll]);
  Result := StringReplace(Result,#10,' ',[rfReplaceAll]);
  while Pos('  ',Result) > 0 do
    Result := StringReplace(Result,'  ',' ',[rfReplaceAll]);
  Result := Trim(Result);
  if Length(Result) > 300 then
    Result := Copy(Result,1,300)+' ...';
end;

function YesNo(_Value : Boolean) : String;
begin
  if _Value then
    Result := 'ja'
  else
    Result := 'nein';
end;

function SendModeAsString(_Value : TOpenMasterdataDataPackagesSendMode) : String;
begin
  if _Value = omddpsm_Exploded then
    Result := 'exploded'
  else
    Result := 'pipedelimited';
end;

//Fasst zusammen, was in der Antwort tatsaechlich angekommen ist. Ein Abruf
//kann technisch gelingen und trotzdem fast leer sein.
function SummarizeResult(_Result : TOpenMasterdataAPI_Result) : String;

  procedure Add(const _Text : String);
  begin
    if Result <> '' then
      Result := Result+', ';
    Result := Result+_Text;
  end;

begin
  Result := '';
  if _Result = nil then
    exit('nichts');

  if _Result.basic.productShortDescr <> '' then
    Add('basic')
  else
  if _Result.basic.commodityGroupId <> '' then
    Add('basic ohne Kurztext');
  if _Result.additional.minOrderQuantity > 0 then
    Add('additional');
  if _Result.prices.listPrice.value <> '' then
    Add('prices');
  if (_Result.descriptions.productDescr <> '') or
     (_Result.descriptions.marketingText <> '') then
    Add('descriptions');
  if _Result.logistics.packagingUnits.Count > 0 then
    Add(Format('logistics mit %d Einheiten',[_Result.logistics.packagingUnits.Count]));
  if _Result.pictures.Count > 0 then
    Add(Format('%d Bilder',[_Result.pictures.Count]));
  if _Result.documents.Count > 0 then
    Add(Format('%d Dokumente',[_Result.documents.Count]));
  if _Result.sparepartlist.sparepartlistRow.Count > 0 then
    Add(Format('%d Ersatzteilzeilen',[_Result.sparepartlist.sparepartlistRow.Count]));

  if Result = '' then
    Result := 'Antwort ohne verwertbare Felder';
end;

//Ein einzelner Abrufversuch. Meldet zurueck, ob er gelungen ist.
function Probe(_Ini : TMemIniFile; const _Section,_Label,_ArtNo : String;
  _Packages : TOpenMasterdataAPI_DataPackages;
  _SendMode : TOpenMasterdataDataPackagesSendMode) : Boolean;
var
  client : IOpenMasterdataApiClient;
  res : TOpenMasterdataAPI_Result;
begin
  Result := false;
  Write(Format('    %-32s : ',[_Label]));
  client := CreateClient(_Ini,_Section,_Section+'#probe',_SendMode);
  res := nil;
  try
    try
      Result := client.GetBySupplierPid(_ArtNo,_Packages,res);
    except
      on E:Exception do
      begin
        Writeln('Ausnahme '+E.ClassName+' '+ShortMsg(E.Message));
        exit;
      end;
    end;
    if Result and (res <> nil) then
      Writeln('ok, '+SummarizeResult(res))
    else
      Writeln(Format('Fehler %d %s',[client.GetLastErrorCode,
        ShortMsg(client.GetLastErrorMessage)]));
  finally
    res.Free;
  end;
end;

//Sucht die Ursache, wenn die Abfrage aller Datenpakete scheitert.
procedure NarrowDownFailure(_Ini : TMemIniFile; const _Section,_ArtNo : String;
  _SendMode : TOpenMasterdataDataPackagesSendMode);
var
  otherMode : TOpenMasterdataDataPackagesSendMode;
  package : TOpenMasterdataAPI_DataPackage;
  selected : TOpenMasterdataAPI_DataPackages;
  failing : String;
begin
  Writeln('  EINGRENZUNG');

  //Zuerst denselben Aufruf wiederholen. Gelingt er jetzt, war die Stoerung
  //voruebergehend und jeder Schluss aus einem einzelnen Fehlversuch waere
  //falsch. Ein Serverfehler tritt durchaus nur zeitweise auf.
  if Probe(_Ini,_Section,'noch einmal, unveraendert',_ArtNo,
       ReadConfiguration(_Ini,_Section).DataPackages,_SendMode) then
  begin
    Writeln('    -> der Fehler war voruebergehend, die Konfiguration stimmt');
    exit;
  end;

  //Dann der andere Sendemodus: versteht der Lieferant die Paketliste nicht,
  //scheitert jede Abfrage mit mehr als einem Paket.
  if _SendMode = omddpsm_PipeDelimited then
    otherMode := omddpsm_Exploded
  else
    otherMode := omddpsm_PipeDelimited;

  if Probe(_Ini,_Section,'alle Pakete, '+SendModeAsString(otherMode),_ArtNo,
       ReadConfiguration(_Ini,_Section).DataPackages,otherMode) then
  begin
    Writeln('    -> mit DataPackageSendMode='+SendModeAsString(otherMode)+' geht es;');
    Writeln('       vor dem Eintragen pruefen, ob dabei auch alle Felder ankommen');
    exit;
  end;

  //Sonst einzeln pruefen, welches Paket der Server nicht liefern kann
  failing := '';
  //Nur die Pakete pruefen, die auch angefragt werden
  selected := ReadConfiguration(_Ini,_Section).DataPackages;
  for package := Low(TOpenMasterdataAPI_DataPackage) to High(TOpenMasterdataAPI_DataPackage) do
    if (package in selected) and
       not Probe(_Ini,_Section,
         'nur '+TOpenMasterdataAPI_DataPackageHelper.DataPackageAsString(package),
         _ArtNo,[package],_SendMode) then
    begin
      if failing <> '' then
        failing := failing+', ';
      failing := failing+TOpenMasterdataAPI_DataPackageHelper.DataPackageAsString(package);
    end;

  if failing = '' then
    Writeln('    -> einzeln geht jedes Paket, der Server vertraegt nur die Kombination nicht')
  else
    Writeln('    -> Fehler bei: '+failing);
end;

var
  configurationFilename : String;
  ini : TMemIniFile;
  sections : TStringList;
  unknownNames : TStringList;
  section,artNo,token,oauthResponse : String;
  client : IOpenMasterdataApiClient;
  res : TOpenMasterdataAPI_Result;
  sendMode : TOpenMasterdataDataPackagesSendMode;
  configuration : TOpenMasterdataConfiguration;
  dataReceived,loggedIn : Boolean;
  countLoginOk,countDataOk,countTotal : Integer;
begin
  countTotal := 0;
  countLoginOk := 0;
  countDataOk := 0;

  configurationFilename := LocateConfiguration;
  if configurationFilename = '' then
  begin
    Writeln('Samples\configuration.ini nicht gefunden.');
    Writeln('Vorlage: Samples\configuration.sample.ini');
    ExitCode := 2;
    exit;
  end;

  Writeln('Konfiguration: '+configurationFilename);

  ini := TMemIniFile.Create(configurationFilename,TEncoding.UTF8);
  sections := TStringList.Create;
  unknownNames := TStringList.Create;
  try
    ini.ReadSections(sections);

    for section in sections do
    begin
      if (ParamCount > 0) and not ContainsText(section,ParamStr(1)) then
        continue;

      Writeln('');
      Writeln('=== '+section);

      unknownNames.Clear;
      configuration := ReadConfiguration(ini,section,unknownNames);
      sendMode := configuration.DataPackagesSendMode;

      Writeln('  Konfiguration     : '+
              IfThen(configuration.GrantType = omdgt_ClientCredentials,
                     'client_credentials','password')+
              ', '+SendModeAsString(sendMode));
      Writeln('  gesetzt           : Benutzer '+YesNo(configuration.Username <> '')+
              ', Kundennummer '+YesNo(configuration.CustomerNumber <> '')+
              ', Passwort '+YesNo(configuration.Password <> '')+
              ', ClientSecret '+YesNo(configuration.ClientSecret <> '')+
              ', Scope '+YesNo(configuration.ClientScope <> ''));
      Writeln('  OAuthURL          : '+configuration.OAuthURL);
      Writeln('  Datenpakete       : '+
        StringReplace(TOpenMasterdataAPI_DataPackageHelper.DataPackagesAsString(
          configuration.DataPackages),'%7C',', ',[rfReplaceAll]));
      //Ein Tippfehler in der Konfiguration bliebe sonst unbemerkt
      if unknownNames.Count > 0 then
        Writeln('    unbekannt       : '+unknownNames.CommaText);

      artNo := FirstArtNo(ini.ReadString(section,'ArtNoAsCommatext',''));
      if artNo = '' then
      begin
        //Ohne Artikelnummer laesst sich nichts pruefen. Der Zugang zaehlt dann
        //auch nicht als Fehlschlag, sonst meldete das Programm einen Defekt,
        //wo nur nichts zu tun war.
        Writeln('  ERGEBNIS          : uebersprungen, keine Artikelnummer hinterlegt');
        continue;
      end;

      Inc(countTotal);

      client := CreateClient(ini,section,section,sendMode,unknownNames);

      res := nil;
      dataReceived := false;
      try
        dataReceived := client.GetBySupplierPid(artNo,
                          configuration.DataPackages,res);
      except
        on E:Exception do
          Writeln('  AUSNAHME          : '+E.ClassName+' '+ShortMsg(E.Message));
      end;

      try
        //Nicht der Token selbst zeigt die geglueckte Anmeldung an: nach einer
        //Antwort mit 401 oder 403 verwirft die Bibliothek ihn wieder. Die
        //Antwort des Token-Endpunkts bleibt dagegen erhalten.
        oauthResponse := client.GetLastOAuthResponseContent;
        token := client.GetCurrentAuthorizationToken;
        loggedIn := (token <> '') or ContainsText(oauthResponse,'access_token');
        if loggedIn then
        begin
          Inc(countLoginOk);
          if token <> '' then
            Writeln('  LOGIN             : ok, Token mit '+IntToStr(Length(token))+' Zeichen')
          else
            Writeln('  LOGIN             : ok, Token nach der Antwort verworfen (401 oder 403)');
          //Nicht jeder Lieferant liefert ein Refresh-Token. Fehlt es, wird nach
          //Ablauf immer neu angemeldet.
          Writeln('    refresh_token   : '+YesNo(ContainsText(oauthResponse,'refresh_token'))+
                  ', expires_in '+YesNo(ContainsText(oauthResponse,'expires_in')));
        end
        else
          Writeln('  LOGIN             : FEHLGESCHLAGEN');

        if dataReceived and (res <> nil) then
        begin
          Inc(countDataOk);
          Writeln('  ARTIKEL '+artNo+' : ok, '+res.basic.productShortDescr);
          Writeln('    eingelesen      : '+SummarizeResult(res));
        end
        else
        begin
          Writeln('  ARTIKEL '+artNo+' : kein Ergebnis');
          Writeln('    HTTP-Code       : '+IntToStr(client.GetLastErrorCode));
          Writeln('    Meldung         : '+ShortMsg(client.GetLastErrorMessage));
          //Ohne Anmeldung ist jede weitere Abfrage sinnlos
          if loggedIn then
            NarrowDownFailure(ini,section,artNo,sendMode);
        end;
      finally
        res.Free;
      end;
    end;

    Writeln('');
    Writeln('---');
    Writeln(Format('%d Zugaenge, %d Logins erfolgreich, %d Artikel geliefert',
      [countTotal,countLoginOk,countDataOk]));

    //Ein nicht mehr gueltiger Zugang ist ein Befund, kein Programmfehler.
    //Der Rueckgabewert erlaubt trotzdem eine Auswertung im Skript.
    if (countLoginOk < countTotal) or (countDataOk < countTotal) then
      ExitCode := 1;
  finally
    unknownNames.Free;
    sections.Free;
    ini.Free;
  end;
end.
