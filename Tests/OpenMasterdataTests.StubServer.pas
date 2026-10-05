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

//HTTP-Gegenstelle fuer die Tests des Clients.
//
//Lauscht auf 127.0.0.1 an einem freien Port und beantwortet jede Anfrage
//ueber eine Funktion, die der Test vorgibt. Damit laeuft der echte Weg durch
//TRESTClient, ExecuteWithRetry und SleepWithoutLock, ohne dass der Client
//dafuer eine Naht braucht. Die Funktion wird in den Threads des Servers
//aufgerufen, auch gleichzeitig; sie muss das selbst vertragen.

unit OpenMasterdataTests.StubServer;

interface

uses
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  System.Generics.Collections,
  IdContext,
  IdSocketHandle,
  IdCustomHTTPServer,
  IdHTTPServer;

type
  TStubRequest = record
    Method : String;
    Path : String;
    Query : String;
    Authorization : String;
    Body : String;
  end;

  TStubReply = record
    Status : Integer;
    Content : String;
    RetryAfter : String;
    class function Make(_Status : Integer; const _Content : String;
      const _RetryAfter : String = '') : TStubReply; static;
  end;

  TStubHandler = reference to function(const _Request : TStubRequest) : TStubReply;

  TStubServer = class
  private
    FServer : TIdHTTPServer;
    FLock : TCriticalSection;
    FRequests : TList<TStubRequest>;
    FHandler : TStubHandler;
    FPort : Integer;
    procedure CommandGet(AContext : TIdContext; ARequestInfo : TIdHTTPRequestInfo;
      AResponseInfo : TIdHTTPResponseInfo);
    procedure ParseAuthentication(AContext : TIdContext; const AAuthType,
      AAuthData : String; var VUsername, VPassword : String; var VHandled : Boolean);
  public
    constructor Create(_Handler : TStubHandler);
    destructor Destroy; override;
    function Url(const _Path : String) : String;
    //Anzahl der Anfragen an _Path, deren Query _QueryPart enthaelt
    function RequestCount(const _Path : String; const _QueryPart : String = '') : Integer;
    function Requests : TArray<TStubRequest>;
  end;

implementation

{ TStubReply }

class function TStubReply.Make(_Status : Integer; const _Content,
  _RetryAfter : String) : TStubReply;
begin
  Result.Status := _Status;
  Result.Content := _Content;
  Result.RetryAfter := _RetryAfter;
end;

{ TStubServer }

constructor TStubServer.Create(_Handler : TStubHandler);
var
  binding : TIdSocketHandle;
begin
  inherited Create;
  FHandler := _Handler;
  FLock := TCriticalSection.Create;
  FRequests := TList<TStubRequest>.Create;

  FServer := TIdHTTPServer.Create(nil);
  FServer.OnCommandGet := CommandGet;
  FServer.OnParseAuthentication := ParseAuthentication;
  //Port 0 laesst das Betriebssystem einen freien waehlen
  binding := FServer.Bindings.Add;
  binding.IP := '127.0.0.1';
  binding.Port := 0;
  FServer.Active := true;
  FPort := FServer.Bindings[0].Port;
end;

destructor TStubServer.Destroy;
begin
  if Assigned(FServer) then
  begin
    FServer.Active := false;
    FServer.Free;
  end;
  FRequests.Free;
  FLock.Free;
  inherited;
end;

procedure TStubServer.CommandGet(AContext : TIdContext;
  ARequestInfo : TIdHTTPRequestInfo; AResponseInfo : TIdHTTPResponseInfo);
var
  request : TStubRequest;
  reply : TStubReply;
begin
  request.Method := ARequestInfo.Command;
  request.Path := ARequestInfo.Document;
  request.Query := ARequestInfo.QueryParams;
  request.Authorization := ARequestInfo.RawHeaders.Values['Authorization'];
  request.Body := ARequestInfo.FormParams;

  FLock.Acquire;
  try
    FRequests.Add(request);
  finally
    FLock.Release;
  end;

  try
    reply := FHandler(request);
  except
    on E:Exception do
      reply := TStubReply.Make(599,E.ClassName+' '+E.Message);
  end;

  AResponseInfo.ResponseNo := reply.Status;
  AResponseInfo.ContentType := 'application/json';
  AResponseInfo.CharSet := 'utf-8';
  AResponseInfo.ContentText := reply.Content;
  if reply.RetryAfter <> '' then
    AResponseInfo.CustomHeaders.Values['Retry-After'] := reply.RetryAfter;
end;

//Indy kennt von sich aus nur Basic und beantwortet jedes andere Schema mit
//401, bevor CommandGet laeuft. Der Header wird dort roh ausgewertet.
procedure TStubServer.ParseAuthentication(AContext : TIdContext; const AAuthType,
  AAuthData : String; var VUsername, VPassword : String; var VHandled : Boolean);
begin
  VHandled := true;
end;

function TStubServer.Url(const _Path : String) : String;
begin
  Result := Format('http://127.0.0.1:%d%s',[FPort,_Path]);
end;

function TStubServer.RequestCount(const _Path, _QueryPart : String) : Integer;
var
  request : TStubRequest;
begin
  Result := 0;
  FLock.Acquire;
  try
    for request in FRequests do
      if SameText(request.Path,_Path) and
         ((_QueryPart = '') or (Pos(_QueryPart,request.Query) > 0)) then
        Inc(Result);
  finally
    FLock.Release;
  end;
end;

function TStubServer.Requests : TArray<TStubRequest>;
begin
  FLock.Acquire;
  try
    Result := FRequests.ToArray;
  finally
    FLock.Release;
  end;
end;

end.
