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

  function HtmlEncode(const _Value : String) : String;
  begin
    Result := StringReplace(_Value,'&','&amp;',[rfReplaceAll]);
    Result := StringReplace(Result,'<','&lt;',[rfReplaceAll]);
    Result := StringReplace(Result,'>','&gt;',[rfReplaceAll]);
    Result := StringReplace(Result,'"','&quot;',[rfReplaceAll]);
  end;

  function LooksLikeSupportedHtml(const _Value : String) : Boolean;
  var
    trimmedValue : String;
  begin
    trimmedValue := TrimLeft(_Value);
    Result := ContainsText(trimmedValue,'<div')
      or ContainsText(trimmedValue,'<p')
      or ContainsText(trimmedValue,'<ul')
      or ContainsText(trimmedValue,'<ol')
      or ContainsText(trimmedValue,'<table')
      or ContainsText(trimmedValue,'<span')
      or ContainsText(trimmedValue,'<br')
      or ContainsText(trimmedValue,'<strong')
      or ContainsText(trimmedValue,'<em');
  end;

  function ContainsUnsafeHtml(const _Value : String) : Boolean;
  begin
    Result := ContainsText(_Value,'<script')
      or ContainsText(_Value,'<iframe')
      or ContainsText(_Value,'<object')
      or ContainsText(_Value,'<embed')
      or ContainsText(_Value,'<link')
      or ContainsText(_Value,'<meta')
      or ContainsText(_Value,'javascript:')
      or ContainsText(_Value,'vbscript:')
      or ContainsText(_Value,'data:text/html')
      or ContainsText(_Value,' onload=')
      or ContainsText(_Value,' onclick=')
      or ContainsText(_Value,' onerror=')
      or ContainsText(_Value,' onmouseover=');
  end;

  function RenderDescription(const _Value : String) : String;
  begin
    if _Value = '' then
      exit('');

    if LooksLikeSupportedHtml(_Value) and (not ContainsUnsafeHtml(_Value)) then
      exit(_Value);

    Result := HtmlEncode(_Value);
    Result := StringReplace(Result,sLineBreak,'<br/>',[rfReplaceAll]);
    Result := StringReplace(Result,#10,'<br/>',[rfReplaceAll]);
    Result := StringReplace(Result,#13,'',[rfReplaceAll]);
    Result := '<p>' + Result + '</p>';
  end;
begin
  Result := '';
  html := TStringList.Create;
  try
    html.Add('<html>');
    html.Add('<body>');
    html.Add('<h1>Artikel-Nr.: '+HtmlEncode(_Val.supplierPid)+'</h1>');
    html.Add('<h2>'+HtmlEncode(_Val.basic.productShortDescr)+'</h2>');
    if _Val.descriptions.productDescr <> '' then
      html.Add(RenderDescription(_Val.descriptions.productDescr));

    if (_Val.additional.deepLink <> '') then
      html.Add('<a href="'+HtmlEncode(_Val.additional.deepLink)+'" target="_blank">Weitere Details online</a><br/>');
    if _Val.basic.startOfValidity > 0 then
      html.Add('G&uuml;ltig ab: '+DateToStr(_Val.basic.startOfValidity)+'<br/>');
    if _Val.additional.expiringProduct then
    begin
      if _Val.additional.expiringProductHasSuccessor then
        html.Add('Auslaufartikel mit Nachfolgeartikel.<br/>')
      else
        html.Add('Auslaufartikel.<br/>');
    end;
    if (_Val.basic.mainCommodityGroupId <> '') then
      html.Add('Hauptwarengruppe: '+HtmlEncode(_Val.basic.mainCommodityGroupId)+' '+HtmlEncode(_Val.basic.mainCommodityGroupDescr)+'<br/>');
    if (_Val.basic.commodityGroupId <> '') then
      html.Add('Warengruppe: '+HtmlEncode(_Val.basic.commodityGroupId)+' '+HtmlEncode(_Val.basic.commodityGroupDescr)+'<br/>');
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
      html.Add('<img src="'+HtmlEncode(IfThen(_Val.pictures[i].urlThumbnail.IsEmpty,_Val.pictures[i].url,_Val.pictures[i].urlThumbnail))+'"></img><br/>');
    end;

    html.Add('<br/>');
    if _Val.documents.Count > 0 then
      html.Add('<h3>Dokumente</h3>');
    for i := 0 to _Val.documents.Count-1 do
    begin
      if _Val.documents[i].description <> '' then
        html.Add(HtmlEncode(_Val.documents[i].description)+'<br/>');
      html.Add('<a href="'+HtmlEncode(_Val.documents[i].url)+'">'+HtmlEncode(_Val.documents[i].url)+'</a><br/>');
    end;

    if _Val.additional.attribute.Count > 0 then
    begin
      html.Add('<br/>');
      html.Add('<h3>Attribute</h3>');
      for i := 0 to _Val.additional.attribute.Count-1 do
      begin
        html.Add('<strong>'+HtmlEncode(_Val.additional.attribute[i].attributeName)+'</strong>: '+
          HtmlEncode(_Val.additional.attribute[i].attributeValue1));
        if _Val.additional.attribute[i].attributeValue2 <> '' then
          html[html.Count-1] := html[html.Count-1] + ' / ' + HtmlEncode(_Val.additional.attribute[i].attributeValue2);
        html[html.Count-1] := html[html.Count-1] + '<br/>';
      end;
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
