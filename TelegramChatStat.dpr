program TelegramChatStat;

uses
  Vcl.Forms,
  Forms.Main in 'Forms.Main.pas' {FormMain};

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.
