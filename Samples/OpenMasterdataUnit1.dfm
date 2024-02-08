object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'Open Masterdata v1.1.0'
  ClientHeight = 550
  ClientWidth = 782
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    782
    550)
  TextHeight = 15
  object Label1: TLabel
    Left = 8
    Top = 12
    Width = 59
    Height = 15
    Caption = 'Lieferanten'
  end
  object Label2: TLabel
    Left = 8
    Top = 48
    Width = 21
    Height = 15
    Caption = 'Info'
  end
  object Label3: TLabel
    Left = 471
    Top = 48
    Width = 105
    Height = 15
    Caption = 'Testartikelnummern'
  end
  object Label4: TLabel
    Left = 638
    Top = 48
    Width = 66
    Height = 15
    Caption = 'Datenpakete'
  end
  object btBySupplierPid: TButton
    Left = 8
    Top = 517
    Width = 101
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'By Supplier Pid'
    TabOrder = 0
    OnClick = btBySupplierPidClick
  end
  object Memo1: TMemo
    Left = 8
    Top = 224
    Width = 457
    Height = 287
    Anchors = [akLeft, akTop, akBottom]
    ScrollBars = ssBoth
    TabOrder = 1
    WordWrap = False
  end
  object ComboBox1: TComboBox
    Left = 88
    Top = 8
    Width = 679
    Height = 23
    Style = csDropDownList
    Anchors = [akLeft, akTop, akRight]
    DropDownCount = 20
    TabOrder = 2
    OnSelect = ComboBox1Select
  end
  object Memo2: TMemo
    Left = 8
    Top = 66
    Width = 457
    Height = 143
    ScrollBars = ssVertical
    TabOrder = 3
  end
  object ListBox1: TListBox
    Left = 471
    Top = 66
    Width = 161
    Height = 143
    ItemHeight = 15
    TabOrder = 4
  end
  object EdgeBrowser1: TEdgeBrowser
    Left = 480
    Top = 224
    Width = 287
    Height = 287
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 5
    AllowSingleSignOnUsingOSPrimaryAccount = False
    TargetCompatibleBrowserVersion = '117.0.2045.28'
    UserDataFolder = '%LOCALAPPDATA%\bds.exe.WebView2'
    OnWebResourceRequested = EdgeBrowser1WebResourceRequested
  end
  object CheckListBox1: TCheckListBox
    Left = 638
    Top = 66
    Width = 129
    Height = 143
    ItemHeight = 15
    TabOrder = 6
  end
end
