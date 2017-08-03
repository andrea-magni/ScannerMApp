program ScannerMapp;

uses
  System.StartUpCopy,
  FMX.Forms,
  Forms.Main in 'Forms.Main.pas' {MainForm},
  Data.Main in 'Data.Main.pas' {MainDM: TDataModule},
  Frames.Scanning in 'Frames.Scanning.pas' {ScanningFrame: TFrame},
  Frames.Data in 'Frames.Data.pas' {DataFrame: TFrame},
  Frames.ScanResult in 'Frames.ScanResult.pas' {ScanResultFrame: TFrame},
  Frames.Info in 'Frames.Info.pas' {InfoFrame: TFrame};

{$R *.res}

begin
{$IFDEF MSWINDOWS}
  ReportMemoryLeaksOnShutdown := DebugHook > 0;
{$ENDIF}
  Application.Initialize;
  Application.FormFactor.Orientations := [TFormOrientation.Portrait, TFormOrientation.InvertedPortrait];
  Application.CreateForm(TMainDM, MainDM);
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
