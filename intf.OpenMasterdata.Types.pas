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
  ,MVCFramework.Nullables,MVCFramework.Serializer.Commons
  ;

type
//  TOpenMasterdataAPI_CoreResult = class
//  private
//    Fsuccess: Boolean;
//    Ferror: Boolean;
//    Fmessage : String;
//  public
//    property success : Boolean read Fsuccess write Fsuccess;
//    property error : Boolean read Ferror write Ferror;
//    [MVCNameAs('message')]
//    property message_ : String read Fmessage write Fmessage;
//  end;

  TOpenMasterdataAPI_AuthResult = class
  private
    //Fsuccess: Boolean;
    Fexpires_in: Integer;
    Frefresh_token: String;
    //Ferror: Boolean;
    Ftoken_type: String;
    Faccess_token: String;
  public
    //property success : Boolean read Fsuccess write Fsuccess;
    //property error : Boolean read Ferror write Ferror;
    property access_token : String read Faccess_token write Faccess_token;
    property token_type : String read Ftoken_type write Ftoken_type;
    property expires_in : Integer read Fexpires_in write Fexpires_in;
    property refresh_token : String read Frefresh_token write Frefresh_token;
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
  public
    property url : String read Furl write Furl;
    [MVCNameAs('type')]
    property type_ : String read Ftype_ write Ftype_;
    property filename : String read Ffilename write Ffilename;
    property size : Integer read Fsize write Fsize;
    property hash : String read Fhash write Fhash;
  end;

  TOpenMasterdataAPI_DocumentList = class(TObjectList<TOpenMasterdataAPI_Document>)
  end;

  TOpenMasterdataAPI_Accessory = class
  private
    FproductShortDescr: String;
    FnecessaryForFunction: Boolean;
    FmanufacturerPid: String;
    Fgtin: NullableString;
    FmanufacturerId: NullableString;
    FimageLink: String;
    FsupplierPid: String;
  public
    property supplierPid : String read FsupplierPid write FsupplierPid;
    property manufacturerId : NullableString read FmanufacturerId write FmanufacturerId;
    property manufacturerPid : String read FmanufacturerPid write FmanufacturerPid;
    property gtin : NullableString read Fgtin write Fgtin;
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
    Fgtin: NullableString;
    Famount: double;
    FmanufacturerId: NullableString;
    FimageLink: String;
    FsupplierPid: String;
  public
    property supplierPid : String read FsupplierPid write FsupplierPid;
    property manufacturerId : NullableString read FmanufacturerId write FmanufacturerId;
    property manufacturerPid : String read FmanufacturerPid write FmanufacturerPid;
    property gtin : NullableString read Fgtin write Fgtin;
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
  public
    constructor Create; virtual;
    destructor Destroy; override;

    property minOrderQuantity : String read FminOrderQuantity write FminOrderQuantity;
    property minOrderUnit : String read FminOrderUnit write FminOrderUnit;
    property deepLink : String read FdeepLink write FdeepLink;
    property expiringProduct : String read FexpiringProduct write FexpiringProduct;
    property accessories : TOpenMasterdataAPI_AccessoryList read Faccessories write Faccessories;
    property sets : TOpenMasterdataAPI_SetList read Fsets write Fsets;
  end;

  TOpenMasterdataAPI_LogisticsMeasure = class
  private
    Funit_: String;
    Fmeasure: String;
  public
    property measure : String read Fmeasure write Fmeasure;
    [MVCNameAs('unit')]
    property unit_ : String read Funit_ write Funit_;
  end;

  TOpenMasterdataAPI_LogisticsWeight = class
  private
    Funit_: String;
    Fweight: String;
  public
    property weight : String read Fweight write Fweight;
    [MVCNameAs('unit')]
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

  TOpenMasterdataAPI_Basic = class
  private
    FproductShortDescr: String;
    FpriceOnDemand: Boolean;
    FstartOfValidity: TDate;
    Fserie: String;
  public
    property startOfValidity : TDate read FstartOfValidity write FstartOfValidity;
    property productShortDescr : String read FproductShortDescr write FproductShortDescr;
    property priceOnDemand : Boolean read FpriceOnDemand write FpriceOnDemand;
    property serie : String read Fserie write Fserie;
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

  TOpenMasterdataAPI_Prices = class
  private
    FlistPrice: TOpenMasterdataAPI_Price;
    FnetPrice: TOpenMasterdataAPI_Price;
    FtaxCode: Integer;
  public
    constructor Create; virtual;
    destructor Destroy; override;

    property listPrice : TOpenMasterdataAPI_Price read FlistPrice write FlistPrice;
    property netPrice : TOpenMasterdataAPI_Price read FnetPrice write FnetPrice;
    property taxCode : Integer read FtaxCode write FtaxCode;
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
  public
    property url : String read Furl write Furl;
    property urlThumbnail : String read FurlThumbnail write FurlThumbnail;
    [MVCNameAs('type')]
    property type_ : String read Ftype_ write Ftype_;
    property use : String read Fuse write Fuse;
    property substituteId : Boolean read FsubstituteId write FsubstituteId;
    property filename : String read Ffilename write Ffilename;
    property size : Integer read Fsize write Fsize;
    property hash : String read Fhash write Fhash;
  end;

  TOpenMasterdataAPI_PictureList = class(TObjectList<TOpenMasterdataAPI_Picture>)
  end;

  TOpenMasterdataAPI_Result = class
  private
    //Fsuccess: Boolean;
    //Ferror: Boolean;
    Fprices: TOpenMasterdataAPI_Prices;
    Fdocuments: TOpenMasterdataAPI_DocumentList;
    Fdescriptions: TOpenMasterdataAPI_Descriptions;
    Flogistics: TOpenMasterdataAPI_Logistics;
    Fbasic: TOpenMasterdataAPI_Basic;
    Fpictures: TOpenMasterdataAPI_PictureList;
    Fadditional: TOpenMasterdataAPI_Additional;
    FsupplierPid: String;
  public
    constructor Create; virtual;
    destructor Destroy; override;

    //property success : Boolean read Fsuccess write Fsuccess;
    //property error : Boolean read Ferror write Ferror;
    property supplierPid : String read FsupplierPid write FsupplierPid;
    property documents : TOpenMasterdataAPI_DocumentList read Fdocuments write Fdocuments;
    property additional : TOpenMasterdataAPI_Additional read Fadditional write Fadditional;
    property logistics : TOpenMasterdataAPI_Logistics read Flogistics write Flogistics;
    property basic : TOpenMasterdataAPI_Basic read Fbasic write Fbasic;
    property prices : TOpenMasterdataAPI_Prices read Fprices write Fprices;
    property descriptions : TOpenMasterdataAPI_Descriptions read Fdescriptions write Fdescriptions;
    property pictures : TOpenMasterdataAPI_PictureList read Fpictures write Fpictures;
  end;

implementation

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
  FnetPrice := TOpenMasterdataAPI_Price.Create;
end;

destructor TOpenMasterdataAPI_Prices.Destroy;
begin
  if Assigned(FlistPrice) then begin FlistPrice.Free; FlistPrice := nil; end;
  if Assigned(FnetPrice) then begin FnetPrice.Free; FnetPrice := nil; end;
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
  inherited;
end;

end.
