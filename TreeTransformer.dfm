object DataModule1: TDataModule1
  OldCreateOrder = False
  Height = 316
  Width = 692
  object DelphiWebScript1: TDelphiWebScript
    Config.OnNeedUnit = DelphiWebScript1NeedUnit
    Left = 184
    Top = 160
  end
  object TreeTransformer: TdwsUnit
    Script = DelphiWebScript1
    UnitName = 'TreeTransformer'
    ImplicitUse = True
    Variables = <
      item
        Name = 'DFM'
        DataType = 'Variant'
      end>
    StaticSymbols = False
    Left = 344
    Top = 168
  end
  object dwsJSONLibModule1: TdwsJSONLibModule
    Script = DelphiWebScript1
    Left = 504
    Top = 136
  end
end
