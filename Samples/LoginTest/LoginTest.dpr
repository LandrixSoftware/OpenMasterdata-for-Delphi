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
//einer Artikelabfrage und meldet, was der Server geantwortet hat. Damit laesst
//sich vor einer Auslieferung pruefen, welche Zugaenge noch gelten und ob eine
//Aenderung an der Bibliothek einen Lieferanten bricht.
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

var
  configurationFilename : String;
  ini : TMemIniFile;
  sections : TStringList;
  section,artNo,token,oauthResponse : String;
  client : IOpenMasterdataApiClient;
  res : TOpenMasterdataAPI_Result;
  grantType : TOpenMasterdataGrantType;
  sendMode : TOpenMasterdataDataPackagesSendMode;
  dataReceived : Boolean;
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
  try
    ini.ReadSections(sections);

    for section in sections do
    begin
      if (ParamCount > 0) and not ContainsText(section,ParamStr(1)) then
        continue;

      Inc(countTotal);
      Writeln('');
      Writeln('=== '+section);

      grantType := TOpenMasterdataApiClient.GetGrantTypeFromString(
                     ini.ReadString(section,'GrantType',''));
      sendMode := TOpenMasterdataApiClient.GetDataPackagesSendModeFromString(
                     ini.ReadString(section,'DataPackageSendMode',''));

      //Zur Fehlersuche laesst sich der Grant-Type uebersteuern, ohne die
      //Konfiguration zu aendern
      if SameText(ParamStr(2),'cc') then
        grantType := omdgt_ClientCredentials
      else
      if SameText(ParamStr(2),'pw') then
        grantType := omdgt_Password;

      Writeln('  GrantType         : '+IfThen(grantType = omdgt_ClientCredentials,
                                              'client_credentials','password'));
      Writeln('  gesetzt           : Benutzer '+YesNo(ini.ReadString(section,'Username','') <> '')+
              ', Kundennummer '+YesNo(ini.ReadString(section,'Customernumber','') <> '')+
              ', Passwort '+YesNo(ini.ReadString(section,'Password','') <> '')+
              ', ClientSecret '+YesNo(ini.ReadString(section,'ClientSecret','') <> '')+
              ', Scope '+YesNo(ini.ReadString(section,'ClientScope','') <> ''));
      Writeln('  OAuthURL          : '+ini.ReadString(section,'OAuthURL',''));

      artNo := FirstArtNo(ini.ReadString(section,'ArtNoAsCommatext',''));
      if artNo = '' then
      begin
        Writeln('  ERGEBNIS          : uebersprungen, keine Artikelnummer hinterlegt');
        continue;
      end;

      //Eine bestehende Verbindung gleichen Namens wuerde die Zugangsdaten
      //aus einem frueheren Durchlauf weiterverwenden
      client := nil;
      TOpenMasterdataApiClient.RemoveOpenMasterdataConnection(section);
      client := TOpenMasterdataApiClient.NewOpenMasterdataConnection(section,
                  ini.ReadString(section,'Username',''),
                  ini.ReadString(section,'Password',''),
                  ini.ReadString(section,'Customernumber',''),
                  ini.ReadString(section,'ClientID',''),
                  ini.ReadString(section,'ClientSecret',''),
                  ini.ReadString(section,'ClientScope',''),grantType,sendMode);
      client.SetOAuthURL(ini.ReadString(section,'OAuthURL',''));
      client.SetBySupplierPIDURL(ini.ReadString(section,'BySupplierPIDURL',''));
      //Fuer die Diagnose ohne Wiederholungen, sonst dauert ein Ausfall lange
      client.SetRetryPolicy(0,0);

      res := nil;
      dataReceived := false;
      try
        dataReceived := client.GetBySupplierPid(artNo,[omd_datapackage_basic],res);
      except
        on E:Exception do
          Writeln('  AUSNAHME          : '+E.ClassName+' '+ShortMsg(E.Message));
      end;

      try
        token := client.GetCurrentAuthorizationToken;
        if token <> '' then
        begin
          Inc(countLoginOk);
          Writeln('  LOGIN             : ok, Token mit '+IntToStr(Length(token))+' Zeichen');
          //Nicht jeder Lieferant liefert ein Refresh-Token. Fehlt es, wird nach
          //Ablauf immer neu angemeldet.
          oauthResponse := client.GetLastOAuthResponseContent;
          Writeln('    refresh_token   : '+YesNo(ContainsText(oauthResponse,'refresh_token'))+
                  ', expires_in '+YesNo(ContainsText(oauthResponse,'expires_in')));
        end
        else
          Writeln('  LOGIN             : FEHLGESCHLAGEN');

        if dataReceived and (res <> nil) then
        begin
          Inc(countDataOk);
          Writeln('  ARTIKEL '+artNo+' : ok, '+res.basic.productShortDescr);
        end
        else
        begin
          Writeln('  ARTIKEL '+artNo+' : kein Ergebnis');
          Writeln('    HTTP-Code       : '+IntToStr(client.GetLastErrorCode));
          Writeln('    Meldung         : '+ShortMsg(client.GetLastErrorMessage));
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
    if countLoginOk < countTotal then
      ExitCode := 1;
  finally
    sections.Free;
    ini.Free;
  end;
end.
