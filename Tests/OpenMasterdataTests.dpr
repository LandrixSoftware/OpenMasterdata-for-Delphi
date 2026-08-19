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
  intf.OpenMasterdata in '..\intf.OpenMasterdata.pas',
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

//Datum in fester Schreibweise, damit die Tests unabhaengig von den
//Regionseinstellungen des Rechners sind.
function AsIsoDate(_Value : TDateTime) : String;
begin
  Result := FormatDateTime('yyyy-mm-dd',_Value);
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

  //Nicht ueber DateToStr vergleichen, dessen Ergebnis haengt von den
  //Regionseinstellungen des Rechners ab
  CheckEquals('ISO','2026-04-21',AsIsoDate(TOpenMasterdataAPIHelper.JSONStrToDate('2026-04-21')));
  CheckEquals('YYYYMMDD','2026-04-21',AsIsoDate(TOpenMasterdataAPIHelper.JSONStrToDate('20260421')));
  CheckEquals('DDMMYYYY','2026-04-21',AsIsoDate(TOpenMasterdataAPIHelper.JSONStrToDate('21042026')));
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
    CheckEquals('gtin 0 bleibt 0','0',res.gtin);
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
    CheckEquals('reachData','2026-01-01',AsIsoDate(res.logistics.reachDate));
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

procedure TestPriceScale;
var
  res : TOpenMasterdataAPI_Result;
  err : String;
begin
  Writeln('Preisstaffeln');

  res := Parse('{"prices":{"listPrice":[{"value":"10.00","basis":"1"},'+
               '{"value":"9.00","basis":"10"},{"value":"8.00","basis":"100"}],'+
               '"netPrice":{"value":"7.00"}}}',err);
  if res = nil then
  begin
    Check('Antwort parsebar',false,err);
    exit;
  end;
  try
    CheckEquals('listPrice bleibt die erste Stufe','10.00',res.prices.listPrice.value);
    CheckEqualsInt('alle Stufen vorhanden',3,res.prices.listPriceScale.Count);
    if res.prices.listPriceScale.Count = 3 then
    begin
      CheckEquals('zweite Stufe','9.00',res.prices.listPriceScale[1].value);
      CheckEqualsInt('Basis der dritten Stufe',100,res.prices.listPriceScale[2].basis);
    end;
    CheckEquals('Einzelpreis unveraendert','7.00',res.prices.netPrice.value);
    CheckEqualsInt('kein Staffeleintrag bei Einzelpreis',0,res.prices.netPriceScale.Count);
  finally
    res.Free;
  end;
end;

//Felder, die erst mit OM 11 hinzukommen. Antworten nach 9.0.2 enthalten sie nicht;
//liefert ein Echtsystem sie bereits, sollen sie nicht verlorengehen.
procedure TestOpenMasterdata11Fields;
var
  res : TOpenMasterdataAPI_Result;
  err : String;
begin
  Writeln('Felder ab OM 11');

  res := Parse('{"supplierPid":"A1","status":"951",'+
               '"basic":{"noOrderBefore":"2026-01-01","noDeliveryBefore":"2026-02-01",'+
               '"noMarketingBefore":"2026-03-01","sparepartsystemURL":"https://x/ersatzteile",'+
               '"sparepartsystemdescription":"Ersatzteilportal"},'+
               '"additional":{"accessorieGroupIdManufacturer":"ZG7",'+
               '"accessorieGroupDescrManufacturer":"Zubehoergruppe 7"},'+
               '"prices":{"netPrice":[{"value":"10.00","lowerBound":"1.000"},'+
               '{"value":"9.00","lowerBound":"10.000"}],'+
               '"promotionalPrice":[{"value":"7.50","lowerBound":"1.000",'+
               '"startOfValidity":"2026-04-01","endOfValidity":"2026-04-30"}]}}',err);
  if res = nil then
  begin
    Check('Antwort parsebar',false,err);
    exit;
  end;
  try
    CheckEqualsInt('status',951,res.status);
    CheckEquals('noOrderBefore','2026-01-01',AsIsoDate(res.basic.noOrderBefore));
    CheckEquals('noDeliveryBefore','2026-02-01',AsIsoDate(res.basic.noDeliveryBefore));
    CheckEquals('noMarketingBefore','2026-03-01',AsIsoDate(res.basic.noMarketingBefore));
    CheckEquals('sparepartsystemURL','https://x/ersatzteile',res.basic.sparepartsystemURL);
    CheckEquals('sparepartsystemdescription','Ersatzteilportal',res.basic.sparepartsystemdescription);
    CheckEquals('accessorieGroupIdManufacturer','ZG7',res.additional.accessorieGroupIdManufacturer);
    CheckEquals('accessorieGroupDescrManufacturer','Zubehoergruppe 7',res.additional.accessorieGroupDescrManufacturer);

    //netPrice ist ab OM 11 eine Staffel aus BulkPrice
    CheckEqualsInt('netPrice-Staffel',2,res.prices.netPriceScale.Count);
    if res.prices.netPriceScale.Count = 2 then
    begin
      CheckEquals('lowerBound der ersten Stufe','1.000',res.prices.netPriceScale[0].lowerBound);
      CheckEquals('lowerBound der zweiten Stufe','10.000',res.prices.netPriceScale[1].lowerBound);
    end;

    CheckEqualsInt('Aktionspreis vorhanden',1,res.prices.promotionalPrice.Count);
    if res.prices.promotionalPrice.Count = 1 then
    begin
      CheckEquals('Aktionspreis Wert','7.50',res.prices.promotionalPrice[0].value);
      CheckEquals('Aktionspreis ab','2026-04-01',AsIsoDate(res.prices.promotionalPrice[0].startOfValidity));
      CheckEquals('Aktionspreis bis','2026-04-30',AsIsoDate(res.prices.promotionalPrice[0].endOfValidity));
    end;
  finally
    res.Free;
  end;

  //Eine Antwort nach 9.0.2 darf davon unberuehrt bleiben
  res := Parse('{"supplierPid":"A2","prices":{"netPrice":{"value":"5.00"}}}',err);
  if res <> nil then
  try
    CheckEqualsInt('ohne status bleibt 0',0,res.status);
    CheckEquals('lowerBound bleibt leer','',res.prices.netPrice.lowerBound);
    CheckEqualsInt('kein Aktionspreis',0,res.prices.promotionalPrice.Count);
  finally
    res.Free;
  end
  else
    Check('Antwort nach 9.0.2 parsebar',false,err);
end;

//Wiederholungen bei Ueberlast: welcher Status wird wiederholt und wie lange
//wird gewartet.
procedure TestRetryPolicy;
var
  delay : Integer;

  function Retry(_Status,_Attempt : Integer; const _RetryAfter : String = '';
    _MaxRetries : Integer = 2; _MaxDelay : Integer = 10) : Boolean;
  begin
    Result := TOpenMasterdataApiClient.TryGetRetryDelay(_Status,_Attempt,_MaxRetries,
                _MaxDelay,_RetryAfter,delay);
  end;

begin
  Writeln('Wiederholung bei Ueberlast');

  //Nur Ueberlast-Status werden wiederholt
  Check('429 wird wiederholt',Retry(429,0));
  Check('503 wird wiederholt',Retry(503,0));
  Check('502 wird wiederholt',Retry(502,0));
  Check('504 wird wiederholt',Retry(504,0));
  Check('404 wird nicht wiederholt',not Retry(404,0));
  Check('401 wird nicht wiederholt',not Retry(401,0));
  Check('400 wird nicht wiederholt',not Retry(400,0));
  Check('500 wird nicht wiederholt',not Retry(500,0));
  Check('200 wird nicht wiederholt',not Retry(200,0));

  //Exponentiell: 1s, dann 2s
  Retry(429,0);
  CheckEqualsInt('erster Versuch wartet 1s',1000,delay);
  Retry(429,1);
  CheckEqualsInt('zweiter Versuch wartet 2s',2000,delay);

  //Nach der konfigurierten Anzahl ist Schluss
  Check('dritter Versuch entfaellt',not Retry(429,2));
  Check('Wiederholungen abschaltbar',not Retry(429,0,'',0));

  //Retry-After des Servers hat Vorrang, solange es im Rahmen bleibt
  Check('Retry-After 5s wird akzeptiert',Retry(429,0,'5'));
  CheckEqualsInt('Wartezeit folgt Retry-After',5000,delay);
  Check('Retry-After 0 ist zulaessig',Retry(429,0,'0'));
  CheckEqualsInt('Wartezeit 0',0,delay);

  //Zu lange Wartezeit: lieber sofort einen Fehler melden als blockieren
  Check('Retry-After 60s wird abgelehnt',not Retry(429,0,'60'));
  Check('Retry-After genau am Limit gilt',Retry(429,0,'10'));

  //Der exponentielle Abstand wird durch die Obergrenze gedeckelt
  Check('vierter Versuch bei hoher Grenze',Retry(429,3,'',10,10));
  CheckEqualsInt('vierter Versuch wartet 8s',8000,delay);
  //1 shl 4 waeren 16s, die Obergrenze deckelt auf 10s
  Check('fuenfter Versuch bei hoher Grenze',Retry(429,4,'',10,10));
  CheckEqualsInt('Abstand auf Obergrenze gedeckelt',10000,delay);
  Check('Retry-After am Limit',Retry(429,0,'10'));
  CheckEqualsInt('Wartezeit am Limit',10000,delay);
  Check('negatives Retry-After faellt auf Standardabstand zurueck',Retry(429,0,'-5'));
  CheckEqualsInt('Standardabstand bei negativem Wert',1000,delay);

  //Ein HTTP-Datum in Retry-After wird nicht ausgewertet, dann greift der
  //exponentielle Abstand
  Check('HTTP-Datum faellt auf Standardabstand zurueck',Retry(429,0,'Wed, 21 Oct 2026 07:28:00 GMT'));
  CheckEqualsInt('Standardabstand',1000,delay);
end;

//Die Positivliste des Sanitizers: nicht erlaubte Tags muessen als Tag
//verschwinden, nicht nur ihre Attribute.
procedure TestSanitizerTagAllowlist;
var
  html : String;

  function RenderDescr(const _Descr : String) : String;
  var
    r : TOpenMasterdataAPI_Result;
    e : String;
  begin
    Result := '';
    r := Parse('{"descriptions":{"productDescr":'+_Descr+'}}',e);
    if r = nil then
    begin
      Check('Beschreibung parsebar',false,e);
      exit;
    end;
    try
      Result := TOpenMasterdataAPI_ViewHelper.AsHtml(r);
    finally
      r.Free;
    end;
  end;

begin
  Writeln('Sanitizer: Positivliste der Tags');

  //Nicht erlaubte Tags duerfen nicht als Tag durchkommen
  html := RenderDescr('"<div><img src=\"x\"><svg></svg><iframe></iframe><object></object></div>"');
  Check('img verschwindet',not ContainsText(html,'<img'),html);
  Check('svg verschwindet',not ContainsText(html,'<svg'),html);
  Check('iframe verschwindet',not ContainsText(html,'<iframe'),html);
  Check('object verschwindet',not ContainsText(html,'<object'),html);
  Check('style verschwindet',not ContainsText(RenderDescr('"<div><style>x{}</style></div>"'),'<style'));

  //Erlaubte Tags bleiben, damit die Liste nicht einfach leer sein kann
  html := RenderDescr('"<div><p>A</p><ul><li>B</li></ul><strong>C</strong></div>"');
  Check('div bleibt',ContainsText(html,'<div>'),html);
  Check('p bleibt',ContainsText(html,'<p>A</p>'),html);
  Check('li bleibt',ContainsText(html,'<li>B</li>'),html);
  Check('strong bleibt',ContainsText(html,'<strong>C</strong>'),html);

  //Gross-/Kleinschreibung
  html := RenderDescr('"<DIV><P>Gross</P></DIV>"');
  Check('Grossschreibung wird normalisiert',ContainsText(html,'<p>Gross</p>'),html);

  //Attribute erlaubter Tags entfallen
  html := RenderDescr('"<p style=\"a\" onclick=\"evil()\">Text</p>"');
  Check('Attribut entfaellt',not ContainsText(html,'onclick'),html);
  Check('Text bleibt',ContainsText(html,'Text'),html);
end;

//Der Sanitizer darf Text nicht beschaedigen.
procedure TestSanitizerTextIntegrity;
var
  html : String;

  function RenderDescr(const _Descr : String) : String;
  var
    r : TOpenMasterdataAPI_Result;
    e : String;
  begin
    Result := '';
    r := Parse('{"descriptions":{"productDescr":'+_Descr+'}}',e);
    if r = nil then
    begin
      Check('Beschreibung parsebar',false,e);
      exit;
    end;
    try
      Result := TOpenMasterdataAPI_ViewHelper.AsHtml(r);
    finally
      r.Free;
    end;
  end;

begin
  Writeln('Sanitizer: Text bleibt unversehrt');

  //Ein < im Fliesstext ist keine Tag-Eroeffnung und darf nichts verschlucken
  html := RenderDescr('"<p>Druck < 3 bar und Temperatur > 5 Grad, Ende</p>"');
  Check('Text nach < bleibt erhalten',ContainsText(html,'3 bar'),html);
  Check('Text am Ende bleibt erhalten',ContainsText(html,'Ende'),html);

  //Bereits maskierte Entities duerfen nicht ein zweites Mal maskiert werden
  html := RenderDescr('"<p>Anschlussgroesse 1/2&quot; &amp; Dichtung &szlig; Ende</p>"');
  Check('Entity bleibt einfach maskiert',not ContainsText(html,'&amp;szlig;'),html);
  Check('kaufmaennisches Und bleibt Entity',not ContainsText(html,'&amp;amp;'),html);

  //Klartext mit spitzen Klammern darf nicht als HTML gelten und geloescht werden
  html := RenderDescr('"Druck <pmax> bar, Spannung <phase L1> pruefen"');
  Check('pmax bleibt erhalten',ContainsText(html,'pmax'),html);
  Check('phase bleibt erhalten',ContainsText(html,'phase'),html);
end;

//SafeUrl muss zulaessige Adressen durchlassen, sonst verschwindet die halbe Seite.
procedure TestSafeUrlKeepsValidLinks;
var
  res : TOpenMasterdataAPI_Result;
  err,html : String;
begin
  Writeln('Zulaessige Adressen bleiben erhalten');

  res := Parse('{"additional":{"deepLink":"https://example.org/artikel/1"},'+
               '"pictures":[{"url":"http://example.org/bild.jpg"}],'+
               '"documents":[{"url":"https://example.org/datenblatt.pdf"}]}',err);
  if res = nil then
  begin
    Check('Antwort parsebar',false,err);
    exit;
  end;
  try
    html := TOpenMasterdataAPI_ViewHelper.AsHtml(res);
    Check('deepLink verlinkt',ContainsText(html,'href="https://example.org/artikel/1"'),html);
    Check('Bild eingebunden',ContainsText(html,'src="http://example.org/bild.jpg"'),html);
    Check('Dokument verlinkt',ContainsText(html,'href="https://example.org/datenblatt.pdf"'),html);
  finally
    res.Free;
  end;

  //Ein unzulaessiges Schema darf keinen Link erzeugen
  res := Parse('{"additional":{"deepLink":"javascript:alert(1)"}}',err);
  if res <> nil then
  try
    html := TOpenMasterdataAPI_ViewHelper.AsHtml(res);
    Check('kein leerer Link bei unzulaessigem Schema',not ContainsText(html,'href=""'),html);
  finally
    res.Free;
  end
  else
    Check('Antwort parsebar',false,err);
end;

//Ein zweites Laden darf keine Werte des ersten Artikels stehen lassen.
procedure TestReloadResetsEverything;
var
  res : TOpenMasterdataAPI_Result;
  err : String;
begin
  Writeln('Zweites Laden setzt alles zurueck');

  res := TOpenMasterdataAPI_Result.Create;
  try
    Check('erstes Laden',res.TryLoadFromJson(
      '{"supplierPid":"A1","gtin":"4001","status":"200",'+
      '"basic":{"matchcode":"M1","noOrderBefore":"2026-01-01","rrp":{"value":"9.00"}},'+
      '"descriptions":{"productDescr":"Text 1","shorttext1":"S1"},'+
      '"additional":{"deepLink":"https://x/1","accessorieGroupIdManufacturer":"ZG1",'+
      '"alternativeProduct":[{"supplierPid":"B1"}],"accessories":[{"supplierPid":"C1"}],'+
      '"sets":[{"supplierPid":"D1"}],"attribute":[{"attributeName":"N"}],'+
      '"followupProduct":[{"supplierPid":"E1"}]},'+
      '"logistics":{"countryOfOrigin":"DE","measureA":{"measure":"5"},'+
      '"weight":{"weight":"1.5"},"packagingUnits":[{"packagingType":"CT"}]},'+
      '"prices":{"rrp":{"value":"19.99","currency":"EUR"},'+
      '"listPrice":[{"value":"10.00"},{"value":"9.00"}],'+
      '"netPrice":{"value":"8.00"},"rawMaterial":[{"material":"CU"}],'+
      '"linePrice":[{"value":"1.00"}],'+
      '"promotionalPrice":[{"value":"7.00","startOfValidity":"2026-04-01"}]},'+
      '"pictures":[{"url":"http://x/1.jpg"}],"documents":[{"url":"http://x/1.pdf"}],'+
      '"sparepartlists":{"listNumber":"L1"}}',err),err);

    //Zweites Laden mit einer Antwort, die fast nichts enthaelt
    Check('zweites Laden',res.TryLoadFromJson('{"supplierPid":"A2"}',err),err);

    CheckEquals('supplierPid neu','A2',res.supplierPid);
    CheckEquals('gtin zurueckgesetzt','',res.gtin);
    CheckEqualsInt('status zurueckgesetzt',0,res.status);
    CheckEquals('matchcode zurueckgesetzt','',res.basic.matchcode);
    Check('noOrderBefore zurueckgesetzt',res.basic.noOrderBefore = 0);
    CheckEquals('basic.rrp zurueckgesetzt','',res.basic.rrp.value);
    CheckEquals('prices.rrp zurueckgesetzt','',res.prices.rrp.value);
    CheckEquals('prices.rrp.currency zurueckgesetzt','',res.prices.rrp.currency);
    CheckEquals('productDescr zurueckgesetzt','',res.descriptions.productDescr);
    CheckEquals('shorttext1 zurueckgesetzt','',res.descriptions.shorttext1);
    CheckEquals('deepLink zurueckgesetzt','',res.additional.deepLink);
    CheckEquals('Zubehoergruppe zurueckgesetzt','',res.additional.accessorieGroupIdManufacturer);
    CheckEquals('countryOfOrigin zurueckgesetzt','',res.logistics.countryOfOrigin);
    CheckEquals('measureA zurueckgesetzt','',res.logistics.measureA.measure);
    CheckEquals('logistics.weight zurueckgesetzt','',res.logistics.weight.weight);
    CheckEquals('listPrice zurueckgesetzt','',res.prices.listPrice.value);
    CheckEquals('netPrice zurueckgesetzt','',res.prices.netPrice.value);
    CheckEquals('sparepartlist zurueckgesetzt','',res.sparepartlist.listNumber);

    //Alle Listen muessen leer sein
    CheckEqualsInt('pictures leer',0,res.pictures.Count);
    CheckEqualsInt('documents leer',0,res.documents.Count);
    CheckEqualsInt('alternativeProduct leer',0,res.additional.alternativeProduct.Count);
    CheckEqualsInt('followupProduct leer',0,res.additional.followupProduct.Count);
    CheckEqualsInt('accessories leer',0,res.additional.accessories.Count);
    CheckEqualsInt('sets leer',0,res.additional.sets.Count);
    CheckEqualsInt('attribute leer',0,res.additional.attribute.Count);
    CheckEqualsInt('packagingUnits leer',0,res.logistics.packagingUnits.Count);
    CheckEqualsInt('rawMaterial leer',0,res.prices.rawMaterial.Count);
    CheckEqualsInt('linePrice leer',0,res.prices.linePrice.Count);
    CheckEqualsInt('listPriceScale leer',0,res.prices.listPriceScale.Count);
    CheckEqualsInt('netPriceScale leer',0,res.prices.netPriceScale.Count);
    CheckEqualsInt('rrpScale leer',0,res.prices.rrpScale.Count);
    CheckEqualsInt('promotionalPrice leer',0,res.prices.promotionalPrice.Count);
    CheckEqualsInt('sparepartlistRow leer',0,res.sparepartlist.sparepartlistRow.Count);
  finally
    res.Free;
  end;
end;

//Enum-Codes muessen auf sich selbst zurueckabbilden, nicht nur ungleich Unknown sein.
procedure TestEnumRoundTrip;
var
  code : String;
begin
  Writeln('Enum-Codes bilden auf sich selbst ab');

  for code in ['BB','CT','GEB','PMS','BTL','STG'] do
    CheckEquals('PackageType '+code,code,
      TOpenMasterdataAPI_PackageTypeHelper.PackageTypeToStr(
        TOpenMasterdataAPI_PackageTypeHelper.PackageTypeFromStr(code)));

  for code in ['AL','CU','MK','SN','W'] do
    CheckEquals('RawMaterial '+code,code,
      TOpenMasterdataAPI_RawMaterialHelper.RawMaterialToStr(
        TOpenMasterdataAPI_RawMaterialHelper.RawMaterialFromStr(code)));
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
    begin
      //Ohne diese Meldung waeren alle folgenden Negativ-Pruefungen auf einem
      //Leerstring trivial erfuellt und der Test damit wertlos
      Check('Beschreibung parsebar',false,e);
      exit;
    end;
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

//Die Maskierung muss in beide Richtungen stimmen: zu wenig maskieren ist
//gefaehrlich, zu viel zerstoert die Anzeige. Beide Tests sind deshalb positiv
//formuliert, nicht als blosse Abwesenheitspruefung.
procedure TestSanitizerEscaping;
var
  html : String;

  function RenderDescr(const _Descr : String) : String;
  var
    r : TOpenMasterdataAPI_Result;
    e : String;
  begin
    Result := '';
    r := Parse('{"descriptions":{"productDescr":'+_Descr+'}}',e);
    if r = nil then
    begin
      Check('Beschreibung parsebar',false,e);
      exit;
    end;
    try
      Result := TOpenMasterdataAPI_ViewHelper.AsHtml(r);
    finally
      r.Free;
    end;
  end;

begin
  Writeln('Sanitizer: Maskierung in beide Richtungen');

  //Ein rohes Und muss maskiert werden, ein bereits maskiertes nicht doppelt
  html := RenderDescr('"<p>Rohr & Fitting, Stahl &amp; Eisen</p>"');
  Check('rohes Und wird maskiert',ContainsText(html,'Rohr &amp; Fitting'),html);
  Check('Entity bleibt einfach maskiert',ContainsText(html,'Stahl &amp; Eisen'),html);

  //Dasselbe im Klartextpfad, also ohne jedes Tag
  html := RenderDescr('"Anschluss &szlig; und &ouml; sowie A & B"');
  Check('Entity im Klartext bleibt erhalten',ContainsText(html,'&szlig;'),html);
  Check('Entity im Klartext nicht doppelt maskiert',not ContainsText(html,'&amp;szlig;'),html);
  Check('rohes Und im Klartext wird maskiert',ContainsText(html,'A &amp; B'),html);

  //Das Kleiner-Zeichen selbst muss als Entity ankommen, nicht nur der Folgetext
  html := RenderDescr('"<p>Druck < 3 bar und Temperatur > 5 Grad, Ende</p>"');
  Check('kleiner-Zeichen bleibt als Entity',ContainsText(html,'Druck &lt; 3 bar'),html);
  Check('groesser-Zeichen bleibt als Entity',ContainsText(html,'&gt; 5 Grad'),html);
  Check('Text am Ende bleibt erhalten',ContainsText(html,'Ende'),html);

  //Ein groesser-Zeichen im Attributwert darf das Tag nicht vorzeitig beenden
  html := RenderDescr('"<p title=\"a>b\">Text</p>"');
  Check('Attributwert mit groesser-Zeichen beendet Tag nicht',
    ContainsText(html,'<p>Text</p>'),html);
  html := RenderDescr('"<p>A</p><img src=\">\" onerror=\"alert(1)\">B"');
  Check('kein Attributrest im Text',not ContainsText(html,'onerror'),html);

  //Ein Nullzeichen wuerde die Anzeige abschneiden
  html := RenderDescr('"<p>vor'+#0+'nach</p>"');
  Check('Text nach dem Nullzeichen bleibt erhalten',ContainsText(html,'nach'),html);
end;

//Die Laufzeit muss linear bleiben. Eine fehlerhafte Antwort darf die Anzeige
//nicht minutenlang blockieren.
procedure TestSanitizerPerformance;
var
  res : TOpenMasterdataAPI_Result;
  builder : TStringBuilder;
  payload,html : String;
  startTicks : TDateTime;
  elapsedMs : Int64;
  i : Integer;
begin
  Writeln('Sanitizer: Laufzeit bei entarteter Eingabe');

  builder := TStringBuilder.Create;
  try
    //Kein einziges schliessendes Groesserzeichen: der Worst Case
    for i := 1 to 100000 do
      builder.Append('<a');
    payload := builder.ToString;
  finally
    builder.Free;
  end;

  res := TOpenMasterdataAPI_Result.Create;
  try
    res.descriptions.productDescr := payload;
    startTicks := Now;
    html := TOpenMasterdataAPI_ViewHelper.AsHtml(res);
    elapsedMs := MilliSecondsBetween(Now,startTicks);
    Check('200000 Zeichen in unter 2 Sekunden',elapsedMs < 2000,
      IntToStr(elapsedMs)+' ms');
    Check('Ausgabe nicht leer',html <> '');
  finally
    res.Free;
  end;
end;

//Zahlfelder: dezimal geschriebene Ganzzahlen zaehlen, echte Kommawerte nicht.
procedure TestIntegerParsing;
var
  res : TOpenMasterdataAPI_Result;
  err : String;
begin
  Writeln('Zahlfelder aus Dezimalschreibweise');

  res := Parse('{"documents":[{"url":"http://x/1.pdf","size":"1024.0","sortOrder":"2.0"}]}',err);
  if res = nil then
    Check('Antwort parsebar',false,err)
  else
  try
    CheckEqualsInt('size aus Dezimalschreibweise',1024,res.documents[0].size);
    CheckEqualsInt('sortOrder aus Dezimalschreibweise',2,res.documents[0].sortOrder);
  finally
    res.Free;
  end;

  //Ein echter Kommawert ist fachlich unzulaessig und wird nicht gerundet
  res := Parse('{"documents":[{"url":"http://x/2.pdf","size":"1024.6"}]}',err);
  if res <> nil then
  try
    CheckEqualsInt('Kommawert wird nicht gerundet',0,res.documents[0].size);
  finally
    res.Free;
  end
  else
    Check('Antwort parsebar',false,err);
end;

//Die Obergrenzen der Wiederholungsstrategie.
procedure TestRetryPolicyLimits;
var
  retries,delaySeconds : Integer;
begin
  Writeln('Grenzen der Wiederholungsstrategie');

  retries := 40; delaySeconds := 100000;
  TOpenMasterdataApiClient.ClampRetryPolicy(retries,delaySeconds);
  CheckEqualsInt('Wiederholungen gedeckelt',10,retries);
  CheckEqualsInt('Wartezeit gedeckelt',300,delaySeconds);

  retries := -1; delaySeconds := -1;
  TOpenMasterdataApiClient.ClampRetryPolicy(retries,delaySeconds);
  CheckEqualsInt('negative Wiederholungen auf 0',0,retries);
  CheckEqualsInt('negative Wartezeit auf 0',0,delaySeconds);

  retries := 2; delaySeconds := 10;
  TOpenMasterdataApiClient.ClampRetryPolicy(retries,delaySeconds);
  CheckEqualsInt('Standardwert unveraendert',2,retries);
  CheckEqualsInt('Standardwartezeit unveraendert',10,delaySeconds);
end;

//Die Ursprungspruefung entscheidet, ob ein Zugriffstoken mitgesendet werden
//darf. Ein Praefixvergleich waere hier eine Luecke.
//Scheitert ein Login, entscheidet die Meldung darueber, ob der Anwender die
//Ursache findet. Die Antworten stammen aus echten Zugaengen.
//Die Auswahl der Datenpakete kommt aus der Konfiguration. Ein Tippfehler darf
//nicht dazu fuehren, dass stillschweigend nichts oder etwas Falsches abgefragt
//wird.
procedure TestDataPackagesFromString;
var
  packages : TOpenMasterdataAPI_DataPackages;
  unknownNames : TStringList;
  package : TOpenMasterdataAPI_DataPackage;

  function Parse(const _Value : String) : TOpenMasterdataAPI_DataPackages;
  begin
    Result := TOpenMasterdataAPI_DataPackageHelper.DataPackagesFromString(_Value,
                TOpenMasterdataAPI_DataPackageHelper.ALL_DATAPACKAGES,unknownNames);
  end;

begin
  Writeln('Datenpakete aus der Konfiguration');

  unknownNames := TStringList.Create;
  try
    //Ohne Angabe gilt die Vorgabe
    Check('leere Angabe ergibt die Vorgabe',
      Parse('') = TOpenMasterdataAPI_DataPackageHelper.ALL_DATAPACKAGES);
    Check('nur Leerzeichen ergibt die Vorgabe',
      Parse('   ') = TOpenMasterdataAPI_DataPackageHelper.ALL_DATAPACKAGES);

    //Genau die genannten Pakete, nicht mehr
    packages := Parse('basic,prices');
    Check('basic ist enthalten',omd_datapackage_basic in packages);
    Check('prices ist enthalten',omd_datapackage_prices in packages);
    Check('additional ist nicht enthalten',not (omd_datapackage_additional in packages));
    Check('documents ist nicht enthalten',not (omd_datapackage_documents in packages));

    //Die Trenner, die in einer Ini-Datei vorkommen
    Check('Semikolon trennt',Parse('basic;prices') = Parse('basic,prices'));
    Check('senkrechter Strich trennt',Parse('basic|prices') = Parse('basic,prices'));
    Check('Leerzeichen trennt',Parse('basic prices') = Parse('basic,prices'));
    Check('Leerzeichen um die Namen stoeren nicht',
      Parse(' basic , prices ') = Parse('basic,prices'));

    //Gross- und Kleinschreibung wie in der Spec
    Check('Grossschreibung wird erkannt',Parse('BASIC,Prices') = Parse('basic,prices'));

    //Ein Tippfehler darf nicht stillschweigend untergehen
    unknownNames.Clear;
    packages := Parse('basic,preise');
    Check('bekanntes Paket bleibt erhalten',omd_datapackage_basic in packages);
    Check('unbekannter Name wird gemeldet',unknownNames.IndexOf('preise') >= 0,
      unknownNames.CommaText);

    //Nennt die Angabe nur Unsinn, waere eine leere Auswahl unbrauchbar
    unknownNames.Clear;
    Check('unbrauchbare Angabe ergibt die Vorgabe',
      Parse('quatsch') = TOpenMasterdataAPI_DataPackageHelper.ALL_DATAPACKAGES);
    Check('auch dann wird der Name gemeldet',unknownNames.Count = 1,
      unknownNames.CommaText);

    //Doppelnennung ist harmlos
    Check('Doppelnennung aendert nichts',Parse('basic,basic') = Parse('basic'));

    //Jeder Paketname der Spec muss lesbar sein
    for package := Low(TOpenMasterdataAPI_DataPackage) to High(TOpenMasterdataAPI_DataPackage) do
    begin
      unknownNames.Clear;
      packages := Parse(TOpenMasterdataAPI_DataPackageHelper.DataPackageAsString(package));
      Check('Paketname '+TOpenMasterdataAPI_DataPackageHelper.DataPackageAsString(package)+
        ' wird erkannt',(packages = [package]) and (unknownNames.Count = 0));
    end;

    //Der Weg zurueck muss dasselbe ergeben
    Check('Hin- und Rueckweg stimmen ueberein',
      Parse(StringReplace(TOpenMasterdataAPI_DataPackageHelper.DataPackagesAsString(
        [omd_datapackage_basic,omd_datapackage_pictures]),'%7C',',',[rfReplaceAll])) =
      [omd_datapackage_basic,omd_datapackage_pictures]);
  finally
    unknownNames.Free;
  end;
end;

procedure TestOAuthFailureMessage;

  function Describe(const _Content : String) : String;
  begin
    Result := TOpenMasterdataApiClient.DescribeOAuthFailure(_Content);
  end;

var
  msg : String;
begin
  Writeln('Meldung bei fehlgeschlagenem Login');

  //FEGA & Schmitt: gueltiges JSON, aber nur ein Fehlerfeld
  msg := Describe('{"error":"Anmeldung fehlgeschlagen!"}');
  Check('Fehlertext des Servers wird genannt',
    ContainsText(msg,'Anmeldung fehlgeschlagen'),msg);
  Check('nicht faelschlich als ungueltiges JSON gemeldet',
    not ContainsText(msg,'not valid JSON'),msg);

  //Richter+Frenzel: error samt Beschreibung nach RFC 6749
  msg := Describe('{"error_description":"OAuth 2.0 Parameter: grant_type",'+
                  '"error":"unsupported_grant_type"}');
  Check('Fehlercode wird genannt',ContainsText(msg,'unsupported_grant_type'),msg);
  Check('Beschreibung wird genannt',ContainsText(msg,'OAuth 2.0 Parameter'),msg);

  //Gueltiges JSON, kein Token, kein Fehlerfeld
  msg := Describe('{"foo":"bar"}');
  Check('fehlender Token wird benannt',ContainsText(msg,'no access_token'),msg);

  //Eine Anmeldeseite statt einer Token-Antwort
  msg := Describe('<html><body>Bitte anmelden</body></html>');
  Check('HTML wird als solches gemeldet',ContainsText(msg,'HTML'),msg);
  Check('Text der Seite bleibt lesbar',ContainsText(msg,'Bitte anmelden'),msg);

  //Wirklich kein JSON
  msg := Describe('Access denied');
  Check('unlesbare Antwort wird gemeldet',ContainsText(msg,'not valid JSON'),msg);
  Check('Inhalt bleibt sichtbar',ContainsText(msg,'Access denied'),msg);

  //Leere Antwort
  msg := Describe('   ');
  Check('leere Antwort wird gemeldet',ContainsText(msg,'empty'),msg);

  //Ein Zugriffstoken darf nie in der Meldung landen
  msg := Describe('{"error":"invalid_grant","access_token":"GEHEIM123"}');
  Check('Token erscheint nicht in der Meldung',not ContainsText(msg,'GEHEIM123'),msg);
end;

procedure TestSameOrigin;

  function Origin(const _Uri : String) : Boolean;
  begin
    Result := TOpenMasterdataApiClient.IsSameOrigin(_Uri,'https','api.example.org',443);
  end;

begin
  Writeln('Ursprungspruefung');

  Check('gleicher Ursprung',Origin('https://api.example.org/v1/artikel'));
  Check('Standardport ausgeschrieben',Origin('https://api.example.org:443/v1/artikel'));
  Check('Grossschreibung im Host',Origin('https://API.EXAMPLE.ORG/v1/artikel'));

  //Genau der Angriff, gegen den die Pruefung gerichtet ist
  Check('Host nur als Praefix wird abgelehnt',
    not Origin('https://api.example.org.angreifer.tld/logo.png'));
  Check('Host mit Bindestrich-Anhang wird abgelehnt',
    not Origin('https://api.example.org-angreifer.tld/logo.png'));
  Check('eingebettete Zugangsdaten werden abgelehnt',
    not Origin('https://api.example.org@angreifer.tld/logo.png'));

  Check('abweichender Port wird abgelehnt',not Origin('https://api.example.org:8443/v1'));
  Check('abweichendes Schema wird abgelehnt',not Origin('http://api.example.org/v1'));
  Check('fremder Host wird abgelehnt',not Origin('https://angreifer.tld/v1'));

  //Formen, die kein Ursprung sind
  Check('data-Adresse wird abgelehnt',not Origin('data:text/html,<b>x</b>'));
  Check('relativer Pfad wird abgelehnt',not Origin('/v1/artikel'));
  Check('leere Adresse wird abgelehnt',not Origin(''));
  Check('unlesbare Adresse wird abgelehnt',not Origin('kein uri'));

  //Ohne konfigurierten Host darf nie zugestimmt werden
  Check('ohne Host kein Ursprung',
    not TOpenMasterdataApiClient.IsSameOrigin('https://api.example.org/v1','https','',443));
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
      //Nicht nur parsebar, sondern auch inhaltlich gefuellt
      if res = nil then
        Check(TPath.GetFileName(fileName),false,err)
      else
        //Mindestens ein Identifikationsmerkmal muss angekommen sein. Nicht jede
        //Antwort enthaelt supplierPid, etwa die Verbandsdaten des ZVSHK.
        Check(TPath.GetFileName(fileName),
          (res.supplierPid <> '') or (res.gtin <> '') or (res.manufacturerPid <> ''),
          'kein Identifikationsmerkmal gelesen, die Antwort wurde nicht ausgewertet');
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
  ReportMemoryLeaksOnShutdown := true;
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
    TestPriceScale;
    Writeln;
    TestOpenMasterdata11Fields;
    Writeln;
    TestRetryPolicy;
    Writeln;
    TestHtmlSanitizing;
    Writeln;
    TestSanitizerTagAllowlist;
    Writeln;
    TestSanitizerTextIntegrity;
    Writeln;
    TestSafeUrlKeepsValidLinks;
    Writeln;
    TestReloadResetsEverything;
    Writeln;
    TestEnumRoundTrip;
    Writeln;
    TestSanitizerEscaping;
    Writeln;
    TestSanitizerPerformance;
    Writeln;
    TestIntegerParsing;
    Writeln;
    TestRetryPolicyLimits;
    Writeln;
    TestSameOrigin;
    Writeln;
    TestOAuthFailureMessage;
    Writeln;
    TestDataPackagesFromString;
    Writeln;

    if ParamCount > 0 then
      responseFolder := ParamStr(1)
    else
      responseFolder := LocateTestresponses;
    if responseFolder <> '' then
      TestRealResponses(responseFolder)
    else
      Writeln('Echte Lieferanten-Antworten: Ordner nicht gefunden, uebersprungen');

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
