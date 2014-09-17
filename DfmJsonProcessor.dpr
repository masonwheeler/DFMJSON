program DfmJsonProcessor;

uses
  Vcl.Forms,
  main in 'main.pas' {Form5},
  DFMJSON in 'DFMJSON.pas',
  TreeTransformer in 'TreeTransformer.pas' {DataModule1: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmProcessorMain, frmProcessorMain);
  Application.CreateForm(TDataModule1, DataModule1);
  Application.Run;
end.
