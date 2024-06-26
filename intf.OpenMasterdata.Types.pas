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

unit intf.OpenMasterdata.Types;

interface

uses
  System.Classes,System.SysUtils,System.IOUtils,DateUtils,System.StrUtils
  ,System.Generics.Collections,System.Generics.Defaults
  ,System.Json,REST.Json
  ;

type
  TOpenMasterdataAPIHelper = class(TObject)
  public
    class function JSONStrToDate(_Val : String) : TDate;
    class function JSONStrToFloat(_Val : String) : double;
  end;

  TOpenMasterdataAPI_AuthResult = class
  private
    Fexpires_in: Integer;
    Frefresh_token: String;
    Ftoken_type: String;
    Faccess_token: String;
    Fscope: String;
  public
    property access_token : String read Faccess_token write Faccess_token;
    property token_type : String read Ftoken_type write Ftoken_type;
    property expires_in : Integer read Fexpires_in write Fexpires_in;
    property refresh_token : String read Frefresh_token write Frefresh_token;
    property scope : String read Fscope write Fscope;
  end;

  TOpenMasterdataAPI_AuthResultHelper = class helper for TOpenMasterdataAPI_AuthResult
  public
    procedure LoadFromJson(const _JsonValue : String);
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

  TOpenMasterdataAPI_LinkedProduct = class(TObject)
  private
    FproductShortDescr: String;
    FmanufacturerPid: String;
    Fgtin: String;
    FmanufacturerId: String;
    FmanufacturerIdType: String;
    FimageLink: String;
    FthumbnailUrl: String;
    FsupplierPid: String;
  public
    property supplierPid : String read FsupplierPid write FsupplierPid;
    property manufacturerId : String read FmanufacturerId write FmanufacturerId;
    property manufacturerIdType : String read FmanufacturerIdType write FmanufacturerIdType;
    property manufacturerPid : String read FmanufacturerPid write FmanufacturerPid;
    property gtin : String read Fgtin write Fgtin;
    property productShortDescr : String read FproductShortDescr write FproductShortDescr;
    property imageLink : String read FimageLink write FimageLink;
    property thumbnailUrl : String read FthumbnailUrl write FthumbnailUrl;
  end;

  TOpenMasterdataAPI_LinkedHistoricProduct = class(TObject)
  private
    FhistoricProduct: String;
    FproductShortDescr: String;
    FmanufacturerIdType: String;
    FconstructionFrom: String;
    FimageLink: String;
    FmanufacturerId: String;
  public
    property manufacturerId : String read FmanufacturerId write FmanufacturerId;
    property manufacturerIdType : String read FmanufacturerIdType write FmanufacturerIdType;
    property historicProduct : String read FhistoricProduct write FhistoricProduct;
    property constructionFrom : String read FconstructionFrom write FconstructionFrom;
    property productShortDescr : String read FproductShortDescr write FproductShortDescr;
    property imageLink : String read FimageLink write FimageLink;
  end;

  TOpenMasterdataAPI_Accessory = class(TOpenMasterdataAPI_LinkedProduct)
  private
    FnecessaryForFunction: Boolean;
    FreferenceType: String;
    Famount: double;
  public
    property amount : double read Famount write Famount;
    property referenceType : String read FreferenceType write FreferenceType;
    property necessaryForFunction : Boolean read FnecessaryForFunction write FnecessaryForFunction;
  end;

  TOpenMasterdataAPI_AccessoryList = class(TObjectList<TOpenMasterdataAPI_Accessory>)
  end;

  TOpenMasterdataAPI_Set = class(TOpenMasterdataAPI_LinkedProduct)
  private
    Famount: double;
  public
    property amount : double read Famount write Famount;
  end;

  TOpenMasterdataAPI_SetList = class(TObjectList<TOpenMasterdataAPI_Set>)
  end;

  TOpenMasterdataAPI_AlternativeProduct = class(TOpenMasterdataAPI_LinkedProduct)
  private
    FreferenceType: String;
  public
    property referenceType : String read FreferenceType write FreferenceType;
  end;

  TOpenMasterdataAPI_AlternativeProductList = class(TObjectList<TOpenMasterdataAPI_AlternativeProduct>)
  end;

  TOpenMasterdataAPI_FollowupProduct = class(TOpenMasterdataAPI_LinkedProduct)
  private
    FreferenceType: String;
  public
    property referenceType : String read FreferenceType write FreferenceType;
  end;

  TOpenMasterdataAPI_FollowupProductList = class(TObjectList<TOpenMasterdataAPI_FollowupProduct>)
  end;

  TOpenMasterdataAPI_Attribute = class
  private
    FattributeSystem: String;
    FattributeUnitDesc: String;
    FattributeDesc: String;
    FattributeUnit: String;
    FattributeName: String;
    FattributeValue1Descr: String;
    FattributeClassDesc: String;
    FattributeValue1: String;
  public
    property attributeSystem : String read FattributeSystem write FattributeSystem;
    property attributeName : String read FattributeName write FattributeName;
    property attributeValue1 : String read FattributeValue1 write FattributeValue1;
    property attributeUnit : String read FattributeUnit write FattributeUnit;
    property attributeClassDesc : String read FattributeClassDesc write FattributeClassDesc;
    property attributeDesc : String read FattributeDesc write FattributeDesc;
    property attributeValue1Descr : String read FattributeValue1Descr write FattributeValue1Descr;
    property attributeUnitDesc : String read FattributeUnitDesc write FattributeUnitDesc;
  end;

  TOpenMasterdataAPI_AttributeList = class(TObjectList<TOpenMasterdataAPI_Attribute>)
  end;

  TOpenMasterdataAPI_Additional = class
  private
    FexpiringProduct: Boolean;
    FminOrderQuantity: double;
    FdeepLink: String;
    FminOrderUnit: String;
    Fsets: TOpenMasterdataAPI_SetList;
    Faccessories: TOpenMasterdataAPI_AccessoryList;
    FexpiringDate: TDate;
    FarticleNumberCatalogue: String;
    FalternativeProduct: TOpenMasterdataAPI_AlternativeProductList;
    FfollowupProduct: TOpenMasterdataAPI_FollowupProductList;
    FconstructionText: String;
    FdiscountGroupDescrManufacturer: String;
    FconstructionTo: String;
    FcommodityGroupIdManufacturer: String;
    Fattribute: TOpenMasterdataAPI_AttributeList;
    FcommodityGroupDescrManufacturer: String;
    FconstructionFrom: String;
    FdiscoundGroupIdManufacturer: String;
    FbonusGroupIdManufacturer: String;
    FproductGroupIdManufacturer: String;
    FenergyEfficiencyClass: String;
    FbonusGroupDescrManufacturer: String;
    FproductGroupDescrManufacturer: String;
  public
    constructor Create;
    destructor Destroy; override;

    property minOrderQuantity : double read FminOrderQuantity write FminOrderQuantity; //Mindestbestellmenge
    property minOrderUnit : String read FminOrderUnit write FminOrderUnit; //Units (Mengeneinheiten) -- Code Beschreibung\n- CMK = Quadratzentimeter\n- CMQ = Kubikzentimeter\n- CMT = Zentimeter\n- DZN = Dutzend\n- GRM = Gramm\n- HLT = Hektoliter\n- KGM = Kilogramm\n- KTM = Kilometer\n- LTR = Liter\n- MMT = Millimeter\n- MTK = Quadratmeter\n- MTQ = Kubikmeter\n- MTR = Meter\n- PCE = Stück\n- PR = Paar\n- SET = Satz\n- TNE = Tonne
    property articleNumberCatalogue : String read FarticleNumberCatalogue write FarticleNumberCatalogue; //max 15 Werksartikelnummer Katalog
    property alternativeProduct : TOpenMasterdataAPI_AlternativeProductList read FalternativeProduct write FalternativeProduct;
    property followupProduct : TOpenMasterdataAPI_FollowupProductList read FfollowupProduct write FfollowupProduct;
    property deepLink : String read FdeepLink write FdeepLink; //max 256 Deeplink zum Artikel
    property expiringProduct : Boolean read FexpiringProduct write FexpiringProduct; //enum" : [ true, "Yes-Successor", false ] Auslaufartikel\n  - Yes = Artikel ist Auslauf\n  - Yes-Successor = Artikel ist Auslauf und Nachfolgeartikel existiert\n  - No = Artikel ist nicht Auslauf
    property expiringDate : TDate read FexpiringDate write FexpiringDate; //Auslaufdatum
    property energyEfficiencyClass : String read FenergyEfficiencyClass write FenergyEfficiencyClass;
    property commodityGroupIdManufacturer : String read FcommodityGroupIdManufacturer write FcommodityGroupIdManufacturer;
    property commodityGroupDescrManufacturer : String read FcommodityGroupDescrManufacturer write FcommodityGroupDescrManufacturer;
    property productGroupIdManufacturer : String read FproductGroupIdManufacturer write FproductGroupIdManufacturer;
    property productGroupDescrManufacturer : String read FproductGroupDescrManufacturer write FproductGroupDescrManufacturer;
    property discoundGroupIdManufacturer : String read FdiscoundGroupIdManufacturer write FdiscoundGroupIdManufacturer;
    property discountGroupDescrManufacturer : String read FdiscountGroupDescrManufacturer write FdiscountGroupDescrManufacturer;
    property bonusGroupIdManufacturer : String read FbonusGroupIdManufacturer write FbonusGroupIdManufacturer;
    property bonusGroupDescrManufacturer : String read FbonusGroupDescrManufacturer write FbonusGroupDescrManufacturer;
    property accessories : TOpenMasterdataAPI_AccessoryList read Faccessories write Faccessories;
    property sets : TOpenMasterdataAPI_SetList read Fsets write Fsets;
    property attribute : TOpenMasterdataAPI_AttributeList read Fattribute write Fattribute;
    property constructionFrom : String read FconstructionFrom write FconstructionFrom;
    property constructionTo : String read FconstructionTo write FconstructionTo;
    property constructionText : String read FconstructionText write FconstructionText;
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

  TOpenMasterdataAPI_CarryingCategory = (
      omdCarryingCategory_0,
      omdCarryingCategory_1,
      omdCarryingCategory_2,
      omdCarryingCategory_3,
      omdCarryingCategory_4
    );

  //Art der Verpackungseinheit
  TOpenMasterdataAPI_PackageType = (
      omdPackageType_BB, //BB = Rolle
      omdPackageType_BG, //BG = Sack
      omdPackageType_BH, //BH = Bund/Bündel
      omdPackageType_BK, //BK = Korb
      omdPackageType_CF, //CF = Kiste
      omdPackageType_CG,//CG = Käfig
      omdPackageType_CH,//CH = Gitterbox
      omdPackageType_CT,//CT = Karton
      omdPackageType_PA, //PA = Päckchen
      omdPackageType_PC,//PC = Paket
      omdPackageType_PG,//PG = Einwegpalette
      omdPackageType_PK,//PK = Colli
      omdPackageType_PN,//PN = Europalette
      omdPackageType_PU, //PU = Kasten
      omdPackageType_RG,//RG = Ring
      omdPackageType_SC,//SC = Mischpalette
      omdPackageType_HP, //HP = Halbpalette
      omdPackageType_TU, //TU = Rohr
      omdPackageType_BTL,//BTL = Beutel (Tüte)
      omdPackageType_BX, //BX = Box
      omdPackageType_CO, //CO = Container
      omdPackageType_DY, //DY = Display
      omdPackageType_STG,//STG = Stange
      omdPackageType_TRO,//TRO = Trommel
      omdPackageType_PLA,//PLA = Platte
      omdPackageType_CI, //CI = Kanister
      omdPackageType_GEB,//GEB = Gebinde
      omdPackageType_Unknown
    );

  TOpenMasterdataAPI_PackageTypeHelper = class(TObject)
  public
    class function PackageTypeToStr(_Val : TOpenMasterdataAPI_PackageType) : String;
    class function PackageTypeFromStr(_Val : String) : TOpenMasterdataAPI_PackageType;
  end;

  TOpenMasterdataAPI_PackagingUnit = class
  public
    constructor Create;
    destructor Destroy; override;
  private
    FmeasureB: TOpenMasterdataAPI_LogisticsMeasure;
    FmeasureC: TOpenMasterdataAPI_LogisticsMeasure;
    FmeasureA: TOpenMasterdataAPI_LogisticsMeasure;
    FpackagingType: TOpenMasterdataAPI_PackageType;
    Fgtin: String;
    Fquantity: double;
    Fweight: TOpenMasterdataAPI_LogisticsWeight;
  public
    property packagingType : TOpenMasterdataAPI_PackageType read FpackagingType write FpackagingType;
    property quantity : double read Fquantity write Fquantity;
    property gtin : String read Fgtin write Fgtin;
    property measureA : TOpenMasterdataAPI_LogisticsMeasure read FmeasureA write FmeasureA;
    property measureB : TOpenMasterdataAPI_LogisticsMeasure read FmeasureB write FmeasureB;
    property measureC : TOpenMasterdataAPI_LogisticsMeasure read FmeasureC write FmeasureC;
    property weight : TOpenMasterdataAPI_LogisticsWeight read Fweight write Fweight;
  end;

  TOpenMasterdataAPI_PackagingUnitList = class(TObjectList<TOpenMasterdataAPI_PackagingUnit>);

  TOpenMasterdataAPI_Logistics = class
  private
    FmeasureB: TOpenMasterdataAPI_LogisticsMeasure;
    FmeasureC: TOpenMasterdataAPI_LogisticsMeasure;
    FmeasureA: TOpenMasterdataAPI_LogisticsMeasure;
    FhazardousMaterial: Boolean;
    Fexportable: Boolean;
    Fweight: TOpenMasterdataAPI_LogisticsWeight;
    FcommodityNumber: Integer;
    FcountryOfOrigin: String;
    FpackagingDisposalProvider: String;
    FstandardDeliveryPeriod: Integer;
    FpackagingQuantity: Integer;
    FubaListConform: Boolean;
    FubaListRelevant: Boolean;
    FpackagingUnits: TOpenMasterdataAPI_PackagingUnitList;
    FreachInfo: String;
    FlucidNumber: String;
    FdangerClass: String;
    FunNumber: String;
    FweeeNumber: String;
    FcarryingCategory: TOpenMasterdataAPI_CarryingCategory;
    FreachDate: TDate;
    FdurabilityPeriod: Integer;
  public
    constructor Create;
    destructor Destroy; override;
  public
    property exportable : Boolean read Fexportable write Fexportable;
    property commodityNumber : Integer read FcommodityNumber write FcommodityNumber;
    property countryOfOrigin : String read FcountryOfOrigin write FcountryOfOrigin;
    property hazardousMaterial : Boolean read FhazardousMaterial write FhazardousMaterial;
    property unNumber : String read FunNumber write FunNumber;
    property dangerClass : String read FdangerClass write FdangerClass;
    property carryingCategory : TOpenMasterdataAPI_CarryingCategory read FcarryingCategory write FcarryingCategory;
    property reachInfo : String read FreachInfo write FreachInfo;
    property reachDate : TDate read FreachDate write FreachDate;
    property ubaListRelevant : Boolean read FubaListRelevant write FubaListRelevant;
    property ubaListConform : Boolean read FubaListConform write FubaListConform;
    property durabilityPeriod : Integer read FdurabilityPeriod write FdurabilityPeriod;
    property standardDeliveryPeriod : Integer read FstandardDeliveryPeriod write FstandardDeliveryPeriod;
    property lucidNumber : String read FlucidNumber write FlucidNumber;
    property packagingDisposalProvider : String read FpackagingDisposalProvider write FpackagingDisposalProvider;
    property weeeNumber : String read FweeeNumber write FweeeNumber;
    property measureA : TOpenMasterdataAPI_LogisticsMeasure read FmeasureA write FmeasureA;
    property measureB : TOpenMasterdataAPI_LogisticsMeasure read FmeasureB write FmeasureB;
    property measureC : TOpenMasterdataAPI_LogisticsMeasure read FmeasureC write FmeasureC;
    property weight : TOpenMasterdataAPI_LogisticsWeight read Fweight write Fweight;
    property packagingQuantity : Integer read FpackagingQuantity write FpackagingQuantity;
    property packagingUnits : TOpenMasterdataAPI_PackagingUnitList read FpackagingUnits write FpackagingUnits;
  end;

  TOpenMasterdataAPI_TextRow = class
  private
    Ftext: String;
    Fposition: String;
  public
    property position : String read Fposition write Fposition;
    property text : String read Ftext write Ftext;
  end;

  TOpenMasterdataAPI_ArticleRow = class
  private
    FlinkedHistoricProduct: TOpenMasterdataAPI_LinkedHistoricProduct;
    Fpricegroup: String;
    FlinkedProduct: TOpenMasterdataAPI_LinkedProduct;
    Ftext: String;
    Fposition: String;
  public
    /// <summary>
    /// Position
    /// </summary>
    property position : String read Fposition write Fposition;
    /// <summary>
    /// Preisgruppe
    /// </summary>
    property pricegroup : String read Fpricegroup write Fpricegroup;
    /// <summary>
    /// Text
    /// </summary>
    property text : String read Ftext write Ftext;
    property linkedProduct : TOpenMasterdataAPI_LinkedProduct read FlinkedProduct write FlinkedProduct;
    property linkedHistoricProduct : TOpenMasterdataAPI_LinkedHistoricProduct read FlinkedHistoricProduct write FlinkedHistoricProduct;
  public
    constructor Create;
    destructor Destroy; override;
  end;

  TOpenMasterdataAPI_SparepartlistRow = class
  private
    FtextRow: TOpenMasterdataAPI_TextRow;
    FarticleRow: TOpenMasterdataAPI_ArticleRow;
  public
    property textRow : TOpenMasterdataAPI_TextRow read FtextRow write FtextRow;
    property articleRow : TOpenMasterdataAPI_ArticleRow read FarticleRow write FarticleRow;
  public
    constructor Create;
    destructor Destroy; override;
  end;

  TOpenMasterdataAPI_SparepartlistRowList = class(TObjectList<TOpenMasterdataAPI_SparepartlistRow>)
  end;

  TOpenMasterdataAPI_Sparepartlist = class
  private
    FlistNumber : String;
    FsparepartlistRow : TOpenMasterdataAPI_SparepartlistRowList;
  public
    property listNumber : String read FlistNumber write FlistNumber;
    property sparepartlistRow : TOpenMasterdataAPI_SparepartlistRowList read FsparepartlistRow write FsparepartlistRow;
  public
    constructor Create;
    destructor Destroy; override;
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

  TOpenMasterdataAPI_PriceHelper = class helper for TOpenMasterdataAPI_Price
  public
    function ValueAsCurrency : Currency;
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
    constructor Create;
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

  //Rohstoffangaben
  TOpenMasterdataAPI_RawMaterial = (
    rawMaterial_AL, //Aluminium
    rawMaterial_PB, //Blei
    rawMaterial_CR, //Chrom
    rawMaterial_AU, //Gold
    rawMaterial_CD, //Kadmium
    rawMaterial_CU, //Kupfer
    rawMaterial_MG, //Magnesium
    rawMaterial_MS, //Messing
    rawMaterial_NI, //Nickel
    rawMaterial_PL, //Platin
    rawMaterial_AG, //Silber
    rawMaterial_W,  //Wolfram
    rawMaterial_ZN, //Zink
    rawMaterial_SN,  //Zinn
    rawMaterial_Unknown
    );

  TOpenMasterdataAPI_RawMaterialHelper = class(TObject)
  public
    class function RawMaterialToStr(_Val : TOpenMasterdataAPI_RawMaterial) : String;
    class function RawMaterialFromStr(_Val : String) : TOpenMasterdataAPI_RawMaterial;
  end;

  TOpenMasterdataAPI_Material = class
  private
    FbasisUnit: String;
    Fmaterial: TOpenMasterdataAPI_RawMaterial;
    FproportionUnit: String;
    FquotationOfRawMaterial: double;
    FweightBasis: double;
    FproportionByWeight: double;
  public
    property material : TOpenMasterdataAPI_RawMaterial read Fmaterial write Fmaterial;
    property weightBasis : double read FweightBasis write FweightBasis;
    property basisUnit: String read FbasisUnit write FbasisUnit;
    property proportionByWeight : double read FproportionByWeight write FproportionByWeight;
    property proportionUnit : String read FproportionUnit write FproportionUnit;
    property quotationOfRawMaterial : double read FquotationOfRawMaterial write FquotationOfRawMaterial;
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
    constructor Create;
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
    Fshorttext2: String;
    Fshorttext1: String;
    FmarketingText: String;
  public
    property shorttext1 : String read Fshorttext1 write Fshorttext1;
    property productDescr : String read FproductDescr write FproductDescr;
    property shorttext2 : String read Fshorttext2 write Fshorttext2;
    property marketingText : String read FmarketingText write FmarketingText;
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
    Fsparepartlist: TOpenMasterdataAPI_Sparepartlist;
  public
    constructor Create;
    destructor Destroy; override;
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
    property sparepartlist : TOpenMasterdataAPI_Sparepartlist read Fsparepartlist write Fsparepartlist;
    property documents : TOpenMasterdataAPI_DocumentList read Fdocuments write Fdocuments;
  end;

  TOpenMasterdataAPI_ResultHelper = class helper for TOpenMasterdataAPI_Result
  public
    procedure LoadFromJson(const _JsonValue : String);
  end;

  TOpenMasterdataHelper = class
  public
    class function FixJson(const _JsonValue : String) : String;
  end;

implementation

{ TOpenMasterdataAPI_AuthResultHelper }

procedure TOpenMasterdataAPI_AuthResultHelper.LoadFromJson(
  const _JsonValue: String);
var
  messageJson :      TJSONValue;
  jsonString  : TJSONString;
  jsonValue : TJSONValue;
begin
  messageJson := TJSONObject.ParseJSONValue(_JsonValue) as TJSONValue;
  try
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
  finally
    messageJson.Free;
  end;
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
      Result := Result + '%7C';
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
  FalternativeProduct := TOpenMasterdataAPI_AlternativeProductList.Create;
  FfollowupProduct := TOpenMasterdataAPI_FollowupProductList.Create;
  Faccessories := TOpenMasterdataAPI_AccessoryList.Create;
  Fsets := TOpenMasterdataAPI_SetList.Create;
  Fattribute := TOpenMasterdataAPI_AttributeList.Create;
end;

destructor TOpenMasterdataAPI_Additional.Destroy;
begin
  if Assigned(FalternativeProduct) then begin FalternativeProduct.Free; FalternativeProduct := nil; end;
  if Assigned(FfollowupProduct) then begin FfollowupProduct.Free; FfollowupProduct := nil; end;
  if Assigned(Faccessories) then begin Faccessories.Free; Faccessories := nil; end;
  if Assigned(Fsets) then begin Fsets.Free; Fsets := nil; end;
  if Assigned(Fattribute) then begin Fattribute.Free; Fattribute := nil; end;
  inherited;
end;

{ TOpenMasterdataAPI_Logistics }

constructor TOpenMasterdataAPI_Logistics.Create;
begin
 FmeasureA := TOpenMasterdataAPI_LogisticsMeasure.Create;
 FmeasureB := TOpenMasterdataAPI_LogisticsMeasure.Create;
 FmeasureC := TOpenMasterdataAPI_LogisticsMeasure.Create;
 Fweight := TOpenMasterdataAPI_LogisticsWeight.Create;
 FpackagingUnits := TOpenMasterdataAPI_PackagingUnitList.Create;
end;

destructor TOpenMasterdataAPI_Logistics.Destroy;
begin
  if Assigned(FmeasureA) then begin FmeasureA.Free; FmeasureA := nil; end;
  if Assigned(FmeasureB) then begin FmeasureB.Free; FmeasureB := nil; end;
  if Assigned(FmeasureC) then begin FmeasureC.Free; FmeasureC := nil; end;
  if Assigned(Fweight) then begin Fweight.Free; Fweight := nil; end;
  if Assigned(FpackagingUnits) then begin FpackagingUnits.Free; FpackagingUnits := nil; end;
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
  Fsparepartlist := TOpenMasterdataAPI_Sparepartlist.Create;
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
  if Assigned(Fsparepartlist) then begin Fsparepartlist.Free; Fsparepartlist := nil; end;
  inherited;
end;

{ TOpenMasterdataAPI_ResultHelper }

procedure TOpenMasterdataAPI_ResultHelper.LoadFromJson(const _JsonValue: String);
var
  messageJson:      TJSONValue;

  jsonString  : TJSONString;
  jsonNumber : TJSONNumber;
  jsonArray : TJSONArray;
  jsonBool : TJSONBool;
  jsonValue,jsonValue2,jsonValue3 : TJSONValue;

  itemSparepartlistRow : TOpenMasterdataAPI_SparepartlistRow;

  procedure LoadMeasureUnitFromJson(_Val : TJSONValue; _Result : TOpenMasterdataAPI_LogisticsMeasure);
  var jsonString2  : TJSONString;
  begin
    if _Val = nil then exit;
    if _Result = nil then exit;

    if _Val.TryGetValue<TJSONString>('measure',jsonString2) then
      _Result.measure := jsonString2.Value;
    if _Val.TryGetValue<TJSONString>('unit',jsonString2) then
      _Result.unit_ := jsonString2.Value;
  end;

  procedure LoadWeightFromJson(_Val : TJSONValue; _Result : TOpenMasterdataAPI_LogisticsWeight);
  var jsonString2  : TJSONString;
  begin
    if _Val = nil then exit;
    if _Result = nil then exit;

    if _Val.TryGetValue<TJSONString>('weight',jsonString2) then
      _Result.weight := jsonString2.Value;
    if _Val.TryGetValue<TJSONString>('unit',jsonString2) then
      _Result.unit_ := jsonString2.Value;
  end;

  procedure LoadTextRowFromJson(_Val : TJSONValue; _Result : TOpenMasterdataAPI_TextRow);
  var jsonString2  : TJSONString;
  begin
    if _Val = nil then exit;
    if _Result = nil then exit;

    if _Val.TryGetValue<TJSONString>('position',jsonString2) then
      _Result.position := jsonString2.Value;
    if _Val.TryGetValue<TJSONString>('text',jsonString2) then
      _Result.text := jsonString2.Value;
  end;

  procedure LoadLinkedProductFromJson(_Val : TJSONValue; _Result : TOpenMasterdataAPI_LinkedProduct);
  var jsonString2  : TJSONString;
  begin
    if _Val = nil then exit;
    if _Result = nil then exit;

    if _Val.TryGetValue<TJSONString>('supplierPid',jsonString2) then
      _Result.supplierPid := jsonString2.Value;
    if _Val.TryGetValue<TJSONString>('manufacturerId',jsonString2) then
      _Result.manufacturerId := jsonString2.Value;
    if _Val.TryGetValue<TJSONString>('manufacturerIdType',jsonString2) then
      _Result.manufacturerIdType := jsonString2.Value;
    if _Val.TryGetValue<TJSONString>('manufacturerPid',jsonString2) then
      _Result.manufacturerPid := jsonString2.Value;
    if _Val.TryGetValue<TJSONString>('gtin',jsonString2) then
      _Result.gtin := jsonString2.Value;
    if _Val.TryGetValue<TJSONString>('productShortDescr',jsonString2) then
      _Result.productShortDescr := jsonString2.Value;
    if _Val.TryGetValue<TJSONString>('imageLink',jsonString2) then
      _Result.imageLink := jsonString2.Value;
    if _Val.TryGetValue<TJSONString>('thumbnailUrl',jsonString2) then
      _Result.thumbnailUrl := jsonString2.Value;
  end;

  procedure LoadLinkedHistoricProductFromJson(_Val : TJSONValue; _Result : TOpenMasterdataAPI_LinkedHistoricProduct);
  var jsonString2  : TJSONString;
  begin
    if _Val = nil then exit;
    if _Result = nil then exit;

    if _Val.TryGetValue<TJSONString>('manufacturerId',jsonString2) then
      _Result.manufacturerId := jsonString2.Value;
    if _Val.TryGetValue<TJSONString>('manufacturerIdType',jsonString2) then
      _Result.manufacturerIdType := jsonString2.Value;
    if _Val.TryGetValue<TJSONString>('historicProduct',jsonString2) then
      _Result.historicProduct := jsonString2.Value;
    if _Val.TryGetValue<TJSONString>('constructionFrom',jsonString2) then
      _Result.constructionFrom := jsonString2.Value;
    if _Val.TryGetValue<TJSONString>('productShortDescr',jsonString2) then
      _Result.productShortDescr := jsonString2.Value;
    if _Val.TryGetValue<TJSONString>('imageLink',jsonString2) then
      _Result.imageLink := jsonString2.Value;
  end;

  procedure LoadArticleRowFromJson(_Val : TJSONValue; _Result : TOpenMasterdataAPI_ArticleRow);
  var jsonString2  : TJSONString;
    jsonValue : TJSONValue;
  begin
    if _Val = nil then exit;
    if _Result = nil then exit;

    if _Val.TryGetValue<TJSONString>('position',jsonString2) then
      _Result.position := jsonString2.Value;
    if _Val.TryGetValue<TJSONString>('pricegroup',jsonString2) then
      _Result.pricegroup := jsonString2.Value;
    if _Val.TryGetValue<TJSONString>('text',jsonString2) then
      _Result.text := jsonString2.Value;

    if _Val.TryGetValue<TJSONValue>('linkedProduct',jsonValue) then
      LoadLinkedProductFromJson(jsonValue,_Result.linkedProduct);
    if _Val.TryGetValue<TJSONValue>('linkedHistoricProduct',jsonValue) then
      LoadLinkedHistoricProductFromJson(jsonValue,_Result.linkedHistoricProduct);
  end;

begin
  messageJson := TJSONObject.ParseJSONValue(
       TOpenMasterdataHelper.FixJson(_JsonValue),
       false,true) as TJSONValue;

  if messageJson = nil then
    exit;

  try
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
      if jsonValue.TryGetValue<TJSONValue>('listPrice',jsonValue2) then
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
      if jsonValue.TryGetValue<TJSONValue>('netPrice',jsonValue2) then
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
      if jsonValue.TryGetValue<TJSONArray>('rawMaterial',jsonArray) then
      for jsonValue2 in jsonArray do
      begin
        var itemMaterial : TOpenMasterdataAPI_Material := TOpenMasterdataAPI_Material.Create;
        prices.rawMaterial.Add(itemMaterial);

        if jsonValue2.TryGetValue<TJSONString>('material',jsonString) then
          itemMaterial.material := TOpenMasterdataAPI_RawMaterialHelper.RawMaterialFromStr(jsonString.Value);
        if jsonValue2.TryGetValue<TJSONString>('weightBasis',jsonString) then
          itemMaterial.weightBasis := TOpenMasterdataAPIHelper.JSONStrToFloat(jsonString.Value);
        if jsonValue2.TryGetValue<TJSONString>('basisUnit',jsonString) then
          itemMaterial.basisUnit := jsonString.Value;
        if jsonValue2.TryGetValue<TJSONString>('proportionByWeight',jsonString) then
          itemMaterial.proportionByWeight := TOpenMasterdataAPIHelper.JSONStrToFloat(jsonString.Value);
        if jsonValue2.TryGetValue<TJSONString>('proportionUnit',jsonString) then
          itemMaterial.proportionUnit := jsonString.Value;
        if jsonValue2.TryGetValue<TJSONString>('quotationOfRawMaterial',jsonString) then
          itemMaterial.quotationOfRawMaterial := TOpenMasterdataAPIHelper.JSONStrToFloat(jsonString.Value);
      end;
    end;
    if messageJson.TryGetValue<TJSONValue>('basic',jsonValue) then
    begin
      if jsonValue.TryGetValue<TJSONString>('productType',jsonString) then
        basic.productType := jsonString.Value;
      if jsonValue.TryGetValue<TJSONString>('startOfValidity',jsonString) then
        basic.startOfValidity := TOpenMasterdataAPIHelper.JSONStrToDate(jsonString.Value);
      if jsonValue.TryGetValue<TJSONString>('productShortDescr',jsonString) then
        basic.productShortDescr := jsonString.Value;
      if jsonValue.TryGetValue<TJSONBool>('priceOnDemand',jsonBool) then
        basic.priceOnDemand := jsonBool.AsBoolean;
      if jsonValue.TryGetValue<TJSONValue>('rrp',jsonValue2) then
      begin
        if jsonValue2.TryGetValue<TJSONString>('value',jsonString) then
          basic.rrp.value := jsonString.Value;
        if jsonValue2.TryGetValue<TJSONString>('currency',jsonString) then
          basic.rrp.currency := jsonString.Value;
        if jsonValue2.TryGetValue<TJSONValue>('basis',jsonValue3) then
          basic.rrp.basis := StrToIntDef(jsonValue3.Value,1);
        if jsonValue2.TryGetValue<TJSONString>('quantityUnit',jsonString) then
          basic.rrp.quantityUnit := jsonString.Value;
      end;
      if jsonValue.TryGetValue<TJSONString>('mainCommodityGroupId',jsonString) then
        basic.mainCommodityGroupId := jsonString.Value;
      if jsonValue.TryGetValue<TJSONString>('mainCommodityGroupDescr',jsonString) then
        basic.mainCommodityGroupDescr := jsonString.Value;
      if jsonValue.TryGetValue<TJSONString>('commodityGroupId',jsonString) then
        basic.commodityGroupId := jsonString.Value;
      if jsonValue.TryGetValue<TJSONString>('commodityGroupDescr',jsonString) then
        basic.commodityGroupDescr := jsonString.Value;
      if jsonValue.TryGetValue<TJSONString>('noteOfUse',jsonString) then
        basic.noteOfUse := jsonString.Value;
      if jsonValue.TryGetValue<TJSONString>('matchcode',jsonString) then
        basic.matchcode := jsonString.Value;
      if jsonValue.TryGetValue<TJSONString>('serie',jsonString) then
        basic.serie := jsonString.Value;
      if jsonValue.TryGetValue<TJSONString>('modelNumber',jsonString) then
        basic.modelNumber := jsonString.Value;
    end;
    if messageJson.TryGetValue<TJSONValue>('additional',jsonValue) then
    begin
      if jsonValue.TryGetValue<TJSONString>('minOrderQuantity',jsonString) then
        additional.minOrderQuantity := TOpenMasterdataAPIHelper.JSONStrToFloat(jsonString.Value);
      if jsonValue.TryGetValue<TJSONString>('minOrderUnit',jsonString) then
        additional.minOrderUnit := jsonString.Value;
      if jsonValue.TryGetValue<TJSONString>('articleNumberCatalogue',jsonString) then
        additional.articleNumberCatalogue := jsonString.Value;
      if jsonValue.TryGetValue<TJSONArray>('alternativeProduct',jsonArray) then
      for jsonValue2 in jsonArray do
      begin
        var itemAlternativeProduct : TOpenMasterdataAPI_AlternativeProduct := TOpenMasterdataAPI_AlternativeProduct.Create;
        additional.alternativeProduct.Add(itemAlternativeProduct);

        if jsonValue2.TryGetValue<TJSONString>('supplierPid',jsonString) then
          itemAlternativeProduct.supplierPid := jsonString.Value;
        if jsonValue2.TryGetValue<TJSONString>('manufacturerId',jsonString) then
          itemAlternativeProduct.manufacturerId := jsonString.Value;
        if jsonValue2.TryGetValue<TJSONString>('manufacturerIdType',jsonString) then
          itemAlternativeProduct.manufacturerIdType := jsonString.Value;
        if jsonValue2.TryGetValue<TJSONString>('manufacturerPid',jsonString) then
          itemAlternativeProduct.manufacturerPid := jsonString.Value;
        if jsonValue2.TryGetValue<TJSONString>('gtin',jsonString) then
          itemAlternativeProduct.gtin := jsonString.Value;
        if jsonValue2.TryGetValue<TJSONString>('productShortDescr',jsonString) then
          itemAlternativeProduct.productShortDescr := jsonString.Value;
        if jsonValue2.TryGetValue<TJSONString>('imageLink',jsonString) then
          itemAlternativeProduct.imageLink := jsonString.Value;
        if jsonValue2.TryGetValue<TJSONString>('thumbnailUrl',jsonString) then
          itemAlternativeProduct.thumbnailUrl := jsonString.Value;
        if jsonValue2.TryGetValue<TJSONString>('referenceType',jsonString) then
          itemAlternativeProduct.referenceType := jsonString.Value;
      end;
      if jsonValue.TryGetValue<TJSONArray>('followupProduct',jsonArray) then
      for jsonValue2 in jsonArray do
      begin
        var itemFollowupProduct : TOpenMasterdataAPI_FollowupProduct := TOpenMasterdataAPI_FollowupProduct.Create;
        additional.followupProduct.Add(itemFollowupProduct);

        if jsonValue2.TryGetValue<TJSONString>('supplierPid',jsonString) then
          itemFollowupProduct.supplierPid := jsonString.Value;
        if jsonValue2.TryGetValue<TJSONString>('manufacturerId',jsonString) then
          itemFollowupProduct.manufacturerId := jsonString.Value;
        if jsonValue2.TryGetValue<TJSONString>('manufacturerIdType',jsonString) then
          itemFollowupProduct.manufacturerIdType := jsonString.Value;
        if jsonValue2.TryGetValue<TJSONString>('manufacturerPid',jsonString) then
          itemFollowupProduct.manufacturerPid := jsonString.Value;
        if jsonValue2.TryGetValue<TJSONString>('gtin',jsonString) then
          itemFollowupProduct.gtin := jsonString.Value;
        if jsonValue2.TryGetValue<TJSONString>('productShortDescr',jsonString) then
          itemFollowupProduct.productShortDescr := jsonString.Value;
        if jsonValue2.TryGetValue<TJSONString>('imageLink',jsonString) then
          itemFollowupProduct.imageLink := jsonString.Value;
        if jsonValue2.TryGetValue<TJSONString>('thumbnailUrl',jsonString) then
          itemFollowupProduct.thumbnailUrl := jsonString.Value;
        if jsonValue2.TryGetValue<TJSONString>('referenceType',jsonString) then
          itemFollowupProduct.referenceType := jsonString.Value;
      end;
      if jsonValue.TryGetValue<TJSONString>('deepLink',jsonString) then
        additional.deepLink := jsonString.Value;
      if jsonValue.TryGetValue<TJSONString>('expiringProduct',jsonString) then
        additional.expiringProduct := SameText(jsonString.Value,'yes');
      if jsonValue.TryGetValue<TJSONString>('expiringDate',jsonString) then
        additional.expiringDate := TOpenMasterdataAPIHelper.JSONStrToDate(jsonString.Value);

      if jsonValue.TryGetValue<TJSONString>('energyEfficiencyClass',jsonString) then
        additional.energyEfficiencyClass := jsonString.Value;
      if jsonValue.TryGetValue<TJSONString>('commodityGroupIdManufacturer',jsonString) then
        additional.commodityGroupIdManufacturer := jsonString.Value;
      if jsonValue.TryGetValue<TJSONString>('commodityGroupDescrManufacturer',jsonString) then
        additional.commodityGroupDescrManufacturer := jsonString.Value;
      if jsonValue.TryGetValue<TJSONString>('productGroupIdManufacturer',jsonString) then
        additional.productGroupIdManufacturer := jsonString.Value;
      if jsonValue.TryGetValue<TJSONString>('productGroupDescrManufacturer',jsonString) then
        additional.productGroupDescrManufacturer := jsonString.Value;
      if jsonValue.TryGetValue<TJSONString>('discoundGroupIdManufacturer',jsonString) then
        additional.discoundGroupIdManufacturer := jsonString.Value;
      if jsonValue.TryGetValue<TJSONString>('discountGroupDescrManufacturer',jsonString) then
        additional.discountGroupDescrManufacturer := jsonString.Value;
      if jsonValue.TryGetValue<TJSONString>('bonusGroupIdManufacturer',jsonString) then
        additional.bonusGroupIdManufacturer := jsonString.Value;
      if jsonValue.TryGetValue<TJSONString>('bonusGroupDescrManufacturer',jsonString) then
        additional.bonusGroupDescrManufacturer := jsonString.Value;
      if jsonValue.TryGetValue<TJSONArray>('accessories',jsonArray) then
      for jsonValue2 in jsonArray do
      begin
        var itemAccessory : TOpenMasterdataAPI_Accessory := TOpenMasterdataAPI_Accessory.Create;
        additional.accessories.Add(itemAccessory);

        if jsonValue2.TryGetValue<TJSONString>('supplierPid',jsonString) then
          itemAccessory.supplierPid := jsonString.Value;
        if jsonValue2.TryGetValue<TJSONString>('manufacturerId',jsonString) then
          itemAccessory.manufacturerId := jsonString.Value;
        if jsonValue2.TryGetValue<TJSONString>('manufacturerIdType',jsonString) then
          itemAccessory.manufacturerIdType := jsonString.Value;
        if jsonValue2.TryGetValue<TJSONString>('manufacturerPid',jsonString) then
          itemAccessory.manufacturerPid := jsonString.Value;
        if jsonValue2.TryGetValue<TJSONString>('gtin',jsonString) then
          itemAccessory.gtin := jsonString.Value;
        if jsonValue2.TryGetValue<TJSONString>('productShortDescr',jsonString) then
          itemAccessory.productShortDescr := jsonString.Value;
        if jsonValue2.TryGetValue<TJSONString>('imageLink',jsonString) then
          itemAccessory.imageLink := jsonString.Value;
        if jsonValue2.TryGetValue<TJSONString>('thumbnailUrl',jsonString) then
          itemAccessory.thumbnailUrl := jsonString.Value;
        if jsonValue2.TryGetValue<TJSONString>('amount',jsonString) then
          itemAccessory.amount := TOpenMasterdataAPIHelper.JSONStrToFloat(jsonString.Value);
        if jsonValue2.TryGetValue<TJSONString>('referenceType',jsonString) then
          itemAccessory.referenceType := jsonString.Value;
        if jsonValue2.TryGetValue<TJSONBool>('necessaryForFunction',jsonBool) then
          itemAccessory.necessaryForFunction := jsonBool.AsBoolean;
      end;
      if jsonValue.TryGetValue<TJSONArray>('sets',jsonArray) then
      for jsonValue2 in jsonArray do
      begin
        var itemSet : TOpenMasterdataAPI_Set := TOpenMasterdataAPI_Set.Create;
        additional.sets.Add(itemSet);

        if jsonValue2.TryGetValue<TJSONString>('supplierPid',jsonString) then
          itemSet.supplierPid := jsonString.Value;
        if jsonValue2.TryGetValue<TJSONString>('manufacturerId',jsonString) then
          itemSet.manufacturerId := jsonString.Value;
        if jsonValue2.TryGetValue<TJSONString>('manufacturerIdType',jsonString) then
          itemSet.manufacturerIdType := jsonString.Value;
        if jsonValue2.TryGetValue<TJSONString>('manufacturerPid',jsonString) then
          itemSet.manufacturerPid := jsonString.Value;
        if jsonValue2.TryGetValue<TJSONString>('gtin',jsonString) then
          itemSet.gtin := jsonString.Value;
        if jsonValue2.TryGetValue<TJSONString>('productShortDescr',jsonString) then
          itemSet.productShortDescr := jsonString.Value;
        if jsonValue2.TryGetValue<TJSONString>('imageLink',jsonString) then
          itemSet.imageLink := jsonString.Value;
        if jsonValue2.TryGetValue<TJSONString>('thumbnailUrl',jsonString) then
          itemSet.thumbnailUrl := jsonString.Value;
        if jsonValue2.TryGetValue<TJSONString>('amount',jsonString) then
          itemSet.amount := TOpenMasterdataAPIHelper.JSONStrToFloat(jsonString.Value);
      end;
      if jsonValue.TryGetValue<TJSONArray>('attribute',jsonArray) then
      for jsonValue2 in jsonArray do
      begin
        var itemAttribute : TOpenMasterdataAPI_Attribute := TOpenMasterdataAPI_Attribute.Create;
        additional.attribute.Add(itemAttribute);

        if jsonValue2.TryGetValue<TJSONString>('attributeSystem',jsonString) then
          itemAttribute.attributeSystem := jsonString.Value;
        if jsonValue2.TryGetValue<TJSONString>('attributeName',jsonString) then
          itemAttribute.attributeName := jsonString.Value;
        if jsonValue2.TryGetValue<TJSONString>('attributeValue1',jsonString) then
          itemAttribute.attributeValue1 := jsonString.Value;
        if jsonValue2.TryGetValue<TJSONString>('attributeUnit',jsonString) then
          itemAttribute.attributeUnit := jsonString.Value;
        if jsonValue2.TryGetValue<TJSONString>('attributeClassDesc',jsonString) then
          itemAttribute.attributeClassDesc := jsonString.Value;
        if jsonValue2.TryGetValue<TJSONString>('attributeDesc',jsonString) then
          itemAttribute.attributeDesc := jsonString.Value;
        if jsonValue2.TryGetValue<TJSONString>('attributeValue1Descr',jsonString) then
          itemAttribute.attributeValue1Descr := jsonString.Value;
        if jsonValue2.TryGetValue<TJSONString>('attributeUnitDesc',jsonString) then
          itemAttribute.attributeUnitDesc := jsonString.Value;
      end;
      if jsonValue.TryGetValue<TJSONString>('constructionFrom',jsonString) then
        additional.constructionFrom := jsonString.Value;
      if jsonValue.TryGetValue<TJSONString>('constructionTo',jsonString) then
        additional.constructionTo := jsonString.Value;
      if jsonValue.TryGetValue<TJSONString>('constructionText',jsonString) then
        additional.constructionText := jsonString.Value;
    end;
    if messageJson.TryGetValue<TJSONValue>('descriptions',jsonValue) then
    begin
      if jsonValue.TryGetValue<TJSONString>('shorttext1',jsonString) then
        descriptions.shorttext1 := jsonString.Value;
      if jsonValue.TryGetValue<TJSONString>('shorttext2',jsonString) then
        descriptions.shorttext2 := jsonString.Value;
      if jsonValue.TryGetValue<TJSONString>('productDescr',jsonString) then
        descriptions.productDescr := jsonString.Value;
      if jsonValue.TryGetValue<TJSONString>('marketingText',jsonString) then
        descriptions.marketingText := jsonString.Value;
    end;
    if messageJson.TryGetValue<TJSONValue>('logistics',jsonValue) then
    begin
      if jsonValue.TryGetValue<TJSONBool>('exportable',jsonBool) then
        logistics.exportable := jsonBool.AsBoolean;
      if jsonValue.TryGetValue<TJSONString>('commodityNumber',jsonString) then
        logistics.commodityNumber := StrToIntDef(jsonString.Value,0);
      if jsonValue.TryGetValue<TJSONString>('countryOfOrigin',jsonString) then
        logistics.countryOfOrigin := jsonString.Value;
      if jsonValue.TryGetValue<TJSONBool>('hazardousMaterial',jsonBool) then
        logistics.hazardousMaterial := jsonBool.AsBoolean;
      if jsonValue.TryGetValue<TJSONString>('reachInfo',jsonString) then
        logistics.reachInfo := jsonString.Value;
      if jsonValue.TryGetValue<TJSONString>('reachDate',jsonString) then
        logistics.reachDate := TOpenMasterdataAPIHelper.JSONStrToDate(jsonString.Value);
      if jsonValue.TryGetValue<TJSONString>('durabilityPeriod',jsonString) then
        logistics.durabilityPeriod := StrToIntDef(jsonString.Value,0);
      if jsonValue.TryGetValue<TJSONString>('standardDeliveryPeriod',jsonString) then
        logistics.standardDeliveryPeriod := StrToIntDef(jsonString.Value,0);
      if jsonValue.TryGetValue<TJSONString>('lucidNumber',jsonString) then
        logistics.lucidNumber := jsonString.Value;
      if jsonValue.TryGetValue<TJSONString>('packagingDisposalProvider',jsonString) then
        logistics.packagingDisposalProvider := jsonString.Value;
      if jsonValue.TryGetValue<TJSONValue>('measureA',jsonValue2) then
        LoadMeasureUnitFromJson(jsonValue2,logistics.measureA);
      if jsonValue.TryGetValue<TJSONValue>('measureB',jsonValue2) then
        LoadMeasureUnitFromJson(jsonValue2,logistics.measureB);
      if jsonValue.TryGetValue<TJSONValue>('measureC',jsonValue2) then
        LoadMeasureUnitFromJson(jsonValue2,logistics.measureC);
      if jsonValue.TryGetValue<TJSONValue>('weight',jsonValue2) then
        LoadWeightFromJson(jsonValue2,logistics.weight);
      if jsonValue.TryGetValue<TJSONValue>('unNumber',jsonValue2) then
        logistics.unNumber := jsonValue2.Value;
      if jsonValue.TryGetValue<TJSONValue>('dangerClass',jsonValue2) then
        logistics.dangerClass := jsonValue2.Value;
      if jsonValue.TryGetValue<TJSONBool>('ubaListRelevant',jsonBool) then
        logistics.ubaListRelevant := jsonBool.AsBoolean;
      if jsonValue.TryGetValue<TJSONBool>('ubaListConform',jsonBool) then
        logistics.ubaListConform := jsonBool.AsBoolean;
      if jsonValue.TryGetValue<TJSONValue>('weeeNumber',jsonValue2) then
        logistics.weeeNumber := jsonValue2.Value;
      if jsonValue.TryGetValue<TJSONString>('packagingQuantity',jsonString) then
        logistics.packagingQuantity := StrToIntDef(jsonString.Value,0);
      if jsonValue.TryGetValue<TJSONArray>('packagingUnits',jsonArray) then
      for jsonValue2 in jsonArray do
      begin
        var itemPackagingUnit : TOpenMasterdataAPI_PackagingUnit := TOpenMasterdataAPI_PackagingUnit.Create;
        logistics.packagingUnits.Add(itemPackagingUnit);

        if jsonValue2.TryGetValue<TJSONString>('packagingType',jsonString) then
          itemPackagingUnit.packagingType := TOpenMasterdataAPI_PackageTypeHelper.PackageTypeFromStr(jsonString.Value);
        if jsonValue2.TryGetValue<TJSONString>('quantity',jsonString) then
          itemPackagingUnit.quantity := TOpenMasterdataAPIHelper.JSONStrToFloat(jsonString.Value);
        if jsonValue2.TryGetValue<TJSONString>('gtin',jsonString) then
          itemPackagingUnit.gtin := jsonString.Value;
        if jsonValue2.TryGetValue<TJSONValue>('measureA',jsonValue3) then
          LoadMeasureUnitFromJson(jsonValue3,itemPackagingUnit.measureA);
        if jsonValue2.TryGetValue<TJSONValue>('measureB',jsonValue3) then
          LoadMeasureUnitFromJson(jsonValue3,itemPackagingUnit.measureB);
        if jsonValue2.TryGetValue<TJSONValue>('measureC',jsonValue3) then
          LoadMeasureUnitFromJson(jsonValue3,itemPackagingUnit.measureC);
        if jsonValue2.TryGetValue<TJSONValue>('weight',jsonValue3) then
          LoadWeightFromJson(jsonValue3,itemPackagingUnit.weight);
      end;
    end;
    if messageJson.TryGetValue<TJSONValue>('sparepartlists',jsonValue) then
    begin
      if jsonValue.TryGetValue<TJSONString>('listNumber',jsonString) then
        sparepartlist.listNumber := jsonString.Value;

      jsonValue3 := jsonValue.FindValue('sparepartlistRow');
      if jsonValue3 <> nil then
      begin
        if jsonValue3 is TJSONObject then
        begin
          itemSparepartlistRow := TOpenMasterdataAPI_SparepartlistRow.Create;
          sparepartlist.sparepartlistRow.Add(itemSparepartlistRow);
          if jsonValue3.TryGetValue<TJSONValue>('textRow',jsonValue2) then
            LoadTextRowFromJson(jsonValue2,itemSparepartlistRow.textRow);
          if jsonValue3.TryGetValue<TJSONValue>('articleRow',jsonValue2) then
            LoadArticleRowFromJson(jsonValue2,itemSparepartlistRow.articleRow);
        end
        else
        if jsonValue3 is TJSONArray then
        begin
          if jsonValue.TryGetValue<TJSONArray>('sparepartlistRow',jsonArray) then
          for jsonValue2 in jsonArray do
          begin
            itemSparepartlistRow := TOpenMasterdataAPI_SparepartlistRow.Create;
            sparepartlist.sparepartlistRow.Add(itemSparepartlistRow);
            if jsonValue2.TryGetValue<TJSONValue>('textRow',jsonValue3) then
              LoadTextRowFromJson(jsonValue3,itemSparepartlistRow.textRow);
            if jsonValue2.TryGetValue<TJSONValue>('articleRow',jsonValue3) then
              LoadArticleRowFromJson(jsonValue3,itemSparepartlistRow.articleRow);
          end;
        end;
      end;
    end;
    if messageJson.TryGetValue<TJSONArray>('pictures',jsonArray) then
    for jsonValue in jsonArray do
    begin
      var itemPicture : TOpenMasterdataAPI_Picture := TOpenMasterdataAPI_Picture.Create;
      pictures.Add(itemPicture);

      if jsonValue.TryGetValue<TJSONString>('url',jsonString) then
        itemPicture.url := jsonString.Value;
      if jsonValue.TryGetValue<TJSONString>('urlThumbnail',jsonString) then
        itemPicture.urlThumbnail := jsonString.Value;
      if jsonValue.TryGetValue<TJSONString>('type',jsonString) then
        itemPicture.type_ := jsonString.Value;
      if jsonValue.TryGetValue<TJSONString>('use',jsonString) then
        itemPicture.use := jsonString.Value;
      if jsonValue.TryGetValue<TJSONBool>('substituteId',jsonBool) then
        itemPicture.substituteId := jsonBool.AsBoolean;
      if jsonValue.TryGetValue<TJSONString>('description',jsonString) then
        itemPicture.description := jsonString.Value;
      if jsonValue.TryGetValue<TJSONNumber>('sortOrder',jsonNumber) then
        itemPicture.sortOrder := jsonNumber.AsInt;
      if jsonValue.TryGetValue<TJSONNumber>('size',jsonNumber) then
        itemPicture.size := jsonNumber.AsInt;
      if jsonValue.TryGetValue<TJSONString>('filename',jsonString) then
        itemPicture.filename := jsonString.Value;
      if jsonValue.TryGetValue<TJSONString>('hash',jsonString) then
        itemPicture.hash := jsonString.Value;
    end;
    if messageJson.TryGetValue<TJSONArray>('documents',jsonArray) then
    for jsonValue in jsonArray do
    begin
      var itemDocument : TOpenMasterdataAPI_Document := TOpenMasterdataAPI_Document.Create;
      documents.Add(itemDocument);

      if jsonValue.TryGetValue<TJSONString>('url',jsonString) then
        itemDocument.url := jsonString.Value;
      if jsonValue.TryGetValue<TJSONString>('type',jsonString) then
        itemDocument.type_ := jsonString.Value;
      if jsonValue.TryGetValue<TJSONString>('description',jsonString) then
        itemDocument.description := jsonString.Value;
      if jsonValue.TryGetValue<TJSONNumber>('sortOrder',jsonNumber) then
        itemDocument.sortOrder := jsonNumber.AsInt;
      if jsonValue.TryGetValue<TJSONValue>('size',jsonValue3) then
        itemDocument.size := StrToIntDef(jsonValue3.Value,0);
      if jsonValue.TryGetValue<TJSONString>('filename',jsonString) then
        itemDocument.filename := jsonString.Value;
      if jsonValue.TryGetValue<TJSONString>('hash',jsonString) then
        itemDocument.hash := jsonString.Value;
    end;
  finally
    messageJson.Free;
  end;
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

{ TOpenMasterdataAPI_PriceHelper }

function TOpenMasterdataAPI_PriceHelper.ValueAsCurrency: Currency;
var
  fs : TFormatSettings;
begin
  fs.ThousandSeparator := ',';
  fs.DecimalSeparator := '.';
  Result := StrToCurrDef(value,0,fs);
end;

{ TOpenMasterdataAPIHelper }

class function TOpenMasterdataAPIHelper.JSONStrToDate(
  _Val: String): TDate;
begin
  Result := 0;
  _Val := Trim(_Val);
  if _Val = '' then
    exit;
  if (Length(_Val) = 8) and (Pos('-',_Val) = 0) then
  begin
    exit;
  end;
  Result := ISO8601ToDate(_Val);
end;

class function TOpenMasterdataAPIHelper.JSONStrToFloat(_Val: String): double;
var
  fs : TFormatSettings;
begin
  fs.ThousandSeparator := ',';
  fs.DecimalSeparator := '.';
  Result := StrToFloatDef(_Val,0,fs);
end;

{ TOpenMasterdataAPI_PackagingUnit }

constructor TOpenMasterdataAPI_PackagingUnit.Create;
begin
 FmeasureA := TOpenMasterdataAPI_LogisticsMeasure.Create;
 FmeasureB := TOpenMasterdataAPI_LogisticsMeasure.Create;
 FmeasureC := TOpenMasterdataAPI_LogisticsMeasure.Create;
 Fweight := TOpenMasterdataAPI_LogisticsWeight.Create;
end;

destructor TOpenMasterdataAPI_PackagingUnit.Destroy;
begin
  if Assigned(FmeasureA) then begin FmeasureA.Free; FmeasureA := nil; end;
  if Assigned(FmeasureB) then begin FmeasureB.Free; FmeasureB := nil; end;
  if Assigned(FmeasureC) then begin FmeasureC.Free; FmeasureC := nil; end;
  if Assigned(Fweight) then begin Fweight.Free; Fweight := nil; end;
  inherited;
end;

{ TOpenMasterdataHelper }

class function TOpenMasterdataHelper.FixJson(const _JsonValue: String): String;
begin
  //JSON-Korrektur
  //Ungültiges JSON Wiedemann
  Result := _JsonValue;
  if Pos('"gtin": 0',Result)>0 then
    Result := ReplaceText(Result,'"gtin": 0','"gtin": ');
end;

{ TOpenMasterdataAPI_PackageTypeHelper }

class function TOpenMasterdataAPI_PackageTypeHelper.PackageTypeFromStr(
  _Val: String): TOpenMasterdataAPI_PackageType;
begin
  if SameText(_Val,'BB') then
    Result := omdPackageType_BB //BB = Rolle
  else
  if SameText(_Val,'BG') then
    Result := omdPackageType_BG //BG = Sack
  else
  if SameText(_Val,'BH') then
    Result := omdPackageType_BH //BH = Bund/Bündel
  else
  if SameText(_Val,'BK') then
    Result := omdPackageType_BK //BK = Korb
  else
  if SameText(_Val,'CF') then
    Result := omdPackageType_CF //CF = Kiste
  else
  if SameText(_Val,'CG') then
    Result := omdPackageType_CG//CG = Käfig
  else
  if SameText(_Val,'CH') then
    Result := omdPackageType_CH//CH = Gitterbox
  else
  if SameText(_Val,'CT') then
    Result := omdPackageType_CT//CT = Karton
  else
  if SameText(_Val,'PA') then
    Result := omdPackageType_PA //PA = Päckchen
  else
  if SameText(_Val,'PC') then
    Result := omdPackageType_PC//PC = Paket
  else
  if SameText(_Val,'PG') then
    Result := omdPackageType_PG//PG = Einwegpalette
  else
  if SameText(_Val,'PK') then
    Result := omdPackageType_PK//PK = Colli
  else
  if SameText(_Val,'PN') then
    Result := omdPackageType_PN//PN = Europalette
  else
  if SameText(_Val,'PU') then
    Result := omdPackageType_PU //PU = Kasten
  else
  if SameText(_Val,'RG') then
    Result := omdPackageType_RG//RG = Ring
  else
  if SameText(_Val,'SC') then
    Result := omdPackageType_SC//SC = Mischpalette
  else
  if SameText(_Val,'HP') then
    Result := omdPackageType_HP //HP = Halbpalette
  else
  if SameText(_Val,'TU') then
    Result := omdPackageType_TU //TU = Rohr
  else
  if SameText(_Val,'BTL') then
    Result := omdPackageType_BTL//BTL = Beutel (Tüte)
  else
  if SameText(_Val,'BX') then
    Result := omdPackageType_BX //BX = Box
  else
  if SameText(_Val,'CO') then
    Result := omdPackageType_CO //CO = Container
  else
  if SameText(_Val,'DY') then
    Result := omdPackageType_DY //DY = Display
  else
  if SameText(_Val,'STG') then
    Result := omdPackageType_STG//STG = Stange
  else
  if SameText(_Val,'TRO') then
    Result := omdPackageType_TRO//TRO = Trommel
  else
  if SameText(_Val,'PLA') then
    Result := omdPackageType_PLA//PLA = Platte
  else
  if SameText(_Val,'CI') then
    Result := omdPackageType_CI //CI = Kanister
  else
  if SameText(_Val,'GEB') then
    Result := omdPackageType_GEB//GEB = Gebinde
  else
    Result := omdPackageType_Unknown;
end;

class function TOpenMasterdataAPI_PackageTypeHelper.PackageTypeToStr(
  _Val: TOpenMasterdataAPI_PackageType): String;
begin
  case _Val of
    omdPackageType_BB: Result := 'BB';
    omdPackageType_BG: Result := 'BG';
    omdPackageType_BH: Result := 'BH';
    omdPackageType_BK: Result := 'BK';
    omdPackageType_CF: Result := 'CF';
    omdPackageType_CG: Result := 'CG';
    omdPackageType_CH: Result := 'CH';
    omdPackageType_CT: Result := 'CT';
    omdPackageType_PA: Result := 'PA';
    omdPackageType_PC: Result := 'PC';
    omdPackageType_PG: Result := 'PG';
    omdPackageType_PK: Result := 'PK';
    omdPackageType_PN: Result := 'PN';
    omdPackageType_PU: Result := 'PU';
    omdPackageType_RG: Result := 'RG';
    omdPackageType_SC: Result := 'SC';
    omdPackageType_HP: Result := 'HP';
    omdPackageType_TU: Result := 'TU';
    omdPackageType_BTL:Result := 'BTL' ;
    omdPackageType_BX: Result := 'BX';
    omdPackageType_CO: Result := 'CO';
    omdPackageType_DY: Result := 'DY';
    omdPackageType_STG: Result := 'STG';
    omdPackageType_TRO: Result := 'TRO';
    omdPackageType_PLA: Result := 'PLA';
    omdPackageType_CI: Result := 'CI';
    omdPackageType_GEB: Result := 'GEB';
    else Result := '';
  end;
end;

{ TOpenMasterdataAPI_RawMaterialHelper }

class function TOpenMasterdataAPI_RawMaterialHelper.RawMaterialFromStr(
  _Val: String): TOpenMasterdataAPI_RawMaterial;
begin
  if SameText(_Val,'AL') then
    Result := rawMaterial_AL
  else
  if SameText(_Val,'PB') then
    Result := rawMaterial_PB
  else
  if SameText(_Val,'CR') then
    Result := rawMaterial_CR
  else
  if SameText(_Val,'AU') then
    Result := rawMaterial_AU
  else
  if SameText(_Val,'CD') then
    Result := rawMaterial_CD
  else
  if SameText(_Val,'CU') then
    Result := rawMaterial_CU
  else
  if SameText(_Val,'MG') then
    Result := rawMaterial_MG
  else
  if SameText(_Val,'MS') then
    Result := rawMaterial_MS
  else
  if SameText(_Val,'NI') then
    Result := rawMaterial_NI
  else
  if SameText(_Val,'PL') then
    Result := rawMaterial_PL
  else
  if SameText(_Val,'AG') then
    Result := rawMaterial_AG
  else
  if SameText(_Val,'W') then
    Result := rawMaterial_W
  else
  if SameText(_Val,'ZN') then
    Result := rawMaterial_ZN
  else
  if SameText(_Val,'SN') then
    Result := rawMaterial_SN
  else
    Result := rawMaterial_Unknown;
end;

class function TOpenMasterdataAPI_RawMaterialHelper.RawMaterialToStr(
  _Val: TOpenMasterdataAPI_RawMaterial): String;
begin
  case _Val of
    rawMaterial_AL: Result := 'AL';
    rawMaterial_PB: Result := 'PB';
    rawMaterial_CR: Result := 'CR';
    rawMaterial_AU: Result := 'AU';
    rawMaterial_CD: Result := 'CD';
    rawMaterial_CU: Result := 'CU';
    rawMaterial_MG: Result := 'MG';
    rawMaterial_MS: Result := 'MS';
    rawMaterial_NI: Result := 'NI';
    rawMaterial_PL: Result := 'PL';
    rawMaterial_AG: Result := 'AG';
    rawMaterial_W : Result := 'W';
    rawMaterial_ZN: Result := 'ZN';
    rawMaterial_SN: Result := 'SN';
    else Result := '';
  end;
end;

{ TOpenMasterdataAPI_Sparepartlist }

constructor TOpenMasterdataAPI_Sparepartlist.Create;
begin
  FsparepartlistRow := TOpenMasterdataAPI_SparepartlistRowList.Create;
end;

destructor TOpenMasterdataAPI_Sparepartlist.Destroy;
begin
  if Assigned(FsparepartlistRow) then begin FsparepartlistRow.Free; FsparepartlistRow := nil; end;
  inherited;
end;

{ TOpenMasterdataAPI_ArticleRow }

constructor TOpenMasterdataAPI_ArticleRow.Create;
begin
  FlinkedProduct := TOpenMasterdataAPI_LinkedProduct.Create;
  FlinkedHistoricProduct := TOpenMasterdataAPI_LinkedHistoricProduct.Create;
end;

destructor TOpenMasterdataAPI_ArticleRow.Destroy;
begin
  if Assigned(FlinkedProduct) then begin FlinkedProduct.Free; FlinkedProduct := nil; end;
  if Assigned(FlinkedHistoricProduct) then begin FlinkedHistoricProduct.Free; FlinkedHistoricProduct := nil; end;
  inherited;
end;

{ TOpenMasterdataAPI_SparepartlistRow }

constructor TOpenMasterdataAPI_SparepartlistRow.Create;
begin
  FtextRow := TOpenMasterdataAPI_TextRow.Create;
  FarticleRow := TOpenMasterdataAPI_ArticleRow.Create;
end;

destructor TOpenMasterdataAPI_SparepartlistRow.Destroy;
begin
  if Assigned(FtextRow) then begin FtextRow.Free; FtextRow := nil; end;
  if Assigned(FarticleRow) then begin FarticleRow.Free; FarticleRow := nil; end;
  inherited;
end;

end.
