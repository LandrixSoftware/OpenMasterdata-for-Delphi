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

unit intf.OpenMasterdata;

interface

uses
  System.SysUtils,System.Classes,System.Contnrs,System.Variants,System.DateUtils
  ,System.Generics.Collections,System.Generics.Defaults,System.SyncObjs
  ,System.NetEncoding,System.Net.HttpClient,System.Net.URLClient
  ,Vcl.StdCtrls,System.JSON,REST.Json,REST.JsonReflect, REST.Types, REST.Client
  ,intf.OpenMasterdata.Types
  ;

type
  IOpenMasterdataApiClient = interface
    ['{425FC785-64D4-4A17-A012-49F60448EBF8}']

    function GetBySupplierPid(_SupplierPid : String; _DataPackages : TOpenMasterdataAPI_DataPackages; out _Result: TOpenMasterdataAPI_Result) : Boolean;
    function GetByManufacturerData(_ManufacturerId, _ManufacturerIdType, _ManufacturerPid : String; _DataPackages : TOpenMasterdataAPI_DataPackages; out _Result: TOpenMasterdataAPI_Result) : Boolean;
    function GetByGTIN(_GTIN : String; _DataPackages : TOpenMasterdataAPI_DataPackages; out _Result: TOpenMasterdataAPI_Result) : Boolean;

    procedure SetOAuthURL(const _URL : String);
    procedure SetBySupplierPIDURL(const _URL : String);
    procedure SetByManufacturerDataURL(const _URL : String);
    procedure SetByGTINURL(const _URL : String);

    function GetData(_Url : String; out _Result : TStream) : Boolean;

    function GetConnectionName : String;
    function GetCurrentAuthorizationToken : String;
    function GetLastOAuthResponseContent : String;
    function GetLastBySupplierPIDResponseContent : String;
    function GetLastErrorMessage : String;
    function GetLastErrorCode : Integer;
  end;

  TOpenMasterdataApiClient = class(TInterfacedObject,IOpenMasterdataApiClient)
  public type
    TGrantType = (omdgt_Password,omdgt_ClientCredentials);
    TDataPackagesSendMode = (omddpsm_PipeDelimited,omddpsm_Exploded);
  private
    FCS : TCriticalSection;
    FUsername,
    FPassword,
    FCustomerNumber,
    FClientID,
    FClientSecret,
    FClientScope,
    FConnectionName : String;
    FGrantType : TGrantType;
    FDataPackagesSendMode : TDataPackagesSendMode;

    FAccessToken : String;
    FRefreshToken : String;
    FAccessTokenValidTo : TDateTime;
    //FCookie : String;

    FOAuthUrl : String;
    FBySupplierPIDUrl : String;
    FByManufacturerDataUrl : String;
    FByGTINUrl : String;

    FRESTClientOAuth: TRESTClient;
    FRESTClientBySupplierPID: TRESTClient;
    FRESTClientByManufacturerData: TRESTClient;
    FRESTClientByGTIN: TRESTClient;

    FLastOAuthResponseContent : String;
    FLastBySupplierPIDResponseContent : String;
    FLastErrorMessage : String;
    FLastErrorCode : Integer;

    function LoggedIn: Boolean;
    function Login : Boolean;
    function RefreshLogin : Boolean;
    function ExecuteProductRequest(_RestClient : TRESTClient; const _Resource, _IdentifierName, _IdentifierValue : String;
      _DataPackages : TOpenMasterdataAPI_DataPackages; out _Result: TOpenMasterdataAPI_Result) : Boolean; overload;
    function ExecuteProductRequest(_RestClient : TRESTClient; const _Resource,
      _IdentifierName1, _IdentifierValue1, _IdentifierName2, _IdentifierValue2,
      _IdentifierName3, _IdentifierValue3 : String; _DataPackages : TOpenMasterdataAPI_DataPackages;
      out _Result: TOpenMasterdataAPI_Result) : Boolean; overload;
  public
    constructor Create(_ConnectionName, _Username, _Password, _CustomerNumber, _ClientID, _ClientSecret, _ClientScope : String; _GrantType : TGrantType; _DataPackagesSendMode : TDataPackagesSendMode);
    destructor Destroy; override;
  public
    function GetConnectionName : String;
    function GetCurrentAuthorizationToken : String;
    function GetLastOAuthResponseContent : String;
    function GetLastBySupplierPIDResponseContent : String;
    function GetLastErrorMessage : String;
    function GetLastErrorCode : Integer;

    procedure SetOAuthURL(const _URL : String);
    procedure SetBySupplierPIDURL(const _URL : String);
    procedure SetByManufacturerDataURL(const _URL : String);
    procedure SetByGTINURL(const _URL : String);

    function GetBySupplierPid(_SupplierPid : String; _DataPackages : TOpenMasterdataAPI_DataPackages; out _Result: TOpenMasterdataAPI_Result) : Boolean;
    function GetByManufacturerData(_ManufacturerId, _ManufacturerIdType, _ManufacturerPid : String; _DataPackages : TOpenMasterdataAPI_DataPackages; out _Result: TOpenMasterdataAPI_Result) : Boolean;
    function GetByGTIN(_GTIN : String; _DataPackages : TOpenMasterdataAPI_DataPackages; out _Result: TOpenMasterdataAPI_Result) : Boolean;
  public
    function GetData(_Url : String; out _Result : TStream) : Boolean;
  public
    class function GetOpenMasterdataConnection(_ConnectionName : String; out _Connection : IOpenMasterdataApiClient) : Boolean;
    class function NewOpenMasterdataConnection(_ConnectionName, _Username, _Password, _CustomerNumber,_ClientID, _ClientSecret, _ClientScope : String; _GrantType : TGrantType; _DataPackagesSendMode : TDataPackagesSendMode) : IOpenMasterdataApiClient;
    class function GetGrantTypeFromString(const _Val : String; _Default : TGrantType = TGrantType.omdgt_Password) : TGrantType;
    class function GetDataPackagesSendModeFromString(const _Val : String; _Default : TDataPackagesSendMode = TDataPackagesSendMode.omddpsm_PipeDelimited) : TDataPackagesSendMode;
  end;

implementation

var
  openConnections : TInterfaceList;
  openConnectionsCS : TCriticalSection;
  openConnectionsInitLock : TObject;

function NormalizeSingleLine(const _Value : String) : String;
begin
  Result := Trim(_Value);
  Result := StringReplace(Result,#13#10,' ',[rfReplaceAll]);
  Result := StringReplace(Result,#13,' ',[rfReplaceAll]);
  Result := StringReplace(Result,#10,' ',[rfReplaceAll]);
  while Pos('  ',Result) > 0 do
    Result := StringReplace(Result,'  ',' ',[rfReplaceAll]);
end;

function StripHtmlTags(const _Value : String) : String;
var
  inTag : Boolean;
  i : Integer;
begin
  Result := '';
  inTag := false;
  for i := 1 to Length(_Value) do
  begin
    case _Value[i] of
      '<' : inTag := true;
      '>' : inTag := false;
    else
      if not inTag then
        Result := Result + _Value[i];
    end;
  end;
  Result := NormalizeSingleLine(Result);
end;

function OAuthResponsePreview(const _Content : String) : String;
begin
  Result := StripHtmlTags(_Content);
  if Result = '' then
    Result := NormalizeSingleLine(_Content);
  if Length(Result) > 240 then
    Result := Copy(Result,1,240) + '...';
end;

function OAuthJsonErrorMessage(const _Content : String) : String;
var
  trimmedContent : String;
begin
  trimmedContent := Trim(_Content);
  if trimmedContent = '' then
    exit('OAuth response is empty.');

  if (trimmedContent <> '') and (trimmedContent[1] = '<') then
    Result := 'OAuth response is HTML instead of JSON: ' + OAuthResponsePreview(trimmedContent)
  else
    Result := 'OAuth response is not valid JSON: ' + OAuthResponsePreview(trimmedContent);
end;

function TryLoadAuthResult(const _Content : String; out _AuthResult : TOpenMasterdataAPI_AuthResult;
  out _ErrorMessage : String) : Boolean;
begin
  Result := false;
  _AuthResult := nil;
  _ErrorMessage := '';

  if Trim(_Content) = '' then
  begin
    _ErrorMessage := OAuthJsonErrorMessage(_Content);
    exit;
  end;

  _AuthResult := TOpenMasterdataAPI_AuthResult.Create;
  try
    try
      _AuthResult.LoadFromJson(_Content);
    except
      on E:Exception do
      begin
        _ErrorMessage := OAuthJsonErrorMessage(_Content);
        if E.Message <> '' then
          _ErrorMessage := _ErrorMessage + ' (' + E.Message + ')';
        FreeAndNil(_AuthResult);
        exit;
      end;
    end;

    if _AuthResult.access_token.IsEmpty then
    begin
      _ErrorMessage := OAuthJsonErrorMessage(_Content);
      FreeAndNil(_AuthResult);
      exit;
    end;

    Result := true;
  except
    FreeAndNil(_AuthResult);
    raise;
  end;
end;

procedure EnsureOpenConnectionsInitialized;
begin
  TMonitor.Enter(openConnectionsInitLock);
  try
    if openConnections = nil then
      openConnections := TInterfaceList.Create;
    if openConnectionsCS = nil then
      openConnectionsCS := TCriticalSection.Create;
  finally
    TMonitor.Exit(openConnectionsInitLock);
  end;
end;

function BuildRestBaseUrl(const _Url : TURI) : String;
begin
  Result := _Url.Scheme+'://'+_Url.Host;
  if _Url.Port > 0 then
    Result := Result + ':' + _Url.Port.ToString;
end;

function BuildExplodedDataPackageResource(const _Resource : String;
  _DataPackages : TOpenMasterdataAPI_DataPackages) : String;
var
  dataPackage : TOpenMasterdataAPI_DataPackage;
  hasQuery : Boolean;
begin
  Result := _Resource;
  hasQuery := Pos('?',Result) > 0;

  for dataPackage := Low(TOpenMasterdataAPI_DataPackage) to High(TOpenMasterdataAPI_DataPackage) do
  if dataPackage in _DataPackages then
  begin
    if hasQuery then
      Result := Result + '&'
    else
    begin
      Result := Result + '?';
      hasQuery := true;
    end;
    Result := Result + 'datapackage=' + TNetEncoding.URL.Encode(
      TOpenMasterdataAPI_DataPackageHelper.DataPackageAsString(dataPackage));
  end;
end;

{ TOpenMasterdataApiClient }

class function TOpenMasterdataApiClient.GetOpenMasterdataConnection(
  _ConnectionName: String;
  out _Connection: IOpenMasterdataApiClient): Boolean;
var
  i : Integer;
begin
  Result := false;

  _Connection := nil;
  EnsureOpenConnectionsInitialized;
  openConnectionsCS.Acquire;
  try
    for i := 0 to openConnections.Count-1 do
    if SameText(_ConnectionName,
              IOpenMasterdataApiClient(openConnections[i]).GetConnectionName) then
    begin
      _Connection := IOpenMasterdataApiClient(openConnections[i]);
      Result := true;
      break;
    end;
  finally
    openConnectionsCS.Release;
  end;
end;

class function TOpenMasterdataApiClient.NewOpenMasterdataConnection(
  _ConnectionName, _Username, _Password, _CustomerNumber, _ClientID,
  _ClientSecret,_ClientScope: String;
  _GrantType : TGrantType; _DataPackagesSendMode : TDataPackagesSendMode): IOpenMasterdataApiClient;
var
  i : Integer;
begin
  Result := nil;
  EnsureOpenConnectionsInitialized;
  openConnectionsCS.Acquire;
  try
    for i := 0 to openConnections.Count-1 do
    if SameText(_ConnectionName,
              IOpenMasterdataApiClient(openConnections[i]).GetConnectionName) then
    begin
      Result := IOpenMasterdataApiClient(openConnections[i]);
      exit;
    end;

    Result := TOpenMasterdataApiClient.Create(_ConnectionName,_Username, _Password,
                 _CustomerNumber,_ClientID,_ClientSecret,_ClientScope,_GrantType,_DataPackagesSendMode);
    openConnections.Add(Result);
  finally
    openConnectionsCS.Release;
  end;
end;

constructor TOpenMasterdataApiClient.Create(_ConnectionName, _Username,
  _Password, _CustomerNumber, _ClientID, _ClientSecret, _ClientScope: String;
  _GrantType : TGrantType; _DataPackagesSendMode : TDataPackagesSendMode);
begin
  FConnectionName := _ConnectionName;
  FUsername := _Username;
  FPassword := _Password;
  FCustomerNumber := _CustomerNumber;
  FClientID := _ClientID;
  FClientSecret := _ClientSecret;
  FClientScope := _ClientScope;
  FGrantType := _GrantType;
  FDataPackagesSendMode := _DataPackagesSendMode;
  FCS := TCriticalSection.Create;

  FRESTClientOAuth:= TRESTClient.Create(nil);
  FRESTClientOAuth.Name := 'RESTClientOAuth';
  FRESTClientBySupplierPID:= TRESTClient.Create(nil);
  FRESTClientBySupplierPID.Name := 'RESTClientBySupplierPID';
  FRESTClientByManufacturerData := TRESTClient.Create(nil);
  FRESTClientByManufacturerData.Name := 'RESTClientByManufacturerData';
  FRESTClientByGTIN := TRESTClient.Create(nil);
  FRESTClientByGTIN.Name := 'RESTClientByGTIN';

  FLastOAuthResponseContent := '';
  FLastBySupplierPIDResponseContent := '';
  FLastErrorMessage := '';
  FLastErrorCode := 0;

  FAccessToken := '';
  FRefreshToken := '';
  FAccessTokenValidTo := 0;
  //FCookie := '';
end;

destructor TOpenMasterdataApiClient.Destroy;
begin
  if Assigned(FRESTClientOAuth) then begin FRESTClientOAuth.Free; FRESTClientOAuth := nil; end;
  if Assigned(FRESTClientBySupplierPID) then begin FRESTClientBySupplierPID.Free; FRESTClientBySupplierPID := nil; end;
  if Assigned(FRESTClientByManufacturerData) then begin FRESTClientByManufacturerData.Free; FRESTClientByManufacturerData := nil; end;
  if Assigned(FRESTClientByGTIN) then begin FRESTClientByGTIN.Free; FRESTClientByGTIN := nil; end;
  if Assigned(FCS) then begin FCS.Free; FCS := nil; end;
  inherited;
end;

function TOpenMasterdataApiClient.GetLastBySupplierPIDResponseContent: String;
begin
  Result := FLastBySupplierPIDResponseContent;
end;

function TOpenMasterdataApiClient.GetLastErrorCode: Integer;
begin
  Result := FLastErrorCode;
end;

function TOpenMasterdataApiClient.GetLastErrorMessage: String;
begin
  Result := FLastErrorMessage;
end;

function TOpenMasterdataApiClient.GetLastOAuthResponseContent: String;
begin
  Result := FLastOAuthResponseContent;
end;

function TOpenMasterdataApiClient.LoggedIn: Boolean;
begin
  Result := false;
  if (not FAccessToken.IsEmpty) and (now < FAccessTokenValidTo) then
  begin
    Result := true;
    exit;
  end;
  if FAccessToken.IsEmpty then
    Result := Login
  else
  if FAccessTokenValidTo <= now then
  begin
    if FRefreshToken.IsEmpty then
      Result := Login
    else
      Result := RefreshLogin;
  end;
end;

function TOpenMasterdataApiClient.Login: Boolean;
var
  RESTResponse: TRESTResponse;
  RESTRequest: TRESTRequest;

  itm : TOpenMasterdataAPI_AuthResult;
  authError : String;
begin
  //https://github.com/paolo-rossi/delphi-neon
  Result := false;

  FLastOAuthResponseContent := '';
  FLastErrorMessage := '';
  FLastErrorCode := 0;

  FAccessToken := '';
  FRefreshToken := '';
  //FCookie := '';

  //TOAuth2Authenticator?

  RESTResponse := TRESTResponse.Create(nil);
  RESTRequest := TRESTRequest.Create(nil);
  try
    RESTResponse.Name := 'RESTResponse';
    RESTRequest.Name := 'RESTRequest';
    RESTRequest.AssignedValues := [TCustomRESTRequest.TAssignedValue.rvConnectTimeout, TCustomRESTRequest.TAssignedValue.rvReadTimeout];
    RESTRequest.Client := FRESTClientOAuth;
    RESTRequest.Resource := FOAuthUrl;
    RESTRequest.Method := rmPOST;
    RESTRequest.Accept := '*/*';

    case FGrantType of
      omdgt_Password:          RESTRequest.Params.AddItem('grant_type','password');
      omdgt_ClientCredentials: RESTRequest.Params.AddItem('grant_type','client_credentials');
    end;
    if not FClientSecret.IsEmpty then
      RESTRequest.Params.AddItem('client_secret',FClientSecret);
    if not FClientScope.IsEmpty then
      RESTRequest.Params.AddItem('scope',FClientScope);
    if FClientID <> '' then
      RESTRequest.Params.AddItem('client_id',FClientID);

    if (FUsername <> '') and (FCustomerNumber <> '') then
      RESTRequest.Params.AddItem('username',FUsername+#9+FCustomerNumber)
    else
    if (FCustomerNumber <> '') then
      RESTRequest.Params.AddItem('username',FCustomerNumber)
    else
      RESTRequest.Params.AddItem('username',FUsername);
    RESTRequest.Params.AddItem('password',FPassword);

    RESTRequest.Response := RESTResponse;

    RESTRequest.Execute;

    if not RESTResponse.Status.SuccessOK_200 then
    begin
      FLastErrorMessage := RESTResponse.StatusText+' '+RESTResponse.Content;
      FLastErrorCode := RESTResponse.StatusCode;
      exit;
    end;

    FLastOAuthResponseContent := RESTResponse.Content;

    FAccessTokenValidTo := now;
    if not TryLoadAuthResult(FLastOAuthResponseContent,itm,authError) then
    begin
      FLastErrorMessage := authError;
      exit;
    end;

    try
      FAccessToken := itm.access_token;
      FRefreshToken := itm.refresh_token;
      FAccessTokenValidTo := IncSecond(FAccessTokenValidTo,itm.expires_in-30);
      //if RESTResponse.Cookies.Count > 0 then
      //  FCookie := RESTResponse.Cookies[0].GetServerCookie;

      Result := true;
    finally
      itm.Free;
    end;
  finally
    RESTRequest.Free;
    RESTResponse.Free;
  end;
end;

function TOpenMasterdataApiClient.RefreshLogin: Boolean;
var
  RESTResponse: TRESTResponse;
  RESTRequest: TRESTRequest;

  itm : TOpenMasterdataAPI_AuthResult;
  authError : String;
begin
  //https://github.com/paolo-rossi/delphi-neon
  Result := false;

  FLastOAuthResponseContent := '';
  FLastErrorMessage := '';
  FLastErrorCode := 0;

  FAccessToken := '';
  //FCookie := '';
  if FRefreshToken.IsEmpty then
    exit;

  RESTResponse := TRESTResponse.Create(nil);
  RESTRequest := TRESTRequest.Create(nil);
  try
    RESTResponse.Name := 'RESTResponse';
    RESTRequest.Name := 'RESTRequest';
    RESTRequest.AssignedValues := [TCustomRESTRequest.TAssignedValue.rvConnectTimeout, TCustomRESTRequest.TAssignedValue.rvReadTimeout];
    RESTRequest.Client := FRESTClientOAuth;
    RESTRequest.Resource := FOAuthUrl;
    RESTRequest.Params.AddItem('grant_type','refresh_token');
    if FClientID <> '' then
      RESTRequest.Params.AddItem('client_id',FClientID);
    RESTRequest.Params.AddItem('refresh_token',FRefreshToken);
    RESTRequest.Response := RESTResponse;

    RESTRequest.Execute;

    if not RESTResponse.Status.SuccessOK_200 then
    begin
      FLastErrorMessage := RESTResponse.StatusText;
      FLastErrorCode := RESTResponse.StatusCode;
      exit;
    end;

    FLastOAuthResponseContent := RESTResponse.Content;

    FAccessTokenValidTo := now;
    if not TryLoadAuthResult(FLastOAuthResponseContent,itm,authError) then
    begin
      FLastErrorMessage := authError;
      exit;
    end;

    try
      if itm.refresh_token.IsEmpty then
      begin
        FLastErrorMessage := 'OAuth refresh response does not contain a refresh token.';
        exit;
      end;

      FAccessToken := itm.access_token;
      FRefreshToken := itm.refresh_token;
      FAccessTokenValidTo := IncSecond(FAccessTokenValidTo,itm.expires_in-30);
      //if RESTResponse.Cookies.Count > 0 then
      //  FCookie := RESTResponse.Cookies[0].GetServerCookie;

      Result := true;
    finally
      itm.Free;
    end;
  finally
    RESTRequest.Free;
    RESTResponse.Free;
  end;
end;

function TOpenMasterdataApiClient.GetBySupplierPid(_SupplierPid: String;
  _DataPackages: TOpenMasterdataAPI_DataPackages;
  out _Result: TOpenMasterdataAPI_Result): Boolean;
begin
  Result := ExecuteProductRequest(FRESTClientBySupplierPID,FBySupplierPIDUrl,'supplierPid',_SupplierPid,_DataPackages,_Result);
end;

function TOpenMasterdataApiClient.GetByManufacturerData(_ManufacturerId,
  _ManufacturerIdType, _ManufacturerPid: String;
  _DataPackages: TOpenMasterdataAPI_DataPackages;
  out _Result: TOpenMasterdataAPI_Result): Boolean;
begin
  Result := ExecuteProductRequest(FRESTClientByManufacturerData,FByManufacturerDataUrl,
    'manufacturerId',_ManufacturerId,
    'manufacturerIdType',_ManufacturerIdType,
    'manufacturerPid',_ManufacturerPid,
    _DataPackages,_Result);
end;

function TOpenMasterdataApiClient.GetByGTIN(_GTIN: String;
  _DataPackages: TOpenMasterdataAPI_DataPackages;
  out _Result: TOpenMasterdataAPI_Result): Boolean;
begin
  Result := ExecuteProductRequest(FRESTClientByGTIN,FByGTINUrl,'gtin',_GTIN,_DataPackages,_Result);
end;

function TOpenMasterdataApiClient.ExecuteProductRequest(_RestClient : TRESTClient;
  const _Resource, _IdentifierName, _IdentifierValue : String;
  _DataPackages : TOpenMasterdataAPI_DataPackages; out _Result: TOpenMasterdataAPI_Result) : Boolean;
begin
  Result := ExecuteProductRequest(_RestClient,_Resource,_IdentifierName,_IdentifierValue,'','','','',_DataPackages,_Result);
end;

function TOpenMasterdataApiClient.ExecuteProductRequest(_RestClient : TRESTClient;
  const _Resource, _IdentifierName1, _IdentifierValue1, _IdentifierName2,
  _IdentifierValue2, _IdentifierName3, _IdentifierValue3 : String;
  _DataPackages : TOpenMasterdataAPI_DataPackages; out _Result: TOpenMasterdataAPI_Result) : Boolean;
var
  RESTResponse: TRESTResponse;
  RESTRequest: TRESTRequest;
begin
  Result := false;
  _Result := nil;

  FCS.Acquire;
  try

  if not LoggedIn then
    exit;

  FLastBySupplierPIDResponseContent := '';
  FLastErrorMessage := '';
  FLastErrorCode := 0;

  if (_RestClient = nil) or _Resource.IsEmpty then
    exit;
  if (_IdentifierName1 <> '') and _IdentifierValue1.IsEmpty then
    exit;
  if (_IdentifierName2 <> '') and _IdentifierValue2.IsEmpty then
    exit;
  if (_IdentifierName3 <> '') and _IdentifierValue3.IsEmpty then
    exit;
  if _DataPackages = [] then
    exit;

  RESTResponse := TRESTResponse.Create(nil);
  RESTRequest := TRESTRequest.Create(nil);
  try
    RESTResponse.Name := 'RESTResponse';
    RESTRequest.Name := 'RESTRequest';
    RESTRequest.AssignedValues := [TCustomRESTRequest.TAssignedValue.rvConnectTimeout, TCustomRESTRequest.TAssignedValue.rvReadTimeout];
    RESTRequest.Client := _RestClient;
    if FDataPackagesSendMode = TDataPackagesSendMode.omddpsm_Exploded then
      RESTRequest.Resource := BuildExplodedDataPackageResource(_Resource,_DataPackages)
    else
      RESTRequest.Resource := _Resource;
    RESTRequest.AddAuthParameter('Authorization','Bearer ' + FAccessToken,TRESTRequestParameterKind.pkHTTPHEADER, [TRESTRequestParameterOption.poDoNotEncode]);
    //if FCookie <> '' then
    //  RESTRequest.AddAuthParameter('Cookie',FCookie,TRESTRequestParameterKind.pkCOOKIE, [TRESTRequestParameterOption.poDoNotEncode]);
    RESTRequest.Method := rmGET;
    //RESTRequest.URLAlreadyEncoded := true;
    if _IdentifierName1 <> '' then
      RESTRequest.AddParameter(_IdentifierName1,TNetEncoding.URL.Encode(_IdentifierValue1),TRESTRequestParameterKind.pkQUERY,[TRESTRequestParameterOption.poDoNotEncode]);
    if _IdentifierName2 <> '' then
      RESTRequest.AddParameter(_IdentifierName2,TNetEncoding.URL.Encode(_IdentifierValue2),TRESTRequestParameterKind.pkQUERY,[TRESTRequestParameterOption.poDoNotEncode]);
    if _IdentifierName3 <> '' then
      RESTRequest.AddParameter(_IdentifierName3,TNetEncoding.URL.Encode(_IdentifierValue3),TRESTRequestParameterKind.pkQUERY,[TRESTRequestParameterOption.poDoNotEncode]);
    if FDataPackagesSendMode = TDataPackagesSendMode.omddpsm_PipeDelimited then
      RESTRequest.AddParameter('datapackage',TOpenMasterdataAPI_DataPackageHelper.DataPackagesAsString(_DataPackages),TRESTRequestParameterKind.pkQUERY,[TRESTRequestParameterOption.poDoNotEncode]);
    RESTRequest.Response := RESTResponse;
    RESTRequest.Execute;

    if not RESTResponse.Status.SuccessOK_200 then
    begin
      FLastErrorMessage := RESTResponse.StatusText;
      FLastErrorCode := RESTResponse.StatusCode;
      exit;
    end;

    FLastBySupplierPIDResponseContent := RESTResponse.Content;

    _Result := TOpenMasterdataAPI_Result.Create;
    try
      _Result.LoadFromJson(RESTResponse.Content);
      Result := true;
    except
      on E:Exception do
      begin
        _Result.Free;
        FLastErrorMessage := E.ClassName+' '+e.Message;
        exit;
      end;
    end;
  finally
    RESTRequest.Free;
    RESTResponse.Free;
  end;

  finally
    FCS.Release;
  end;
end;

function TOpenMasterdataApiClient.GetConnectionName: String;
begin
  Result := FConnectionName;
end;

function TOpenMasterdataApiClient.GetCurrentAuthorizationToken: String;
begin
  Result := FAccessToken;
end;

function TOpenMasterdataApiClient.GetData(_Url: String;
  out _Result: TStream): Boolean;
var
  lHttp : THTTPClient;
  lData : TMemoryStream;
  lHeaders : TNetHeaders;
begin
  Result := false;
  _Result := nil;

  if _Url.IsEmpty then
    exit;

  FCS.Acquire;
  try

  if not LoggedIn then
    exit;

  FLastErrorMessage := '';
  FLastErrorCode := 0;

  lHttp := THTTPClient.Create;
  lData := TMemoryStream.Create;
  try
    try
      lHeaders := [TNetHeader.Create('Authorization','Bearer ' + FAccessToken)];
      with lHttp.Get(_URL,lData,lHeaders) do
      begin
        Result := StatusCode = 200;
        if Result then
        begin
          _Result := lData;
          lData := nil;
        end;
      end;
    except
      on E:Exception do
      begin
        FLastErrorMessage := E.ClassName+' '+e.Message;
      end;
    end;
  finally
    if Assigned(lData) then begin lData.Free; lData := nil; end;
    lHttp.Free;
  end;

  finally
    FCS.Release;
  end;
end;

class function TOpenMasterdataApiClient.GetDataPackagesSendModeFromString(const _Val: String;
  _Default: TDataPackagesSendMode): TDataPackagesSendMode;
begin
  if SameText(_Val,'pipedelimited') then
    Result := TOpenMasterdataApiClient.TDataPackagesSendMode.omddpsm_PipeDelimited
  else
  if SameText(_Val,'exploded') then
    Result := TOpenMasterdataApiClient.TDataPackagesSendMode.omddpsm_Exploded
  else
    Result := _Default;
end;

class function TOpenMasterdataApiClient.GetGrantTypeFromString(
  const _Val: String; _Default: TGrantType): TGrantType;
begin
  if SameText(_Val,'client_credentials') then
    Result := TOpenMasterdataApiClient.TGrantType.omdgt_ClientCredentials
  else
  if SameText(_Val,'password') then
    Result := TOpenMasterdataApiClient.TGrantType.omdgt_Password
  else
    Result := _Default;
end;

procedure TOpenMasterdataApiClient.SetBySupplierPIDURL(
  const _URL : String);
var
  lUrl : TURI;
begin
  lUrl := TURI.Create(_URL);
  FBySupplierPIDUrl := lUrl.Path;
  FRESTClientBySupplierPID.BaseURL := BuildRestBaseUrl(lUrl);
  FRESTClientBySupplierPID.Accept  := 'application/json';
  FRESTClientBySupplierPID.AcceptCharSet := 'UTF-8';
  FRESTClientBySupplierPID.ContentType   := 'application/json';
  FRESTClientBySupplierPID.HandleRedirects := true;
end;

procedure TOpenMasterdataApiClient.SetByManufacturerDataURL(const _URL: String);
var
  lUrl : TURI;
begin
  lUrl := TURI.Create(_URL);
  FByManufacturerDataUrl := lUrl.Path;
  FRESTClientByManufacturerData.BaseURL := BuildRestBaseUrl(lUrl);
  FRESTClientByManufacturerData.Accept := 'application/json';
  FRESTClientByManufacturerData.AcceptCharSet := 'UTF-8';
  FRESTClientByManufacturerData.ContentType := 'application/json';
  FRESTClientByManufacturerData.HandleRedirects := true;
end;

procedure TOpenMasterdataApiClient.SetByGTINURL(const _URL: String);
var
  lUrl : TURI;
begin
  lUrl := TURI.Create(_URL);
  FByGTINUrl := lUrl.Path;
  FRESTClientByGTIN.BaseURL := BuildRestBaseUrl(lUrl);
  FRESTClientByGTIN.Accept := 'application/json';
  FRESTClientByGTIN.AcceptCharSet := 'UTF-8';
  FRESTClientByGTIN.ContentType := 'application/json';
  FRESTClientByGTIN.HandleRedirects := true;
end;

procedure TOpenMasterdataApiClient.SetOAuthURL(const _URL : String);
var
  lUrl : TURI;
begin
  lUrl := TURI.Create(_URL);
  FOAuthUrl := lUrl.Path;
  if lUrl.Query <> '' then
    FOAuthUrl := FOAuthUrl + '?' + lUrl.Query;
  FRESTClientOAuth.BaseURL := BuildRestBaseUrl(lUrl);
end;

initialization

  openConnections := nil;
  openConnectionsCS := nil;
  openConnectionsInitLock := TObject.Create;

finalization

  if Assigned(openConnectionsInitLock) then begin openConnectionsInitLock.Free; openConnectionsInitLock := nil; end;
  if Assigned(openConnectionsCS) then begin openConnectionsCS.Free; openConnectionsCS := nil; end;
  if Assigned(openConnections) then begin openConnections.Free; openConnections := nil; end;

end.
