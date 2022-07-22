program OpenMasterdata;

uses
  Vcl.Forms,
  OpenMasterdataUnit1 in 'OpenMasterdataUnit1.pas' {MainForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
