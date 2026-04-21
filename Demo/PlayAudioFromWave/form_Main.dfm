object FormMain: TFormMain
  Left = 0
  Top = 0
  Margins.Right = 8
  Caption = 'PlayAudioFromWave'
  ClientHeight = 111
  ClientWidth = 484
  Color = clBtnFace
  Constraints.MaxHeight = 250
  Constraints.MaxWidth = 500
  Constraints.MinHeight = 150
  Constraints.MinWidth = 500
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object pnl_Settings: TPanel
    Left = 0
    Top = 0
    Width = 484
    Height = 61
    Align = alClient
    Padding.Left = 10
    Padding.Top = 10
    Padding.Right = 10
    Padding.Bottom = 10
    TabOrder = 0
    object pnl_DirWaveFile: TPanel
      Left = 11
      Top = 11
      Width = 462
      Height = 25
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 0
      object txt_DirWaveFile: TLabel
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 65
        Height = 19
        Margins.Right = 8
        Align = alLeft
        Caption = 'DirWaveFile:'
        Layout = tlCenter
        ExplicitLeft = 0
        ExplicitTop = 0
        ExplicitHeight = 15
      end
      object edt_DirWaveFile: TEdit
        Left = 76
        Top = 0
        Width = 303
        Height = 25
        Align = alClient
        ReadOnly = True
        TabOrder = 0
        ExplicitLeft = 65
        ExplicitWidth = 322
        ExplicitHeight = 23
      end
      object btn_OpenWaveFile: TButton
        AlignWithMargins = True
        Left = 387
        Top = 0
        Width = 75
        Height = 25
        Margins.Left = 8
        Margins.Top = 0
        Margins.Right = 0
        Margins.Bottom = 0
        Align = alRight
        Caption = 'OPEN'
        TabOrder = 1
        OnClick = btn_OpenWaveFileClick
      end
    end
  end
  object pnl_Control: TPanel
    Left = 0
    Top = 61
    Width = 484
    Height = 50
    Align = alBottom
    Padding.Left = 10
    Padding.Top = 10
    Padding.Right = 10
    Padding.Bottom = 10
    TabOrder = 1
    object btn_StartPlay: TButton
      Left = 265
      Top = 11
      Width = 100
      Height = 28
      Align = alRight
      Caption = 'START'
      TabOrder = 0
      OnClick = btn_StartPlayClick
      ExplicitLeft = 273
    end
    object btn_EndPlay: TButton
      AlignWithMargins = True
      Left = 373
      Top = 11
      Width = 100
      Height = 28
      Margins.Left = 8
      Margins.Top = 0
      Margins.Right = 0
      Margins.Bottom = 0
      Align = alRight
      Caption = 'END'
      TabOrder = 1
      OnClick = btn_EndPlayClick
    end
    object cmb_ShareMode: TComboBox
      Left = 11
      Top = 11
      Width = 120
      Height = 23
      Cursor = crHandPoint
      Align = alLeft
      Style = csDropDownList
      ItemIndex = 0
      TabOrder = 2
      Text = 'SharedMode'
      Items.Strings = (
        'SharedMode'
        'ExclusiveMode')
      ExplicitTop = 19
    end
  end
  object odl_Wave: TOpenDialog
    Filter = 'WAVE|*.wav'
    Left = 160
    Top = 48
  end
end
