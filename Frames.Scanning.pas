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
    TorchImage: TImage;
    OverlayLayout: TLayout;
    OverlayBottomLayout: TLayout;
    InfoLabel: TLabel;
    FrameRectangle: TRectangle;
    procedure TorchImageClick(Sender: TObject);
  private
    { Private declarations }
//    [FrameInfo] FI: TFrameInfo<TScanningFrame>;
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
, Data.Main
;

{ TScanningFrame }

procedure TScanningFrame.AfterConstruction;
begin
  inherited;

  TMessageManager.DefaultManager.SubscribeToMessage(THardwareBackMessage
  , procedure(const Sender: TObject; const M: TMessage)
    begin
      if MainDM.Scanning then
        MainDM.StopScanning;
    end
  );

  TMessageManager.DefaultManager.SubscribeToMessage(TScanPointMessage
  , procedure(const Sender: TObject; const M: TMessage)
    var
      LValue: TPointF;
    begin
{$IFNDEF IOS}
      LValue := (M as TScanPointMessage).Value;
      DrawScanPoint(LValue, TAlphaColorRec.Lightblue);
{$ENDIF IOS}
    end
  );

  TMessageManager.DefaultManager.SubscribeToMessage(TCameraBufferMessage
  , procedure(const Sender: TObject; const M: TMessage)
    var
      LValue: TBitmap;
    begin
      LValue := (M as TCameraBufferMessage).Value;

      FrameRectangle.Fill.Bitmap.Bitmap.Assign(LValue);
    end
  );

  TMessageManager.DefaultManager.SubscribeToMessage(TScanSettingMessage
  , procedure(const Sender: TObject; const M: TMessage)
    var
      LValue: TVideoCaptureSetting;
    begin
      LValue := (M as TScanSettingMessage).Value;

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
      TThread.Queue(nil
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
end;

procedure TScanningFrame.TorchImageClick(Sender: TObject);
begin
  MainDM.ToggleTorch;
end;

end.
