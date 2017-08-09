unit Data.Main;

interface

uses
  System.SysUtils, System.Classes, ZXing.ScanManager, ZXing.BarcodeFormat,
  ZXing.ReadResult, ZXing.ResultPoint, FMX.Types, FMX.Media, FMX.Graphics,
  System.Messaging, System.Types, System.Diagnostics, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS,
  FireDAC.Phys.Intf, FireDAC.DApt.Intf, Data.DB, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client;

const
  SCAN_EACH_MS: Integer = 133;

type
  TScanResult = class
  private
    FFrame: TBitmap;
    FResult: TReadResult;
    FProcessingTime: TStopWatch;
    procedure SetFrame(const Value: TBitmap);
    procedure SetProcessingTime(const Value: TStopWatch);
    procedure SetResult(const Value: TReadResult);
  public
    constructor Create(const AFrame: TBitmap; const AResult: TReadResult);
    destructor Destroy; override;

    property Frame: TBitmap read FFrame write SetFrame;
    property Result: TReadResult read FResult write SetResult;
    property ProcessingTime: TStopWatch read FProcessingTime
      write SetProcessingTime;
  end;

  TScanningMessage = Class(TMessage<Boolean>);
  TScanResultMessage = Class(TObjectMessage<TScanResult>);
  TScanPointMessage = Class(TMessage<TPointF>);
  TScanSettingMessage = Class(TMessage<TVideoCaptureSetting>);
  TTorchModeMessage = Class(TMessage<Boolean>);
  TCameraBufferMessage = Class(TMessage<TBitmap>);
  THardwareBackMessage = Class(TMessage<Integer>);

  TMainDM = class(TDataModule)
    DataTable: TFDMemTable;
    DataTableScannedAt: TDateTimeField;
    DataTableKind: TStringField;
    DataTableValue: TStringField;
    DataTableBitmap: TGraphicField;
    DataTableThumb: TGraphicField;
    DataTableScanCount: TIntegerField;
    procedure CameraComponent1SampleBufferReady(Sender: TObject;
      const ATime: TMediaTime);

    procedure DataModuleCreate(Sender: TObject);
  private
    { Private declarations }
    FCameraComponent: TCameraComponent;
    FLastScan: TDateTime;
    FScanning: Boolean;
    FWaitingResult: Boolean;

    function CropBitmap(const ABitmap: TBitmap): TBitmap;
    procedure ScanFrames(const AReducedBuffer: TBitmap);
    procedure SetCameraSettings(ACameraComponent: TCameraComponent);
    procedure OnResultPointHandler(const APoint: IResultPoint);
    function GetTorchModeOn: Boolean;
  public
    { Public declarations }

    procedure Scan(const ABitmap: TBitmap; const ACropBitmap: Boolean = True); overload;
    procedure Scan(const AFileName: string); overload;
    procedure StartScanning;
    procedure StopScanning;
    procedure ToggleTorch;

    property Scanning: Boolean read FScanning;
    property TorchModeOn: Boolean read GetTorchModeOn;
  end;

var
  MainDM: TMainDM;

function BarcodeToString(const ABarcode: TBarcodeFormat): string;
procedure Beep;

implementation

{%CLASSGROUP 'FMX.Controls.TControl'}
{$R *.dfm}

uses
  System.Threading, DateUtils, Rtti, TypInfo, IOUtils, Variants
{$IFDEF ANDROID}
    , Androidapi.JNI.Media, Androidapi.JNI.JavaTypes
{$ENDIF}
    , FMX.Ani, UITypes;

function BarcodeToString(const ABarcode: TBarcodeFormat): string;
begin
  Result := '';
  case ABarcode of
    Auto:
      Result := '*';
    AZTEC:
      Result := 'AZTEC';
    CODABAR:
      Result := 'CODABAR';
    CODE_39:
      Result := 'CODE_39';
    CODE_93:
      Result := 'CODE_93';
    CODE_128:
      Result := 'CODE_128';
    DATA_MATRIX:
      Result := 'DATA_MATRIX';
    EAN_8:
      Result := 'EAN_8';
    EAN_13:
      Result := 'EAN_13';
    ITF:
      Result := 'ITF';
    MAXICODE:
      Result := 'MAXICODE';
    PDF_417:
      Result := 'PDF_417';
    QR_CODE:
      Result := 'QR_CODE';
    RSS_14:
      Result := 'RSS_14';
    RSS_EXPANDED:
      Result := 'RSS_EXPANDED';
    UPC_A:
      Result := 'UPC_A';
    UPC_E:
      Result := 'UPC_E';
    UPC_EAN_EXTENSION:
      Result := 'UPC_EAN_EXTENSION';
    MSI:
      Result := 'MSI';
    PLESSEY:
      Result := 'PLESSEY';
  end;
end;

procedure Beep;
{$IFDEF ANDROID}
var
  Volume: Integer;
  StreamType: Integer;
  ToneType: Integer;
  ToneGenerator: JToneGenerator;
{$ENDIF}
begin
{$IFDEF ANDROID}
  Volume := TJToneGenerator.JavaClass.MAX_VOLUME;

  StreamType := TJAudioManager.JavaClass.STREAM_ALARM;
  ToneType := TJToneGenerator.JavaClass.TONE_CDMA_EMERGENCY_RINGBACK;
  try
    ToneGenerator := TJToneGenerator.JavaClass.init(StreamType, Volume);
    ToneGenerator.startTone(ToneType, 100);
  finally
    ToneGenerator.release;
  end;
{$ENDIF}
end;

procedure TMainDM.CameraComponent1SampleBufferReady(Sender: TObject;
  const ATime: TMediaTime);
begin
  if Sender is TCameraComponent then
  begin
    TThread.Synchronize(nil,
      procedure
      var
        LBuffer, LReducedBuffer: TBitmap;
      begin
        LBuffer := TBitmap.Create;
        try
          TCameraComponent(Sender).SampleBufferToBitmap(LBuffer, True);
          LReducedBuffer := CropBitmap(LBuffer);
          try
            TMessageManager.DefaultManager.SendMessage(Sender,
              TCameraBufferMessage.Create(LReducedBuffer));
            if FWaitingResult and (MilliSecondsBetween(FLastScan, Now) >=
              SCAN_EACH_MS) then
              ScanFrames(LReducedBuffer);
          finally
            if Assigned(LReducedBuffer) then
              FreeAndnil(LReducedBuffer);
          end;
        finally
          LBuffer.Free;
        end;
      end);
  end;
end;

function TMainDM.CropBitmap(const ABitmap: TBitmap): TBitmap;
var
  LCropW, LCropH, LCropMargin: Integer;
begin
  LCropMargin := Round(Abs(ABitmap.Width - ABitmap.Height) / 2);
  LCropW := LCropMargin;
  LCropH := 0;
  if ABitmap.Width < ABitmap.Height then
  begin
    LCropW := 0;
    LCropH := LCropMargin;
  end;

  Result := TBitmap.Create(ABitmap.Width - (2 * LCropW),
    ABitmap.Height - (2 * LCropH));
  Result.CopyFromBitmap(ABitmap, Rect(LCropW, LCropH, ABitmap.Width - LCropW,
    ABitmap.Height - LCropH), 0, 0);
end;

procedure TMainDM.DataModuleCreate(Sender: TObject);
begin
  FLastScan := Now;
  FScanning := False;
  FWaitingResult := False;

  TMessageManager.DefaultManager.SubscribeToMessage(TScanResultMessage,
    procedure(const Sender: TObject; const M: TMessage)
    const
      POINT_SIZE = 3;
    var
      LValue: TScanResult;
      LFrameWithPoints: TBitmap;
      LPoint: IResultPoint;
      LThumb: TBitmap;
      LKind, LText: string;
    begin
      LValue := (M as TScanResultMessage).Value;

      LKind := BarcodeToString(LValue.Result.BarcodeFormat);
      LText := LValue.Result.ToString;
      if DataTable.Locate('Kind;Value', VarArrayOf([LKind, LText])) then
      begin
        DataTable.Edit;
        try
          DataTable.FieldByName('ScanCount').AsInteger :=
            DataTable.FieldByName('ScanCount').AsInteger + 1;
        except
          DataTable.Cancel;
          raise;
        end;
      end
      else
      begin // add new record
        LFrameWithPoints := TBitmap.Create(LValue.Frame.Width,
          LValue.Frame.Height);
        try
          LFrameWithPoints.CopyFromBitmap(LValue.Frame);

          LFrameWithPoints.Canvas.BeginScene();
          try
            LFrameWithPoints.Canvas.Fill.Color := TAlphaColorRec.Lime;
            for LPoint in LValue.Result.resultPoints do
            begin
              LFrameWithPoints.Canvas.FillRect(RectF(LPoint.x - POINT_SIZE,
                LPoint.y - POINT_SIZE, LPoint.x + POINT_SIZE,
                LPoint.y + POINT_SIZE), 0, 0, [TCorner.TopLeft,
                TCorner.TopRight, TCorner.BottomLeft,
                TCorner.BottomRight], 0.8);
            end;
          finally
            LFrameWithPoints.Canvas.EndScene();
          end;

          LThumb := LValue.Frame.CreateThumbnail(100, 100);
          try
            DataTable.AppendRecord([LValue.Result.timeStamp, LKind, LText,
              LThumb, LFrameWithPoints, 1]);
          finally
            LThumb.Free;
          end;
        finally
          LFrameWithPoints.Free;
        end;
      end;
    end);
end;

function TMainDM.GetTorchModeOn: Boolean;
begin
  Result := Assigned(FCameraComponent) and (FCameraComponent.TorchMode = TTorchMode.ModeOn);
end;

procedure TMainDM.OnResultPointHandler(const APoint: IResultPoint);
begin
  if (TThread.CurrentThread.ThreadID = MainThreadID) then
    TMessageManager.DefaultManager.SendMessage(Self,
      TScanPointMessage.Create(PointF(APoint.x, APoint.y)))
  else
    TThread.Queue(nil,
      procedure
      begin
        TMessageManager.DefaultManager.SendMessage(Self,
          TScanPointMessage.Create(PointF(APoint.x, APoint.y)));
      end);
end;

procedure TMainDM.Scan(const ABitmap: TBitmap;
  const ACropBitmap: Boolean = True);
var
  LReducedBuffer: TBitmap;
begin
  if ACropBitmap then
    LReducedBuffer := CropBitmap(ABitmap)
  else
  begin
    LReducedBuffer := TBitmap.Create(ABitmap.Width, ABitmap.Height);
    try
      LReducedBuffer.CopyFromBitmap(ABitmap);
    except
      LReducedBuffer.Free;
      raise;
    end;
  end;

  FWaitingResult := True;
  ScanFrames(LReducedBuffer);
end;

procedure TMainDM.Scan(const AFileName: string);
var
  LBitmap: TBitmap;
begin
  LBitmap := TBitmap.Create;
  try
    LBitmap.LoadFromFile(AFileName);
    Scan(LBitmap, False);
  finally
    LBitmap.Free;
  end;
end;

procedure TMainDM.ScanFrames(const AReducedBuffer: TBitmap);
    var
      LReadResult: TReadResult;
      LScanManager: TScanManager;
begin
  if not Assigned(AReducedBuffer) or (AReducedBuffer.Width < 2) then
    Exit;

  FLastScan := Now;

  if (not FWaitingResult) or (not FScanning) then // already found
    Exit;

  LScanManager := TScanManager.Create(TBarcodeFormat.Auto, nil);
  try
{$IFNDEF IOS}
    LScanManager.OnResultPoint := OnResultPointHandler;
{$ENDIF IOS}

    LReadResult := nil;
    try
      LReadResult := LScanManager.Scan(AReducedBuffer);
    except
      LReadResult := nil;
    end;

    if (LReadResult <> nil) and FWaitingResult then
    begin
      TThread.Synchronize(nil,
        procedure
        begin
          StopScanning;
          TMessageManager.DefaultManager.SendMessage(Self,
            TScanResultMessage.Create(TScanResult.Create(AReducedBuffer,
            LReadResult)));
        end);

    end;
  finally
    FreeAndNil(LScanManager);
    if Assigned(LReadResult) then
      FreeAndNil(LReadResult);
  end;
end;

procedure TMainDM.SetCameraSettings(ACameraComponent: TCameraComponent);
var
  LSetting: TVideoCaptureSetting;
begin
  for LSetting in ACameraComponent.AvailableCaptureSettings do
  begin
    if (LSetting.FrameRate >= 24) and (LSetting.Width <= 700) then
    begin
      ACameraComponent.SetCaptureSetting(LSetting);
      TMessageManager.DefaultManager.SendMessage(Self,
        TScanSettingMessage.Create(LSetting));
      Break;
    end;
  end;

  ACameraComponent.FocusMode := TFocusMode.ContinuousAutoFocus;
  ACameraComponent.CaptureSettingPriority :=
    TVideoCaptureSettingPriority.FrameRate;
end;

procedure TMainDM.StartScanning;
begin
  if Not Assigned(FCameraComponent) then
  begin
    FCameraComponent := TCameraComponent.Create(Self);
    SetCameraSettings(FCameraComponent);
    FCameraComponent.OnSampleBufferReady := CameraComponent1SampleBufferReady;
    FCameraComponent.Active := True;
  end;
  FScanning := True;
  FWaitingResult := True;
  TMessageManager.DefaultManager.SendMessage(Self, TScanningMessage.Create(True));
end;

procedure TMainDM.StopScanning;
begin
  FWaitingResult := False;
  FScanning := False;

  if Assigned(FCameraComponent) then
  begin
    FCameraComponent.OnSampleBufferReady := nil;
{$IFDEF MSWINDOWS}
    //FCameraComponent.Active := False;
{$ENDIF}
    FreeAndNil(FCameraComponent);
  end;

  TMessageManager.DefaultManager.SendMessage(Self, TScanningMessage.Create(False));
end;

procedure TMainDM.ToggleTorch;
begin
  if Assigned(FCameraComponent) then
  begin
    if FCameraComponent.TorchMode = TTorchMode.ModeOff then
      FCameraComponent.TorchMode := TTorchMode.ModeOn
    else
      FCameraComponent.TorchMode := TTorchMode.ModeOff;
  end;

  TMessageManager.DefaultManager.SendMessage(Self, TTorchModeMessage.Create(TorchModeOn));
end;

{ TScanResult }

constructor TScanResult.Create(const AFrame: TBitmap;
const AResult: TReadResult);
begin
  inherited Create;
  FFrame := AFrame;
  FResult := AResult;
end;

destructor TScanResult.Destroy;
begin
  if Assigned(FFrame) then
  begin
    FFrame.DisposeOf;
    FFrame := nil;
  end;

  // FResult is a reference injected and disposed of elsewhere
  // if Assigned(FResult) then
  // begin
  // FResult.DisposeOf;
  // FResult := nil;
  // end;

  inherited;
end;

procedure TScanResult.SetFrame(const Value: TBitmap);
begin
  FFrame := Value;
end;

procedure TScanResult.SetProcessingTime(const Value: TStopWatch);
begin
  FProcessingTime := Value;
end;

procedure TScanResult.SetResult(const Value: TReadResult);
begin
  FResult := Value;
end;

end.
