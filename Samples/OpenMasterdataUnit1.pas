{
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

unit OpenMasterdataUnit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils,System.IniFiles,
  System.Variants, System.Classes, System.UITypes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, System.IOUtils,
  Vcl.StdCtrls, REST.Types, REST.Client, System.JSON, REST.Json,
  Winapi.WebView2, Winapi.ActiveX, Vcl.Edge,Vcl.CheckLst,
  intf.OpenMasterdata,intf.OpenMasterdata.Types,intf.OpenMasterdata.View
  ;

type
  TMainForm = class(TForm)
    btBySupplierPid: TButton;
    Memo1: TMemo;
    Label1: TLabel;
    ComboBox1: TComboBox;
    Label2: TLabel;
    Label3: TLabel;
    Memo2: TMemo;
    ListBox1: TListBox;
    EdgeBrowser1: TEdgeBrowser;
    Label4: TLabel;
    CheckListBox1: TCheckListBox;
    ListBox2: TListBox;
    Button1: TButton;
    procedure btBySupplierPidClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ComboBox1Select(Sender: TObject);
    procedure EdgeBrowser1WebResourceRequested(Sender: TCustomEdgeBrowser;
      Args: TWebResourceRequestedEventArgs);
    procedure Button1Click(Sender: TObject);
  public
    Configuration : TMemIniFile;
    CurrentAuthorizationToken : String;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

procedure TMainForm.FormCreate(Sender: TObject);
var
  basePath,configurationFilename : String;
begin
  if (Pos('Samples\Win32',Application.ExeName)>0) or (Pos('Samples\Win64',Application.ExeName)>0) then
    basePath := ExtractFilePath(ExtractFileDir(ExtractFileDir(Application.ExeName)))
  else
    basePath := ExtractFilePath(Application.ExeName);

  basePath := ExcludeTrailingPathDelimiter(basePath);
  basePath := ExtractFilePath(basePath);

  configurationFilename := basePath + 'Samples\configuration.ini';

  Configuration := TMemIniFile.Create(configurationFilename,TEncoding.UTF8);

  //Inhaltsaufbau configuration.ini, eine Ini-Section je Lieferant
  //[Lieferant-Name]
  //Username=
  //Password=
  //Customernumber=
  //ClientID=
  //ClientSecret=
  //ClientScope=openMasterdata
  //GrantType=password or client_credentials
  //UsernameRequired=True or False
  //CustomernumberRequired=True or False
  //ClientSecretRequired=True or False
  //OAuthURL=
  //BySupplierPIDURL=
  //ByManufacturerDataURL=
  //ByGTINURL=
  //ArtNoAsCommatext=123,456

  Configuration.ReadSections(ComboBox1.Items);

  if ComboBox1.Items.Count>0 then
  begin
    ComboBox1.ItemIndex := 0;
    ComboBox1.OnSelect(nil);
  end;

  Left := 50;
  Top := 50;
  Width := Screen.WorkAreaWidth-100;
  Height := Screen.WorkAreaHeight-100;

  CheckListBox1.Items.Add(TOpenMasterdataAPI_DataPackageHelper.DataPackageAsString(omd_datapackage_basic));
  CheckListBox1.Items.Add(TOpenMasterdataAPI_DataPackageHelper.DataPackageAsString(omd_datapackage_additional));
  CheckListBox1.Items.Add(TOpenMasterdataAPI_DataPackageHelper.DataPackageAsString(omd_datapackage_prices));
  CheckListBox1.Items.Add(TOpenMasterdataAPI_DataPackageHelper.DataPackageAsString(omd_datapackage_descriptions));
  CheckListBox1.Items.Add(TOpenMasterdataAPI_DataPackageHelper.DataPackageAsString(omd_datapackage_logistics));
  CheckListBox1.Items.Add(TOpenMasterdataAPI_DataPackageHelper.DataPackageAsString(omd_datapackage_sparepartlists));
  CheckListBox1.Items.Add(TOpenMasterdataAPI_DataPackageHelper.DataPackageAsString(omd_datapackage_pictures));
  CheckListBox1.Items.Add(TOpenMasterdataAPI_DataPackageHelper.DataPackageAsString(omd_datapackage_documents));
  for var i : Integer := 0 to CheckListBox1.Items.Count-1 do
    CheckListBox1.Checked[i] := true;

  EdgeBrowser1.UserDataFolder := ExtractFilePath(Application.ExeName);
  EdgeBrowser1.Navigate('about:blank');

  var _Result : TOpenMasterdataAPI_Result;

  if FileExists(basePath+'Documentation\OpenMasterdata 1.1.0\sample.json') then
  begin
    _Result := TOpenMasterdataAPI_Result.Create;
    try
    try
      _Result.LoadFromJson(TFile.ReadAllText(basePath+'Documentation\OpenMasterdata 1.1.0\sample.json'));
    except
      on E:Exception do
      begin
        //FLastErrorMessage := E.ClassName+' '+e.Message;
        exit;
      end;
    end;
    finally
      _Result.Free;
    end;
  end;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  if Assigned(Configuration) then begin Configuration.Free; Configuration := nil; end;
end;

procedure TMainForm.Button1Click(Sender: TObject);
var
  client : IOpenMasterdataApiClient;
  data : TStream;
begin
  if ListBox2.ItemIndex < 0 then
    exit;

  if not TOpenMasterdataApiClient.GetOpenMasterdataConnection(ComboBox1.Text,client) then
  begin
    var gt : TOpenMasterdataApiClient.TGrantType := TOpenMasterdataApiClient.GetGrantTypeFromString(Configuration.ReadString(ComboBox1.Text,'GrantType',''));

    client := TOpenMasterdataApiClient.NewOpenMasterdataConnection(ComboBox1.Text,
               Configuration.ReadString(ComboBox1.Text,'Username',''),
               Configuration.ReadString(ComboBox1.Text,'Password',''),
               Configuration.ReadString(ComboBox1.Text,'Customernumber',''),
               Configuration.ReadString(ComboBox1.Text,'ClientID',''),
               Configuration.ReadString(ComboBox1.Text,'ClientSecret',''),
               Configuration.ReadString(ComboBox1.Text,'ClientScope',''),gt);
    client.SetOAuthURL(Configuration.ReadString(ComboBox1.Text,'OAuthURL',''));
    client.SetBySupplierPIDURL(Configuration.ReadString(ComboBox1.Text,'BySupplierPIDURL',''));
  end;

  if client.GetData(ListBox2.Items[ListBox2.ItemIndex],data) then
  try
    if data is TMemoryStream then
    begin
      var lFilename : String := ListBox2.Items[ListBox2.ItemIndex];
      if lFilename.EndsWith('.pdf',true) then
        lFilename := 'test.pdf'
      else
      if lFilename.EndsWith('.jpg',true) then
        lFilename := 'test.jpg'
      else
        lFilename := 'test.unknown';
      TMemoryStream(data).SaveToFile(ExtractFilePath(Application.ExeName)+lFilename);
    end;
  finally
    data.Free;
  end else
  begin
    MessageDlg(client.GetLastErrorMessage, mtError, [mbOK], 0);
  end;
end;

procedure TMainForm.ComboBox1Select(Sender: TObject);
begin
  ListBox1.Items.CommaText := Configuration.ReadString(ComboBox1.Text,'ArtNoAsCommatext','');
  if ListBox1.Items.Count > 0 then
    ListBox1.ItemIndex := 0;
  Memo2.Clear;
  Memo2.Lines.Add(Configuration.ReadString(ComboBox1.Text,'Username',''));
  Memo2.Lines.Add(Configuration.ReadString(ComboBox1.Text,'Password',''));
  Memo2.Lines.Add(Configuration.ReadString(ComboBox1.Text,'Customernumber',''));
  Memo2.Lines.Add(Configuration.ReadString(ComboBox1.Text,'ClientID',''));
  Memo2.Lines.Add(Configuration.ReadString(ComboBox1.Text,'ClientSecret',''));
  Memo2.Lines.Add(Configuration.ReadString(ComboBox1.Text,'ClientScope',''));
  Memo2.Lines.Add(Configuration.ReadString(ComboBox1.Text,'GrantType',''));
  Memo2.Lines.Add(Configuration.ReadString(ComboBox1.Text,'UsernameRequired',''));
  Memo2.Lines.Add(Configuration.ReadString(ComboBox1.Text,'CustomernumberRequired',''));
  Memo2.Lines.Add(Configuration.ReadString(ComboBox1.Text,'ClientSecretRequired',''));
  Memo2.Lines.Add(Configuration.ReadString(ComboBox1.Text,'OAuthURL',''));
  Memo2.Lines.Add(Configuration.ReadString(ComboBox1.Text,'BySupplierPIDURL',''));
  Memo2.Lines.Add(Configuration.ReadString(ComboBox1.Text,'ByManufacturerDataURL',''));
  Memo2.Lines.Add(Configuration.ReadString(ComboBox1.Text,'ByGTINURL',''));
end;

procedure TMainForm.EdgeBrowser1WebResourceRequested(Sender: TCustomEdgeBrowser;
  Args: TWebResourceRequestedEventArgs);
var
  request: ICoreWebView2WebResourceRequest;
//  requestURI, responseHeaders, method: PWideChar;
//  response: ICoreWebView2WebResourceResponse;
//  requestFilename, localFilename, payload: string;
  headers: ICoreWebView2HttpRequestHeaders;
//    requestStringStream : IStream;
//    core:ICoreWebView2;
//    sett:ICoreWebView2Settings;
begin
  if CurrentAuthorizationToken = '' then
    exit;
  Args.ArgsInterface.Get_Request(request);
  //request.Get_uri(requestURI);
  request.Get_Headers(headers);
  headers.SetHeader('Authorization',PChar('Bearer '+CurrentAuthorizationToken));

  //headers.SetHeader('User-Agent', PChar('TestBrowserDownload v' + GetVersion));
  //headers.SetHeader('Content-Type', PChar('application/x-www-form-urlencoded'));
  //request.Set_Method('POST');
  //payload := 'a=textusw';
  //  requestStringStream := TStreamAdapter.Create(TStringStream.Create(payload, TEncoding.UTF8), soOwned);
  //  request.Set_Content(requestStringStream);
  //  //Versuch IStream für den Dateitransfer zur Verfügung zu stellen...
  //  Args.ArgsInterface.Get_Response(response);
  //  requestFileStream := TStreamAdapter.Create(TFileStream.Create(extractfilepath(paramstr(0)) + 'test.dat', fmCreate or fmOpenReadWrite or fmShareDenyNone), soOwned);
  //  response.Set_Content(requestFileStream);
end;

procedure TMainForm.btBySupplierPidClick(Sender: TObject);
var
  client : IOpenMasterdataApiClient;
  supplierPid : TOpenMasterdataAPI_Result;
  html : String;
  dataPackages : TOpenMasterdataAPI_DataPackages;
  i : Integer;

  function FormatJSON(json: String): String;
  var
    tmpJson: System.JSON.TJSONValue;
  begin
    tmpJson := System.JSON.TJSONObject.ParseJSONValue(
      TOpenMasterdataHelper.FixJson(json),false,true);
    if tmpJson <> nil then
    begin
      Result := Rest.Json.TJson.Format(tmpJson);
      FreeAndNil(tmpJson);
    end else
      Result := json;
  end;

begin
  Memo1.Clear;
  CurrentAuthorizationToken := '';
  ListBox2.Clear;

  if ComboBox1.ItemIndex < 0 then
    exit;
  if ListBox1.ItemIndex < 0 then
    exit;

  if not TOpenMasterdataApiClient.GetOpenMasterdataConnection(ComboBox1.Text,client) then
  begin
    var gt : TOpenMasterdataApiClient.TGrantType := TOpenMasterdataApiClient.GetGrantTypeFromString(Configuration.ReadString(ComboBox1.Text,'GrantType',''));

    client := TOpenMasterdataApiClient.NewOpenMasterdataConnection(ComboBox1.Text,
               Configuration.ReadString(ComboBox1.Text,'Username',''),
               Configuration.ReadString(ComboBox1.Text,'Password',''),
               Configuration.ReadString(ComboBox1.Text,'Customernumber',''),
               Configuration.ReadString(ComboBox1.Text,'ClientID',''),
               Configuration.ReadString(ComboBox1.Text,'ClientSecret',''),
               Configuration.ReadString(ComboBox1.Text,'ClientScope',''),gt);
    client.SetOAuthURL(Configuration.ReadString(ComboBox1.Text,'OAuthURL',''));
    client.SetBySupplierPIDURL(Configuration.ReadString(ComboBox1.Text,'BySupplierPIDURL',''));
  end;

  dataPackages := [];
  for var iDataPackage : TOpenMasterdataAPI_DataPackage := Low(TOpenMasterdataAPI_DataPackage) to High(TOpenMasterdataAPI_DataPackage) do
  if CheckListBox1.Checked[Integer(iDataPackage)] then
    dataPackages := dataPackages + [iDataPackage];

  if client.GetBySupplierPid(ListBox1.Items[ListBox1.ItemIndex],dataPackages,supplierPid) then
  try
    Memo1.Lines.Text := FormatJSON(client.GetLastBySupplierPIDResponseContent);

    html := TOpenMasterdataAPI_ViewHelper.AsHtml(supplierPid);
    CurrentAuthorizationToken := client.GetCurrentAuthorizationToken;

    EdgeBrowser1.AddWebResourceRequestedFilter('*', COREWEBVIEW2_WEB_RESOURCE_CONTEXT_ALL);
    EdgeBrowser1.NavigateToString(html);

    for i := 0 to supplierPid.pictures.Count-1 do
    begin
      ListBox2.Items.Add(supplierPid.pictures[i].url);
    end;
    for i := 0 to supplierPid.documents.Count-1 do
    begin
      ListBox2.Items.Add(supplierPid.documents[i].url);
    end;

  finally
    supplierPid.Free;
  end else
  begin
    MessageDlg(client.GetLastErrorMessage, mtError, [mbOK], 0);
    Memo1.Lines.Text := client.GetLastBySupplierPIDResponseContent;
  end;
end;

end.
