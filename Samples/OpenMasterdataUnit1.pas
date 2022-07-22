unit OpenMasterdataUnit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils,System.IniFiles,
  System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, REST.Types, REST.Client, System.JSON, REST.Json,
  MVCFramework.Serializer.Defaults,
  MVCFramework.Serializer.Commons,
  intf.OpenMasterdata,intf.OpenMasterdata.Types
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
  //OAuthURL=
  //BySupplierPIDURL=
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
  Memo2.Lines.Add(Configuration.ReadString(ComboBox1.Text,'OAuthURL',''));
  Memo2.Lines.Add(Configuration.ReadString(ComboBox1.Text,'BySupplierPIDURL',''));
end;

procedure TMainForm.btBySupplierPidClick(Sender: TObject);
var
  client : TOpenMasterdataApiClient;
  supplierPid : TOpenMasterdataAPI_BySupplierPIDResult;
  json : String;

  function FormatJSON(json: String): String;
  var
    tmpJson: System.JSON.TJSONValue;
  begin
    tmpJson := System.JSON.TJSONObject.ParseJSONValue(json);
    Result := Rest.Json.TJson.Format(tmpJson);
    FreeAndNil(tmpJson);
  end;

begin
  if ComboBox1.ItemIndex < 0 then
    exit;
  if ListBox1.ItemIndex < 0 then
    exit;

  client := TOpenMasterdataApiClient.Create(
               Configuration.ReadString(ComboBox1.Text,'Username',''),
               Configuration.ReadString(ComboBox1.Text,'Password',''),
               Configuration.ReadString(ComboBox1.Text,'Customernumber',''));
  client.OAuthURL := Configuration.ReadString(ComboBox1.Text,'OAuthURL','');
  client.BySupplierPIDURL := Configuration.ReadString(ComboBox1.Text,'BySupplierPIDURL','');
  try
    if client.GetBySupplierPid(ListBox1.Items[ListBox1.ItemIndex],TOpenMasterdataAPI_DataPackageHelper.ALL_DATAPACKAGES,supplierPid) then
    try
      json := GetDefaultSerializer.SerializeObject(supplierPid);
      Memo1.Lines.Text := FormatJSON(json);
    finally
      supplierPid.Free;
    end;
  finally
    client.Free;
  end;
end;

end.
