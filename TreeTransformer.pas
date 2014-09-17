unit TreeTransformer;

interface

uses
  System.SysUtils, System.Classes,
  dwsExprs, dwsComp, dwsJSONConnector, dwsFunctions;

type
  TDataModule1 = class(TDataModule)
    DelphiWebScript1: TDelphiWebScript;
    TreeTransformer: TdwsUnit;
    dwsJSONLibModule1: TdwsJSONLibModule;
    function DelphiWebScript1NeedUnit(const unitName: string; var unitSource:
        string): IdwsUnit;
  private
    procedure DoTransform(const prog: IDwsProgram; const filename: string; const onSuccess, onErr: TProc<string>);
    { Private declarations }
  public
    { Public declarations }
    procedure RunTransform(const script, path, mask: string; recurse: boolean;
       const onSuccess, onErr: TProc<string>);
  end;

var
  DataModule1: TDataModule1;

implementation
uses
  System.Types,
  Vcl.Dialogs,
  System.IOUtils,
  DFMJSON,
  dwsErrors,
  dwsJson;

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

{ TDataModule1 }

procedure TDataModule1.RunTransform(const script, path, mask: string; recurse: boolean;
   const onSuccess, onErr: TProc<string>);
var
  files: TStringDynArray;
  filename: string;
  prog: IDwsProgram;
  option: TSearchOption;
begin
  prog := DelphiWebScript1.Compile(script);
  if prog.Msgs.HasErrors then
  begin
    onErr(prog.Msgs.AsInfo);
    Exit;
  end;
  if recurse then
    option := TSearchOption.soAllDirectories
  else option := TSearchOption.soTopDirectoryOnly;
  files := TDirectory.GetFiles(path, mask, option);
  for filename in files do
    DoTransform(prog, filename, onSuccess, onErr);
end;

procedure TDataModule1.DoTransform(const prog: IDwsProgram; const filename: string; const onSuccess, onErr: TProc<string>);
var
  exec: IdwsProgramExecution;
  dfm: TdwsJSONObject;
begin
  try
    try
      dfm := DFMJSON.Dfm2JSON(filename);
    except on EParserError do
      try
        dfm := DFMJSON.DfmBin2JSON(filename)
      except on E: Exception do
        begin
          if assigned(onErr) then
            onErr(format('Error while parsing %s.  Exception %s: %s', [filename, e.ClassName, e.Message]));
          exit;
        end;
      end;
    end;
    exec := prog.BeginNewExecution;
    exec.Info.ValueAsVariant['DFM'] := BoxedJSONValue(dfm);
    exec.RunProgram(0);
    dfm := (IInterface(exec.Info.ValueAsVariant['DFM']) as IBoxedJSONValue).Value as TdwsJSONObject;
    exec.EndProgram;
    SaveJSON2Dfm(dfm, filename);
    if assigned(onSuccess) then
      onSuccess(format('Successfully converted %s.', [filename]));
  except on E: Exception do
    if assigned(onErr) then
      onErr(format('Error while converting %s.  Exception %s: %s', [filename, e.ClassName, e.Message]));
  end;
end;

function TDataModule1.DelphiWebScript1NeedUnit(const unitName: string; var
    unitSource: string): IdwsUnit;
var
  rtlPath, filename: string;
begin
  rtlPath := TPath.Combine(ExtractFilePath(ParamStr(0)), 'RTL');
  filename := TPath.Combine(rtlPath, unitName + '.dws');
  if FileExists(filename) then
    unitSource := TFile.ReadAllText(filename);
end;

end.
