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

  //Nur diese Tags duerfen unveraendert durchgereicht werden. Eine Positivliste
  //ist hier zwingend: eine Sperrliste laesst sich mit Varianten wie
  //<img src=x onerror =...> oder <svg onload=...> umgehen.
  function IsAllowedTag(const _TagName : String) : Boolean;
  const
    CAllowedTags : array[0..13] of String = (
      'p','br','div','span','ul','ol','li','table','tr','td','th','strong','em','b');
  var
    allowed : String;
  begin
    Result := false;
    for allowed in CAllowedTags do
      if SameText(_TagName,allowed) then
        exit(true);
  end;

  //Entfernt alle nicht erlaubten Tags und saemtliche Attribute. Damit bleiben
  //Absaetze und Listen der Lieferantenbeschreibung erhalten, waehrend
  //Ereignis-Attribute, Skripte und aktive URLs nicht ins Ergebnis gelangen.
  function SanitizeHtml(const _Value : String) : String;
  var
    i,tagStart : Integer;
    tagContent,tagName : String;
    isClosingTag : Boolean;
    builder : TStringBuilder;
  begin
    builder := TStringBuilder.Create;
    try
      i := 1;
      while i <= Length(_Value) do
      begin
        if _Value[i] <> '<' then
        begin
          //Zeichen ausserhalb von Tags werden maskiert
          case _Value[i] of
            '&' : builder.Append('&amp;');
            '>' : builder.Append('&gt;');
            '"' : builder.Append('&quot;');
          else
            builder.Append(_Value[i]);
          end;
          Inc(i);
          continue;
        end;

        tagStart := i;
        Inc(i);
        tagContent := '';
        while (i <= Length(_Value)) and (_Value[i] <> '>') do
        begin
          tagContent := tagContent + _Value[i];
          Inc(i);
        end;
        if i > Length(_Value) then
        begin
          //Kein schliessendes >, der Rest ist Text
          builder.Append('&lt;');
          builder.Append(HtmlEncode(Copy(_Value,tagStart+1,MaxInt)));
          break;
        end;
        Inc(i); //das > ueberspringen

        tagContent := Trim(tagContent);
        isClosingTag := StartsText('/',tagContent);
        if isClosingTag then
          tagContent := Trim(Copy(tagContent,2,MaxInt));
        //Selbstschliessendes Tag
        tagContent := TrimRight(tagContent);
        if EndsText('/',tagContent) then
          tagContent := TrimRight(Copy(tagContent,1,Length(tagContent)-1));

        //Nur der Tagname bis zum ersten Trennzeichen zaehlt, Attribute entfallen
        tagName := tagContent;
        for var charIndex := 1 to Length(tagContent) do
          if CharInSet(tagContent[charIndex],[' ',#9,#10,#13,'/']) then
          begin
            tagName := Copy(tagContent,1,charIndex-1);
            break;
          end;

        if IsAllowedTag(tagName) then
        begin
          if isClosingTag then
            builder.Append('</'+LowerCase(tagName)+'>')
          else
          if SameText(tagName,'br') then
            builder.Append('<br/>')
          else
            builder.Append('<'+LowerCase(tagName)+'>');
        end;
        //Nicht erlaubte Tags werden ersatzlos verworfen
      end;
      Result := builder.ToString;
    finally
      builder.Free;
    end;
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

  function RenderDescription(const _Value : String) : String;
  begin
    if _Value = '' then
      exit('');

    if LooksLikeSupportedHtml(_Value) then
      exit(SanitizeHtml(_Value));

    Result := HtmlEncode(_Value);
    Result := StringReplace(Result,sLineBreak,'<br/>',[rfReplaceAll]);
    Result := StringReplace(Result,#10,'<br/>',[rfReplaceAll]);
    Result := StringReplace(Result,#13,'',[rfReplaceAll]);
    Result := '<p>' + Result + '</p>';
  end;

  //HTML-Encoding allein schuetzt nicht vor javascript: und aehnlichen Schemata
  function SafeUrl(const _Value : String) : String;
  var
    trimmedValue : String;
  begin
    Result := '';
    trimmedValue := Trim(_Value);
    if trimmedValue = '' then
      exit;
    if StartsText('http://',trimmedValue) or
       StartsText('https://',trimmedValue) or
       StartsText('mailto:',trimmedValue) then
      Result := HtmlEncode(trimmedValue);
  end;

  procedure AddLinkedProductHtml(_Item : TOpenMasterdataAPI_LinkedProduct; const _ReferenceType : String = '');
  var
    imageUrl : String;
  begin
    if _Item = nil then
      exit;

    html.Add('<div style="margin-bottom:1rem;">');
    imageUrl := IfThen(_Item.thumbnailUrl.IsEmpty,_Item.imageLink,_Item.thumbnailUrl);
    imageUrl := SafeUrl(imageUrl);
    if imageUrl <> '' then
      html.Add('<img src="'+imageUrl+'" style="max-width:180px;max-height:180px;display:block;margin-bottom:0.5rem;"/>');
    if _Item.productShortDescr <> '' then
      html.Add('<strong>'+HtmlEncode(_Item.productShortDescr)+'</strong><br/>');
    if _Item.manufacturerPid <> '' then
      html.Add('Hersteller-Artikelnummer: '+HtmlEncode(_Item.manufacturerPid)+'<br/>');
    if _Item.gtin <> '' then
      html.Add('GTIN: '+HtmlEncode(_Item.gtin)+'<br/>');
    if _ReferenceType <> '' then
      html.Add('Referenztyp: '+HtmlEncode(_ReferenceType)+'<br/>');
    html.Add('</div>');
  end;

  procedure AddAccessoryHtml(_Item : TOpenMasterdataAPI_Accessory);
  begin
    if _Item = nil then
      exit;

    AddLinkedProductHtml(_Item,_Item.referenceType);

    //AddLinkedProductHtml schliesst mit </div>, davor gehoeren die Zusatzangaben
    if _Item.amount > 0 then
      html.Insert(html.Count-1,'Menge: '+FloatToStr(_Item.amount)+'<br/>');
    if _Item.necessaryForFunction then
      html.Insert(html.Count-1,'Funktionsrelevant: Ja<br/>')
    else
      html.Insert(html.Count-1,'Funktionsrelevant: Nein<br/>');
  end;

  procedure AddRawMaterialHtml(_Item : TOpenMasterdataAPI_Material);
  begin
    if _Item = nil then
      exit;

    html.Add('<div style="margin-bottom:1rem;">');
    html.Add('<strong>'+HtmlEncode(TOpenMasterdataAPI_RawMaterialHelper.RawMaterialToStr(_Item.material))+'</strong><br/>');
    if _Item.weightBasis > 0 then
      html.Add('Basis: '+FloatToStr(_Item.weightBasis)+' '+HtmlEncode(_Item.basisUnit)+'<br/>');
    if _Item.proportionByWeight > 0 then
      html.Add('Anteil: '+FloatToStr(_Item.proportionByWeight)+' '+HtmlEncode(_Item.proportionUnit)+'<br/>');
    if _Item.quotationOfRawMaterial > 0 then
      html.Add('Rohstoffnotierung: '+FloatToStr(_Item.quotationOfRawMaterial)+'<br/>');
    if _Item.currentQuotationOfRawMaterial > 0 then
      html.Add('Aktuelle Rohstoffnotierung: '+FloatToStr(_Item.currentQuotationOfRawMaterial)+'<br/>');
    html.Add('</div>');
  end;
begin
  Result := '';
  if _Val = nil then
    exit;

  html := TStringList.Create;
  try
    html.Add('<html>');
    html.Add('<body>');
    html.Add('<h1>Artikel-Nr.: '+HtmlEncode(_Val.supplierPid)+'</h1>');
    html.Add('<h2>'+HtmlEncode(_Val.basic.productShortDescr)+'</h2>');
    if _Val.descriptions.productDescr <> '' then
      html.Add(RenderDescription(_Val.descriptions.productDescr));

    if (_Val.additional.deepLink <> '') then
      html.Add('<a href="'+SafeUrl(_Val.additional.deepLink)+'" target="_blank" rel="noopener noreferrer">Weitere Details online</a><br/>');
    if _Val.basic.startOfValidity > 0 then
      html.Add('G&uuml;ltig ab: '+DateToStr(_Val.basic.startOfValidity)+'<br/>');
    if _Val.additional.expiringProduct then
    begin
      if _Val.additional.expiringProductHasSuccessor then
        html.Add('Auslaufartikel mit Nachfolgeartikel.<br/>')
      else
        html.Add('Auslaufartikel.<br/>');
    end;
    if _Val.additional.expiringDate > 0 then
      html.Add('Auslaufdatum: '+DateToStr(_Val.additional.expiringDate)+'<br/>');
    if (_Val.basic.mainCommodityGroupId <> '') then
      html.Add('Hauptwarengruppe: '+HtmlEncode(_Val.basic.mainCommodityGroupId)+' '+HtmlEncode(_Val.basic.mainCommodityGroupDescr)+'<br/>');
    if (_Val.basic.commodityGroupId <> '') then
      html.Add('Warengruppe: '+HtmlEncode(_Val.basic.commodityGroupId)+' '+HtmlEncode(_Val.basic.commodityGroupDescr)+'<br/>');
    html.Add('<br/>');
    if (_Val.basic.priceOnDemand) then
      html.Add('Preis nur auf Anfrage.<br/>');
    if (_Val.prices.listPrice.ValueAsCurrency > 0) then
      html.Add('Listenpreis: '+Format('%n %s',[_Val.prices.listPrice.ValueAsCurrency,HtmlEncode(_Val.prices.listPrice.currency)])+'<br/>');
    if (_Val.prices.netPrice.ValueAsCurrency > 0) then
      html.Add('Einkaufspreis: '+Format('%n %s',[_Val.prices.netPrice.ValueAsCurrency,HtmlEncode(_Val.prices.netPrice.currency)])+'<br/>');

    html.Add('<br/>');
    if _Val.prices.rawMaterial.Count > 0 then
      html.Add('<h3>Rohstoffangaben</h3>');
    for i := 0 to _Val.prices.rawMaterial.Count-1 do
      AddRawMaterialHtml(_Val.prices.rawMaterial[i]);

    html.Add('<br/>');
    if _Val.pictures.Count > 0 then
      html.Add('<h3>Bilder</h3>');
    for i := 0 to _Val.pictures.Count-1 do
    begin
      var pictureUrl : String := SafeUrl(IfThen(_Val.pictures[i].urlThumbnail.IsEmpty,_Val.pictures[i].url,_Val.pictures[i].urlThumbnail));
      if pictureUrl <> '' then
        html.Add('<img src="'+pictureUrl+'"/><br/>');
    end;

    html.Add('<br/>');
    if _Val.additional.alternativeProduct.Count > 0 then
      html.Add('<h3>Alternativartikel</h3>');
    for i := 0 to _Val.additional.alternativeProduct.Count-1 do
      AddLinkedProductHtml(_Val.additional.alternativeProduct[i],_Val.additional.alternativeProduct[i].referenceType);

    html.Add('<br/>');
    if _Val.additional.followupProduct.Count > 0 then
      html.Add('<h3>Nachfolgeartikel</h3>');
    for i := 0 to _Val.additional.followupProduct.Count-1 do
      AddLinkedProductHtml(_Val.additional.followupProduct[i],_Val.additional.followupProduct[i].referenceType);

    html.Add('<br/>');
    if _Val.additional.accessories.Count > 0 then
      html.Add('<h3>Zubeh&ouml;rartikel</h3>');
    for i := 0 to _Val.additional.accessories.Count-1 do
      AddAccessoryHtml(_Val.additional.accessories[i]);

    html.Add('<br/>');
    if _Val.documents.Count > 0 then
      html.Add('<h3>Dokumente</h3>');
    for i := 0 to _Val.documents.Count-1 do
    begin
      if _Val.documents[i].description <> '' then
        html.Add(HtmlEncode(_Val.documents[i].description)+'<br/>');
      var documentUrl : String := SafeUrl(_Val.documents[i].url);
      if documentUrl <> '' then
        html.Add('<a href="'+documentUrl+'" rel="noopener noreferrer">'+documentUrl+'</a><br/>')
      else
        html.Add(HtmlEncode(_Val.documents[i].url)+'<br/>');
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

    html.Add('</body>');
    html.Add('</html>');

    Result := html.Text;
  finally
    html.Free;
  end;
end;

end.
