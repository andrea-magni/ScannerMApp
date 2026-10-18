unit Frames.ScanResult;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Layouts, FMX.Controls.Presentation,
  Data.Bind.EngExt, Fmx.Bind.DBEngExt, System.Rtti, System.Bindings.Outputs,
  Fmx.Bind.Editors, Data.Bind.Components, Data.Bind.DBScope
, FrameStand, SubjectStand, System.Actions, FMX.ActnList, FMX.StdActns,
  FMX.MediaLibrary.Actions, Fmx.Bind.Navigator
;

type
  TScanResultFrame = class(TFrame)
    BindSourceDB1: TBindSourceDB;
    BindingsList1: TBindingsList;
    LinkPropertyToFieldText: TLinkPropertyToField;
    LinkPropertyToFieldText2: TLinkPropertyToField;
    LinkPropertyToFieldText3: TLinkPropertyToField;
    LinkPropertyToFieldText4: TLinkPropertyToField;
    LinkPropertyToFieldBitmap: TLinkPropertyToField;
    ActionList1: TActionList;
    ShareAction: TShowShareSheetAction;
    DeleteAction: TAction;
    CardRectangle: TRectangle;
    HeaderRow: TLayout;
    CloseButton: TCircle;
    CloseIcon: TPath;
    KindChip: TRectangle;
    KindLabel: TLabel;
    ActionsLayout: TLayout;
    CopyButton: TRectangle;
    CopyIcon: TPath;
    CopyLabel: TLabel;
    DeleteButton: TRectangle;
    DeleteIcon: TPath;
    DeleteLabel: TLabel;
    ShareButton: TRectangle;
    ShareContentLayout: TLayout;
    ShareIcon: TPath;
    ShareLabel: TLabel;
    MetaRow: TLayout;
    ScanCountLabel: TLabel;
    ScansCaptionLabel: TLabel;
    TimeStampLabel: TLabel;
    ValueScrollBox: TVertScrollBox;
    ResultLabel: TLabel;
    ImageBox: TRectangle;
    ImageViewport: TLayout;
    FrameImage: TImage;
    procedure FrameClick(Sender: TObject);
    procedure ShareActionBeforeExecute(Sender: TObject);
    procedure DeleteActionExecute(Sender: TObject);
    procedure CloseButtonClick(Sender: TObject);
    procedure CopyButtonClick(Sender: TObject);
    procedure ShareButtonClick(Sender: TObject);
    procedure DeleteButtonClick(Sender: TObject);
    procedure PressableMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure PressableMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure PressableMouseLeave(Sender: TObject);
    procedure ImageViewportGesture(Sender: TObject;
      const EventInfo: TGestureEventInfo; var Handled: Boolean);
    procedure ImageViewportMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure ImageViewportMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Single);
    procedure ImageViewportMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure ImageViewportMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; var Handled: Boolean);
    procedure ImageViewportResize(Sender: TObject);
  private
    { Private declarations }
    [FrameInfo] FI: TFrameInfo<TScanResultFrame>;
    // image zoom & pan
    FZoom: Single;
    FOffset: TPointF;
    FDragging: Boolean;
    FPinching: Boolean;
    FDragStart: TPointF;
    FDragStartOffset: TPointF;
    FLastPinchDistance: Integer;
    FGesturesRegistered: Boolean;
    procedure RegisterGestures;
    procedure SetCopied(const ACopied: Boolean);
    procedure ZoomAt(const APoint: TPointF; const AZoom: Single);
    procedure ApplyZoom;
  protected
  public
    { Public declarations }
    procedure AfterConstruction; override;
    [BeforeShow] procedure ResetZoom;
  end;

implementation

{$R *.fmx}

uses
  System.Messaging, System.Math, FMX.Platform, FMX.Clipboard
, Data.Main, UI.Theme
;

const
  MIN_ZOOM = 1.0;
  MAX_ZOOM = 6.0;
  DOUBLE_TAP_ZOOM = 2.5;

procedure TScanResultFrame.AfterConstruction;
begin
  inherited;
  FZoom := MIN_ZOOM;

  TMessageManager.DefaultManager.SubscribeToMessage(THardwareBackMessage
  , procedure(const Sender: TObject; const M: TMessage)
    begin
      FI.Hide;
    end
  );
end;

procedure TScanResultFrame.CloseButtonClick(Sender: TObject);
begin
  FI.Hide;
end;

procedure TScanResultFrame.CopyButtonClick(Sender: TObject);
var
  LClipboard: IFMXExtendedClipboardService;
begin
  if TPlatformServices.Current.SupportsPlatformService(IFMXExtendedClipboardService, LClipboard) then
  begin
    LClipboard.SetText(MainDM.DataTable.FieldByName('Value').AsString);
    SetCopied(True);
    TThread.ForceQueue(nil
    , procedure
      begin
        SetCopied(False);
      end
    , 1500);
  end;
end;

procedure TScanResultFrame.DeleteActionExecute(Sender: TObject);
begin
  BindSourceDB1.DataSet.Delete;
  FI.Hide;
end;

procedure TScanResultFrame.DeleteButtonClick(Sender: TObject);
begin
  DeleteAction.Execute;
end;

procedure TScanResultFrame.FrameClick(Sender: TObject);
begin
  FI.Hide;
end;

procedure TScanResultFrame.ApplyZoom;
// FrameImage (WrapMode = Fit) is the viewport scaled by FZoom and shifted by FOffset
begin
  var LViewport := ImageViewport.LocalRect;
  var LWidth := LViewport.Width * FZoom;
  var LHeight := LViewport.Height * FZoom;

  // keep the viewport always covered (no panning beyond the image edges)
  FOffset.X := EnsureRange(FOffset.X, LViewport.Width - LWidth, 0);
  FOffset.Y := EnsureRange(FOffset.Y, LViewport.Height - LHeight, 0);

  FrameImage.SetBounds(FOffset.X, FOffset.Y, LWidth, LHeight);
end;

procedure TScanResultFrame.ZoomAt(const APoint: TPointF; const AZoom: Single);
// APoint (viewport coordinates) stays still while zooming
begin
  var LZoom := EnsureRange(AZoom, MIN_ZOOM, MAX_ZOOM);
  var LContentPoint := (APoint - FOffset) / FZoom;
  FOffset := APoint - LContentPoint * LZoom;
  FZoom := LZoom;
  ApplyZoom;
end;

procedure TScanResultFrame.RegisterGestures;
// TCustomTouchManager.SetInteractiveGestures registers the gesture recognizers with the
// form found walking the *Owner* chain: TFrameStand creates frames with Owner = nil, so
// (on Android) Zoom and DoubleTap would never be recognized. Register them here, once
// the frame is parented within a form.
begin
  if FGesturesRegistered or not Assigned(Root) or not (Root.GetObject is TCommonCustomForm) then
    Exit;

  var LForm := TCommonCustomForm(Root.GetObject);
  for var LGesture in ImageViewport.Touch.InteractiveGestures do
    if not (LGesture in LForm.GetRecognizers) then
      LForm.AddRecognizer(LGesture);
  FGesturesRegistered := True;
end;

procedure TScanResultFrame.ResetZoom;
begin
  RegisterGestures;
  FZoom := MIN_ZOOM;
  FOffset := TPointF.Zero;
  FDragging := False;
  FPinching := False;
  ApplyZoom;
end;

procedure TScanResultFrame.ImageViewportResize(Sender: TObject);
begin
  ApplyZoom;
end;

procedure TScanResultFrame.ImageViewportGesture(Sender: TObject;
  const EventInfo: TGestureEventInfo; var Handled: Boolean);
begin
  var LPoint := ImageViewport.AbsoluteToLocal(EventInfo.Location);
  case EventInfo.GestureID of
    igiZoom:
    begin
      if TInteractiveGestureFlag.gfBegin in EventInfo.Flags then
      begin
        FPinching := True;
        FDragging := False;
      end
      else if FLastPinchDistance > 0 then
        ZoomAt(LPoint, FZoom * EventInfo.Distance / FLastPinchDistance);
      FLastPinchDistance := EventInfo.Distance;

      if TInteractiveGestureFlag.gfEnd in EventInfo.Flags then
      begin
        FPinching := False;
        FLastPinchDistance := 0;
      end;
      Handled := True;
    end;
    igiDoubleTap:
    begin
      if FZoom > MIN_ZOOM then
        ResetZoom
      else
        ZoomAt(LPoint, DOUBLE_TAP_ZOOM);
      Handled := True;
    end;
  end;
end;

procedure TScanResultFrame.ImageViewportMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
{$IF not (Defined(ANDROID) or Defined(IOS))}
  if ssDouble in Shift then // desktop counterpart of the double tap gesture
  begin
    if FZoom > MIN_ZOOM then
      ResetZoom
    else
      ZoomAt(PointF(X, Y), DOUBLE_TAP_ZOOM);
    Exit;
  end;
{$ENDIF}
  FDragging := not FPinching;
  FDragStart := PointF(X, Y);
  FDragStartOffset := FOffset;
end;

procedure TScanResultFrame.ImageViewportMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Single);
begin
  if FDragging and not FPinching and (FZoom > MIN_ZOOM) then
  begin
    FOffset := FDragStartOffset + (PointF(X, Y) - FDragStart);
    ApplyZoom;
  end;
end;

procedure TScanResultFrame.ImageViewportMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  FDragging := False;
end;

procedure TScanResultFrame.ImageViewportMouseWheel(Sender: TObject;
  Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
begin
  var LPoint := ImageViewport.AbsoluteToLocal(ImageViewport.Scene.ScreenToLocal(Screen.MousePos));
  ZoomAt(LPoint, FZoom * Power(1.15, WheelDelta / 120));
  Handled := True;
end;

procedure TScanResultFrame.PressableMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  SetPressed(Sender, True);
end;

procedure TScanResultFrame.PressableMouseLeave(Sender: TObject);
begin
  SetPressed(Sender, False);
end;

procedure TScanResultFrame.PressableMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  SetPressed(Sender, False);
end;

procedure TScanResultFrame.SetCopied(const ACopied: Boolean);
begin
  if ACopied then
  begin
    CopyIcon.Data.Data := ICON_CHECK;
    CopyIcon.Fill.Color := COLOR_ACCENT;
    CopyLabel.Text := 'Copied';
    CopyLabel.TextSettings.FontColor := COLOR_ACCENT;
  end
  else
  begin
    CopyIcon.Data.Data := ICON_COPY;
    CopyIcon.Fill.Color := COLOR_TEXT;
    CopyLabel.Text := 'Copy';
    CopyLabel.TextSettings.FontColor := COLOR_TEXT;
  end;
end;

procedure TScanResultFrame.ShareActionBeforeExecute(Sender: TObject);
begin
  ShareAction.TextMessage := MainDM.DataTable.FieldByName('Value').AsString;
end;

procedure TScanResultFrame.ShareButtonClick(Sender: TObject);
begin
  ShareAction.Execute;
end;

end.
