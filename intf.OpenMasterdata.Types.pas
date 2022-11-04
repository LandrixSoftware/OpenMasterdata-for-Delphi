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

unit intf.OpenMasterdata.Types;

interface

uses
  System.Classes,System.SysUtils,System.IOUtils,DateUtils,System.StrUtils
  ,System.Generics.Collections,System.Generics.Defaults
  ,System.Json,REST.Json
  ;

type
  TOpenMasterdataAPI_AuthResult = class
  private
    Fexpires_in: Integer;
    Frefresh_token: String;
    Ftoken_type: String;
    Faccess_token: String;
    Fscope: String;
  public
    procedure LoadFromJson(const _JsonValue : String);
  public
    property access_token : String read Faccess_token write Faccess_token;
    property token_type : String read Ftoken_type write Ftoken_type;
    property expires_in : Integer read Fexpires_in write Fexpires_in;
    property refresh_token : String read Frefresh_token write Frefresh_token;
    property scope : String read Fscope write Fscope;
  end;

  TOpenMasterdataAPI_DataPackage = (omd_datapackage_basic,
                                    omd_datapackage_additional,
                                    omd_datapackage_prices,
                                    omd_datapackage_descriptions,
                                    omd_datapackage_logistics,
                                    omd_datapackage_sparepartlists,
                                    omd_datapackage_pictures,
                                    omd_datapackage_documents);

  TOpenMasterdataAPI_DataPackages = set of TOpenMasterdataAPI_DataPackage;

  TOpenMasterdataAPI_DataPackageHelper = class
  public const
    ALL_DATAPACKAGES = [omd_datapackage_basic,
                        omd_datapackage_additional,
                        omd_datapackage_prices,
                        omd_datapackage_descriptions,
                        omd_datapackage_logistics,
                        omd_datapackage_sparepartlists,
                        omd_datapackage_pictures,
                        omd_datapackage_documents];
  public
    class function DataPackageAsString(_Val : TOpenMasterdataAPI_DataPackage) : String;
    class function DataPackagesAsString(_Val : TOpenMasterdataAPI_DataPackages) : String;
  end;

  TOpenMasterdataAPI_Document = class
  private
    Ffilename: String;
    Fhash: String;
    Ftype_: String;
    Fsize: Integer;
    Furl: String;
    Fdescription: String;
    FsortOrder: Integer;
  public
    property url : String read Furl write Furl;
    property type_ : String read Ftype_ write Ftype_; //Typ des Dokuments\nCode Beschreibung\n- 2D = 2D-Draufsicht\n- 2F = 2D-Frontale\n- 2S = 2D-Seitenansicht\n- 3C = 3D-Daten\n- 3B = 3D-Daten\n- 3A = 3D-Daten zur Darstellung im Browser\n- AN = Animation\n- DB = Datenblatt\n- GG = Gefahrgut – Datenblatt\n- IS = Instruktion/Bedienungsanleitung\n- MA = Montageanleitung\n- VM = Montagevideo\n- TI = Technische Info\n- VT = Tutorial\n- TZ = Technische Zeichnung \n- VI = Video\n- WA = Wartungsanleitung\n- VP = Produktvideo\n- PA = Planungsanleitung\n- PP = Prospekte\n- ZL = Zulassung\n- SB = Schaltbild\n- SF = Schulungsfolie\n- PF = Pflegeanleitung\n- LE = Bauproduktenverordnung\n- EL = ErP-Label\n- EP = Einzelprospekt\n- UP = UBA-Positivliste\n- WL = WELL-Label\n- BS = Brandschutz  \n- EX = EX-Schut  \n- AS = Arbeitsschutz  \n- KS = Korrisionsschutz  \n- CE = CE-Konformitätserklärung  \n- VD = VDS-Zulassung  \n- SS = Schallschutznachweis  \n- PL = Prüfreport Lithiumbatterie
    property description : String read Fdescription write Fdescription; //max 40 Beschreibung
    property sortOrder : Integer read FsortOrder write FsortOrder; //max 2 Reihenfolge
    property size : Integer read Fsize write Fsize; //Dokumentgröße in Byte
    property filename : String read Ffilename write Ffilename; //max 35 Dateiname
    property hash : String read Fhash write Fhash;
  end;

  TOpenMasterdataAPI_DocumentList = class(TObjectList<TOpenMasterdataAPI_Document>)
  end;

  TOpenMasterdataAPI_Accessory = class
  private
    FproductShortDescr: String;
    FnecessaryForFunction: Boolean;
    FmanufacturerPid: String;
    Fgtin: String;
    FmanufacturerId: String;
    FimageLink: String;
    FsupplierPid: String;
  public
    property supplierPid : String read FsupplierPid write FsupplierPid;
    property manufacturerId : String read FmanufacturerId write FmanufacturerId;
    property manufacturerPid : String read FmanufacturerPid write FmanufacturerPid;
    property gtin : String read Fgtin write Fgtin;
    property productShortDescr : String read FproductShortDescr write FproductShortDescr;
    property imageLink : String read FimageLink write FimageLink;
    property necessaryForFunction : Boolean read FnecessaryForFunction write FnecessaryForFunction;
  end;

  TOpenMasterdataAPI_AccessoryList = class(TObjectList<TOpenMasterdataAPI_Accessory>)
  end;

  TOpenMasterdataAPI_Set = class
  private
    FproductShortDescr: String;
    FmanufacturerPid: String;
    Fgtin: String;
    Famount: double;
    FmanufacturerId: String;
    FimageLink: String;
    FsupplierPid: String;
  public
    property supplierPid : String read FsupplierPid write FsupplierPid;
    property manufacturerId : String read FmanufacturerId write FmanufacturerId;
    property manufacturerPid : String read FmanufacturerPid write FmanufacturerPid;
    property gtin : String read Fgtin write Fgtin;
    property productShortDescr : String read FproductShortDescr write FproductShortDescr;
    property imageLink : String read FimageLink write FimageLink;
    property amount : double read Famount write Famount;
  end;

  TOpenMasterdataAPI_SetList = class(TObjectList<TOpenMasterdataAPI_Set>)
  end;

  TOpenMasterdataAPI_Additional = class
  private
    FexpiringProduct: String;
    FminOrderQuantity: String;
    FdeepLink: String;
    FminOrderUnit: String;
    Fsets: TOpenMasterdataAPI_SetList;
    Faccessories: TOpenMasterdataAPI_AccessoryList;
    FexpiringDate: TDate;
    FarticleNumberCatalogue: String;
  public
    constructor Create;
    destructor Destroy; override;

    property minOrderQuantity : String read FminOrderQuantity write FminOrderQuantity; //Mindestbestellmenge
    property minOrderUnit : String read FminOrderUnit write FminOrderUnit; //Units (Mengeneinheiten) -- Code Beschreibung\n- CMK = Quadratzentimeter\n- CMQ = Kubikzentimeter\n- CMT = Zentimeter\n- DZN = Dutzend\n- GRM = Gramm\n- HLT = Hektoliter\n- KGM = Kilogramm\n- KTM = Kilometer\n- LTR = Liter\n- MMT = Millimeter\n- MTK = Quadratmeter\n- MTQ = Kubikmeter\n- MTR = Meter\n- PCE = Stück\n- PR = Paar\n- SET = Satz\n- TNE = Tonne
    property articleNumberCatalogue : String read FarticleNumberCatalogue write FarticleNumberCatalogue; //max 15 Werksartikelnummer Katalog
    //TODO property alternativeProduct //array #/components/schemas/AlternativeProduct
    //TODO property followupProduct //components/schemas/FollowupProduct
    property deepLink : String read FdeepLink write FdeepLink; //max 256 Deeplink zum Artikel
    property expiringProduct : String read FexpiringProduct write FexpiringProduct; //enum" : [ true, "Yes-Successor", false ] Auslaufartikel\n  - Yes = Artikel ist Auslauf\n  - Yes-Successor = Artikel ist Auslauf und Nachfolgeartikel existiert\n  - No = Artikel ist nicht Auslauf
    property expiringDate : TDate read FexpiringDate write FexpiringDate; //Auslaufdatum
    property accessories : TOpenMasterdataAPI_AccessoryList read Faccessories write Faccessories;
    property sets : TOpenMasterdataAPI_SetList read Fsets write Fsets;
//            "energyEfficiencyClass" : {
//              "$ref" : "#/components/schemas/EnergyEfficiencyClass"
//            },
//            "commodityGroupIdManufacturer" : {
//              "type" : "string",
//              "description" : "Warengruppen ID des Herstellers",
//              "maxLength" : 3
//            },
//            "commodityGroupDescrManufacturer" : {
//              "type" : "string",
//              "description" : "Warengruppen Bezeichnung des Herstellers",
//              "maxLength" : 40
//            },
//            "productGroupIdManufacturer" : {
//              "type" : "string",
//              "description" : "Produktgrupppen ID",
//              "maxLength" : 10
//            },
//            "productGroupDescrManufacturer" : {
//              "type" : "string",
//              "description" : "Produktgruppen Bezeichnung",
//              "maxLength" : 40
//            },
//            "discoundGroupIdManufacturer" : {
//              "type" : "string",
//              "description" : "Rabattgruppen ID",
//              "maxLength" : 4
//            },
//            "discountGroupDescrManufacturer" : {
//              "type" : "string",
//              "description" : "Rabattgruppen Bezeichnung",
//              "maxLength" : 40
//            },
//            "bonusGroupIdManufacturer" : {
//              "type" : "string",
//              "description" : "Bonusgruppen ID",
//              "maxLength" : 35
//            },
//            "bonusGroupDescrManufacturer" : {
//              "type" : "string",
//              "description" : "Bonusgruppen Bezeichnung",
//              "maxLength" : 40
//            },
//            "accessories" : {
//              "type" : "array",
//              "description" : "Liste von Zubehörartikeln",
//              "items" : {
//                "$ref" : "#/components/schemas/AccessoriesProduct"
//              }
//            },
//            "sets" : {
//              "type" : "array",
//              "description" : "Artikelsets",
//              "items" : {
//                "$ref" : "#/components/schemas/SetsProduct"
//              }
//            },
//            "attribute" : {
//              "type" : "array",
//              "description" : "Liste von Artikelattributen",
//              "items" : {
//                "$ref" : "#/components/schemas/ProductAttribute"
//              }
//            },
//            "constructionFrom" : {
//              "$ref" : "#/components/schemas/ConstructionFrom"
//            },
//            "constructionTo" : {
//              "type" : "string",
//              "format" : "date",
//              "description" : "Baujahr bis"
//            },
//            "constructionText" : {
//              "type" : "string",
//              "description" : "Baujahr Text",
//              "maxLength" : 35
//            }
  end;

  TOpenMasterdataAPI_LogisticsMeasure = class
  private
    Funit_: String;
    Fmeasure: String;
  public
    property measure : String read Fmeasure write Fmeasure;
    property unit_ : String read Funit_ write Funit_;
  end;

  TOpenMasterdataAPI_LogisticsWeight = class
  private
    Funit_: String;
    Fweight: String;
  public
    property weight : String read Fweight write Fweight;
    property unit_ : String read Funit_ write Funit_;
  end;

  TOpenMasterdataAPI_Logistics = class
  private
    FmeasureB: TOpenMasterdataAPI_LogisticsMeasure;
    FmeasureC: TOpenMasterdataAPI_LogisticsMeasure;
    FmeasureA: TOpenMasterdataAPI_LogisticsMeasure;
    FhazardousMaterial: Boolean;
    Fexportable: Boolean;
    Fweight: TOpenMasterdataAPI_LogisticsWeight;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    property exportable : Boolean read Fexportable write Fexportable;
    property hazardousMaterial : Boolean read FhazardousMaterial write FhazardousMaterial;
    property measureA : TOpenMasterdataAPI_LogisticsMeasure read FmeasureA write FmeasureA;
    property measureB : TOpenMasterdataAPI_LogisticsMeasure read FmeasureB write FmeasureB;
    property measureC : TOpenMasterdataAPI_LogisticsMeasure read FmeasureC write FmeasureC;
    property weight : TOpenMasterdataAPI_LogisticsWeight read Fweight write Fweight;
  end;

  TOpenMasterdataAPI_Price = class
  private
    Fbasis: Integer;
    FquantityUnit: String;
    Fvalue: String;
    Fcurrency: String;
  public
    property value : String read Fvalue write Fvalue;
    property currency : String read Fcurrency write Fcurrency;
    property basis : Integer read Fbasis write Fbasis;
    property quantityUnit : String read FquantityUnit write FquantityUnit;
  end;

  TOpenMasterdataAPI_Basic = class
  private
    FproductShortDescr: String;
    FpriceOnDemand: Boolean;
    FstartOfValidity: TDate;
    Fserie: String;
    FproductType: String;
    FnoteOfUse: String;
    FcommodityGroupId: String;
    Frrp: TOpenMasterdataAPI_Price;
    FcommodityGroupDescr: String;
    FmainCommodityGroupId: String;
    FmodelNumber: String;
    Fmatchcode: String;
    FmainCommodityGroupDescr: String;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    property productType : String read FproductType write FproductType; //Artikeltyp -- Code Beschreibung\n- STD = Standardartikel\n- ERA = Ersatzteil A\n- ERB = Ersatzteil B\n- ERC = Ersatzteil C\n- VA = Variante\n- MA = Maßanfertigung\n- DLS = Dienstleistung / Software\n- PAK = Paket / Set\n- SON = Sonderartikel\n- KAL = Kalkulationsartikel\n- STG = Schüttgut\n",
    property startOfValidity : TDate read FstartOfValidity write FstartOfValidity; //Gültigkeitsbeginn
    property productShortDescr : String read FproductShortDescr write FproductShortDescr; //max 256 Artikelkurzbeschreibung (neuer Text aus dem Textgipfel)
    property priceOnDemand : Boolean read FpriceOnDemand write FpriceOnDemand; //Angabe, ob der Preis des Artikels nur auf Anfrage übermittelt wird
    property rrp : TOpenMasterdataAPI_Price read Frrp write Frrp;
    property mainCommodityGroupId : String read FmainCommodityGroupId write FmainCommodityGroupId; //max 3 Hauptwarengruppe Handel
    property mainCommodityGroupDescr : String read FmainCommodityGroupDescr write FmainCommodityGroupDescr; //max 40 Hauptwarengruppe Beschreibung Handel
    property commodityGroupId : String read FcommodityGroupId write FcommodityGroupId; //max 10 Warengruppe Handel
    property commodityGroupDescr : String read FcommodityGroupDescr write FcommodityGroupDescr; // max 40 Warengruppe Beschreibung Handel
    property noteOfUse : String read FnoteOfUse write FnoteOfUse; //max 512 Verwendungshinweis
    property matchcode : String read Fmatchcode write Fmatchcode; //max 15 Matchcode
    property serie : String read Fserie write Fserie; //max 80 Serie
    property modelNumber : String read FmodelNumber write FmodelNumber; //max 15 Modell
  end;

  TOpenMasterdataAPI_Material = class
  public
//"Material" : {
//          "type" : "object",
//          "description" : "Rohstoff",
//          "required" : [ "material", "weightBasis", "basisUnit", "proportionByWeight", "proportionUnit", "quotationOfRawMaterial" ],
//          "properties" : {
//            "material" : {
//              "$ref" : "#/components/schemas/RawMaterial"


//        "RawMaterial" : {
//          "type" : "string",
//          "description" : "Rohstoffangaben\nCode Beschreibung\n-  AL = Aluminium\n-  PB = Blei\n-  CR = Chrom\n-  AU = Gold\n-  CD = Kadmium\n-  CU = Kupfer\n-  MG = Magnesium\n-  MS = Messing\n-  NI = Nickel\n-  PL = Platin\n-  AG = Silber\n-  W  = Wolfram\n-  ZN = Zink\n-  SN = Zinn\n",
//          "enum" : [ "AL", "PB", "CR", "AU", "CD", "CU", "MG", "MS", "NI", "PL", "AG", "W", "ZN", "SN" ]
//        },


//            },
//            "weightBasis" : {
//              "type" : "string",
//              "pattern" : "^\\d{1,18}\\.\\d{1,4}?$",
//              "description" : "Gewichtsbasis. Basisangabe, auf die sich das Gewicht bezieht."
//            },
//            "basisUnit" : {
//              "$ref" : "#/components/schemas/Unit"
//            },
//            "proportionByWeight" : {
//              "type" : "string",
//              "pattern" : "^\\d{1,18}\\.\\d{1,4}?$",
//              "description" : "Gewichtsanteil des Rohstoffs"
//            },
//            "proportionUnit" : {
//              "$ref" : "#/components/schemas/Unit"
//            },
//            "quotationOfRawMaterial" : {
//              "type" : "string",
//              "pattern" : "^\\d{1,15}\\.\\d{1,2}?$",
//              "description" : "Notierung (pro 100 KG) des Rohstoffs, welcher im Preis bereits einkalkuliert ist."
//            }
  end;

  TOpenMasterdataAPI_Materials = class(TObjectList<TOpenMasterdataAPI_Material>)
  end;

  TOpenMasterdataAPI_Prices = class
  private
    FlistPrice: TOpenMasterdataAPI_Price;
    frrp : TOpenMasterdataAPI_Price;
    FnetPrice: TOpenMasterdataAPI_Price;
    FtaxCode: Integer;
    FbillBasis : String;
    FrawMaterial: TOpenMasterdataAPI_Materials;
  public
    constructor Create; virtual;
    destructor Destroy; override;

    property listPrice : TOpenMasterdataAPI_Price read FlistPrice write FlistPrice;
    property rrp : TOpenMasterdataAPI_Price read Frrp write Frrp;
    property netPrice : TOpenMasterdataAPI_Price read FnetPrice write FnetPrice;
    property taxCode : Integer read FtaxCode write FtaxCode; //Umsatzsteuer - 0 = voller Satz Ust.-Artikel - 1 = halber Satz Ust.-Artikel - 7 = Umkehr der Steuerschuld nach §13b UstG - 8 = Umsatzsteuerfrei nach §13b UstG „Bauleistungen
    property billBasis : String read FbillBasis write FbillBasis; //Abrechnungsbasis
    property rawMaterial : TOpenMasterdataAPI_Materials read FrawMaterial write FrawMaterial; //Liste von Materialzuschlägen
  end;

  TOpenMasterdataAPI_Descriptions = class
  private
    FproductDescr: String;
  public
    property productDescr : String read FproductDescr write FproductDescr;
  end;

  TOpenMasterdataAPI_Picture = class
  private
    Ffilename: String;
    Fhash: String;
    Fuse: String;
    FsubstituteId: Boolean;
    Ftype_: String;
    Fsize: Integer;
    FurlThumbnail: String;
    Furl: String;
    Fdescription: String;
    FsortOrder: Integer;
  public
    property url : String read Furl write Furl;
    property urlThumbnail : String read FurlThumbnail write FurlThumbnail;
    property type_ : String read Ftype_ write Ftype_; //Typ des Bildes\nCode Beschreibung\n- B_ = Fotorealistisches Produktbild in Farbe\n- S_ = Fotorealistisches Schwarz-Weiß-Bild\n- U_ = Unvermaßtes Bild (Strichzeichnung)\n- V_ = Vermaßtes Bild (Strichzeichnung)\n- X_ = Explosionszeichnung\n- MI = Milieubild, Badszene\n- DT = Detailbild/-ansicht\n- KV = Keyvisuals – Leitbilder\n- LO = Logo\n- LS = Lifestyle (Emotionsbilder mit Menschen)
    property use : String read Fuse write Fuse; //Verwendung des Dokumentes\nCode Beschreibung\n- Druck = Bild ist für die Verwendung in Printmedien geeignet\n- Web   = Bild ist für die Verwendung im Web geeignet
    property substituteId : Boolean read FsubstituteId write FsubstituteId; //Stellvertreterkennzeichen
    property description : String read Fdescription write Fdescription; //max 40 Beschreibung
    property sortOrder : Integer read FsortOrder write FsortOrder; //max 2 Reihenfolge
    property size : Integer read Fsize write Fsize; //Bildgröße in Byte
    property filename : String read Ffilename write Ffilename; //max 35 Dateiname
    property hash : String read Fhash write Fhash; //max 100 Hash-Wert der Datei als Fingerprint
  end;

  TOpenMasterdataAPI_PictureList = class(TObjectList<TOpenMasterdataAPI_Picture>)
  end;

  TOpenMasterdataAPI_Sparepartlist = class
    //TODO
  end;

  TOpenMasterdataAPI_Result = class
  private
    Fprices: TOpenMasterdataAPI_Prices;
    Fdocuments: TOpenMasterdataAPI_DocumentList;
    Fdescriptions: TOpenMasterdataAPI_Descriptions;
    Flogistics: TOpenMasterdataAPI_Logistics;
    Fbasic: TOpenMasterdataAPI_Basic;
    Fpictures: TOpenMasterdataAPI_PictureList;
    Fadditional: TOpenMasterdataAPI_Additional;
    FsupplierPid: String;
    FmanufacturerPid: String;
    FmanufacturerId: String;
    FmanufacturerIdType: String;
    Fgtin: String;
    Fsparepartlists: TOpenMasterdataAPI_Sparepartlist;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure LoadFromJson(const _JsonValue : String);
  public
    property supplierPid : String read FsupplierPid write FsupplierPid; //Artikelnummer innerhalb des angefragten Lieferanten (Großhandelsnummer)
    property manufacturerId : String read FmanufacturerId write FmanufacturerId; //Herstellerartikelnummer
    property manufacturerIdType : String read FmanufacturerIdType write FmanufacturerIdType; //Typ der Identifikation des Herstellers (z. B. DUNS, GLN, ...)
    property manufacturerPid : String read FmanufacturerPid write FmanufacturerPid; //Identifikation des Herstellers
    property gtin : String read Fgtin write Fgtin; //GTIN des Artikels
    property basic : TOpenMasterdataAPI_Basic read Fbasic write Fbasic;
    property additional : TOpenMasterdataAPI_Additional read Fadditional write Fadditional;
    property logistics : TOpenMasterdataAPI_Logistics read Flogistics write Flogistics;
    property prices : TOpenMasterdataAPI_Prices read Fprices write Fprices;
    property descriptions : TOpenMasterdataAPI_Descriptions read Fdescriptions write Fdescriptions;
    property pictures : TOpenMasterdataAPI_PictureList read Fpictures write Fpictures;
    property sparepartlists : TOpenMasterdataAPI_Sparepartlist read Fsparepartlists write Fsparepartlists;
    property documents : TOpenMasterdataAPI_DocumentList read Fdocuments write Fdocuments;
  end;

implementation

{ TOpenMasterdataAPI_AuthResult }

procedure TOpenMasterdataAPI_AuthResult.LoadFromJson(
  const _JsonValue: String);
var
  messageJson :      TJSONValue;
  jsonString  : TJSONString;
  jsonValue : TJSONValue;
begin
  messageJson := TJSONObject.ParseJSONValue(_JsonValue) as TJSONValue;

  if messageJson.TryGetValue<TJSONString>('access_token',jsonString) then
    access_token := jsonString.Value;
  if messageJson.TryGetValue<TJSONString>('token_type',jsonString) then
    token_type := jsonString.Value;
  if messageJson.TryGetValue<TJSONValue>('expires_in',jsonValue) then
    expires_in := StrToIntDef(jsonValue.Value,0);
  if messageJson.TryGetValue<TJSONString>('refresh_token',jsonString) then
    refresh_token := jsonString.Value;
  if messageJson.TryGetValue<TJSONString>('scope',jsonString) then
    scope := jsonString.Value;
end;

{ TOpenMasterdataAPI_DataPackageHelper }

class function TOpenMasterdataAPI_DataPackageHelper.DataPackageAsString(
  _Val: TOpenMasterdataAPI_DataPackage): String;
begin
  case _Val of
    omd_datapackage_additional: Result := 'additional';
    omd_datapackage_prices: Result := 'prices';
    omd_datapackage_descriptions: Result := 'descriptions';
    omd_datapackage_logistics: Result := 'logistics';
    omd_datapackage_sparepartlists: Result := 'sparepartlists';
    omd_datapackage_pictures: Result := 'pictures';
    omd_datapackage_documents: Result := 'documents';
    else Result := 'basic';
  end;
end;

class function TOpenMasterdataAPI_DataPackageHelper.DataPackagesAsString(
  _Val: TOpenMasterdataAPI_DataPackages): String;
var
  i : TOpenMasterdataAPI_DataPackage;
begin
  Result := '';
  //basic|additional|prices|descriptions|logistics|sparepartlists|pictures|documents
  for i := Low(TOpenMasterdataAPI_DataPackage) to High(TOpenMasterdataAPI_DataPackage) do
  if i in _Val then
  begin
    if Result <> '' then
      Result := Result + '|';
    Result := Result + TOpenMasterdataAPI_DataPackageHelper.DataPackageAsString(i);
  end;
end;

{ TOpenMasterdataAPI_Prices }

constructor TOpenMasterdataAPI_Prices.Create;
begin
  FlistPrice := TOpenMasterdataAPI_Price.Create;
  frrp := TOpenMasterdataAPI_Price.Create;
  FnetPrice := TOpenMasterdataAPI_Price.Create;
  FrawMaterial := TOpenMasterdataAPI_Materials.Create;
end;

destructor TOpenMasterdataAPI_Prices.Destroy;
begin
  if Assigned(FlistPrice) then begin FlistPrice.Free; FlistPrice := nil; end;
  if Assigned(frrp) then begin frrp.Free; frrp := nil; end;
  if Assigned(FnetPrice) then begin FnetPrice.Free; FnetPrice := nil; end;
  if Assigned(FrawMaterial) then begin FrawMaterial.Free; FrawMaterial := nil; end;
  inherited;
end;

{ TOpenMasterdataAPI_Additional }

constructor TOpenMasterdataAPI_Additional.Create;
begin
  Faccessories := TOpenMasterdataAPI_AccessoryList.Create;
  Fsets := TOpenMasterdataAPI_SetList.Create;
end;

destructor TOpenMasterdataAPI_Additional.Destroy;
begin
  if Assigned(Faccessories) then begin Faccessories.Free; Faccessories := nil; end;
  if Assigned(Fsets) then begin Fsets.Free; Fsets := nil; end;
  inherited;
end;

{ TOpenMasterdataAPI_Logistics }

constructor TOpenMasterdataAPI_Logistics.Create;
begin
 FmeasureA := TOpenMasterdataAPI_LogisticsMeasure.Create;
 FmeasureB := TOpenMasterdataAPI_LogisticsMeasure.Create;
 FmeasureC := TOpenMasterdataAPI_LogisticsMeasure.Create;
 Fweight := TOpenMasterdataAPI_LogisticsWeight.Create;
end;

destructor TOpenMasterdataAPI_Logistics.Destroy;
begin
  if Assigned(FmeasureA) then begin FmeasureA.Free; FmeasureA := nil; end;
  if Assigned(FmeasureB) then begin FmeasureB.Free; FmeasureB := nil; end;
  if Assigned(FmeasureC) then begin FmeasureC.Free; FmeasureC := nil; end;
  if Assigned(Fweight) then begin Fweight.Free; Fweight := nil; end;
  inherited;
end;

{ TOpenMasterdataAPI_Result }

constructor TOpenMasterdataAPI_Result.Create;
begin
  Fdocuments := TOpenMasterdataAPI_DocumentList.Create;
  Fadditional := TOpenMasterdataAPI_Additional.Create;
  Flogistics := TOpenMasterdataAPI_Logistics.Create;
  Fbasic := TOpenMasterdataAPI_Basic.Create;
  Fprices := TOpenMasterdataAPI_Prices.Create;
  Fdescriptions := TOpenMasterdataAPI_Descriptions.Create;
  Fpictures := TOpenMasterdataAPI_PictureList.Create;
  sparepartlists := TOpenMasterdataAPI_Sparepartlist.Create;
end;

destructor TOpenMasterdataAPI_Result.Destroy;
begin
  if Assigned(Fdocuments) then begin Fdocuments.Free; Fdocuments := nil; end;
  if Assigned(Fadditional) then begin Fadditional.Free; Fadditional := nil; end;
  if Assigned(Flogistics) then begin Flogistics.Free; Flogistics := nil; end;
  if Assigned(Fbasic) then begin Fbasic.Free; Fbasic := nil; end;
  if Assigned(Fprices) then begin Fprices.Free; Fprices := nil; end;
  if Assigned(Fdescriptions) then begin Fdescriptions.Free; Fdescriptions := nil; end;
  if Assigned(Fpictures) then begin Fpictures.Free; Fpictures := nil; end;
  if Assigned(sparepartlists) then begin sparepartlists.Free; sparepartlists := nil; end;
  inherited;
end;

procedure TOpenMasterdataAPI_Result.LoadFromJson(const _JsonValue: String);
var
  messageJson:      TJSONValue;

  jsonString  : TJSONString;
  jsonNumber : TJSONNumber;
  jsonValue,jsonValue2,jsonValue3 : TJSONValue;
  jsonValueFound : Boolean;

//   messageObject:      TErrorMessage;
//   messagesObjects:   TArray<TErrorMessage>;
begin
  messageJson := TJSONObject.ParseJSONValue(_JsonValue) as TJSONValue;

  if messageJson.TryGetValue<TJSONString>('supplierPid',jsonString) then
    supplierPid := jsonString.Value;
  if messageJson.TryGetValue<TJSONString>('manufacturerId',jsonString) then
    manufacturerId := jsonString.Value;
  if messageJson.TryGetValue<TJSONString>('manufacturerIdType',jsonString) then
    manufacturerIdType := jsonString.Value;
  if messageJson.TryGetValue<TJSONString>('manufacturerPid',jsonString) then
    manufacturerPid := jsonString.Value;
  if messageJson.TryGetValue<TJSONString>('gtin',jsonString) then
    gtin := jsonString.Value;

  if messageJson.TryGetValue<TJSONValue>('prices',jsonValue) then
  begin
    if jsonValue.TryGetValue<TJSONValue>('listPrice',jsonValue2) then //entspricht Spezifikation
      jsonValueFound := true else
    if jsonValue.TryGetValue<TJSONValue>('listprice',jsonValue2) then //entspricht nicht der Spezifikation - Mosecker
      jsonValueFound := true else jsonValueFound := false;
    if jsonValueFound then
    begin
      if jsonValue2.TryGetValue<TJSONString>('value',jsonString) then
        prices.listPrice.value := jsonString.Value;
      if jsonValue2.TryGetValue<TJSONString>('currency',jsonString) then
        prices.listPrice.currency := jsonString.Value;
      if jsonValue2.TryGetValue<TJSONValue>('basis',jsonValue3) then
        prices.listPrice.basis := StrToIntDef(jsonValue3.Value,1);
      if jsonValue2.TryGetValue<TJSONString>('quantityUnit',jsonString) then
        prices.listPrice.quantityUnit := jsonString.Value;
    end;
    if jsonValue.TryGetValue<TJSONValue>('rrp',jsonValue2) then
    begin
      if jsonValue2.TryGetValue<TJSONString>('value',jsonString) then
        prices.rrp.value := jsonString.Value;
      if jsonValue2.TryGetValue<TJSONString>('currency',jsonString) then
        prices.rrp.currency := jsonString.Value;
      if jsonValue2.TryGetValue<TJSONValue>('basis',jsonValue3) then
        prices.rrp.basis := StrToIntDef(jsonValue3.Value,1);
      if jsonValue2.TryGetValue<TJSONString>('quantityUnit',jsonString) then
        prices.rrp.quantityUnit := jsonString.Value;
    end;
    if jsonValue.TryGetValue<TJSONValue>('netPrice',jsonValue2) then //entspricht Spezifikation
      jsonValueFound := true else
    if jsonValue.TryGetValue<TJSONValue>('netprice',jsonValue2) then //entspricht nicht der Spezifikation - Mosecker
      jsonValueFound := true else jsonValueFound := false;
    if jsonValueFound then
    begin
      if jsonValue2.TryGetValue<TJSONString>('value',jsonString) then
        prices.netprice.value := jsonString.Value;
      if jsonValue2.TryGetValue<TJSONString>('currency',jsonString) then
        prices.netprice.currency := jsonString.Value;
      if jsonValue2.TryGetValue<TJSONValue>('basis',jsonValue3) then
        prices.netPrice.basis := StrToIntDef(jsonValue3.Value,1);
      if jsonValue2.TryGetValue<TJSONString>('quantityUnit',jsonString) then
        prices.netprice.quantityUnit := jsonString.Value;
    end;

    if jsonValue.TryGetValue<TJSONNumber>('taxCode',jsonNumber) then
      prices.taxCode := jsonNumber.AsInt;
    if jsonValue.TryGetValue<TJSONString>('billBasis',jsonString) then
      prices.billBasis := jsonString.Value;
    //TODO rawMaterial
  end;


//    manufacturerPid := jsonString.Value;
//
//  if messageJson.TryGetValue<TJSONNumber>('expires_in',jsonNumber) then
//    expires_in := jsonNumber.AsInt;
//  if messageJson.TryGetValue<TJSONString>('refresh_token',jsonString) then
//    refresh_token := jsonString.Value;
//  if messageJson.TryGetValue<TJSONString>('scope',jsonString) then
//    scope := jsonString.Value;


//    "basic": {
//        "productType": "PAK",
//        "startOfValidity": "2022-11-03",
//        "productShortDescr": "AS-Anschluss-Spannschelle DN  56, an SML- und Stahl-Rohre",
//        "priceOnDemand": false,
//        "rrp": {
//            "value": "3.93",
//            "currency": "EUR",
//            "basis": 1,
//            "quantityUnit": "PCE"
//        },
//        "mainCommodityGroupId": "I",
//        "mainCommodityGroupDescr": "Installation",
//        "commodityGroupId": "I999",
//        "commodityGroupDescr": "INS Installation Diverse",
//        "noteOfUse": "",
//        "matchcode": "",
//        "serie": "",
//        "modelNumber": ""
//    },
//    "additional": {
//        "minOrderQuantity": "1.000",
//        "minOrderUnit": "PCE",
//        "articleNumberCatalogue": "",
//        "alternativeProduct": [],
//        "followupProduct": [],
//        "deepLink": "https://www.mosecker-online.de/online3/artikelauskunft.csp?Artikel=09%2B10044",
//        "expiringProduct": "No",
//        "commodityGroupIdManufacturer": "",
//        "commodityGroupDescrManufacturer": "",
//        "productGroupIdManufacturer": "",
//        "productGroupDescrManufacturer": "",
//        "discoundGroupIdManufacturer": "",
//        "discountGroupDescrManufacturer": "",
//        "bonusGroupIdManufacturer": "",
//        "bonusGroupDescrManufacturer": "",
//        "accessories": [],
//        "sets": [],
//        "attribute": [],
//        "constructionText": ""
//    },
//    "descriptions": {
//        "shorttext1": "AS-Anschluss-Spannschelle DN  56, an",
//        "shorttext2": "SML- und Stahl-Rohre",
//        "productDescr": "",
//        "marketingText": ""
//    },
//    "logistics": {
//        "exportable": true,
//        "countryOfOrigin": "DE",
//        "hazardousMaterial": false,
//        "unNumber": "",
//        "dangerClass": "",
//        "reachInfo": "no data",
//        "reachData": "",
//        "ubaListRelevant": false,
//        "ubaListConform": false,
//        "durabilityPeriod": 99,
//        "standardDeliveryPeriod": 14,
//        "lucidNumber": "",
//        "packagingDisposalProvider": "",
//        "weeeNumber": "",
//        "packagingQuantity": 1
//    },
//    "pictures": [
//        {
//            "url": "https://www.mosecker-online.de/bilddaten/arge/mmedia/wv/web_bilder/wvb_0003127.jpg",
//            "urlThumbnail": "https://www.mosecker-online.de/thumbnails/bilddaten/arge/mmedia/wv/web_bilder/wvb_0003127-tn-120-120.jpg",
//            "type": "B_",
//            "use": "Web",
//            "substituteId": true,
//            "description": "Farbbild",
//            "sortOrder": 1,
//            "size": 233190,
//            "filename": "wvb_0003127.jpg"
//        }
//    ],
//    "documents": []
//}

//  messagesJson := TJSONObject.ParseJSONValue(_JsonValue) as TJSONArray;

 //  messagesObjects := [];
//  for messageJson in messagesJson do
//  begin

      //messageObject := TJson.JsonToObject<TErrorMessage>(messageJson as TJsonObject);
      //messagesObjects := messagesObjects + [messageObject];
//  end;

end;

{ TOpenMasterdataAPI_Basic }

constructor TOpenMasterdataAPI_Basic.Create;
begin
  Frrp := TOpenMasterdataAPI_Price.Create;
end;

destructor TOpenMasterdataAPI_Basic.Destroy;
begin
  if Assigned(Frrp) then begin Frrp.Free; Frrp := nil; end;
  inherited;
end;

end.
