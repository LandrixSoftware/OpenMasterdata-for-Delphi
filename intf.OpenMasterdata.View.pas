﻿{
License OpenMasterdata-for-Delphi

Copyright (C) 2024 Landrix Software GmbH & Co. KG
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

unit intf.OpenMasterdata.View;

interface

uses
  System.Classes,System.SysUtils,System.IOUtils,DateUtils,System.StrUtils
  ,System.Generics.Collections,System.Generics.Defaults
  ,intf.OpenMasterdata.Types
  ;

type
  TOpenMasterdataAPI_ViewHelper = class
  public
    class function AsHtml(_Val : TOpenMasterdataAPI_Result) : String;
  end;

implementation

{ TOpenMasterdataAPI_ViewHelper }

class function TOpenMasterdataAPI_ViewHelper.AsHtml(
  _Val: TOpenMasterdataAPI_Result): String;
var
  html : TStringList;
  i : Integer;
begin
  Result := '';
  html := TStringList.Create;
  try
    html.Add('<html>');
    html.Add('<body>');
    html.Add('<h1>Artikel-Nr.: '+_Val.supplierPid+'</h1>');
    html.Add('<h2>'+_Val.basic.productShortDescr+'</h2>');
    if _Val.descriptions.productDescr <> '' then
      html.Add('<p>'+_Val.descriptions.productDescr+'</p>');

    if (_Val.additional.deepLink <> '') then
      html.Add('<a href="'+_Val.additional.deepLink+'" target="_blank">Weitere Details online</a><br/>');
    if _Val.basic.startOfValidity > 0 then
      html.Add('G&uuml;ltig ab: '+DateToStr(_Val.basic.startOfValidity)+'<br/>');
    if (_Val.basic.mainCommodityGroupId <> '') then
      html.Add('Hauptwarengruppe: '+_Val.basic.mainCommodityGroupId+' '+_Val.basic.mainCommodityGroupDescr+'<br/>');
    if (_Val.basic.commodityGroupId <> '') then
      html.Add('Warengruppe: '+_Val.basic.commodityGroupId+' '+_Val.basic.commodityGroupDescr+'<br/>');
    html.Add('<br/>');
    if (_Val.basic.priceOnDemand) then
      html.Add('Preis nur auf Anfrage.<br/>');
    if (_Val.prices.listPrice.ValueAsCurrency > 0) then
      html.Add('Listenpreis: '+Format('%n %s',[_Val.prices.listPrice.ValueAsCurrency,_Val.prices.listPrice.currency])+'<br/>');
    if (_Val.prices.netPrice.ValueAsCurrency > 0) then
      html.Add('Einkaufspreis: '+Format('%n %s',[_Val.prices.netPrice.ValueAsCurrency,_Val.prices.netPrice.currency])+'<br/>');

    html.Add('<br/>');
    if _Val.pictures.Count > 0 then
      html.Add('<h3>Bilder</h3>');
    for i := 0 to _Val.pictures.Count-1 do
    begin
      html.Add('<img src="'+IfThen(_Val.pictures[i].urlThumbnail.IsEmpty,_Val.pictures[i].url,_Val.pictures[i].urlThumbnail)+'"></img><br/>');
    end;

    html.Add('<br/>');
    if _Val.documents.Count > 0 then
      html.Add('<h3>Dokumente</h3>');
    for i := 0 to _Val.documents.Count-1 do
    begin
      html.Add('<a href="'+_Val.documents[i].url+'">'+_Val.documents[i].url+'</a><br/>');
    end;

    html.Add('');
    html.Add('');
    html.Add('');
    html.Add('');
    html.Add('');
    html.Add('</body>');
    html.Add('</html>');

    Result := html.Text;
  finally
    html.Free;
  end;
end;

end.
