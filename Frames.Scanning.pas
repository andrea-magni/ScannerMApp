unit Frames.Scanning;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Layouts, FMX.Controls.Presentation, FMX.Media
, FrameStand
, ZXing.ResultPoint
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
    procedure UpdateTorch(const AOn: Boolean);
    procedure DrawScanPoint(const APosition: TPointF; const AColor: TAlphaColor;
      const ASize: Integer = 6; const AOpacity: Double = 0.8;
      const AFadeTime: Integer = 500);
  public
    { Public declarations }
    procedure AfterConstruction; override;
    procedure PrepareToShow;
  end;

implementation

{$R *.fmx}

uses
  System.Messaging, System.Threading, Math
, Data.Main, UI.Theme
;

{ TScanningFrame }

procedure TScanningFrame.AfterConstruction;
begin
  inherited;

  TMessageManager.DefaultManager.SubscribeToMessage(TScanPointMessage
  , procedure(const Sender: TObject; const M: TMessage)
    var
      LValue: TPointF;
    begin
{$IFNDEF IOS}
      LValue := (M as TScanPointMessage).Value;
      DrawScanPoint(LValue, COLOR_ACCENT);
{$ENDIF IOS}
    end
  );

  TMessageManager.DefaultManager.SubscribeToMessage(TCameraBufferMessage
  , procedure(const Sender: TObject; const M: TMessage)
    begin
      var LValue := (M as TCameraBufferMessage).Value;
      FrameRectangle.Fill.Bitmap.Bitmap.Assign(LValue);
    end
  );

  TMessageManager.DefaultManager.SubscribeToMessage(TTorchModeMessage
  , procedure(const Sender: TObject; const M: TMessage)
    begin
      UpdateTorch((M as TTorchModeMessage).Value);
    end
  );

  TMessageManager.DefaultManager.SubscribeToMessage(TScanSettingMessage
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

procedure TScanningFrame.PrepareToShow;
begin
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
