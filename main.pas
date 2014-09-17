unit main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TfrmProcessorMain = class(TForm)
    OpenDialog1: TOpenDialog;
    btnProcess: TButton;
    txtScript: TMemo;
    Label1: TLabel;
    Label2: TLabel;
    txtPath: TEdit;
    Label3: TLabel;
    txtOutput: TMemo;
    txtMask: TEdit;
    Label4: TLabel;
    chkRecurse: TCheckBox;
    procedure btnProcessClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmProcessorMain: TfrmProcessorMain;

implementation
uses
   DFMJSON,
   TreeTransformer,
   dwsJSON;

{$R *.dfm}

procedure TfrmProcessorMain.btnProcessClick(Sender: TObject);
begin
  txtOutput.Clear;
  TreeTransformer.DataModule1.RunTransform(
    txtScript.Text, txtPath.Text, txtMask.Text, chkRecurse.Checked,
    procedure(value: string) begin txtOutput.Lines.Add(value) end,
    procedure(value: string) begin txtOutput.Lines.Add(value) end);
end;

end.
