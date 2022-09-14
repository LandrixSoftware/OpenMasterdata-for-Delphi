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

type
  IOpenMasterdataApiClient = interface
    ['{425FC785-64D4-4A17-A012-49F60448EBF8}']

    function GetBySupplierPid(_SupplierPid : String; _DataPackages : TOpenMasterdataAPI_DataPackages; out _Result: TOpenMasterdataAPI_Result) : Boolean;

    procedure SetOAuthURL(const _URL : String);
    procedure SetBySupplierPIDURL(const _URL : String);

    function GetConnectionName : String;
    function GetLastOAuthResponseContent : String;
    function GetLastBySupplierPIDResponseContent : String;
    function GetLastErrorMessage : String;
  end;

  TOpenMasterdataApiClient = class(TInterfacedObject,IOpenMasterdataApiClient)
  private type
    TOpenMasterdataApiClientGrantType = (omdgt_Password,omdgt_ClientCredentials);
  private
    FCS : TCriticalSection;
    FUsername,
    FPassword,
    FCustomerNumber,
    FClientID,
    FClientSecret,
    FConnectionName : String;

    FGrantType : TOpenMasterdataApiClientGrantType;

    FAccessToken : String;
    FRefreshToken : String;
    FAccessTokenValidTo : TDateTime;

    FRESTClientOAuth: TRESTClient;
    FRESTClientBySupplierPID: TRESTClient;

    FLastOAuthResponseContent : String;
    FLastBySupplierPIDResponseContent : String;
    FLastErrorMessage : String;

    function LoggedIn: Boolean;
    function Login : Boolean;
    function RefreshLogin : Boolean;
  public
    constructor Create(_ConnectionName, _Username, _Password, _CustomerNumber, _ClientID, _ClientSecret : String); overload;
    destructor Destroy; override;
  public
    function GetConnectionName : String;
    function GetLastOAuthResponseContent : String;
    function GetLastBySupplierPIDResponseContent : String;
    function GetLastErrorMessage : String;

    procedure SetOAuthURL(const _URL : String);
    procedure SetBySupplierPIDURL(const _URL : String);

    function GetBySupplierPid(_SupplierPid : String; _DataPackages : TOpenMasterdataAPI_DataPackages; out _Result: TOpenMasterdataAPI_Result) : Boolean;
  public
    class function GetOpenMasterdataConnection(_ConnectionName : String; out _Connection : IOpenMasterdataApiClient) : Boolean;
    class function NewOpenMasterdataConnection(_ConnectionName, _Username, _Password, _CustomerNumber,_ClientID, _ClientSecret : String) : IOpenMasterdataApiClient;
  end;

implementation

var
  openConnections : TInterfaceList;

{ TOpenMasterdataApiClient }

class function TOpenMasterdataApiClient.GetOpenMasterdataConnection(
  _ConnectionName: String;
  out _Connection: IOpenMasterdataApiClient): Boolean;
var
  i : Integer;
begin
  Result := false;

  if openConnections = nil then
    openConnections := TInterfaceList.Create;

  for i := 0 to openConnections.Count-1 do
  if SameText(_ConnectionName,IOpenMasterdataApiClient(openConnections[i]).GetConnectionName) then
  begin
    _Connection := IOpenMasterdataApiClient(openConnections[i]);
    Result := true;
    break;
  end;
end;

class function TOpenMasterdataApiClient.NewOpenMasterdataConnection(
  _ConnectionName, _Username, _Password, _CustomerNumber, _ClientID,
  _ClientSecret: String): IOpenMasterdataApiClient;
begin
  if openConnections = nil then
    openConnections := TInterfaceList.Create;

  if GetOpenMasterdataConnection(_ConnectionName,Result) then
    exit;

  Result := TOpenMasterdataApiClient.Create(_ConnectionName,_Username, _Password,
                  _CustomerNumber,_ClientID,_ClientSecret);
  openConnections.Add(Result);
end;

constructor TOpenMasterdataApiClient.Create(_ConnectionName, _Username,
  _Password, _CustomerNumber, _ClientID, _ClientSecret: String);
begin
  FConnectionName := _ConnectionName;
  FUsername := _Username;
  FPassword := _Password;
  FCustomerNumber := _CustomerNumber;
  FClientID := _ClientID;
  FClientSecret := _ClientSecret;
  if not FClientSecret.IsEmpty then
    FGrantType := TOpenMasterdataApiClient.TOpenMasterdataApiClientGrantType.omdgt_ClientCredentials
  else
    FGrantType := TOpenMasterdataApiClient.TOpenMasterdataApiClientGrantType.omdgt_Password;
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
  //minimalResult : TOpenMasterdataAPI_CoreResult;

  itm : TOpenMasterdataAPI_AuthResult;
begin
  //https://github.com/paolo-rossi/delphi-neon
  Result := false;

  FLastOAuthResponseContent := '';
  FLastErrorMessage := '';

  FAccessToken := '';
  FRefreshToken := '';

  //TOAuth2Authenticator?

  RESTResponse := TRESTResponse.Create(nil);
  RESTRequest := TRESTRequest.Create(nil);
  try
    RESTResponse.Name := 'RESTResponse';
    RESTRequest.Name := 'RESTRequest';
    RESTRequest.AssignedValues := [TCustomRESTRequest.TAssignedValue.rvConnectTimeout, TCustomRESTRequest.TAssignedValue.rvReadTimeout];
    RESTRequest.Client := FRESTClientOAuth;
    RESTRequest.Method := rmPOST;
    case FGrantType of
      omdgt_Password:          RESTRequest.Params.AddItem('grant_type','password');
      omdgt_ClientCredentials:
      begin
        RESTRequest.Params.AddItem('grant_type','client_credentials');
        RESTRequest.Params.AddItem('client_secret',FClientSecret);
      end;
    end;
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
      FLastErrorMessage := RESTResponse.StatusText;
      exit;
    end;

    FLastOAuthResponseContent := RESTResponse.Content;

//   minimalResult := TOpenMasterdataAPI_CoreResult.Create;
//    try
//    try
//      GetDefaultSerializer.DeserializeObject(RESTResponse.Content, minimalResult);
//      if not minimalResult.success then
//      begin
//        FLastErrorMessage := minimalResult.message_;
//        exit;
//      end;
//    except
//      on E:Exception do
//      begin
//        FLastErrorMessage := E.ClassName+' '+e.Message;
//        exit;
//      end;
//    end;
//    finally
//      minimalResult.Free;
//    end;

    itm := TOpenMasterdataAPI_AuthResult.Create;
    FAccessTokenValidTo := now;
    try
    try
      GetDefaultSerializer.DeserializeObject(RESTResponse.Content, itm);

      if itm.access_token.IsEmpty then
        exit;

      FAccessToken := itm.access_token;
      FRefreshToken := itm.refresh_token;
      FAccessTokenValidTo := IncSecond(FAccessTokenValidTo,itm.expires_in-30);

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
  //minimalResult : TOpenMasterdataAPI_CoreResult;

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
    RESTRequest.Params.AddItem('client_id',FClientID);
    RESTRequest.Params.AddItem('refresh_token',FRefreshToken);
    RESTRequest.Response := RESTResponse;

    RESTRequest.Execute;

    if not RESTResponse.Status.SuccessOK_200 then
    begin
      FLastErrorMessage := RESTResponse.StatusText;
      exit;
    end;

    FLastOAuthResponseContent := RESTResponse.Content;

//    minimalResult := TOpenMasterdataAPI_CoreResult.Create;
//    try
//    try
//      GetDefaultSerializer.DeserializeObject(RESTResponse.Content, minimalResult);
//      if not minimalResult.success then
//      begin
//        FLastErrorMessage := minimalResult.message_;
//        exit;
//      end;
//    except
//      on E:Exception do
//      begin
//        FLastErrorMessage := E.ClassName+' '+e.Message;
//        exit;
//      end;
//    end;
//    finally
//      minimalResult.Free;
//    end;

    itm := TOpenMasterdataAPI_AuthResult.Create;
    FAccessTokenValidTo := now;
    try
    try
      GetDefaultSerializer.DeserializeObject(RESTResponse.Content, itm);

      if itm.access_token.IsEmpty or itm.refresh_token.IsEmpty then
        exit;

      FAccessToken := itm.access_token;
      FRefreshToken := itm.refresh_token;
      FAccessTokenValidTo := IncSecond(FAccessTokenValidTo,itm.expires_in-30);

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
  out _Result: TOpenMasterdataAPI_Result): Boolean;
var
  RESTResponse: TRESTResponse;
  RESTRequest: TRESTRequest;
  //minimalResult : TOpenMasterdataAPI_CoreResult;
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

    _Result := TOpenMasterdataAPI_Result.Create;
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

function TOpenMasterdataApiClient.GetConnectionName: String;
begin
  Result := FConnectionName;
end;

procedure TOpenMasterdataApiClient.SetBySupplierPIDURL(
  const _URL : String);
begin
  FRESTClientBySupplierPID.BaseURL := _URL;
end;

procedure TOpenMasterdataApiClient.SetOAuthURL(const _URL : String);
begin
  FRESTClientOAuth.BaseURL := _URL;
end;

initialization

  openConnections := nil;

finalization

  if Assigned(openConnections) then begin openConnections.Free; openConnections := nil; end;

end.
