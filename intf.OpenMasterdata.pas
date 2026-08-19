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
  System.SysUtils,System.Classes,System.Contnrs,System.Variants,System.DateUtils,System.StrUtils
  ,System.Generics.Collections,System.Generics.Defaults,System.SyncObjs
  ,System.NetEncoding,System.Net.HttpClient,System.Net.URLClient
  ,System.JSON,REST.Json,REST.JsonReflect, REST.Types, REST.Client
  ,intf.OpenMasterdata.Types
  ;

const
  //Sonderstatus der Open-Masterdata-Spec 9.0.0. Zu 950 und 951 liefert der
  //Server trotz Fehlerstatus ein vollstaendiges Produkt.
  COpenMasterdataStatusAlternativeProduct = 950; //Artikel nicht verfuegbar, Alternativartikel im Body
  COpenMasterdataStatusSuccessorProduct   = 951; //Artikel nicht verfuegbar, Nachfolgeartikel im Body
  COpenMasterdataStatusAmbiguous          = 952; //mehr als ein Treffer
  COpenMasterdataStatusInactive           = 960; //Artikel nicht mehr aktiv

  //Obergrenzen fuer SetRetryPolicy. Sie halten die Wartezeitberechnung im
  //gueltigen Zahlenbereich und verhindern absurd lange Blockaden.
  CMaxRetryLimit = 10;
  CMaxRetryDelayLimitSeconds = 300;

type
  //Auf Unit-Ebene deklariert, damit sie schon im Interface verwendbar sind.
  //TOpenMasterdataApiClient fuehrt sie als TGrantType bzw.
  //TDataPackagesSendMode weiter, bestehender Code bleibt gueltig.
  //Auswahl eines Produktendpunkts fuer den gesperrten Zugriff auf sein Feld
  TEndpointKind = (epBySupplierPid,epByManufacturerData,epByGTIN);

  TOpenMasterdataGrantType = (omdgt_Password,omdgt_ClientCredentials);
  TOpenMasterdataDataPackagesSendMode = (omddpsm_PipeDelimited,omddpsm_Exploded);

  IOpenMasterdataApiClient = interface
    ['{425FC785-64D4-4A17-A012-49F60448EBF8}']

    function GetBySupplierPid(_SupplierPid : String; _DataPackages : TOpenMasterdataAPI_DataPackages; out _Result: TOpenMasterdataAPI_Result) : Boolean;
    function GetByManufacturerData(_ManufacturerId, _ManufacturerIdType, _ManufacturerPid : String; _DataPackages : TOpenMasterdataAPI_DataPackages; out _Result: TOpenMasterdataAPI_Result) : Boolean;
    function GetByGTIN(_GTIN : String; _DataPackages : TOpenMasterdataAPI_DataPackages; out _Result: TOpenMasterdataAPI_Result) : Boolean;

    procedure SetOAuthURL(const _URL : String);
    procedure SetBySupplierPIDURL(const _URL : String);
    procedure SetByManufacturerDataURL(const _URL : String);
    procedure SetByGTINURL(const _URL : String);
    //Optionaler Query-Parameter der Spec 9.0.0. Gilt ein Zugang fuer mehrere
    //Kunden, waehlt customerId den Kunden aus, fuer den die Preise gelten.
    procedure SetCustomerId(const _CustomerId : String);
    //Aktualisiert die Zugangsdaten einer bestehenden Verbindung. Ein bereits
    //erhaltener Token wird dabei verworfen.
    procedure SetCredentials(const _Username, _Password, _CustomerNumber, _ClientID,
      _ClientSecret, _ClientScope : String; _GrantType : TOpenMasterdataGrantType;
      _DataPackagesSendMode : TOpenMasterdataDataPackagesSendMode);
    //Steuert das Wiederholen ueberlasteter Anfragen (429, 502, 503, 504).
    //_MaxRetries = 0 schaltet Wiederholungen ab.
    //_MaxDelaySeconds begrenzt die Wartezeit je Versuch. Nennt der Server im
    //Header Retry-After eine laengere Zeit, wird nicht gewartet, sondern der
    //Fehler gemeldet, damit die Anwendung nicht scheinbar haengt.
    procedure SetRetryPolicy(_MaxRetries, _MaxDelaySeconds : Integer);

    function GetData(_Url : String; out _Result : TStream) : Boolean;

    function GetConnectionName : String;
    //Achtung: die folgenden beiden Funktionen dienen der Fehlersuche. Die
    //OAuth-Antwort enthaelt das Zugriffs- und das Refresh-Token im Klartext.
    //Ihr Ergebnis gehoert nicht unveraendert in ein Protokoll.
    function GetCurrentAuthorizationToken : String;
    function GetLastOAuthResponseContent : String;
    function GetLastBySupplierPIDResponseContent : String;
    function GetLastErrorMessage : String;
    function GetLastErrorCode : Integer;
  end;

  TOpenMasterdataApiClient = class(TInterfacedObject,IOpenMasterdataApiClient)
  public type
    TGrantType = TOpenMasterdataGrantType;
    TDataPackagesSendMode = TOpenMasterdataDataPackagesSendMode;
  private
    FCS : TCriticalSection;
    FUsername,
    FPassword,
    FCustomerNumber,
    FCustomerId,
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

    FMaxRetries : Integer;
    FMaxRetryDelaySeconds : Integer;
    //Wird bei jeder Konfigurationsaenderung erhoeht. Ein Wiederholungsversuch
    //bricht ab, wenn sich die Konfiguration waehrend der Wartezeit geaendert
    //hat, denn der vorbereitete Request zeigt dann auf den alten Endpunkt.
    FConfigGeneration : Integer;

    function LoggedIn: Boolean;
    function Login : Boolean;
    function RefreshLogin : Boolean;
    function CalculateTokenValidTo(_ExpiresInSeconds : Integer) : TDateTime;

    //Fuehrt den Request aus und wiederholt ihn bei Ueberlast-Status.
    //Liefert false, wenn der Aufruf mit einer Exception endete.
    function ExecuteWithRetry(_Request : TRESTRequest; _Response : TRESTResponse) : Boolean;
    function TrySplitEndpointUrl(const _URL : String; out _Resource, _BaseUrl : String) : Boolean;
    //Liest die Adresse eines Endpunkts unter der Sperre. Der Endpunkt wird
    //ueber das Enum ausgewaehlt und nicht als const-String uebergeben: bei
    //const erhoeht Delphi den Referenzzaehler nicht, und der Zeiger waere
    //bereits vor dem Acquire geladen.
    function ReadEndpointUrl(_Endpoint : TEndpointKind) : String;
    function SleepWithoutLock(_Milliseconds : Integer) : Boolean;
    procedure SetupProductRestClient(_RestClient : TRESTClient; const _BaseUrl : String);
    class function StatusCodeToMessage(_StatusCode : Integer; const _StatusText : String) : String; static;
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
    procedure SetCustomerId(const _CustomerId : String);
    procedure SetCredentials(const _Username, _Password, _CustomerNumber, _ClientID,
      _ClientSecret, _ClientScope : String; _GrantType : TGrantType;
      _DataPackagesSendMode : TDataPackagesSendMode);
    procedure SetRetryPolicy(_MaxRetries, _MaxDelaySeconds : Integer);
    //Beschreibt, warum eine OAuth-Antwort keinen Token enthaelt. Oeffentlich,
    //damit die Meldung ohne Server geprueft werden kann.
    class function DescribeOAuthFailure(const _Content : String) : String;
    //Entscheidet, ob ein Status wiederholt wird und wie lange vorher zu warten
    //ist. Als reine Funktion ausgelegt, damit sie sich testen laesst.
    class function TryGetRetryDelay(_StatusCode, _Attempt, _MaxRetries, _MaxDelaySeconds : Integer;
      const _RetryAfterHeader : String; out _DelayMilliseconds : Integer) : Boolean; static;
    //Begrenzt die Werte einer Wiederholungsstrategie auf den zulaessigen
    //Bereich. Als reine Funktion ausgelegt, damit sie sich testen laesst.
    class procedure ClampRetryPolicy(var _MaxRetries, _MaxDelaySeconds : Integer); static;
    //Prueft, ob eine Adresse denselben Ursprung hat wie der angegebene
    //Endpunkt, also Schema, Host und Port uebereinstimmen. Ein Praefixvergleich
    //reicht dafuer nicht: zu "https://api.example" passt sonst auch
    //"https://api.example.angreifer.tld". Wird von Anwendungen gebraucht, die
    //den Zugriffstoken nur an den API-Host senden duerfen.
    class function IsSameOrigin(const _RequestUri, _Scheme, _Host : String;
      _Port : Integer) : Boolean; static;

    function GetBySupplierPid(_SupplierPid : String; _DataPackages : TOpenMasterdataAPI_DataPackages; out _Result: TOpenMasterdataAPI_Result) : Boolean;
    function GetByManufacturerData(_ManufacturerId, _ManufacturerIdType, _ManufacturerPid : String; _DataPackages : TOpenMasterdataAPI_DataPackages; out _Result: TOpenMasterdataAPI_Result) : Boolean;
    function GetByGTIN(_GTIN : String; _DataPackages : TOpenMasterdataAPI_DataPackages; out _Result: TOpenMasterdataAPI_Result) : Boolean;
  public
    function GetData(_Url : String; out _Result : TStream) : Boolean;
  public
    class function GetOpenMasterdataConnection(_ConnectionName : String; out _Connection : IOpenMasterdataApiClient) : Boolean;
    class function NewOpenMasterdataConnection(_ConnectionName, _Username, _Password, _CustomerNumber,_ClientID, _ClientSecret, _ClientScope : String; _GrantType : TGrantType; _DataPackagesSendMode : TDataPackagesSendMode) : IOpenMasterdataApiClient;
    //Entfernt eine Verbindung aus der Verwaltung. Danach gibt der naechste
    //Aufruf von NewOpenMasterdataConnection eine frische Instanz zurueck.
    class function RemoveOpenMasterdataConnection(_ConnectionName : String) : Boolean;
    class function GetGrantTypeFromString(const _Val : String; _Default : TGrantType = TGrantType.omdgt_Password) : TGrantType;
    class function GetDataPackagesSendModeFromString(const _Val : String; _Default : TDataPackagesSendMode = TDataPackagesSendMode.omddpsm_PipeDelimited) : TDataPackagesSendMode;
  end;

implementation

var
  openConnections : TInterfaceList;
  openConnectionsCS : TCriticalSection;
  openConnectionsInitLock : TObject;

//Macht eine Servermeldung protokolltauglich: eine Zeile, keine Steuerzeichen.
//Ein #0 schneidet die Zeile bei vielen Lesern ab, mit ESC lassen sich ueber
//Terminalsequenzen fremde Protokolleintraege vortaeuschen.
function NormalizeSingleLine(const _Value : String) : String;
var
  builder : TStringBuilder;
  i : Integer;
begin
  builder := TStringBuilder.Create;
  try
    for i := 1 to Length(_Value) do
      if _Value[i] < #32 then
        builder.Append(' ')
      else
        builder.Append(_Value[i]);
    Result := builder.ToString;
  finally
    builder.Free;
  end;
  while Pos('  ',Result) > 0 do
    Result := StringReplace(Result,'  ',' ',[rfReplaceAll]);
  Result := Trim(Result);
end;

//Kuerzt einen Text auf ein fuer eine Fehlermeldung vertraegliches Mass.
function ShortenForMessage(const _Value : String; _MaxLength : Integer = 240) : String;
begin
  Result := _Value;
  if Length(Result) > _MaxLength then
    Result := Copy(Result,1,_MaxLength) + '...';
end;

function LooksLikeHtml(const _Content : String) : Boolean;
var
  trimmedContent : String;
begin
  trimmedContent := TrimLeft(_Content);
  Result := (trimmedContent <> '') and (trimmedContent[1] = '<');
end;

function StripHtmlTags(const _Value : String) : String;
var
  inTag : Boolean;
  i : Integer;
  builder : TStringBuilder;
begin
  builder := TStringBuilder.Create;
  try
    inTag := false;
    for i := 1 to Length(_Value) do
    begin
      case _Value[i] of
        '<' : inTag := true;
        '>' : inTag := false;
      else
        if not inTag then
          builder.Append(_Value[i]);
      end;
    end;
    Result := NormalizeSingleLine(builder.ToString);
  finally
    builder.Free;
  end;
end;

//Bereitet einen Antwortkoerper fuer eine Fehlermeldung auf. Markup wird nur
//entfernt, wenn die Antwort wirklich HTML ist. Sonst wuerde ein einzelnes <
//in einer Meldung wie {"hint":"value < 10 required"} den gesamten Rest
//verschlucken, also genau die Beschreibung, derentwegen der Koerper
//ueberhaupt angehaengt wird.
function ResponsePreview(const _Content : String) : String;
begin
  if LooksLikeHtml(_Content) then
    Result := StripHtmlTags(_Content)
  else
    Result := NormalizeSingleLine(_Content);
  Result := ShortenForMessage(Result);
end;

//Erkennt Antworten, die ein Geheimnis enthalten koennen. Eine Token-Antwort
//fuehrt Zugriffs- und Refresh-Token im Klartext; manche Server spiegeln auch
//den Authorization-Header. Solche Koerper duerfen nicht in eine Meldung
//geraten, die protokolliert oder an den Anwender weitergereicht wird.
function MayContainSecret(const _Content : String) : Boolean;
const
  CSecretMarkers : array[0..5] of String =
    ('access_token','refresh_token','id_token','client_secret','authorization','password');
var
  marker : String;
begin
  Result := false;
  for marker in CSecretMarkers do
    if ContainsText(_Content,marker) then
      exit(true);
end;

//Wie ResponsePreview, unterdrueckt aber Koerper, die ein Geheimnis enthalten
//koennen. Die Laengenangabe genuegt zur Einordnung; den vollstaendigen Text
//liefert GetLastOAuthResponseContent, das ausdruecklich als heikel
//gekennzeichnet ist.
function SafeResponsePreview(const _Content : String) : String;
begin
  if MayContainSecret(_Content) then
    Result := '['+IntToStr(Length(_Content))+
              ' Zeichen, wegen moeglicher Zugangsdaten nicht ausgegeben]'
  else
    Result := ResponsePreview(_Content);
end;

//Nennt die Feldnamen einer JSON-Antwort, aber keinen einzigen Wert. Damit
//laesst sich erkennen, wie der Server geantwortet hat, ohne ein Token
//preiszugeben.
function JsonFieldNames(_Object : TJSONObject) : String;
var
  pair : TJSONPair;
begin
  Result := '';
  for pair in _Object do
  begin
    if Result <> '' then
      Result := Result+', ';
    Result := Result+pair.JsonString.Value;
  end;
  if Result = '' then
    Result := 'keine';
end;

//Ein Token-Endpunkt kann mit gueltigem JSON antworten und trotzdem keinen
//Token liefern. RFC 6749 Abschnitt 5.2 sieht dafuer error und
//error_description vor. Deren Text nennt den Grund und ist fuer die
//Fehlersuche weit brauchbarer als der Hinweis, die Antwort sei kein JSON.
//Der Antwortkoerper nennt oft den eigentlichen Grund, etwa welches Feld der
//Server nicht schreiben konnte. Ohne ihn bleibt nur der nackte Statuscode.
function AppendResponseDetail(const _Message,_Content : String) : String;
var
  detail : String;
begin
  Result := _Message;
  detail := SafeResponsePreview(_Content);
  if detail = '' then
    exit;
  //Nicht wiederholen, was schon in der Meldung steht
  if Pos(detail,_Message) > 0 then
    exit;
  Result := Trim(_Message+' '+detail);
end;

function OAuthJsonErrorMessage(const _Content : String) : String;
var
  trimmedContent,errorCode,errorDescr : String;
  jsonValue : TJSONValue;
  jsonString : TJSONString;
begin
  trimmedContent := Trim(_Content);
  if trimmedContent = '' then
    exit('OAuth response is empty.');

  if trimmedContent[1] = '<' then
    exit('OAuth response is HTML instead of JSON: ' + SafeResponsePreview(trimmedContent));

  try
    jsonValue := TJSONObject.ParseJSONValue(trimmedContent);
  except
    //Eine unlesbare Antwort wird unten als solche gemeldet
    jsonValue := nil;
  end;

  if jsonValue <> nil then
  try
    if jsonValue is TJSONObject then
    begin
      errorCode := '';
      errorDescr := '';
      if TJSONObject(jsonValue).TryGetValue<TJSONString>('error',jsonString) then
        errorCode := jsonString.Value;
      if TJSONObject(jsonValue).TryGetValue<TJSONString>('error_description',jsonString) then
        errorDescr := jsonString.Value;

      if (errorCode <> '') or (errorDescr <> '') then
      begin
        Result := 'OAuth server reported an error';
        if errorCode <> '' then
          Result := Result + ' (' + errorCode + ')';
        if errorDescr <> '' then
          //Auch dieser Text kommt vom Server und kann beliebig lang sein
          Result := Result + ': ' + ShortenForMessage(NormalizeSingleLine(errorDescr));
        exit;
      end;

      //Gueltiges JSON, aber ohne Token und ohne Fehlerfeld. Ausgegeben werden
      //nur die Feldnamen: der Koerper fuehrt in diesem Fall haeufig ein
      //Refresh-Token, das nicht in eine Meldung gehoert.
      exit('OAuth response contains no access_token. Felder: ' +
           JsonFieldNames(TJSONObject(jsonValue)));
    end;
  finally
    jsonValue.Free;
  end;

  Result := 'OAuth response is not valid JSON: ' + SafeResponsePreview(trimmedContent);
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
  //TURI setzt bei fehlender Portangabe den Standardport des Schemas ein.
  //Diesen wieder anzuhaengen ist ueberfluessig und stoert Gegenstellen mit
  //strikter Pruefung des Host-Headers.
  if (_Url.Port > 0) and
     not (SameText(_Url.Scheme,'https') and (_Url.Port = 443)) and
     not (SameText(_Url.Scheme,'http') and (_Url.Port = 80)) then
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
      //Eine bestehende Verbindung wird weiterverwendet, die uebergebenen
      //Zugangsdaten duerfen dabei aber nicht verlorengehen
      Result.SetCredentials(_Username,_Password,_CustomerNumber,_ClientID,
        _ClientSecret,_ClientScope,_GrantType,_DataPackagesSendMode);
      exit;
    end;

    Result := TOpenMasterdataApiClient.Create(_ConnectionName,_Username, _Password,
                 _CustomerNumber,_ClientID,_ClientSecret,_ClientScope,_GrantType,_DataPackagesSendMode);
    openConnections.Add(Result);
  finally
    openConnectionsCS.Release;
  end;
end;

class function TOpenMasterdataApiClient.RemoveOpenMasterdataConnection(
  _ConnectionName: String): Boolean;
var
  i : Integer;
begin
  Result := false;
  EnsureOpenConnectionsInitialized;
  openConnectionsCS.Acquire;
  try
    for i := openConnections.Count-1 downto 0 do
    if SameText(_ConnectionName,
              IOpenMasterdataApiClient(openConnections[i]).GetConnectionName) then
    begin
      openConnections.Delete(i);
      Result := true;
    end;
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

  //TRESTRequest.Execute wandelt jede Antwort ab Status 500 in eine
  //ERESTException um, solange RaiseExceptionOn500 gesetzt ist. Damit waeren
  //die Sonderstatus 950 bis 960 der Open-Masterdata-Spec und die Wiederholung
  //bei 502, 503 und 504 nicht erreichbar, weil die Auswertung des Statuscodes
  //nie stattfaende. Die Antwort ist zu diesem Zeitpunkt bereits vollstaendig
  //gefuellt, der Code wertet sie selbst aus.
  FRESTClientOAuth.RaiseExceptionOn500 := false;
  FRESTClientBySupplierPID.RaiseExceptionOn500 := false;
  FRESTClientByManufacturerData.RaiseExceptionOn500 := false;
  FRESTClientByGTIN.RaiseExceptionOn500 := false;

  FLastOAuthResponseContent := '';
  FLastBySupplierPIDResponseContent := '';
  FLastErrorMessage := '';
  FLastErrorCode := 0;

  FAccessToken := '';
  FRefreshToken := '';
  FAccessTokenValidTo := 0;
  //FCookie := '';

  //Zwei Wiederholungen bei Ueberlast, dazwischen 1 und 2 Sekunden. Laengere
  //Wartezeiten aus Retry-After werden nicht abgewartet, siehe SetRetryPolicy.
  FMaxRetries := 2;
  FMaxRetryDelaySeconds := 10;
  FConfigGeneration := 0;
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
    begin
      //Schlaegt der Refresh fehl, etwa weil der Server ihn nicht unterstuetzt,
      //ist ein vollstaendiger Login der richtige Ausweg statt eines Fehlers
      Result := RefreshLogin;
      if not Result then
        Result := Login;
    end;
  end;
end;

class function TOpenMasterdataApiClient.DescribeOAuthFailure(
  const _Content: String): String;
begin
  Result := OAuthJsonErrorMessage(_Content);
end;

class function TOpenMasterdataApiClient.TryGetRetryDelay(_StatusCode, _Attempt,
  _MaxRetries, _MaxDelaySeconds: Integer; const _RetryAfterHeader: String;
  out _DelayMilliseconds: Integer): Boolean;
var
  retryAfterSeconds : Integer;
  delaySeconds : Integer;
begin
  Result := false;
  _DelayMilliseconds := 0;

  if _MaxRetries <= 0 then
    exit;
  if _Attempt >= _MaxRetries then
    exit;
  case _StatusCode of
    429, 502, 503, 504 : ;
  else
    exit;
  end;

  //Exponentiell: 1s, 2s, 4s ...
  delaySeconds := 1 shl _Attempt;

  //Retry-After gibt entweder Sekunden oder ein HTTP-Datum an. Nur die
  //Sekundenform wird ausgewertet, sie ist bei 429 die uebliche.
  retryAfterSeconds := StrToIntDef(Trim(_RetryAfterHeader),-1);
  if retryAfterSeconds >= 0 then
  begin
    //Nennt der Server eine laengere Wartezeit als zugestanden, wird nicht
    //gewartet. Ein blockierter Aufrufer waere schlimmer als ein klarer Fehler.
    if retryAfterSeconds > _MaxDelaySeconds then
      exit;
    delaySeconds := retryAfterSeconds;
  end
  else
  if delaySeconds > _MaxDelaySeconds then
    delaySeconds := _MaxDelaySeconds;

  _DelayMilliseconds := delaySeconds*1000;
  Result := true;
end;

function TOpenMasterdataApiClient.ExecuteWithRetry(_Request: TRESTRequest;
  _Response: TRESTResponse): Boolean;
var
  attempt : Integer;
  delayMilliseconds : Integer;
begin
  Result := false;
  attempt := 0;
  repeat
    try
      _Request.Execute;
    except
      on E:Exception do
      begin
        FLastErrorMessage := E.ClassName+' '+E.Message;
        exit;
      end;
    end;

    if not TryGetRetryDelay(_Response.StatusCode,attempt,FMaxRetries,FMaxRetryDelaySeconds,
                            _Response.Headers.Values['Retry-After'],delayMilliseconds) then
      break;

    if not SleepWithoutLock(delayMilliseconds) then
    begin
      FLastErrorMessage := 'Die Konfiguration hat sich waehrend der Wartezeit geaendert.';
      exit;
    end;
    Inc(attempt);
  until false;

  Result := true;
end;

procedure TOpenMasterdataApiClient.SetRetryPolicy(_MaxRetries, _MaxDelaySeconds: Integer);
begin
  FCS.Acquire;
  try
    ClampRetryPolicy(_MaxRetries,_MaxDelaySeconds);
    FMaxRetries := _MaxRetries;
    FMaxRetryDelaySeconds := _MaxDelaySeconds;
  finally
    FCS.Release;
  end;
end;

function TOpenMasterdataApiClient.CalculateTokenValidTo(_ExpiresInSeconds: Integer): TDateTime;
const
  CDefaultLifetimeSeconds = 3600; //Annahme, wenn der Server keine Laufzeit meldet
  CSafetyMarginSeconds = 30;
begin
  if _ExpiresInSeconds <= 0 then
    _ExpiresInSeconds := CDefaultLifetimeSeconds;
  //Der Sicherheitsabstand darf die Laufzeit nicht aufzehren, sonst gilt der
  //Token sofort als abgelaufen und jede Abfrage loest einen Login aus
  if _ExpiresInSeconds > CSafetyMarginSeconds*2 then
    _ExpiresInSeconds := _ExpiresInSeconds - CSafetyMarginSeconds;
  Result := IncSecond(now,_ExpiresInSeconds);
end;

function TOpenMasterdataApiClient.ReadEndpointUrl(_Endpoint: TEndpointKind): String;
begin
  FCS.Acquire;
  try
    case _Endpoint of
      epBySupplierPid:      Result := FBySupplierPIDUrl;
      epByManufacturerData: Result := FByManufacturerDataUrl;
      epByGTIN:             Result := FByGTINUrl;
    else
      Result := '';
    end;
  finally
    FCS.Release;
  end;
end;

//Wartet, ohne die Sperre zu halten, und meldet zurueck, ob die Konfiguration
//unveraendert geblieben ist. Nur dann darf der vorbereitete Request wiederholt
//werden: ein zwischenzeitlich geaenderter Endpunkt wuerde ihn sonst samt
//Zugriffstoken an eine andere Adresse senden.
function TOpenMasterdataApiClient.SleepWithoutLock(_Milliseconds: Integer): Boolean;
var
  generationBefore : Integer;
begin
  generationBefore := FConfigGeneration;
  if _Milliseconds > 0 then
  begin
    FCS.Release;
    try
      Sleep(_Milliseconds);
    finally
      FCS.Acquire;
    end;
  end;
  Result := FConfigGeneration = generationBefore;
end;

class procedure TOpenMasterdataApiClient.ClampRetryPolicy(var _MaxRetries,
  _MaxDelaySeconds: Integer);
begin
  if _MaxRetries < 0 then
    _MaxRetries := 0;
  //Obergrenze, sonst laeuft 1 shl _Attempt in der Wartezeitberechnung ueber
  if _MaxRetries > CMaxRetryLimit then
    _MaxRetries := CMaxRetryLimit;
  if _MaxDelaySeconds < 0 then
    _MaxDelaySeconds := 0;
  if _MaxDelaySeconds > CMaxRetryDelayLimitSeconds then
    _MaxDelaySeconds := CMaxRetryDelayLimitSeconds;
end;

class function TOpenMasterdataApiClient.IsSameOrigin(const _RequestUri, _Scheme,
  _Host: String; _Port: Integer): Boolean;
var
  uri : TURI;
begin
  Result := false;
  if (_Host = '') or (Trim(_RequestUri) = '') then
    exit;
  try
    uri := TURI.Create(_RequestUri);
  except
    //Formen wie data:, blob:, about:blank oder relative Pfade sind kein
    //Ursprung im Sinne dieser Pruefung
    on E:Exception do
      exit;
  end;
  Result := SameText(uri.Scheme,_Scheme) and
            SameText(uri.Host,_Host) and
            (uri.Port = _Port);
end;

class function TOpenMasterdataApiClient.StatusCodeToMessage(_StatusCode: Integer;
  const _StatusText: String): String;
begin
  case _StatusCode of
    COpenMasterdataStatusAmbiguous:
      Result := 'Die Suche liefert mehr als einen Treffer.';
    COpenMasterdataStatusInactive:
      Result := 'Der Artikel ist nicht mehr aktiv.';
    401:
      Result := 'Die Anmeldung wurde abgelehnt oder ist abgelaufen.';
    403:
      Result := 'Fuer diesen Zugang ist die Abfrage nicht freigeschaltet.';
    404:
      Result := 'Der Artikel wurde nicht gefunden.';
    429:
      Result := 'Zu viele Anfragen. Bitte spaeter erneut versuchen.';
  else
    Result := '';
  end;

  if Result = '' then
    Result := _StatusText
  else
  if _StatusText <> '' then
    Result := Result+' ('+_StatusText+')';

  if Result = '' then
    Result := 'HTTP-Status '+IntToStr(_StatusCode);
end;

function TOpenMasterdataApiClient.Login: Boolean;
var
  RESTResponse: TRESTResponse;
  RESTRequest: TRESTRequest;

  itm : TOpenMasterdataAPI_AuthResult;
  authError,loginName : String;
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

    //Zugangsdaten werden gesendet, sobald welche konfiguriert sind. Der
    //Grant-Type taugt dafuer nicht als Kriterium: die GC-Gruppe fuehrt
    //client_credentials und verlangt trotzdem username und password, sonst
    //antwortet der Server mit 400 und "make sure to supply password".
    //Verlangt der Lieferant die Kundennummer, gehoert sie mit Tabulator
    //getrennt an den Benutzernamen. Leere Felder werden nicht gesendet:
    //strikte Server weisen ein leeres password mit 400 zurueck.
    if (FUsername <> '') and (FCustomerNumber <> '') then
      loginName := FUsername+#9+FCustomerNumber
    else
    if FCustomerNumber <> '' then
      loginName := FCustomerNumber
    else
      loginName := FUsername;

    if loginName <> '' then
      RESTRequest.Params.AddItem('username',loginName);
    if FPassword <> '' then
      RESTRequest.Params.AddItem('password',FPassword);

    RESTRequest.Response := RESTResponse;

    if not ExecuteWithRetry(RESTRequest,RESTResponse) then
      exit;

    if not RESTResponse.Status.SuccessOK_200 then
    begin
      //RFC 6749 Abschnitt 5.2 laesst Fehler mit Status 400 beantworten, das ist
      //der Regelfall. Ohne diese Auswertung stuende hier der rohe Koerper samt
      //allem, was der Server hineinschreibt.
      FLastErrorMessage := Trim(RESTResponse.StatusText+' '+
                                OAuthJsonErrorMessage(RESTResponse.Content));
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
      FAccessTokenValidTo := CalculateTokenValidTo(itm.expires_in);
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
    //RFC 6749 verlangt POST am Token-Endpunkt. Ohne diese Zeile greift der
    //Standardwert rmGET und die Zugangsdaten stuenden im Query-String.
    RESTRequest.Method := rmPOST;
    RESTRequest.Accept := '*/*';
    RESTRequest.Params.AddItem('grant_type','refresh_token');
    //client_secret und scope wie beim Login mitsenden, sonst weisen
    //Confidential-Client-Endpunkte den Refresh mit invalid_client zurueck
    if not FClientSecret.IsEmpty then
      RESTRequest.Params.AddItem('client_secret',FClientSecret);
    if not FClientScope.IsEmpty then
      RESTRequest.Params.AddItem('scope',FClientScope);
    if FClientID <> '' then
      RESTRequest.Params.AddItem('client_id',FClientID);
    RESTRequest.Params.AddItem('refresh_token',FRefreshToken);
    RESTRequest.Response := RESTResponse;

    if not ExecuteWithRetry(RESTRequest,RESTResponse) then
      exit;

    if not RESTResponse.Status.SuccessOK_200 then
    begin
      //RFC 6749 Abschnitt 5.2 laesst Fehler mit Status 400 beantworten, das ist
      //der Regelfall. Ohne diese Auswertung stuende hier der rohe Koerper samt
      //allem, was der Server hineinschreibt.
      FLastErrorMessage := Trim(RESTResponse.StatusText+' '+
                                OAuthJsonErrorMessage(RESTResponse.Content));
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
      if itm.access_token.IsEmpty then
      begin
        FLastErrorMessage := 'OAuth refresh response does not contain an access token.';
        exit;
      end;

      FAccessToken := itm.access_token;
      //RFC 6749 Abschnitt 5.1: ein neues Refresh-Token ist optional.
      //Rotiert der Server nicht, bleibt das bisherige gueltig.
      if not itm.refresh_token.IsEmpty then
        FRefreshToken := itm.refresh_token;
      FAccessTokenValidTo := CalculateTokenValidTo(itm.expires_in);
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
  Result := ExecuteProductRequest(FRESTClientBySupplierPID,ReadEndpointUrl(epBySupplierPid),
    'supplierPid',_SupplierPid,_DataPackages,_Result);
end;

function TOpenMasterdataApiClient.GetByManufacturerData(_ManufacturerId,
  _ManufacturerIdType, _ManufacturerPid: String;
  _DataPackages: TOpenMasterdataAPI_DataPackages;
  out _Result: TOpenMasterdataAPI_Result): Boolean;
begin
  Result := ExecuteProductRequest(FRESTClientByManufacturerData,ReadEndpointUrl(epByManufacturerData),
    'manufacturerId',_ManufacturerId,
    'manufacturerIdType',_ManufacturerIdType,
    'manufacturerPid',_ManufacturerPid,
    _DataPackages,_Result);
end;

function TOpenMasterdataApiClient.GetByGTIN(_GTIN: String;
  _DataPackages: TOpenMasterdataAPI_DataPackages;
  out _Result: TOpenMasterdataAPI_Result): Boolean;
begin
  Result := ExecuteProductRequest(FRESTClientByGTIN,ReadEndpointUrl(epByGTIN),'gtin',_GTIN,_DataPackages,_Result);
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
  parseError : String;
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
  begin
    FLastErrorMessage := 'Fuer diese Abfrage ist keine URL konfiguriert.';
    exit;
  end;
  if ((_IdentifierName1 <> '') and _IdentifierValue1.IsEmpty) or
     ((_IdentifierName2 <> '') and _IdentifierValue2.IsEmpty) or
     ((_IdentifierName3 <> '') and _IdentifierValue3.IsEmpty) then
  begin
    FLastErrorMessage := 'Die Abfrage enthaelt kein vollstaendiges Suchkriterium.';
    exit;
  end;
  if _DataPackages = [] then
  begin
    FLastErrorMessage := 'Es wurde kein Datenpaket ausgewaehlt.';
    exit;
  end;

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
    //Optionaler Parameter der Spec 9.0.0 fuer Zugaenge, die fuer mehrere Kunden gelten
    if not FCustomerId.IsEmpty then
      RESTRequest.AddParameter('customerId',TNetEncoding.URL.Encode(FCustomerId),TRESTRequestParameterKind.pkQUERY,[TRESTRequestParameterOption.poDoNotEncode]);
    RESTRequest.Response := RESTResponse;

    if not ExecuteWithRetry(RESTRequest,RESTResponse) then
      exit;

    //Nur im Fehlerfall setzen, damit GetLastErrorCode nach einem erfolgreichen
    //Abruf 0 bleibt. Bei 950 und 951 bleibt der Code abfragbar.
    if RESTResponse.StatusCode <> 200 then
      FLastErrorCode := RESTResponse.StatusCode;

    //Ein abgelaufener oder zurueckgezogener Token muss verworfen werden,
    //sonst laufen alle weiteren Abfragen bis zum rechnerischen Ablauf in 401
    if (RESTResponse.StatusCode = 401) or (RESTResponse.StatusCode = 403) then
    begin
      FAccessToken := '';
      FAccessTokenValidTo := 0;
    end;

    //Die Spec 9.0.0 liefert zu 950 und 951 ein vollstaendiges Produkt:
    //den Alternativ- bzw. Nachfolgeartikel zum nicht verfuegbaren Artikel.
    if not (RESTResponse.Status.SuccessOK_200 or
            (RESTResponse.StatusCode = COpenMasterdataStatusAlternativeProduct) or
            (RESTResponse.StatusCode = COpenMasterdataStatusSuccessorProduct)) then
    begin
      FLastErrorMessage := AppendResponseDetail(
        StatusCodeToMessage(RESTResponse.StatusCode,RESTResponse.StatusText),
        RESTResponse.Content);
      FLastBySupplierPIDResponseContent := RESTResponse.Content;
      exit;
    end;

    FLastBySupplierPIDResponseContent := RESTResponse.Content;

    _Result := TOpenMasterdataAPI_Result.Create;
    try
      if not _Result.TryLoadFromJson(RESTResponse.Content,parseError) then
      begin
        FreeAndNil(_Result);
        FLastErrorMessage := parseError;
        exit;
      end;
      Result := true;
    except
      on E:Exception do
      begin
        FreeAndNil(_Result);
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
  //Der Token wird waehrend eines Requests unter FCS neu gesetzt
  FCS.Acquire;
  try
    Result := FAccessToken;
  finally
    FCS.Release;
  end;
end;

function TOpenMasterdataApiClient.GetData(_Url: String;
  out _Result: TStream): Boolean;
var
  lHttp : THTTPClient;
  lData : TMemoryStream;
  lHeaders : TNetHeaders;
  lResponse : IHTTPResponse;
  lAttempt : Integer;
  lDelayMilliseconds : Integer;
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
      lAttempt := 0;
      repeat
        //Bei einem Wiederholungsversuch muss der Stream wieder leer sein,
        //sonst haengt die zweite Antwort an der ersten
        lData.Clear;
        lResponse := lHttp.Get(_URL,lData,lHeaders);
        Result := lResponse.StatusCode = 200;
        //Auch nach einem zuvor gescheiterten Versuch muss der Code stimmen
        if Result then
          FLastErrorCode := 0
        else
          FLastErrorCode := lResponse.StatusCode;
        if Result then
          break;
        if not TryGetRetryDelay(lResponse.StatusCode,lAttempt,FMaxRetries,FMaxRetryDelaySeconds,
                                lResponse.HeaderValue['Retry-After'],lDelayMilliseconds) then
          break;
        if not SleepWithoutLock(lDelayMilliseconds) then
        begin
          FLastErrorMessage := 'Die Konfiguration hat sich waehrend der Wartezeit geaendert.';
          break;
        end;
        Inc(lAttempt);
      until false;

      if Result then
      begin
        _Result := lData;
        lData := nil;
      end
      else
      begin
        //Der Antwortkoerper steht hier schon im Zielpuffer des Downloads und
        //ist deshalb nicht mehr als Meldung verwertbar
        FLastErrorMessage := StatusCodeToMessage(lResponse.StatusCode,lResponse.StatusText);
        //Ein zurueckgezogener Token muss auch hier verworfen werden
        if (lResponse.StatusCode = 401) or (lResponse.StatusCode = 403) then
        begin
          FAccessToken := '';
          FAccessTokenValidTo := 0;
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

function TOpenMasterdataApiClient.TrySplitEndpointUrl(const _URL: String;
  out _Resource, _BaseUrl: String): Boolean;
var
  lUrl : TURI;
begin
  Result := false;
  _Resource := '';
  _BaseUrl := '';

  //Ein leerer Eintrag in der Konfiguration schaltet den Endpunkt ab und darf
  //keine Exception ausloesen. TURI.Create wirft bei leerem oder schemalosem Wert.
  if Trim(_URL) = '' then
    exit;
  try
    lUrl := TURI.Create(_URL);
  except
    on E:Exception do
      exit;
  end;

  _Resource := lUrl.Path;
  //Query-Parameter der konfigurierten URL muessen erhalten bleiben, etwa ein
  //Mandanten- oder Versionsparameter. Weitere Parameter haengt die REST-Klasse
  //korrekt mit & an.
  if lUrl.Query <> '' then
    _Resource := _Resource + '?' + lUrl.Query;
  _BaseUrl := BuildRestBaseUrl(lUrl);
  Result := true;
end;

procedure TOpenMasterdataApiClient.SetupProductRestClient(_RestClient : TRESTClient; const _BaseUrl : String);
begin
  _RestClient.BaseURL := _BaseUrl;
  _RestClient.Accept := 'application/json';
  _RestClient.AcceptCharSet := 'UTF-8';
  _RestClient.ContentType := 'application/json';
  _RestClient.HandleRedirects := true;
end;

//Die Setter laufen wie die Requests unter FCS, damit die Konfiguration nicht
//mitten in einer laufenden Abfrage aus einem anderen Thread wechselt.
procedure TOpenMasterdataApiClient.SetBySupplierPIDURL(
  const _URL : String);
var
  baseUrl : String;
begin
  FCS.Acquire;
  try
    if TrySplitEndpointUrl(_URL,FBySupplierPIDUrl,baseUrl) then
      SetupProductRestClient(FRESTClientBySupplierPID,baseUrl);
    Inc(FConfigGeneration);
  finally
    FCS.Release;
  end;
end;

procedure TOpenMasterdataApiClient.SetByManufacturerDataURL(const _URL: String);
var
  baseUrl : String;
begin
  FCS.Acquire;
  try
    if TrySplitEndpointUrl(_URL,FByManufacturerDataUrl,baseUrl) then
      SetupProductRestClient(FRESTClientByManufacturerData,baseUrl);
    Inc(FConfigGeneration);
  finally
    FCS.Release;
  end;
end;

procedure TOpenMasterdataApiClient.SetByGTINURL(const _URL: String);
var
  baseUrl : String;
begin
  FCS.Acquire;
  try
    if TrySplitEndpointUrl(_URL,FByGTINUrl,baseUrl) then
      SetupProductRestClient(FRESTClientByGTIN,baseUrl);
    Inc(FConfigGeneration);
  finally
    FCS.Release;
  end;
end;

procedure TOpenMasterdataApiClient.SetOAuthURL(const _URL : String);
var
  baseUrl : String;
begin
  FCS.Acquire;
  try
    if TrySplitEndpointUrl(_URL,FOAuthUrl,baseUrl) then
      FRESTClientOAuth.BaseURL := baseUrl;
    Inc(FConfigGeneration);
  finally
    FCS.Release;
  end;
end;

procedure TOpenMasterdataApiClient.SetCustomerId(const _CustomerId: String);
begin
  FCS.Acquire;
  try
    FCustomerId := _CustomerId;
    Inc(FConfigGeneration);
  finally
    FCS.Release;
  end;
end;

procedure TOpenMasterdataApiClient.SetCredentials(const _Username, _Password,
  _CustomerNumber, _ClientID, _ClientSecret, _ClientScope: String;
  _GrantType: TGrantType; _DataPackagesSendMode: TDataPackagesSendMode);
begin
  FCS.Acquire;
  try
    if (FUsername = _Username) and (FPassword = _Password) and
       (FCustomerNumber = _CustomerNumber) and (FClientID = _ClientID) and
       (FClientSecret = _ClientSecret) and (FClientScope = _ClientScope) and
       (FGrantType = _GrantType) and (FDataPackagesSendMode = _DataPackagesSendMode) then
      exit;

    FUsername := _Username;
    FPassword := _Password;
    FCustomerNumber := _CustomerNumber;
    FClientID := _ClientID;
    FClientSecret := _ClientSecret;
    FClientScope := _ClientScope;
    FGrantType := _GrantType;
    FDataPackagesSendMode := _DataPackagesSendMode;

    //Mit geaenderten Zugangsdaten ist der bisherige Token nicht mehr gueltig
    FAccessToken := '';
    FRefreshToken := '';
    FAccessTokenValidTo := 0;
    Inc(FConfigGeneration);
  finally
    FCS.Release;
  end;
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
