unit Frames.Scanning;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Layouts, FMX.Controls.Presentation, FMX.Media
, FrameStand
, ZXing.ResultPoint
, Data.Main
;

type
  TScanningFrame = class(TFrame)
    HintLabel: TLabel;
    OverlayBottomLayout: TLayout;
    InfoLabel: TLabel;
    TorchButton: TCircle;
    TorchIcon: TPath;
    ViewfinderLayout: TLayout;
    FrameRectangle: TRectangle;
    procedure ViewfinderLayoutResize(Sender: TObject);
    procedure TorchButtonClick(Sender: TObject);
    procedure PressableMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure PressableMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure PressableMouseLeave(Sender: TObject);
  private
    { Private declarations }
//    [FrameInfo] FI: TFrameInfo<TScanningFrame>;
    FSubscriptions: TSubscriptions;
    FDefaultHint: string;
    FHintTicket: Integer;
    procedure ShowHint(const AText: string);
    procedure RestoreHint;
    procedure UpdateTorch(const AOn: Boolean);
    procedure DrawScanPoint(const APosition: TPointF; const AColor: TAlphaColor;
      const ASize: Integer = 6; const AOpacity: Double = 0.8;
      const AFadeTime: Integer = 500);
  public
    { Public declarations }
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    procedure PrepareToShow;
  end;

implementation

{$R *.fmx}

uses
  System.Messaging, System.Threading, Math
, UI.Theme
;

{ TScanningFrame }

procedure TScanningFrame.BeforeDestruction;
begin
  FSubscriptions.Clear;
  inherited;
end;

procedure TScanningFrame.AfterConstruction;
begin
  inherited;

  FSubscriptions.Add(TScanPointMessage
  , procedure(const Sender: TObject; const M: TMessage)
    begin
      DrawScanPoint((M as TScanPointMessage).Value, COLOR_ACCENT);
    end
  );

  FSubscriptions.Add(TCameraBufferMessage
  , procedure(const Sender: TObject; const M: TMessage)
    begin
      var LValue := (M as TCameraBufferMessage).Value;
      FrameRectangle.Fill.Bitmap.Bitmap.Assign(LValue);
    end
  );

  FSubscriptions.Add(TScanHintMessage
  , procedure(const Sender: TObject; const M: TMessage)
    begin
      ShowHint((M as TScanHintMessage).Value);
    end
  );

  FSubscriptions.Add(TTorchModeMessage
  , procedure(const Sender: TObject; const M: TMessage)
    begin
      UpdateTorch((M as TTorchModeMessage).Value);
    end
  );

  FSubscriptions.Add(TScanSettingMessage
  , procedure(const Sender: TObject; const M: TMessage)
    begin
      var LValue := (M as TScanSettingMessage).Value;

      InfoLabel.Text := LValue.Width.ToString + ' x ' + LValue.Height.ToString
        + ' ' + LValue.FrameRate.ToString(TFloatFormat.ffFixed, 15, 1) + ' FPS';
    end
  );
end;

procedure TScanningFrame.DrawScanPoint(const APosition: TPointF;
  const AColor: TAlphaColor; const ASize: Integer; const AOpacity: Double;
  const AFadeTime: Integer);
var
  LRect: TRectangle;
begin
  if FrameRectangle.Fill.Bitmap.Bitmap.IsEmpty then
    Exit;

  LRect := TRectangle.Create(nil);

  LRect.Opacity := AOpacity;
  LRect.Fill.Color := AColor;
  LRect.Width := ASize;
  LRect.Height := ASize;
  LRect.Position.X := (APosition.x - (ASize/2))  * (FrameRectangle.Width / FrameRectangle.Fill.Bitmap.Bitmap.Width);
  LRect.Position.Y := (APosition.y - (ASize/2))  * (FrameRectangle.Height / FrameRectangle.Fill.Bitmap.Bitmap.Height);

  FrameRectangle.AddObject(LRect);

  TTask.Run(
    procedure
    begin
      Sleep(AFadeTime);
      TThread.ForceQueue(nil
      , procedure begin
          FrameRectangle.RemoveObject(LRect);
          LRect.Free;
        end
      );
    end
  );
end;

procedure TScanningFrame.ShowHint(const AText: string);
const
  HINT_MS = 1500;
begin
  if FDefaultHint = '' then
    FDefaultHint := HintLabel.Text;
  HintLabel.Text := AText;
  HintLabel.TextSettings.FontColor := COLOR_ACCENT;

  // back to the default hint when no other one came meanwhile
  Inc(FHintTicket);
  var LTicket := FHintTicket;
  TThread.ForceQueue(nil,
    procedure
    begin
      if LTicket = FHintTicket then
        RestoreHint;
    end, HINT_MS);
end;

procedure TScanningFrame.RestoreHint;
begin
  if FDefaultHint <> '' then
    HintLabel.Text := FDefaultHint;
  HintLabel.TextSettings.FontColor := COLOR_TEXT;
end;

procedure TScanningFrame.PrepareToShow;
begin
  Inc(FHintTicket); // a pending restore is not needed any more
  RestoreHint;
  FrameRectangle.Fill.Bitmap.Bitmap := nil;
  UpdateTorch(False); // a new camera starts with the torch off
end;

procedure TScanningFrame.PressableMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  SetPressed(Sender, True);
end;

procedure TScanningFrame.PressableMouseLeave(Sender: TObject);
begin
  SetPressed(Sender, False);
end;

procedure TScanningFrame.PressableMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  SetPressed(Sender, False);
end;

procedure TScanningFrame.TorchButtonClick(Sender: TObject);
begin
  MainDM.ToggleTorch;
end;

procedure TScanningFrame.ViewfinderLayoutResize(Sender: TObject);
begin
  // square viewfinder, as large as the available space allows
  var LSide := Max(0, Min(ViewfinderLayout.Width, ViewfinderLayout.Height) - 16);
  FrameRectangle.Size.Size := TSizeF.Create(LSide, LSide);
end;

procedure TScanningFrame.UpdateTorch(const AOn: Boolean);
begin
  if AOn then
  begin
    TorchButton.Fill.Color := COLOR_ACCENT;
    TorchIcon.Fill.Color := COLOR_ON_ACCENT;
  end
  else
  begin
    TorchButton.Fill.Color := COLOR_SURFACE_2;
    TorchIcon.Fill.Color := COLOR_TEXT;
  end;
end;

end.
