unit intf.OpenMasterdata;

interface

uses
  System.SysUtils,System.Classes,System.Contnrs,System.Variants,System.DateUtils
  ,System.Generics.Collections,System.Generics.Defaults,System.SyncObjs
  ,Vcl.StdCtrls,System.JSON,REST.Json,REST.JsonReflect, REST.Types, REST.Client,
  MVCFramework.Serializer.Defaults,
  MVCFramework.Serializer.Commons,
  intf.OpenMasterdata.Types
  ;

  //https://docwiki.embarcadero.com/RADStudio/Alexandria/de/REST-Clientbibliothek
  //https://www.clevercomponents.com/portal/kb/a135/how-to-write-a-rest-client-with-json-in-delphi.aspx

type
//  TOpenMasterdataApiClient = class;
//
//  IOpenMasterdataApiClientResource_Auth = interface(IInvokable)
//    ['{D139CD79-CFE5-49E3-8CFB-27686621311B}']
//
//    [RESTResource(TMVCHTTPMethodType.httpGET, '{baseUrlOAuth}')]
//    function Login([Param('username')] _Username: String; [Param('password')] _Password: String; [Param('customernumber')] _CustomerNumber: String): TOpenMasterdataAPI_AuthResult;
//
//    //https://portal.mainmetall.de/oauth/login?grant_type=password&client_id=landrixsoftware&username=info@landrix.de&password=rxPKo9rRSUgjQHJSXsX4
//
//    function RefreshLogin: TOpenMasterdataAPI_AuthResult;
//  end;
//
//  TOpenMasterdataApiClient_Auth = record
//  private
//    clientRef : TOpenMasterdataApiClient;
//    RESTAdapter: TRESTAdapter<IOpenMasterdataApiClientResource_Auth>;
//    AppResource: IOpenMasterdataApiClientResource_Auth;
//  public
//    constructor Create(_Client: TOpenMasterdataApiClient);
//  public
//    function Login(out _AccessToken : String; out _RefreshToken : String) : Boolean;
//    function RefreshLogin(_RefreshToken : String; out _AccessToken : String; out _NewRefreshToken : String) : Boolean;
//  end;

  TOpenMasterdataApiClient = class(TObject)
  private
    FCS : TCriticalSection;
    FUsername,
    FPassword,
    FCustomerNumber,
    FOAuthURL, FBySupplierPIDURL : String;

    FAccessToken : String;
    FRefreshToken : String;
    FAccessTokenValidTo : TDateTime;

    FRESTClientOAuth: TRESTClient;
    FRESTClientBySupplierPID: TRESTClient;

    FLastOAuthResponseContent : String;
    FLastBySupplierPIDResponseContent : String;
    FLastErrorMessage : String;

    procedure CheckResultBody(const _Body : String);
    procedure SetBySupplierPIDURL(const Value: String);
    procedure SetOAuthURL(const Value: String);
    function LoggedIn: Boolean;
    function Login : Boolean;
    function RefreshLogin : Boolean;
  public
    constructor Create(_Username, _Password, _CustomerNumber : String);
    destructor Destroy; override;
  public
    function GetLastOAuthResponseContent : String;
    function GetLastBySupplierPIDResponseContent : String;
    function GetLastErrorMessage : String;

    function GetBySupplierPid(_SupplierPid : String; _DataPackages : TOpenMasterdataAPI_DataPackages; out _Result: TOpenMasterdataAPI_BySupplierPIDResult) : Boolean;
  public
    property OAuthURL : String read FOAuthURL write SetOAuthURL;
    property BySupplierPIDURL : String read FBySupplierPIDURL write SetBySupplierPIDURL;
  end;

implementation

{$I intf.OpenMasterdata.inc}

{ TOpenMasterdataApiClient }

constructor TOpenMasterdataApiClient.Create(_Username, _Password, _CustomerNumber : String);
begin
  FUsername := _Username;
  FPassword := _Password;
  FCustomerNumber := _CustomerNumber;
  FCS := TCriticalSection.Create;

  FRESTClientOAuth:= TRESTClient.Create(nil);
  FRESTClientOAuth.Name := 'RESTClientOAuth';
  FRESTClientBySupplierPID:= TRESTClient.Create(nil);
  FRESTClientBySupplierPID.Name := 'RESTClientBySupplierPID';

  FLastOAuthResponseContent := '';
  FLastBySupplierPIDResponseContent := '';
  FLastErrorMessage := '';

  FAccessToken := '';
  FRefreshToken := '';
  FAccessTokenValidTo := 0;
end;

destructor TOpenMasterdataApiClient.Destroy;
begin
  if Assigned(FRESTClientOAuth) then begin FRESTClientOAuth.Free; FRESTClientOAuth := nil; end;
  if Assigned(FRESTClientBySupplierPID) then begin FRESTClientBySupplierPID.Free; FRESTClientBySupplierPID := nil; end;
  if Assigned(FCS) then begin FCS.Free; FCS := nil; end;
  inherited;
end;

function TOpenMasterdataApiClient.GetLastBySupplierPIDResponseContent: String;
begin
  Result := FLastBySupplierPIDResponseContent;
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
    Result := RefreshLogin;
end;

function TOpenMasterdataApiClient.Login: Boolean;
var
  RESTResponse: TRESTResponse;
  RESTRequest: TRESTRequest;
  minimalResult : TOpenMasterdataAPI_Result;

  jValue:TJSONValue;
  hstr : String;
  itm : TOpenMasterdataAPI_AuthResult;
begin
  //https://github.com/paolo-rossi/delphi-neon
  Result := false;

  FLastOAuthResponseContent := '';
  FLastErrorMessage := '';

  FAccessToken := '';
  FRefreshToken := '';

  RESTResponse := TRESTResponse.Create(nil);
  RESTRequest := TRESTRequest.Create(nil);
  try
    RESTResponse.Name := 'RESTResponse';
    RESTRequest.Name := 'RESTRequest';
    RESTRequest.AssignedValues := [TCustomRESTRequest.TAssignedValue.rvConnectTimeout, TCustomRESTRequest.TAssignedValue.rvReadTimeout];
    RESTRequest.Client := FRESTClientOAuth;
    RESTRequest.Params.AddItem('grant_type','password');
    RESTRequest.Params.AddItem('client_id',OPENMASTERDATA_CLIENT_ID);
    RESTRequest.Params.AddItem('username',FUsername);
    RESTRequest.Params.AddItem('password',FPassword);
    if FCustomerNumber <> '' then
      RESTRequest.Params.AddItem('customernumber',FCustomerNumber);
    RESTRequest.Response := RESTResponse;

    RESTRequest.Execute;

    if not RESTResponse.Status.SuccessOK_200 then
    begin
      FLastErrorMessage := RESTResponse.StatusText;
      exit;
    end;

    FLastOAuthResponseContent := RESTResponse.Content;

    minimalResult := TOpenMasterdataAPI_Result.Create;
    try
    try
      GetDefaultSerializer.DeserializeObject(RESTResponse.Content, minimalResult);
      if not minimalResult.success then
      begin
        FLastErrorMessage := minimalResult.message_;
        exit;
      end;
    except
      on E:Exception do
      begin
        FLastErrorMessage := E.ClassName+' '+e.Message;
        exit;
      end;
    end;
    finally
      minimalResult.Free;
    end;

    itm := TOpenMasterdataAPI_AuthResult.Create;
    FAccessTokenValidTo := now;
    try
    try
      GetDefaultSerializer.DeserializeObject(RESTResponse.Content, itm);

      if itm.access_token.IsEmpty or itm.refresh_token.IsEmpty then
        exit;

      FAccessToken := itm.access_token;
      FRefreshToken := itm.refresh_token;
      IncSecond(FAccessTokenValidTo,itm.expires_in-30);

      Result := true;
    except
      on E:Exception do
      begin
        FLastErrorMessage := E.ClassName+' '+e.Message;
        exit;
      end;
    end;
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
  minimalResult : TOpenMasterdataAPI_Result;

  jValue:TJSONValue;
  hstr : String;
  itm : TOpenMasterdataAPI_AuthResult;
begin
  //https://github.com/paolo-rossi/delphi-neon
  Result := false;

  FLastOAuthResponseContent := '';
  FLastErrorMessage := '';

  FAccessToken := '';
  if FRefreshToken.IsEmpty then
    exit;

  RESTResponse := TRESTResponse.Create(nil);
  RESTRequest := TRESTRequest.Create(nil);
  try
    RESTResponse.Name := 'RESTResponse';
    RESTRequest.Name := 'RESTRequest';
    RESTRequest.AssignedValues := [TCustomRESTRequest.TAssignedValue.rvConnectTimeout, TCustomRESTRequest.TAssignedValue.rvReadTimeout];
    RESTRequest.Client := FRESTClientOAuth;
    RESTRequest.Params.AddItem('grant_type','refresh_token');
    RESTRequest.Params.AddItem('client_id',OPENMASTERDATA_CLIENT_ID);
    RESTRequest.Params.AddItem('refresh_token',FRefreshToken);
    RESTRequest.Response := RESTResponse;

    RESTRequest.Execute;

    if not RESTResponse.Status.SuccessOK_200 then
    begin
      FLastErrorMessage := RESTResponse.StatusText;
      exit;
    end;

    FLastOAuthResponseContent := RESTResponse.Content;

    minimalResult := TOpenMasterdataAPI_Result.Create;
    try
    try
      GetDefaultSerializer.DeserializeObject(RESTResponse.Content, minimalResult);
      if not minimalResult.success then
      begin
        FLastErrorMessage := minimalResult.message_;
        exit;
      end;
    except
      on E:Exception do
      begin
        FLastErrorMessage := E.ClassName+' '+e.Message;
        exit;
      end;
    end;
    finally
      minimalResult.Free;
    end;

    itm := TOpenMasterdataAPI_AuthResult.Create;
    FAccessTokenValidTo := now;
    try
    try
      GetDefaultSerializer.DeserializeObject(RESTResponse.Content, itm);

      if itm.access_token.IsEmpty or itm.refresh_token.IsEmpty then
        exit;

      FAccessToken := itm.access_token;
      FRefreshToken := itm.refresh_token;
      IncSecond(FAccessTokenValidTo,itm.expires_in-30);

      Result := true;
    except
      on E:Exception do
      begin
        FLastErrorMessage := E.ClassName+' '+e.Message;
        exit;
      end;
    end;
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
  out _Result: TOpenMasterdataAPI_BySupplierPIDResult): Boolean;
var
  RESTResponse: TRESTResponse;
  RESTRequest: TRESTRequest;
  minimalResult : TOpenMasterdataAPI_Result;
  jValue:TJSONValue;
  hstr : String;
begin
  Result := false;

  FCS.Acquire;
  try

  if not LoggedIn then
    exit;

  FLastBySupplierPIDResponseContent := '';
  FLastErrorMessage := '';

  if _SupplierPid.IsEmpty then
    exit;
  if _DataPackages = [] then
    exit;

  RESTResponse := TRESTResponse.Create(nil);
  RESTRequest := TRESTRequest.Create(nil);
  try
    RESTResponse.Name := 'RESTResponse';
    RESTRequest.Name := 'RESTRequest';
    RESTRequest.AssignedValues := [TCustomRESTRequest.TAssignedValue.rvConnectTimeout, TCustomRESTRequest.TAssignedValue.rvReadTimeout];
    RESTRequest.Client := FRESTClientBySupplierPID;
    RESTRequest.AddAuthParameter('Authorization','Bearer ' + FAccessToken,pkHTTPHEADER, [poDoNotEncode]);
    RESTRequest.Params.AddItem('supplierPid',_SupplierPid);
    RESTRequest.Params.AddItem('datapackage',TOpenMasterdataAPI_DataPackageHelper.DataPackagesAsString(_DataPackages));
    RESTRequest.Response := RESTResponse;

    RESTRequest.Execute;

    if not RESTResponse.Status.SuccessOK_200 then
    begin
      FLastErrorMessage := RESTResponse.StatusText;
      exit;
    end;

    FLastBySupplierPIDResponseContent := RESTResponse.Content;

    minimalResult := TOpenMasterdataAPI_Result.Create;
    try
    try
      GetDefaultSerializer.DeserializeObject(RESTResponse.Content, minimalResult);
      if not minimalResult.success then
      begin
        FLastErrorMessage := minimalResult.message_;
        exit;
      end;
    except
      on E:Exception do
      begin
        FLastErrorMessage := E.ClassName+' '+e.Message;
        exit;
      end;
    end;
    finally
      minimalResult.Free;
    end;

    _Result := TOpenMasterdataAPI_BySupplierPIDResult.Create;
    try
      GetDefaultSerializer.DeserializeObject(RESTResponse.Content, _Result);
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

procedure TOpenMasterdataApiClient.SetBySupplierPIDURL(
  const Value: String);
begin
  FBySupplierPIDURL := Value;
  FRESTClientBySupplierPID.BaseURL := Value;
end;

procedure TOpenMasterdataApiClient.SetOAuthURL(const Value: String);
begin
  FOAuthURL := Value;
  FRESTClientOAuth.BaseURL := Value;
end;

//procedure TLandrixApiClient.AnalyticsAddItem(_Item: TLandrixApiAnalytics);
//var
//  lResp: IMVCRESTResponse;
//begin
//  //FAppResource.AnalyticsAddItem(_Item);
//
//  FCS.Acquire;
//  try
//  lResp := FRESTClient
//// .SetBasicAuthorization('dmvc', '123')
//    .AddBody(GetDefaultSerializer.SerializeObject(_Item),TMVCMediaType.APPLICATION_JSON)
//    //.AddBodyFieldURLEncoded('field2', 'João Antônio')
//    //.AddBodyFieldURLEncoded('field3', 'Special characters: öüáàçãõºs')
//    .Put('/analytics/'+_Item.uuid);
//  finally
//    FCS.Release;
//  end;
//
//  //Assert.AreEqual(lResp.StatusCode, 200);
//end;
//
//function TLandrixApiClient.AnalyticsGetItemsByNotAlreadyProcessed(
//  out _Items: TObjectList<TLandrixApiAnalytics>): Boolean;
//var
//  lBody: string;
//  res : IMVCRESTResponse;
//begin
//  Result := false;
//
//  FCS.Acquire;
//  try
//  try
//    res := FRESTClient
//      .AddQueryStringParam('alreadyprocessed','0')
//      .Get('/analytics');
//  //  FRESTClient.SetBasicAuthorization('dmvc', '123');
//
//    if not res.Success then
//      raise Exception.Create(res.Content);
//
//    lBody := res.Content;
//
//    CheckResultBody(lBody);
//
//    // Objects
//    _Items := TObjectList<TLandrixApiAnalytics>.Create(True);
//    GetDefaultSerializer.DeserializeCollection(lBody, _Items, TLandrixApiAnalytics); // BodyAsJSONArray.AsObjectList<TAppUser>;
//    Result := true;
//  except
//    on E:Exception do begin ShowException(E,nil) end;
//  end;
//  finally
//    FCS.Release;
//  end;
//end;
//
//function TLandrixApiClient.AnalyticsGetItemsByProjectUUID(
//  const _ProjectUUID : String; out _Items: TObjectList<TLandrixApiAnalytics>): Boolean;
//var
//  lBody: string;
//  res : IMVCRESTResponse;
//begin
//  Result := false;
//  if _ProjectUUID = '' then
//    exit;
//
//  FCS.Acquire;
//  try
//  try
//    res := FRESTClient
//      .AddQueryStringParam('projectuuid',_ProjectUUID)
//      .Get('/analytics');
//  //  FRESTClient.SetBasicAuthorization('dmvc', '123');
//
//    if not res.Success then
//      raise Exception.Create(res.Content);
//
//    lBody := res.Content;
//
//    CheckResultBody(lBody);
//
//    // Objects
//    _Items := TObjectList<TLandrixApiAnalytics>.Create(True);
//    GetDefaultSerializer.DeserializeCollection(lBody, _Items, TLandrixApiAnalytics); // BodyAsJSONArray.AsObjectList<TAppUser>;
//    Result := true;
//  except
//    on E:Exception do begin ShowException(E,nil) end;
//  end;
//  finally
//    FCS.Release;
//  end;
//end;
//
procedure TOpenMasterdataApiClient.CheckResultBody(const _Body: String);
begin
  if Pos('ESQLite',_Body) > 0 then
    raise Exception.Create(_Body);
  if Pos('<html>',_Body) > 0 then
    raise Exception.Create(_Body);
end;

//function TLandrixApiClient.SettingPlainGetItem(const _SettingUUID,
//  _UserUUID: String; out _Item: TLandrixApiSettingPlain): Boolean;
//var
//  lBody : String;
//  res : IMVCRESTResponse;
//begin
//  Result := false;
//  if _SettingUUID = '' then
//    exit;
//  if _UserUUID = '' then
//    exit;
//
//  FCS.Acquire;
//  try
//  try
//    res := FRESTClient
//      .Get('/settings/plain/'+_SettingUUID+'/'+_UserUUID);
//  //  FRESTClient.SetBasicAuthorization('dmvc', '123');
//
//    if not res.Success then
//      raise Exception.Create(res.Content);
//
//    lBody := res.Content;
//
//    CheckResultBody(lBody);
//
//    // Objects
//    _Item := TLandrixApiSettingPlain.Create;
//    GetDefaultSerializer.DeserializeCollection(lBody, _Item, TLandrixApiSettingPlain); // BodyAsJSONArray.AsObjectList<TAppUser>;
//    Result := true;
//  except
//    on E:Exception do begin ShowException(E,nil) end;
//  end;
//  finally
//    FCS.Release;
//  end;
//end;
//
//function TLandrixApiClient.EvaluationDeleteEvaluationHalfFinishedOrder(
//  const _ProjectUUID, _Uuid: String): Boolean;
//var
//  res : IMVCRESTResponse;
//begin
//  Result := false;
//  if _ProjectUUID = '' then
//    exit;
//  if _Uuid = '' then
//    exit;
//
//  FCS.Acquire;
//  try
//  try
//    res := FRESTClient
//      .Delete('/projects/'+_ProjectUUID+'/evaluation/halffinishedorders/'+_Uuid);
//  //  FRESTClient.SetBasicAuthorization('dmvc', '123');
//
//    if not res.Success then
//      raise Exception.Create(res.Content);
//
//    CheckResultBody(res.Content);
//
//    Result := true;
//  except
//    on E:Exception do begin ShowException(E,nil) end;
//  end;
//  finally
//    FCS.Release;
//  end;
//end;
//
//function TLandrixApiClient.EvaluationGetEvaluationHalfFinishedOrders(
//  const _ProjectUUID: String;
//  out _Items: TObjectList<TLandrixApiProjectHalffinishedOrder>): Boolean;
//var
//  lBody: string;
//  res : IMVCRESTResponse;
//begin
//  Result := false;
//  if _ProjectUUID = '' then
//    exit;
//
//  FCS.Acquire;
//  try
//  try
//    res := FRESTClient
//      .Get('/projects/'+_ProjectUUID+'/evaluation/halffinishedorders');
//  //  FRESTClient.SetBasicAuthorization('dmvc', '123');
//
//    if not res.Success then
//      raise Exception.Create(res.Content);
//
//    lBody := res.Content;
//
//    CheckResultBody(lBody);
//
//    // Objects
//    _Items := TObjectList<TLandrixApiProjectHalffinishedOrder>.Create(True);
//    GetDefaultSerializer.DeserializeCollection(lBody, _Items, TLandrixApiProjectHalffinishedOrder); // BodyAsJSONArray.AsObjectList<TAppUser>;
//    Result := true;
//  except
//    on E:Exception do begin ShowException(E,nil) end;
//  end;
//  finally
//    FCS.Release;
//  end;
//end;
//
//function TLandrixApiClient.EvaluationSetEvaluationHalfFinishedOrder(
//  _Item: TLandrixApiProjectHalffinishedOrder): Boolean;
//var
//  res : IMVCRESTResponse;
//begin
//  Result := false;
//
//  FCS.Acquire;
//  try
//  try
//    res := FRESTClient
//      .AddBody(GetDefaultSerializer.SerializeObject(_Item),TMVCMediaType.APPLICATION_JSON)
//      .Put('/projects/'+_Item.projectUuid+'/evaluation/halffinishedorders/'+_Item.uuid);
//  //  FRESTClient.SetBasicAuthorization('dmvc', '123');
//
//    if not res.Success then
//      raise Exception.Create(res.Content);
//
//    CheckResultBody(res.Content);
//
//    Result := true;
//  except
//    on E:Exception do begin ShowException(E,nil) end;
//  end;
//  finally
//    FCS.Release;
//  end;
//end;

//{ TOpenMasterdataApiClient_Auth }
//
//constructor TOpenMasterdataApiClient_Auth.Create(
//  _Client: TOpenMasterdataApiClient);
//begin
//  clientRef := _Client;
//  RESTAdapter := TRESTAdapter<IOpenMasterdataApiClientResource_Auth>.Create;
//  RESTAdapter.Build(_Client.FRESTClient);
//  AppResource := RESTAdapter.ResourcesService;
//end;
//
//function TOpenMasterdataApiClient_Auth.Login(out _AccessToken,
//  _RefreshToken: String): Boolean;
//var
//  itm : TOpenMasterdataAPI_AuthResult;
//begin
//  Result := false;
//  clientRef.FCS.Acquire;
//  try
//  try
//    itm := AppResource.Login(clientRef.FUsername,clientRef.FPassword,clientRef.FCustomerNumber);
//    if not itm.success then
//      exit;
//    _AccessToken := itm.access_token;
//    _RefreshToken := itm.refresh_token;
//    Result := true;
//  except
//    on E:Exception do begin ShowException(E,nil) end;
//  end;
//  finally
//    clientRef.FCS.Release;
//  end;
//end;
//
//function TOpenMasterdataApiClient_Auth.RefreshLogin(_RefreshToken: String;
//  out _AccessToken, _NewRefreshToken: String): Boolean;
//begin
//
//end;

end.
