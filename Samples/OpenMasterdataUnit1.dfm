object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'Open Masterdata 1.0.5'
  ClientHeight = 441
  ClientWidth = 624
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    624
    441)
  TextHeight = 15
  object Label1: TLabel
    Left = 8
    Top = 12
    Width = 59
    Height = 15
    Caption = 'Lieferanten'
  end
  object Label2: TLabel
    Left = 88
    Top = 48
    Width = 21
    Height = 15
    Caption = 'Info'
  end
  object Label3: TLabel
    Left = 448
    Top = 48
    Width = 105
    Height = 15
    Caption = 'Testartikelnummern'
  end
  object btBySupplierPid: TButton
    Left = 8
    Top = 408
    Width = 101
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'By Supplier Pid'
    TabOrder = 0
    OnClick = btBySupplierPidClick
  end
  object Memo1: TMemo
    Left = 8
    Top = 184
    Width = 601
    Height = 218
    Anchors = [akLeft, akTop, akRight, akBottom]
    ScrollBars = ssBoth
    TabOrder = 1
    WordWrap = False
  end
  object ComboBox1: TComboBox
    Left = 88
    Top = 8
    Width = 521
    Height = 23
    Style = csDropDownList
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 2
    OnSelect = ComboBox1Select
  end
  object Memo2: TMemo
    Left = 88
    Top = 66
    Width = 354
    Height = 112
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 3
  end
  object ListBox1: TListBox
    Left = 448
    Top = 66
    Width = 161
    Height = 112
    Anchors = [akTop, akRight]
    ItemHeight = 15
    TabOrder = 4
  end
end
