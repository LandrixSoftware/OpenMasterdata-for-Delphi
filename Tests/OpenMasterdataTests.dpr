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

//Regressionstests fuer den JSON-Parser.
//
//Aufruf:   OpenMasterdataTests.exe [Pfad zum Ordner Testresponses]
//Rueckgabe: Exitcode 0 = alle Tests bestanden, 1 = mindestens ein Test fehlgeschlagen.
//
//Die Tests in RunParserTests laufen ohne externe Daten. Ist zusaetzlich der Ordner
//Testresponses vorhanden, wird jede dort abgelegte Lieferanten-Antwort als Smoketest geparst.

program OpenMasterdataTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.StrUtils,
  System.DateUtils,
  intf.OpenMasterdata.Types in '..\intf.OpenMasterdata.Types.pas',
  intf.OpenMasterdata.View in '..\intf.OpenMasterdata.View.pas';

var
  TestsRun : Integer = 0;
  TestsFailed : Integer = 0;

procedure Check(const _Name : String; _Condition : Boolean; const _Detail : String = '');
begin
  Inc(TestsRun);
  if _Condition then
    Writeln('  ok   ',_Name)
  else
  begin
    Inc(TestsFailed);
    if _Detail <> '' then
      Writeln('  FAIL ',_Name,' -> ',_Detail)
    else
      Writeln('  FAIL ',_Name);
  end;
end;

procedure CheckEquals(const _Name, _Expected, _Actual : String);
begin
  Check(_Name,_Expected = _Actual,'erwartet "'+_Expected+'", war "'+_Actual+'"');
end;

procedure CheckEqualsInt(const _Name : String; _Expected, _Actual : Integer);
begin
  Check(_Name,_Expected = _Actual,'erwartet '+IntToStr(_Expected)+', war '+IntToStr(_Actual));
end;

//Laedt JSON in ein frisches Ergebnisobjekt. Der Aufrufer gibt es frei.
function Parse(const _Json : String; out _Error : String) : TOpenMasterdataAPI_Result;
begin
  Result := TOpenMasterdataAPI_Result.Create;
  if not Result.TryLoadFromJson(_Json,_Error) then
  begin
    Result.Free;
    Result := nil;
  end;
end;

procedure TestInvalidJsonIsRejected;
var
  res : TOpenMasterdataAPI_Result;
  err : String;
begin
  Writeln('Ungueltige Antworten werden abgewiesen');

  res := Parse('{invalid',err);
  Check('kaputtes JSON liefert false',res = nil);
  res.Free;

  res := Parse('null',err);
  Check('JSON null liefert false',res = nil);
  res.Free;

  res := Parse('[]',err);
  Check('JSON-Array liefert false',res = nil);
  res.Free;

  res := Parse('',err);
  Check('leere Antwort liefert false',res = nil);
  res.Free;

  res := Parse('{"supplierPid":"A1"}',err);
  Check('gueltiges Objekt liefert true',res <> nil,err);
  res.Free;
end;

procedure TestNullValues;
var
  res : TOpenMasterdataAPI_Result;
  err : String;
begin
  Writeln('JSON null wird nicht zum Text "null"');

  res := Parse('{"supplierPid":null,"gtin":null,"basic":{"matchcode":null},'+
               '"logistics":{"unNumber":null,"weeeNumber":null}}',err);
  if res = nil then
  begin
    Check('Antwort mit null-Werten parsebar',false,err);
    exit;
  end;
  try
    CheckEquals('supplierPid','',res.supplierPid);
    CheckEquals('gtin','',res.gtin);
    CheckEquals('basic.matchcode','',res.basic.matchcode);
    CheckEquals('logistics.unNumber','',res.logistics.unNumber);
    CheckEquals('logistics.weeeNumber','',res.logistics.weeeNumber);
  finally
    res.Free;
  end;
end;

procedure TestPackagingUnitMeasures;
var
  res : TOpenMasterdataAPI_Result;
  err : String;
  pu : TOpenMasterdataAPI_PackagingUnit;
begin
  Writeln('Verpackungseinheiten: alle Masse und das Gewicht kommen an');

  res := Parse('{"logistics":{"packagingUnits":[{"packagingType":"CT","quantity":"1",'+
               '"measureA":{"measure":"87.0","unit":"MMT"},'+
               '"measureB":{"measure":"53.0","unit":"MMT"},'+
               '"measureC":{"measure":"56.5","unit":"MMT"},'+
               '"weight":{"weight":"0.35","unit":"KGM"}}]}}',err);
  if res = nil then
  begin
    Check('Antwort parsebar',false,err);
    exit;
  end;
  try
    CheckEqualsInt('Anzahl Verpackungseinheiten',1,res.logistics.packagingUnits.Count);
    if res.logistics.packagingUnits.Count < 1 then
      exit;
    pu := res.logistics.packagingUnits[0];
    CheckEquals('measureA','87.0',pu.measureA.measure);
    CheckEquals('measureB','53.0',pu.measureB.measure);
    CheckEquals('measureC','56.5',pu.measureC.measure);
    CheckEquals('measureC.unit','MMT',pu.measureC.unit_);
    CheckEquals('weight','0.35',pu.weight.weight);
    CheckEquals('weight.unit','KGM',pu.weight.unit_);
  finally
    res.Free;
  end;
end;

procedure TestLogisticsMeasures;
var
  res : TOpenMasterdataAPI_Result;
  err : String;
begin
  Writeln('Logistik: Masse, Gewicht und die Schreibweisen der Spec');

  //Die Spec 9.0.0 schreibt heigth und weigth
  res := Parse('{"logistics":{"length":{"measure":"10","unit":"MMT"},'+
               '"width":{"measure":"20","unit":"MMT"},'+
               '"heigth":{"measure":"30","unit":"MMT"},'+
               '"weigth":{"weight":"1.5","unit":"KGM"}}}',err);
  if res = nil then
  begin
    Check('Antwort parsebar',false,err);
    exit;
  end;
  try
    CheckEquals('length -> measureA','10',res.logistics.measureA.measure);
    CheckEquals('width -> measureB','20',res.logistics.measureB.measure);
    CheckEquals('heigth -> measureC','30',res.logistics.measureC.measure);
    CheckEquals('weigth -> weight','1.5',res.logistics.weight.weight);
  finally
    res.Free;
  end;
end;

procedure TestNumbersAsStrings;
var
  res : TOpenMasterdataAPI_Result;
  err : String;
begin
  Writeln('Zahlfelder werden auch als String gelesen');

  res := Parse('{"pictures":[{"url":"http://x/1.jpg","size":"796853","sortOrder":"2"}],'+
               '"documents":[{"url":"http://x/1.pdf","size":264199,"sortOrder":1}]}',err);
  if res = nil then
  begin
    Check('Antwort parsebar',false,err);
    exit;
  end;
  try
    CheckEqualsInt('pictures[0].size (String)',796853,res.pictures[0].size);
    CheckEqualsInt('pictures[0].sortOrder (String)',2,res.pictures[0].sortOrder);
    CheckEqualsInt('documents[0].size (Zahl)',264199,res.documents[0].size);
    CheckEqualsInt('documents[0].sortOrder (Zahl)',1,res.documents[0].sortOrder);
  finally
    res.Free;
  end;
end;

procedure TestDateFormats;
begin
  Writeln('Datumsformate');

  CheckEquals('ISO','21.04.2026',DateToStr(TOpenMasterdataAPIHelper.JSONStrToDate('2026-04-21')));
  CheckEquals('YYYYMMDD','21.04.2026',DateToStr(TOpenMasterdataAPIHelper.JSONStrToDate('20260421')));
  CheckEquals('DDMMYYYY','21.04.2026',DateToStr(TOpenMasterdataAPIHelper.JSONStrToDate('21042026')));
  Check('leerer Wert ergibt 0',TOpenMasterdataAPIHelper.JSONStrToDate('') = 0);
  Check('Unsinn ergibt 0',TOpenMasterdataAPIHelper.JSONStrToDate('keinDatum') = 0);
end;

procedure TestGtinFix;
var
  res : TOpenMasterdataAPI_Result;
  err : String;
begin
  Writeln('GTIN mit fuehrender Null');

  //Fuehrende Null ist kein gueltiges JSON, muss aber erhalten bleiben
  res := Parse('{"gtin": 04001234567890,"supplierPid":"A1"}',err);
  if res = nil then
    Check('GTIN mit fuehrender Null parsebar',false,err)
  else
  try
    CheckEquals('gtin bleibt vollstaendig','04001234567890',res.gtin);
    CheckEquals('supplierPid unveraendert','A1',res.supplierPid);
  finally
    res.Free;
  end;

  //Eine alleinstehende 0 ist gueltiges JSON und darf nicht zerstoert werden
  res := Parse('{"gtin": 0,"supplierPid":"A2"}',err);
  if res = nil then
    Check('gtin 0 zerstoert die Antwort nicht',false,err)
  else
  try
    CheckEquals('supplierPid trotz gtin 0','A2',res.supplierPid);
  finally
    res.Free;
  end;
end;

procedure TestExpiringProduct;
var
  res : TOpenMasterdataAPI_Result;
  err : String;
begin
  Writeln('Auslaufartikel');

  res := Parse('{"additional":{"expiringProduct":"Yes-Successor"}}',err);
  if res <> nil then
  try
    Check('String Yes-Successor setzt Flag',res.additional.expiringProduct);
    Check('String Yes-Successor erkennt Nachfolger',res.additional.expiringProductHasSuccessor);
    CheckEquals('State bleibt erhalten','Yes-Successor',res.additional.expiringProductState);
  finally
    res.Free;
  end
  else
    Check('Antwort parsebar',false,err);

  res := Parse('{"additional":{"expiringProduct":true}}',err);
  if res <> nil then
  try
    Check('Boolean true setzt Flag',res.additional.expiringProduct);
    CheckEquals('Boolean true wird zu Yes','Yes',res.additional.expiringProductState);
  finally
    res.Free;
  end
  else
    Check('Antwort parsebar',false,err);

  res := Parse('{"additional":{"expiringProduct":"No"}}',err);
  if res <> nil then
  try
    Check('No setzt kein Flag',not res.additional.expiringProduct);
    CheckEquals('State No','No',res.additional.expiringProductState);
  finally
    res.Free;
  end
  else
    Check('Antwort parsebar',false,err);
end;

procedure TestSpecSpellings;
var
  res : TOpenMasterdataAPI_Result;
  err : String;
begin
  Writeln('Abweichende Schreibweisen aus Spec und Praxis');

  res := Parse('{"additional":{"attributes":[{"attributeName":"Farbe","attributeValue1":"weiss"}],'+
               '"discoundGroupIdManufacturer":"RG12"},'+
               '"prices":{"linePrice":[{"value":"1.00","descriptiion":"Zeile 1"}]},'+
               '"logistics":{"reachData":"2026-01-01"}}',err);
  if res = nil then
  begin
    Check('Antwort parsebar',false,err);
    exit;
  end;
  try
    CheckEqualsInt('attributes (Plural) wird gelesen',1,res.additional.attribute.Count);
    if res.additional.attribute.Count > 0 then
      CheckEquals('Attributname','Farbe',res.additional.attribute[0].attributeName);
    CheckEquals('discoundGroupIdManufacturer','RG12',res.additional.discountGroupIdManufacturer);
    CheckEqualsInt('linePrice vorhanden',1,res.prices.linePrice.Count);
    if res.prices.linePrice.Count > 0 then
      CheckEquals('descriptiion aus der Spec','Zeile 1',res.prices.linePrice[0].description);
    CheckEquals('reachData','01.01.2026',DateToStr(res.logistics.reachDate));
  finally
    res.Free;
  end;
end;

procedure TestRepeatedLoadDoesNotAccumulate;
var
  res : TOpenMasterdataAPI_Result;
  err : String;
begin
  Writeln('Mehrfaches Laden haengt keine Eintraege an');

  res := TOpenMasterdataAPI_Result.Create;
  try
    Check('erstes Laden',res.TryLoadFromJson('{"pictures":[{"url":"a"}]}',err),err);
    Check('zweites Laden',res.TryLoadFromJson('{"pictures":[{"url":"b"}]}',err),err);
    CheckEqualsInt('nur ein Bild nach zwei Aufrufen',1,res.pictures.Count);
    if res.pictures.Count > 0 then
      CheckEquals('Bild stammt aus der zweiten Antwort','b',res.pictures[0].url);
  finally
    res.Free;
  end;
end;

procedure TestEnumCodes;
begin
  Writeln('Enum-Codes der Spec 9.0.0');

  Check('PackageType PMS',
    TOpenMasterdataAPI_PackageTypeHelper.PackageTypeFromStr('PMS') <> omdPackageType_Unknown);
  Check('PackageType GEB',
    TOpenMasterdataAPI_PackageTypeHelper.PackageTypeFromStr('GEB') <> omdPackageType_Unknown);
  Check('RawMaterial MK',
    TOpenMasterdataAPI_RawMaterialHelper.RawMaterialFromStr('MK') <> rawMaterial_Unknown);
  Check('RawMaterial CU',
    TOpenMasterdataAPI_RawMaterialHelper.RawMaterialFromStr('CU') <> rawMaterial_Unknown);
  Check('unbekannter Code bleibt Unknown',
    TOpenMasterdataAPI_PackageTypeHelper.PackageTypeFromStr('XYZ') = omdPackageType_Unknown);
end;

procedure TestDocumentLanguage;
var
  res : TOpenMasterdataAPI_Result;
  err : String;
begin
  Writeln('Dokumentsprache');

  res := Parse('{"documents":[{"url":"http://x/1.pdf","language":["de","en"]},'+
               '{"url":"http://x/2.pdf","language":"fr"}]}',err);
  if res = nil then
  begin
    Check('Antwort parsebar',false,err);
    exit;
  end;
  try
    CheckEqualsInt('zwei Dokumente',2,res.documents.Count);
    if res.documents.Count = 2 then
    begin
      CheckEquals('Sprachliste','de, en',res.documents[0].language);
      CheckEquals('einzelne Sprache','fr',res.documents[1].language);
    end;
  finally
    res.Free;
  end;
end;

//Die HTML-Ausgabe darf keine aktiven Inhalte aus der Lieferantenantwort uebernehmen.
procedure TestHtmlSanitizing;
var
  res : TOpenMasterdataAPI_Result;
  err,html : String;

  function RenderDescr(const _Descr : String) : String;
  var
    r : TOpenMasterdataAPI_Result;
    e : String;
  begin
    Result := '';
    r := Parse('{"descriptions":{"productDescr":'+_Descr+'}}',e);
    if r = nil then
      exit;
    try
      Result := TOpenMasterdataAPI_ViewHelper.AsHtml(r);
    finally
      r.Free;
    end;
  end;

begin
  Writeln('HTML-Ausgabe');

  Check('AsHtml(nil) liefert Leerstring',TOpenMasterdataAPI_ViewHelper.AsHtml(nil) = '');

  //Erlaubte Auszeichnung bleibt erhalten
  html := RenderDescr('"<p>Zeile eins</p><ul><li>Punkt</li></ul>"');
  Check('Absatz bleibt erhalten',ContainsText(html,'<p>Zeile eins</p>'),html);
  Check('Liste bleibt erhalten',ContainsText(html,'<li>Punkt</li>'),html);

  //Skripte und Ereignisattribute duerfen nicht durchkommen
  html := RenderDescr('"<div><script>alert(1)</script></div>"');
  Check('script-Tag entfernt',not ContainsText(html,'<script'),html);

  html := RenderDescr('"<div><img src=x onerror =alert(1)></div>"');
  Check('img mit onerror entfernt',not ContainsText(html,'onerror'),html);

  html := RenderDescr('"<div><svg onload=alert(1)></svg></div>"');
  Check('svg mit onload entfernt',not ContainsText(html,'onload'),html);

  html := RenderDescr('"<div><p style=\"x\" onclick=\"evil()\">Text</p></div>"');
  Check('Attribute werden entfernt',not ContainsText(html,'onclick'),html);
  Check('Text bleibt erhalten',ContainsText(html,'Text'),html);

  //Aktive URL-Schemata
  res := Parse('{"additional":{"deepLink":"javascript:alert(1)"},'+
               '"documents":[{"url":"javascript:alert(2)"}],'+
               '"pictures":[{"url":"javascript:alert(3)"}]}',err);
  if res = nil then
    Check('Antwort parsebar',false,err)
  else
  try
    html := TOpenMasterdataAPI_ViewHelper.AsHtml(res);
    //Der Wert darf als Text erscheinen, aber nie als aktive URL
    Check('kein href mit javascript:',not ContainsText(html,'href="javascript:'),html);
    Check('kein src mit javascript:',not ContainsText(html,'src="javascript:'),html);
    Check('unsichere Dokument-URL wird nicht verlinkt',not ContainsText(html,'<a href="javascript'),html);
  finally
    res.Free;
  end;

  //Waehrung wird maskiert
  res := Parse('{"prices":{"listPrice":{"value":"1.00","currency":"EUR<img src=x onerror=alert(1)>"}}}',err);
  if res = nil then
    Check('Antwort parsebar',false,err)
  else
  try
    html := TOpenMasterdataAPI_ViewHelper.AsHtml(res);
    Check('Waehrung maskiert',not ContainsText(html,'<img'),html);
  finally
    res.Free;
  end;
end;

//Smoketest gegen die echten Lieferanten-Antworten, sofern vorhanden.
procedure TestRealResponses(const _Folder : String);
var
  files : TArray<String>;
  fileName : String;
  res : TOpenMasterdataAPI_Result;
  err : String;
begin
  if not TDirectory.Exists(_Folder) then
  begin
    Writeln('Echte Lieferanten-Antworten: Ordner "',_Folder,'" nicht vorhanden, uebersprungen');
    Writeln;
    exit;
  end;

  files := TDirectory.GetFiles(_Folder,'*.json');
  Writeln('Echte Lieferanten-Antworten (',Length(files),' Dateien)');
  for fileName in files do
  begin
    res := Parse(TFile.ReadAllText(fileName,TEncoding.UTF8),err);
    try
      Check(TPath.GetFileName(fileName),res <> nil,err);
    finally
      res.Free;
    end;
  end;
  Writeln;
end;

function LocateTestresponses : String;
var
  candidate : String;
  i : Integer;
begin
  //Von der EXE aus nach oben suchen, damit der Test aus jedem Ausgabeordner laeuft
  Result := '';
  candidate := ExtractFilePath(ParamStr(0));
  for i := 0 to 4 do
  begin
    if TDirectory.Exists(TPath.Combine(candidate,'Testresponses')) then
      exit(TPath.Combine(candidate,'Testresponses'));
    candidate := TPath.Combine(candidate,'..');
  end;
end;

var
  responseFolder : String;
begin
  try
    Writeln('OpenMasterdata-for-Delphi - Parsertests');
    Writeln;

    TestInvalidJsonIsRejected;
    Writeln;
    TestNullValues;
    Writeln;
    TestPackagingUnitMeasures;
    Writeln;
    TestLogisticsMeasures;
    Writeln;
    TestNumbersAsStrings;
    Writeln;
    TestDateFormats;
    Writeln;
    TestGtinFix;
    Writeln;
    TestExpiringProduct;
    Writeln;
    TestSpecSpellings;
    Writeln;
    TestRepeatedLoadDoesNotAccumulate;
    Writeln;
    TestEnumCodes;
    Writeln;
    TestDocumentLanguage;
    Writeln;
    TestHtmlSanitizing;
    Writeln;

    if ParamCount > 0 then
      responseFolder := ParamStr(1)
    else
      responseFolder := LocateTestresponses;
    if responseFolder <> '' then
      TestRealResponses(responseFolder);

    Writeln('---');
    Writeln(Format('%d Tests, %d fehlgeschlagen',[TestsRun,TestsFailed]));
    if TestsFailed > 0 then
      ExitCode := 1;
  except
    on E: Exception do
    begin
      Writeln('Unerwartete Ausnahme: ',E.ClassName,' ',E.Message);
      ExitCode := 2;
    end;
  end;
end.
