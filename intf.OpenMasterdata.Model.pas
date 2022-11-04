{
License OpenMasterdata-for-Delphi

Copyright (C) 2022 Landrix Software GmbH & Co. KG
Sven Harazim, info@landrix.de

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
}

unit intf.OpenMasterdata.Model;

interface

uses
  System.Classes,System.SysUtils,System.IOUtils,DateUtils,System.StrUtils
  ,System.Generics.Collections,System.Generics.Defaults
  ,System.Net.HttpClient,System.Net.URLClient,System.Net.Mime
  ,intf.OpenMasterdata.Types
  ;

type
  TOpenMasterdata_DocumentType = (
    omd_doctype_None,
    omd_doctype_2D,
    omd_doctype_2F, //CAD Zeichnungen 2D bzw. 3D Darstellungen des Artikels
    omd_doctype_2S,//Dokumenttyp „2D“, „2F“, „2S“, „3C“, „3B“, „3A“
    omd_doctype_3C,
    omd_doctype_3B,
    omd_doctype_3A,
    omd_doctype_AN,//Animationen Animierte Darstellung des Artikels Dokumenttyp „AN“
    omd_doctype_VI,//um Artikel Dokumenttyp „VI“
    omd_doctype_VM,//Montagevideo Dokumenttyp „VM“
    omd_doctype_VT,//Tutorial Dokumenttyp „VT“
    omd_doctype_VP,//Produktvideo Dokumenttyp „VP“
    omd_doctype_DB,//Datenblatt Technische Details zum Artikel Dokumenttyp „DB“
    omd_doctype_GG,//Gefahrgut-Datenblatt Gefahrgutinformationen Dokumenttyp „GG“
    omd_doctype_IS,//Instruktionen Bedienungsanleitung des Artikels Dokumenttyp „IS“
    omd_doctype_MA,//Montageanleitung Installationshinweise für Handwerker Dokumenttyp „MA“
    omd_doctype_TI,//Technische Informationen Technische Details zum Artikel Dokumenttyp „TI“
    omd_doctype_WA,//Wartungsanleitung Informationen zur Wartung des Artikels Dokumenttyp „WA“
    omd_doctype_PA,//Planungsanleitung Informationen zur Planung und Ausschreibung Dokumenttyp „PA“
    omd_doctype_PP,//Prospekte Prospektmaterial Verkauf Dokumenttyp „PP“
    omd_doctype_ZL,//Zulassung DIN-Angaben zum Artikel Dokumenttyp „ZL“
    omd_doctype_SF,//Schulungsfolie Schulungsmaterial für Installation und Nutzung Dokumenttyp „SF“
    omd_doctype_LE,//Leistungserklärung Bauproduktenverordnung Dokumenttyp „LE“
    omd_doctype_PF,//Pflegeanleitung Hinweise zur Produktpflege Dokumenttyp „PF“
    omd_doctype_EL,//ErP Label Energielabel als Energieverbrauchskennzeichnung Dokumenttyp „EL“
    omd_doctype_SB,//Schaltbild Schaltbild zur Installation Dokumenttyp „SB“
    omd_doctype_TZ,//Technische Zeichnung Graphische Beschreibung der Funktionen und Eigenschaften Dokumenttyp „TZ“
    omd_doctype_EP,//Einzelprospekt Dokumenttyp „EP“
    omd_doctype_UP,//UBA-Positivliste Dokumenttyp „UP“
    omd_doctype_WL,//WELL-Label Dokumenttyp „WL“
    omd_doctype_BS,//Brandschutz Dokumenttyp „BS“
    omd_doctype_EX,//EX-Schutz Dokumenttyp „EX“
    omd_doctype_AS,//Arbeitsschutz Dokumenttyp „AS“
    omd_doctype_KS,//Korrosionsschutz Dokumenttyp „KS“
    omd_doctype_CE,//CE-Konformitätserklärung Dokumenttyp „CE“
    omd_doctype_VD,//VDS-Zulassung Dokumenttyp „VD“
    omd_doctype_SS//Schallschutznachweis Dokumenttyp „SS
    );

  TOpenMasterdata_DocumentTypeHelper = class
  public
    class function Description(_Val : TOpenMasterdata_DocumentType) : String;
    class function FromString(_Val : String) : TOpenMasterdata_DocumentType;
  end;

  TOpenMasterdata_Document = class
  private
    document : TMemoryStream;
  public
    url : String;
    type_ : TOpenMasterdata_DocumentType;
    filename : String;
    size : Integer;
    hash : String;
    constructor Create;
    destructor Destroy; override;
    function GetDocument(out _DocumentStreamReference : TStream) : Boolean;
    function SaveDocumentToFile(const _Filename : String) : Boolean;
  end;

  TOpenMasterdata_DocumentList = class(TObjectList<TOpenMasterdata_Document>)
  end;

  TOpenMasterdata_Price = class
  public
    value : Currency;
    currency : String;
    basis : Integer;
    quantityUnit : String;
  end;

  TOpenMasterdata_Prices = class
  public
    listPrice : TOpenMasterdata_Price;
    netPrice : TOpenMasterdata_Price;
    taxCode : Integer;
    constructor Create;
    destructor Destroy; override;
  end;

  TOpenMasterdata_Descriptions = class
  public
    productDescr : String;
  end;

  TOpenMasterdata_PictureType = (
    omd_picturetype_None,
    omd_picturetype_B, //Farbbilder Bild (schwarz/weiß oder Farbe) eines Artikels, freigestellt (ohne Hintergrund) Bildtyp „B_“ und „S_“
    omd_picturetype_S,//
    omd_picturetype_U,//Strichzeichnungen Abbild eines Artikels aus Strichen (vermaßt und unvermaßt)
    omd_picturetype_V,//Bildtyp „U_“ und „V_“
    omd_picturetype_LO,//Logos Firmen- und Produktlogos Bildtyp „LO“
    omd_picturetype_MI,//Milieu Bild eines Artikels innerhalb einer Anwendungsszene Bildtyp „MI“
    omd_picturetype_DT,//Detailbild Ansicht eines Artikels im Detail Bildtyp „DT“
    omd_picturetype_LS,//LifeStyle Bildliche Darstellung einer Lebensführung/ eines Lebensstils Bildtyp „LS“
    omd_picturetype_KV,//KeyVisual Bildliche Produktdarstellung als werbewirksamer Blickfang Bildtyp „KV“
    omd_picturetype_X//Explosionszeichung Explosionszeichung Bildtyp „X_
    );

  TOpenMasterdata_PictureTypeHelper = class
  public
    class function Description(_Val : TOpenMasterdata_PictureType) : String;
    class function FromString(_Val : String) : TOpenMasterdata_PictureType;
  end;

  TOpenMasterdata_Picture = class
  private
    picture : TMemoryStream;
    pictureThumbnail : TMemoryStream;
  public
    url : String;
    urlThumbnail : String;
    type_ : TOpenMasterdata_PictureType;
    use : String;
    substituteId : Boolean;
    filename : String;
    size : Integer;
    hash : String;
    constructor Create;
    destructor Destroy; override;
    function GetPicture(out _PictureStreamReference : TStream) : Boolean;
    function GetPictureThumbnail(out _PictureStreamReference : TStream) : Boolean;
    function SavePictureToFile(const _Filename : String) : Boolean;
  end;

  TOpenMasterdata_PictureList = class(TObjectList<TOpenMasterdata_Picture>)
  end;

  TOpenMasterdata_Result = class
  public
    supplierPid : String;
    documents : TOpenMasterdata_DocumentList;
    prices : TOpenMasterdata_Prices;
    descriptions : TOpenMasterdata_Descriptions;
    pictures : TOpenMasterdata_PictureList;
    constructor Create; virtual;
    destructor Destroy; override;
    procedure LoadDataFrom(_Val : TOpenMasterdataAPI_Result);
  end;

  TOpenMasterdataHelper = class
  public
    class function GetStreamFromURL(const _URL: String; _Result: TStream; _OnReceiveData: TReceiveDataEvent = nil): Boolean;
  end;

implementation

{ TOpenMasterdata_Prices }

constructor TOpenMasterdata_Prices.Create;
begin
  listPrice := TOpenMasterdata_Price.Create;
  netPrice := TOpenMasterdata_Price.Create;
end;

destructor TOpenMasterdata_Prices.Destroy;
begin
  if Assigned(listPrice) then begin listPrice.Free; listPrice := nil; end;
  if Assigned(netPrice) then begin netPrice.Free; netPrice := nil; end;
  inherited;
end;

{ TOpenMasterdata_Result }

constructor TOpenMasterdata_Result.Create;
begin
  documents := TOpenMasterdata_DocumentList.Create;
  prices := TOpenMasterdata_Prices.Create;
  descriptions := TOpenMasterdata_Descriptions.Create;
  pictures := TOpenMasterdata_PictureList.Create;
end;

destructor TOpenMasterdata_Result.Destroy;
begin
  if Assigned(documents) then begin documents.Free; documents := nil; end;
  if Assigned(prices) then begin prices.Free; prices := nil; end;
  if Assigned(descriptions) then begin descriptions.Free; descriptions := nil; end;
  if Assigned(pictures) then begin pictures.Free; pictures := nil; end;
  inherited;
end;

procedure TOpenMasterdata_Result.LoadDataFrom(
  _Val: TOpenMasterdataAPI_Result);
var
  i : Integer;
  localFormatSettings : TFormatSettings;
begin
  supplierPid := '';
  documents.Clear;
  //prices.
  //descriptions.
  pictures.Clear;
  if _Val = nil then
    exit;
  supplierPid := _Val.supplierPid;
  for i := 0 to _Val.documents.Count-1 do
  begin
    var document : TOpenMasterdata_Document := TOpenMasterdata_Document.Create;
    document.url := _Val.documents[i].url;
    document.type_ := TOpenMasterdata_DocumentTypeHelper.FromString(_Val.documents[i].type_);
    document.filename := ReplaceText(_Val.documents[i].filename,'/','_');
    document.size := _Val.documents[i].size;
    document.hash := _Val.documents[i].hash;
    documents.Add(document);
  end;
  localFormatSettings := System.SysUtils.FormatSettings;
  localFormatSettings.DecimalSeparator := '.';
  localFormatSettings.ThousandSeparator := ',';
  prices.listPrice.value := StrToCurrDef(_Val.prices.listPrice.value,0,localFormatSettings);
  prices.listPrice.currency := _Val.prices.listPrice.currency;
  prices.listPrice.basis := _Val.prices.listPrice.basis;
  prices.listPrice.quantityUnit := _Val.prices.listPrice.quantityUnit;
  prices.netPrice.value := StrToCurrDef(_Val.prices.netPrice.value,0,localFormatSettings);
  prices.netPrice.currency := _Val.prices.netPrice.currency;
  prices.netPrice.basis := _Val.prices.netPrice.basis;
  prices.netPrice.quantityUnit := _Val.prices.netPrice.quantityUnit;
  prices.taxCode := _Val.prices.taxCode;
  descriptions.productDescr := _Val.descriptions.productDescr;
  for i := 0 to _Val.pictures.Count-1 do
  begin
    var picture : TOpenMasterdata_Picture := TOpenMasterdata_Picture.Create;
    picture.url := _Val.pictures[i].url;
    picture.urlThumbnail := _Val.pictures[i].urlThumbnail;
    picture.type_ := TOpenMasterdata_PictureTypeHelper.FromString(_Val.pictures[i].type_);
    picture.use := _Val.pictures[i].use;
    picture.substituteId := _Val.pictures[i].substituteId;
    picture.filename := ReplaceText(_Val.pictures[i].filename,'/','_');
    picture.size := _Val.pictures[i].size;
    picture.hash := _Val.pictures[i].hash;
    pictures.Add(picture);
  end;
end;

{ TOpenMasterdata_DocumentTypeHelper }

class function TOpenMasterdata_DocumentTypeHelper.Description(
  _Val: TOpenMasterdata_DocumentType): String;
begin
  case _Val of
    omd_doctype_2D : Result := 'CAD Zeichnung 2D';
    omd_doctype_2F : Result := 'CAD Zeichnung 2D'; //CAD Zeichnungen 2D bzw. 3D Darstellungen des Artikels
    omd_doctype_2S : Result := 'CAD Zeichnung 2D';//Dokumenttyp „2D“, „2F“, „2S“, „3C“, „3B“, „3A“
    omd_doctype_3C : Result := 'CAD Zeichnung 3D';
    omd_doctype_3B : Result := 'CAD Zeichnung 3D';
    omd_doctype_3A : Result := 'CAD Zeichnung 3D';
    omd_doctype_AN : Result := 'Animierte Darstellung';//Animationen Animierte Darstellung des Artikels Dokumenttyp „AN“
    omd_doctype_VI : Result := 'Animierte Darstellung';//um Artikel Dokumenttyp „VI“
    omd_doctype_VM : Result := 'Montagevideo';//Montagevideo Dokumenttyp „VM“
    omd_doctype_VT : Result := 'Tutorial';//Tutorial Dokumenttyp „VT“
    omd_doctype_VP : Result := 'Produktvideo';//Produktvideo Dokumenttyp „VP“
    omd_doctype_DB : Result := 'Datenblatt';//Datenblatt Technische Details zum Artikel Dokumenttyp „DB“
    omd_doctype_GG : Result := 'Gefahrgutinformationen';//Gefahrgut-Datenblatt Gefahrgutinformationen Dokumenttyp „GG“
    omd_doctype_IS : Result := 'Bedienungsanleitung des Artikels';//Instruktionen Bedienungsanleitung des Artikels Dokumenttyp „IS“
    omd_doctype_MA : Result := 'Montageanleitung';//Montageanleitung Installationshinweise für Handwerker Dokumenttyp „MA“
    omd_doctype_TI : Result := 'Technische Details zum Artikel';//Technische Informationen Technische Details zum Artikel Dokumenttyp „TI“
    omd_doctype_WA : Result := 'Informationen zur Wartung des Artikels';//Wartungsanleitung Informationen zur Wartung des Artikels Dokumenttyp „WA“
    omd_doctype_PA : Result := 'Informationen zur Planung und Ausschreibung';//Planungsanleitung Informationen zur Planung und Ausschreibung Dokumenttyp „PA“
    omd_doctype_PP : Result := 'Prospektmaterial Verkauf';//Prospekte Prospektmaterial Verkauf Dokumenttyp „PP“
    omd_doctype_ZL : Result := 'Zulassung DIN-Angaben zum Artikel';//Zulassung DIN-Angaben zum Artikel Dokumenttyp „ZL“
    omd_doctype_SF : Result := 'Schulungsmaterial für Installation und Nutzung';//Schulungsfolie Schulungsmaterial für Installation und Nutzung Dokumenttyp „SF“
    omd_doctype_LE : Result := 'Leistungserklärung Bauproduktenverordnung';//Leistungserklärung Bauproduktenverordnung Dokumenttyp „LE“
    omd_doctype_PF : Result := 'Hinweise zur Produktpflege';//Pflegeanleitung Hinweise zur Produktpflege Dokumenttyp „PF“
    omd_doctype_EL : Result := 'Energielabel als Energieverbrauchskennzeichnung';//ErP Label Energielabel als Energieverbrauchskennzeichnung Dokumenttyp „EL“
    omd_doctype_SB : Result := 'Schaltbild zur Installation';//Schaltbild Schaltbild zur Installation Dokumenttyp „SB“
    omd_doctype_TZ : Result := 'Technische Zeichnung';//Technische Zeichnung Graphische Beschreibung der Funktionen und Eigenschaften Dokumenttyp „TZ“
    omd_doctype_EP : Result := 'Einzelprospekt';//Einzelprospekt Dokumenttyp „EP“
    omd_doctype_UP : Result := 'UBA-Positivliste';//UBA-Positivliste Dokumenttyp „UP“
    omd_doctype_WL : Result := 'WELL-Label';//WELL-Label Dokumenttyp „WL“
    omd_doctype_BS : Result := 'Brandschutz';//Brandschutz Dokumenttyp „BS“
    omd_doctype_EX : Result := 'EX-Schutz';//EX-Schutz Dokumenttyp „EX“
    omd_doctype_AS : Result := 'Arbeitsschutz';//Arbeitsschutz Dokumenttyp „AS“
    omd_doctype_KS : Result := 'Korrosionsschutz';//Korrosionsschutz Dokumenttyp „KS“
    omd_doctype_CE : Result := 'CE-Konformitätserklärung';//CE-Konformitätserklärung Dokumenttyp „CE“
    omd_doctype_VD : Result := 'VDS-Zulassung';//VDS-Zulassung Dokumenttyp „VD“
    omd_doctype_SS : Result := 'Schallschutznachweis';//Schallschutznachweis Dokumenttyp „SS
    else Result := '';
  end;
end;

class function TOpenMasterdata_DocumentTypeHelper.FromString(
  _Val: String): TOpenMasterdata_DocumentType;
begin
  if SameText(_Val,'2D') then Result :=  omd_doctype_2D else
  if SameText(_Val,'2F') then Result :=  omd_doctype_2F else //CAD Zeichnungen 2D bzw. 3D Darstellungen des Artikels
  if SameText(_Val,'2S') then Result :=  omd_doctype_2S else//Dokumenttyp „2D“, „2F“, „2S“, „3C“, „3B“, „3A“
  if SameText(_Val,'3C') then Result :=  omd_doctype_3C else
  if SameText(_Val,'3B') then Result :=  omd_doctype_3B else
  if SameText(_Val,'3A') then Result :=  omd_doctype_3A else
  if SameText(_Val,'AN') then Result :=  omd_doctype_AN else//Animationen Animierte Darstellung des Artikels Dokumenttyp „AN“
  if SameText(_Val,'VI') then Result :=  omd_doctype_VI else//um Artikel Dokumenttyp „VI“
  if SameText(_Val,'VM') then Result :=  omd_doctype_VM else//Montagevideo Dokumenttyp „VM“
  if SameText(_Val,'VT') then Result :=  omd_doctype_VT else//Tutorial Dokumenttyp „VT“
  if SameText(_Val,'VP') then Result :=  omd_doctype_VP else//Produktvideo Dokumenttyp „VP“
  if SameText(_Val,'DB') then Result :=  omd_doctype_DB else//Datenblatt Technische Details zum Artikel Dokumenttyp „DB“
  if SameText(_Val,'GG') then Result :=  omd_doctype_GG else//Gefahrgut-Datenblatt Gefahrgutinformationen Dokumenttyp „GG“
  if SameText(_Val,'IS') then Result :=  omd_doctype_IS else//Instruktionen Bedienungsanleitung des Artikels Dokumenttyp „IS“
  if SameText(_Val,'MA') then Result :=  omd_doctype_MA else//Montageanleitung Installationshinweise für Handwerker Dokumenttyp „MA“
  if SameText(_Val,'TI') then Result :=  omd_doctype_TI else//Technische Informationen Technische Details zum Artikel Dokumenttyp „TI“
  if SameText(_Val,'WA') then Result :=  omd_doctype_WA else//Wartungsanleitung Informationen zur Wartung des Artikels Dokumenttyp „WA“
  if SameText(_Val,'PA') then Result :=  omd_doctype_PA else//Planungsanleitung Informationen zur Planung und Ausschreibung Dokumenttyp „PA“
  if SameText(_Val,'PP') then Result :=  omd_doctype_PP else//Prospekte Prospektmaterial Verkauf Dokumenttyp „PP“
  if SameText(_Val,'ZL') then Result :=  omd_doctype_ZL else//Zulassung DIN-Angaben zum Artikel Dokumenttyp „ZL“
  if SameText(_Val,'SF') then Result :=  omd_doctype_SF else//Schulungsfolie Schulungsmaterial für Installation und Nutzung Dokumenttyp „SF“
  if SameText(_Val,'LE') then Result :=  omd_doctype_LE else//Leistungserklärung Bauproduktenverordnung Dokumenttyp „LE“
  if SameText(_Val,'PF') then Result :=  omd_doctype_PF else//Pflegeanleitung Hinweise zur Produktpflege Dokumenttyp „PF“
  if SameText(_Val,'EL') then Result :=  omd_doctype_EL else//ErP Label Energielabel als Energieverbrauchskennzeichnung Dokumenttyp „EL“
  if SameText(_Val,'SB') then Result :=  omd_doctype_SB else//Schaltbild Schaltbild zur Installation Dokumenttyp „SB“
  if SameText(_Val,'TZ') then Result :=  omd_doctype_TZ else//Technische Zeichnung Graphische Beschreibung der Funktionen und Eigenschaften Dokumenttyp „TZ“
  if SameText(_Val,'EP') then Result :=  omd_doctype_EP else//Einzelprospekt Dokumenttyp „EP“
  if SameText(_Val,'UP') then Result :=  omd_doctype_UP else//UBA-Positivliste Dokumenttyp „UP“
  if SameText(_Val,'WL') then Result :=  omd_doctype_WL else//WELL-Label Dokumenttyp „WL“
  if SameText(_Val,'BS') then Result :=  omd_doctype_BS else//Brandschutz Dokumenttyp „BS“
  if SameText(_Val,'EX') then Result :=  omd_doctype_EX else//EX-Schutz Dokumenttyp „EX“
  if SameText(_Val,'AS') then Result :=  omd_doctype_AS else//Arbeitsschutz Dokumenttyp „AS“
  if SameText(_Val,'KS') then Result :=  omd_doctype_KS else//Korrosionsschutz Dokumenttyp „KS“
  if SameText(_Val,'CE') then Result :=  omd_doctype_CE else//CE-Konformitätserklärung Dokumenttyp „CE“
  if SameText(_Val,'VD') then Result :=  omd_doctype_VD else//VDS-Zulassung Dokumenttyp „VD“
  if SameText(_Val,'SS') then Result :=  omd_doctype_SS else//Schallschutznachweis Dokumenttyp „SS
    Result := omd_doctype_None;
end;

{ TOpenMasterdata_PictureTypeHelper }

class function TOpenMasterdata_PictureTypeHelper.Description(
  _Val: TOpenMasterdata_PictureType): String;
begin
  case _Val of
    omd_picturetype_B : Result := 'Bild'; //Farbbilder Bild (schwarz/weiß oder Farbe) eines Artikels, freigestellt (ohne Hintergrund) Bildtyp „B_“ und „S_“
    omd_picturetype_S : Result := 'Bild';
    omd_picturetype_U : Result := 'Strichzeichnung unvermaßt';//Strichzeichnungen Abbild eines Artikels aus Strichen (vermaßt und unvermaßt)
    omd_picturetype_V : Result := 'Strichzeichnung vermaßt';//Bildtyp „U_“ und „V_“
    omd_picturetype_LO : Result := 'Logos';// Firmen- und Produktlogos Bildtyp „LO“
    omd_picturetype_MI : Result := 'Milieu Bild';// eines Artikels innerhalb einer Anwendungsszene Bildtyp „MI“
    omd_picturetype_DT : Result := 'Detailbild';// Ansicht eines Artikels im Detail Bildtyp „DT“
    omd_picturetype_LS : Result := 'LifeStyle';// Bildliche Darstellung einer Lebensführung/ eines Lebensstils Bildtyp „LS“
    omd_picturetype_KV : Result := 'KeyVisual';// Bildliche Produktdarstellung als werbewirksamer Blickfang Bildtyp „KV“
    omd_picturetype_X : Result := 'Explosionszeichung';// Explosionszeichung Bildtyp „X_
    else Result := '';
  end;
end;

class function TOpenMasterdata_PictureTypeHelper.FromString(
  _Val: String): TOpenMasterdata_PictureType;
begin
  if SameText(_Val,'B_') then Result := omd_picturetype_B   else
  if SameText(_Val,'S_') then Result := omd_picturetype_S   else
  if SameText(_Val,'U_') then Result := omd_picturetype_U   else
  if SameText(_Val,'V_') then Result := omd_picturetype_V   else
  if SameText(_Val,'LO') then Result := omd_picturetype_LO  else
  if SameText(_Val,'MI') then Result := omd_picturetype_MI  else
  if SameText(_Val,'DT') then Result := omd_picturetype_DT  else
  if SameText(_Val,'LS') then Result := omd_picturetype_LS  else
  if SameText(_Val,'KV') then Result := omd_picturetype_KV  else
  if SameText(_Val,'X_') then Result := omd_picturetype_X   else
    Result := omd_picturetype_None;
end;

{ TOpenMasterdataHelper }

class function TOpenMasterdataHelper.GetStreamFromURL(const _URL: String;
  _Result: TStream; _OnReceiveData: TReceiveDataEvent): Boolean;
var
  http : THTTPClient;
  //vcHelper : TLclHelperInet.TValidateCertificatHelper;
begin
  Result := false;
  if _Result = nil then
    exit;
  http := THTTPClient.Create;
  //vcHelper := TLclHelperInet.TValidateCertificatHelper.Create;
  try
    //http.OnValidateServerCertificate := vcHelper.DoValidateCertificateEvent;
    http.OnReceiveData := _OnReceiveData;
    try
      with http.Get(_URL,_Result) do
        Result := StatusCode = 200;
    except
      on E:Exception do ;//if Assigned(_OnError) then _OnError('',E);
    end;
  finally
    //vcHelper.Free;
    http.Free;
  end;
end;

{ TOpenMasterdata_Picture }

constructor TOpenMasterdata_Picture.Create;
begin
  picture := nil;
  pictureThumbnail := nil;
end;

destructor TOpenMasterdata_Picture.Destroy;
begin
  if Assigned(picture) then begin picture.Free; picture := nil; end;
  if Assigned(pictureThumbnail) then begin pictureThumbnail.Free; pictureThumbnail := nil; end;
  inherited;
end;

function TOpenMasterdata_Picture.GetPicture(
  out _PictureStreamReference: TStream): Boolean;
begin
  Result := false;
  if url.IsEmpty then
    exit;
  if picture = nil then
  begin
    picture := TMemoryStream.Create;
    Result := TOpenMasterdataHelper.GetStreamFromURL(url,picture);
  end else
  begin
    Result := picture.Size > 0;
  end;
  if Result then
  begin
    picture.Position := 0;
    _PictureStreamReference := picture;
  end;
end;

function TOpenMasterdata_Picture.GetPictureThumbnail(
  out _PictureStreamReference: TStream): Boolean;
begin
  Result := false;
  if urlThumbnail.IsEmpty then
    exit;
  if pictureThumbnail = nil then
  begin
    pictureThumbnail := TMemoryStream.Create;
    Result := TOpenMasterdataHelper.GetStreamFromURL(urlThumbnail,pictureThumbnail);
  end else
  begin
    Result := pictureThumbnail.Size > 0;
  end;
  if Result then
  begin
    pictureThumbnail.Position := 0;
    _PictureStreamReference := pictureThumbnail;
  end;
end;

function TOpenMasterdata_Picture.SavePictureToFile(
  const _Filename: String): Boolean;
var
  stream : TStream;
begin
  Result := false;
  if _Filename.IsEmpty then
    exit;
  if not DirectoryExists(ExtractFilePath(_Filename)) then
    exit;
  Result := GetPicture(stream);
  if not Result then
    exit;
  TMemoryStream(stream).SaveToFile(_Filename);
end;

{ TOpenMasterdata_Document }

constructor TOpenMasterdata_Document.Create;
begin
  document := nil;
end;

destructor TOpenMasterdata_Document.Destroy;
begin
  if Assigned(document) then begin document.Free; document := nil; end;
  inherited;
end;

function TOpenMasterdata_Document.GetDocument(
  out _DocumentStreamReference: TStream): Boolean;
begin
  Result := false;
  if url.IsEmpty then
    exit;
  if document = nil then
  begin
    document := TMemoryStream.Create;
    Result := TOpenMasterdataHelper.GetStreamFromURL(url,document);
  end else
  begin
    Result := document.Size > 0;
  end;
  if Result then
  begin
    document.Position := 0;
    _DocumentStreamReference := document;
  end;
end;

function TOpenMasterdata_Document.SaveDocumentToFile(
  const _Filename: String): Boolean;
var
  stream : TStream;
begin
  Result := false;
  if _Filename.IsEmpty then
    exit;
  if not DirectoryExists(ExtractFilePath(_Filename)) then
    exit;
  Result := GetDocument(stream);
  if not Result then
    exit;
  TMemoryStream(stream).SaveToFile(_Filename);
end;

end.
