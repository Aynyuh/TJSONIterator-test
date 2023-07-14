object FormMain: TFormMain
  Left = 0
  Top = 0
  Caption = 'FormMain'
  ClientHeight = 441
  ClientWidth = 624
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnClose = FormClose
  OnCreate = FormCreate
  DesignSize = (
    624
    441)
  TextHeight = 15
  object btnOpenFile: TButton
    Left = 8
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Open'
    TabOrder = 0
    OnClick = btnOpenFileClick
  end
  object Memo1: TMemo
    Left = 8
    Top = 48
    Width = 608
    Height = 385
    Anchors = [akLeft, akTop, akRight, akBottom]
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Courier New'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssBoth
    TabOrder = 1
  end
  object btnCount: TButton
    Left = 89
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Count'
    TabOrder = 2
    OnClick = btnCountClick
  end
  object OpenDialog1: TOpenDialog
    Filter = 'JSON (*.json)|*.json|All (*.*)|*.*'
    Left = 408
    Top = 216
  end
end
