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

unit OpenMasterdataUnit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils,System.IniFiles,
  System.Variants, System.Classes, System.UITypes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, REST.Types, REST.Client, System.JSON, REST.Json,
  MVCFramework.Serializer.Defaults,
  MVCFramework.Serializer.Commons,
  Winapi.WebView2, Winapi.ActiveX, Vcl.Edge,
  intf.OpenMasterdata,intf.OpenMasterdata.Types,intf.OpenMasterdata.View,
  Vcl.CheckLst
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
    procedure btBySupplierPidClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ComboBox1Select(Sender: TObject);
  public
    Configuration : TMemIniFile;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

procedure TMainForm.FormCreate(Sender: TObject);
var
  configurationFilename : String;
begin
  if (Pos('Samples\Win32',Application.ExeName)>0) or (Pos('Samples\Win64',Application.ExeName)>0) then
    configurationFilename := ExtractFilePath(ExtractFileDir(ExtractFileDir(Application.ExeName)))
  else
    configurationFilename := ExtractFilePath(Application.ExeName);

  configurationFilename := configurationFilename + 'configuration.ini';

  Configuration := TMemIniFile.Create(configurationFilename);

  //Inhaltsaufbau einer Ini-Section je Lieferant
  //[Lieferant-Name]
  //Username=
  //Password=
  //Customernumber=
  //ClientID=
  //ClientSecret=
  //UsernameRequired=
  //CustomernumberRequired=
  //ClientSecretRequired=
  //OAuthURL=
  //BySupplierPIDURL=
  //ByManufacturerDataURL=
  //ByGTINURL=
  //ArtNoAsCommatext=

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
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  if Assigned(Configuration) then begin Configuration.Free; Configuration := nil; end;
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
  Memo2.Lines.Add(Configuration.ReadString(ComboBox1.Text,'UsernameRequired',''));
  Memo2.Lines.Add(Configuration.ReadString(ComboBox1.Text,'CustomernumberRequired',''));
  Memo2.Lines.Add(Configuration.ReadString(ComboBox1.Text,'ClientSecretRequired',''));
  Memo2.Lines.Add(Configuration.ReadString(ComboBox1.Text,'OAuthURL',''));
  Memo2.Lines.Add(Configuration.ReadString(ComboBox1.Text,'BySupplierPIDURL',''));
  Memo2.Lines.Add(Configuration.ReadString(ComboBox1.Text,'ByManufacturerDataURL',''));
  Memo2.Lines.Add(Configuration.ReadString(ComboBox1.Text,'ByGTINURL',''));
end;

procedure TMainForm.btBySupplierPidClick(Sender: TObject);
var
  client : IOpenMasterdataApiClient;
  supplierPid : TOpenMasterdataAPI_Result;
  json,html : String;
  dataPackages : TOpenMasterdataAPI_DataPackages;

  function FormatJSON(json: String): String;
  var
    tmpJson: System.JSON.TJSONValue;
  begin
    tmpJson := System.JSON.TJSONObject.ParseJSONValue(json);
    Result := Rest.Json.TJson.Format(tmpJson);
    FreeAndNil(tmpJson);
  end;

begin
  Memo1.Clear;

  if ComboBox1.ItemIndex < 0 then
    exit;
  if ListBox1.ItemIndex < 0 then
    exit;

  if not TOpenMasterdataApiClient.GetOpenMasterdataConnection(ComboBox1.Text,client) then
  begin
    client := TOpenMasterdataApiClient.NewOpenMasterdataConnection(ComboBox1.Text,
               Configuration.ReadString(ComboBox1.Text,'Username',''),
               Configuration.ReadString(ComboBox1.Text,'Password',''),
               Configuration.ReadString(ComboBox1.Text,'Customernumber',''),
               Configuration.ReadString(ComboBox1.Text,'ClientID',''),
               Configuration.ReadString(ComboBox1.Text,'ClientSecret',''));
    client.SetOAuthURL(Configuration.ReadString(ComboBox1.Text,'OAuthURL',''));
    client.SetBySupplierPIDURL(Configuration.ReadString(ComboBox1.Text,'BySupplierPIDURL',''));
  end;

  dataPackages := [];
  for var i : TOpenMasterdataAPI_DataPackage := Low(TOpenMasterdataAPI_DataPackage) to High(TOpenMasterdataAPI_DataPackage) do
  if CheckListBox1.Checked[Integer(i)] then
    dataPackages := dataPackages + [i];

  if client.GetBySupplierPid(ListBox1.Items[ListBox1.ItemIndex],dataPackages,supplierPid) then
  try
    json := GetDefaultSerializer.SerializeObject(supplierPid);
    Memo1.Lines.Text := FormatJSON(json);

    html := TOpenMasterdataAPI_ViewHelper.AsHtml(supplierPid);

    EdgeBrowser1.NavigateToString(html);

    EdgeBrowser1.Navigate('www.google.de');
  finally
    supplierPid.Free;
  end else
  begin
    MessageDlg(client.GetLastErrorMessage, mtError, [mbOK], 0);
    Memo1.Lines.Text := client.GetLastBySupplierPIDResponseContent;
  end;
end;

end.
