object frmProcessorMain: TfrmProcessorMain
  Left = 0
  Top = 0
  BorderStyle = bsSingle
  Caption = 'DFMJSON Processor'
  ClientHeight = 885
  ClientWidth = 833
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -14
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  DesignSize = (
    833
    885)
  PixelsPerInch = 120
  TextHeight = 17
  object Label1: TLabel
    Left = 10
    Top = 59
    Width = 40
    Height = 17
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Caption = 'Script:'
  end
  object Label2: TLabel
    Left = 10
    Top = 10
    Width = 33
    Height = 17
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Caption = 'Path:'
  end
  object Label3: TLabel
    Left = 10
    Top = 373
    Width = 44
    Height = 17
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Caption = 'Output'
  end
  object Label4: TLabel
    Left = 544
    Top = 10
    Width = 29
    Height = 17
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Caption = 'Files:'
  end
  object btnProcess: TButton
    Left = 366
    Top = 825
    Width = 98
    Height = 33
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Anchors = [akLeft, akBottom]
    Caption = '&Process'
    TabOrder = 0
    OnClick = btnProcessClick
  end
  object txtScript: TMemo
    Left = 10
    Top = 84
    Width = 813
    Height = 276
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Anchors = [akLeft, akTop, akRight, akBottom]
    ScrollBars = ssVertical
    TabOrder = 1
  end
  object txtPath: TEdit
    Left = 52
    Top = 7
    Width = 476
    Height = 25
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    TabOrder = 2
  end
  object txtOutput: TMemo
    Left = 10
    Top = 398
    Width = 813
    Height = 419
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Anchors = [akLeft, akTop, akRight, akBottom]
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 3
  end
  object txtMask: TEdit
    Left = 577
    Top = 7
    Width = 246
    Height = 25
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    TabOrder = 4
  end
  object chkRecurse: TCheckBox
    Left = 52
    Top = 39
    Width = 181
    Height = 17
    Caption = 'Include Subdirectories'
    TabOrder = 5
  end
  object OpenDialog1: TOpenDialog
    Filter = 'DFM files|*.dfm'
    Left = 144
    Top = 288
  end
end
