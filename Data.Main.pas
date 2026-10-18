unit Data.Main;

interface

uses
  System.SysUtils, System.Classes, ZXing.ScanManager, ZXing.BarcodeFormat,
  ZXing.ReadResult, ZXing.ResultPoint, ZXing.DecodeHintType, FMX.Types, FMX.Media, FMX.Graphics,
  System.Messaging, System.Types, System.Diagnostics, System.Generics.Collections,
  FireDAC.Stan.Intf,
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
  TDataChangedMessage = Class(TMessage);

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
    // ZXing.Delphi 4: one scan manager per use, held as interface (ScanAsync keeps
    // it alive while a scan runs). Not meant to be used by two threads at once.
    FCameraScanManager: IScanManager; // camera frames, decoded in background (ScanAsync)
    FStillScanManager: IScanManager;  // still images (library, file), TRY_HARDER
    FScanFrame: TBitmap; // the frame being decoded by FCameraScanManager

    function CropBitmap(const ABitmap: TBitmap): TBitmap;
    procedure ScanCameraFrame(const AFrame: TBitmap);
    procedure DeliverResult(const AFrame: TBitmap; const AResult: TReadResult);
    procedure SetCameraSettings(ACameraComponent: TCameraComponent);
    procedure OnResultPointHandler(const APoint: IResultPoint);
    function GetTorchModeOn: Boolean;
    procedure DataTableChanged(DataSet: TDataSet);
  public
    { Public declarations }
    procedure BeforeDestruction; override;

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
    , FMX.Ani, UITypes, Math
    , UI.Theme;

function BarcodeToString(const ABarcode: TBarcodeFormat): string;
begin
  // TBarcodeFormat has explicit (sparse) values: no RTTI names, hence the table.
  // The names are the identifiers of the enum, as stored in DataTable.Kind.
  case ABarcode of
    TBarcodeFormat.Auto: Result := '*';
    TBarcodeFormat.AZTEC: Result := 'AZTEC';
    TBarcodeFormat.CODABAR: Result := 'CODABAR';
    TBarcodeFormat.CODE_39: Result := 'CODE_39';
    TBarcodeFormat.CODE_93: Result := 'CODE_93';
    TBarcodeFormat.CODE_128: Result := 'CODE_128';
    TBarcodeFormat.DATA_MATRIX: Result := 'DATA_MATRIX';
    TBarcodeFormat.EAN_8: Result := 'EAN_8';
    TBarcodeFormat.EAN_13: Result := 'EAN_13';
    TBarcodeFormat.ITF: Result := 'ITF';
    TBarcodeFormat.MAXICODE: Result := 'MAXICODE';
    TBarcodeFormat.PDF_417: Result := 'PDF_417';
    TBarcodeFormat.QR_CODE: Result := 'QR_CODE';
    TBarcodeFormat.RSS_14: Result := 'RSS_14';
    TBarcodeFormat.RSS_EXPANDED: Result := 'RSS_EXPANDED';
    TBarcodeFormat.UPC_A: Result := 'UPC_A';
    TBarcodeFormat.UPC_E: Result := 'UPC_E';
    TBarcodeFormat.UPC_EAN_EXTENSION: Result := 'UPC_EAN_EXTENSION';
    TBarcodeFormat.MSI: Result := 'MSI';
    TBarcodeFormat.PLESSEY: Result := 'PLESSEY';
    TBarcodeFormat.TELEPEN: Result := 'TELEPEN';
    TBarcodeFormat.RSS_LIMITED: Result := 'RSS_LIMITED';
    TBarcodeFormat.MICRO_PDF417: Result := 'MICRO_PDF417';
    TBarcodeFormat.MICRO_QR_CODE: Result := 'MICRO_QR_CODE';
    TBarcodeFormat.RMQR_CODE: Result := 'RMQR_CODE';
    TBarcodeFormat.DX_FILM_EDGE: Result := 'DX_FILM_EDGE';
    TBarcodeFormat.CODE_32: Result := 'CODE_32';
    TBarcodeFormat.PZN: Result := 'PZN';
    TBarcodeFormat.PHARMA_CODE: Result := 'PHARMA_CODE';
    TBarcodeFormat.KIX: Result := 'KIX';
    TBarcodeFormat.RM4SCC: Result := 'RM4SCC';
    TBarcodeFormat.IMB: Result := 'IMB';
    TBarcodeFormat.POSTNET: Result := 'POSTNET';
    TBarcodeFormat.PLANET: Result := 'PLANET';
    TBarcodeFormat.JAPAN_POST: Result := 'JAPAN_POST';
    TBarcodeFormat.AUSTRALIA_POST: Result := 'AUSTRALIA_POST';
    TBarcodeFormat.MAILMARK_4STATE: Result := 'MAILMARK_4STATE';
    TBarcodeFormat.CODE_11: Result := 'CODE_11';
    TBarcodeFormat.INDUSTRIAL_2_OF_5: Result := 'INDUSTRIAL_2_OF_5';
    TBarcodeFormat.IATA_2_OF_5: Result := 'IATA_2_OF_5';
    TBarcodeFormat.MATRIX_2_OF_5: Result := 'MATRIX_2_OF_5';
    TBarcodeFormat.DATALOGIC_2_OF_5: Result := 'DATALOGIC_2_OF_5';
    TBarcodeFormat.PHARMA_CODE_TWO_TRACK: Result := 'PHARMA_CODE_TWO_TRACK';
    TBarcodeFormat.CEPNET: Result := 'CEPNET';
    TBarcodeFormat.KOREA_POST: Result := 'KOREA_POST';
    TBarcodeFormat.FIM: Result := 'FIM';
    TBarcodeFormat.DP_LEITCODE: Result := 'DP_LEITCODE';
    TBarcodeFormat.DP_IDENTCODE: Result := 'DP_IDENTCODE';
    TBarcodeFormat.CODABLOCK_F: Result := 'CODABLOCK_F';
    TBarcodeFormat.CODE_16K: Result := 'CODE_16K';
    TBarcodeFormat.CODE_49: Result := 'CODE_49';
    TBarcodeFormat.GS1_COMPOSITE: Result := 'GS1_COMPOSITE';
    TBarcodeFormat.DOTCODE: Result := 'DOTCODE';
    TBarcodeFormat.HAN_XIN: Result := 'HAN_XIN';
  else
    Result := 'FORMAT_' + IntToStr(Ord(ABarcode));
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

procedure TMainDM.BeforeDestruction;
begin
  // the camera off without StopScanning: no messages at shutdown, the
  // subscribers (forms, frames) may already be gone
  FWaitingResult := False;
  FScanning := False;
  if Assigned(FCameraComponent) then
  begin
    FCameraComponent.OnSampleBufferReady := nil;
    FreeAndNil(FCameraComponent);
  end;
  // a running scan calls back through TThread.Synchronize: let it complete
  // before the data module (referenced by the callback) goes away
  while Assigned(FCameraScanManager) and FCameraScanManager.Scanning do
    CheckSynchronize(10);
  FCameraScanManager := nil;
  FStillScanManager := nil;
  FreeAndNil(FScanFrame);

  inherited;
end;

procedure TMainDM.CameraComponent1SampleBufferReady(Sender: TObject;
  const ATime: TMediaTime);
begin
  // FMX (Android) already fires OnSampleBufferReady in the main thread, through a
  // TThread.Synchronize issued by the camera thread: no further synchronization needed here.
  // Never stop/free the camera from within this handler (see DeliverResult).
  if not (Sender is TCameraComponent) or not FScanning then
    Exit;

  var LBuffer := TBitmap.Create;
  try
    TCameraComponent(Sender).SampleBufferToBitmap(LBuffer, True);
    if LBuffer.IsEmpty then
      Exit;

    var LReducedBuffer := CropBitmap(LBuffer);
    try
      TMessageManager.DefaultManager.SendMessage(
        Sender
      , TCameraBufferMessage.Create(LReducedBuffer)
      );
      // a frame that arrives while a scan runs is skipped (ScanAsync would skip it too)
      if FWaitingResult and not FCameraScanManager.Scanning
        and (MilliSecondsBetween(FLastScan, Now) >= SCAN_EACH_MS)
      then
        ScanCameraFrame(LReducedBuffer);
    finally
      LReducedBuffer.Free;
    end;
  finally
    LBuffer.Free;
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

  Result := TBitmap.Create(ABitmap.Width - (2 * LCropW), ABitmap.Height - (2 * LCropH));
  Result.CopyFromBitmap(
    ABitmap
  , Rect(LCropW, LCropH, ABitmap.Width - LCropW, ABitmap.Height - LCropH)
  , 0, 0
  );
end;

procedure TMainDM.DataModuleCreate(Sender: TObject);
begin
  FLastScan := Now;
  FScanning := False;
  FWaitingResult := False;

  FScanFrame := TBitmap.Create;
  FCameraScanManager := TScanManager.Create(TBarcodeFormat.Auto, nil);
{$IFNDEF IOS}
  FCameraScanManager.OnResultPoint := OnResultPointHandler;
{$ENDIF IOS}

  var LHints := TDictionary<TDecodeHintType, TObject>.Create; // freed by the scan manager
  LHints.Add(TDecodeHintType.TRY_HARDER, nil);       // slower, finds more (also rotated 1D codes)
  LHints.Add(TDecodeHintType.ENABLE_INVERSION, nil); // also light codes on a dark background
  FStillScanManager := TScanManager.Create(TBarcodeFormat.Auto, LHints);

  DataTable.AfterPost := DataTableChanged;
  DataTable.AfterDelete := DataTableChanged;

  TMessageManager.DefaultManager.SubscribeToMessage(TScanResultMessage,
    procedure(const Sender: TObject; const M: TMessage)
    var
      LValue: TScanResult;
      LFrameWithPoints: TBitmap;
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
          DataTable.Post;
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

          // the outline of the code: Position holds its 4 corners in the frame
          // (estimated from the result points when the reader did not set them)
          var LCorners := LValue.Result.Position;
          if Length(LCorners) >= 2 then
          begin
            var LOutline := TPathData.Create;
            try
              LOutline.MoveTo(PointF(LCorners[0].x, LCorners[0].y));
              for var I := 1 to High(LCorners) do
                LOutline.LineTo(PointF(LCorners[I].x, LCorners[I].y));
              LOutline.ClosePath;

              LFrameWithPoints.Canvas.BeginScene();
              try
                LFrameWithPoints.Canvas.Stroke.Kind := TBrushKind.Solid;
                LFrameWithPoints.Canvas.Stroke.Color := COLOR_ACCENT;
                LFrameWithPoints.Canvas.Stroke.Thickness :=
                  Max(2, Min(LValue.Frame.Width, LValue.Frame.Height) / 100);
                LFrameWithPoints.Canvas.Stroke.Join := TStrokeJoin.Round;
                LFrameWithPoints.Canvas.DrawPath(LOutline, 0.9);
              finally
                LFrameWithPoints.Canvas.EndScene();
              end;
            finally
              LOutline.Free;
            end;
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

procedure TMainDM.DataTableChanged(DataSet: TDataSet);
begin
  TMessageManager.DefaultManager.SendMessage(Self, TDataChangedMessage.Create);
end;

function TMainDM.GetTorchModeOn: Boolean;
begin
  Result := Assigned(FCameraComponent) and (FCameraComponent.TorchMode = TTorchMode.ModeOn);
end;

procedure TMainDM.OnResultPointHandler(const APoint: IResultPoint);
begin
  // ZXing 4 calls this from the decoding tasks (several at once with ParallelDecoding);
  // a point is a record now, captured by value
  if APoint.IsNone then
    Exit;
  TThread.ForceQueue(
    nil
  , procedure
    begin
      TMessageManager.DefaultManager.SendMessage(Self,
        TScanPointMessage.Create(PointF(APoint.x, APoint.y)));
    end
  );
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

  try
    FWaitingResult := True;
    var LReadResult: TReadResult;
    try
      LReadResult := FStillScanManager.Scan(LReducedBuffer);
    except
      LReadResult := nil;
    end;
    if Assigned(LReadResult) then
      DeliverResult(LReducedBuffer, LReadResult);
  finally
    LReducedBuffer.Free; // DeliverResult keeps a copy
  end;
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

procedure TMainDM.ScanCameraFrame(const AFrame: TBitmap);
// AFrame remains owned by the caller: ScanAsync takes its pixels before returning
begin
  if not Assigned(AFrame) or (AFrame.Width < 2) then
    Exit;

  FLastScan := Now;
  FScanFrame.Assign(AFrame); // shown with the result; untouched while the scan runs

  FCameraScanManager.ScanAsync(AFrame,
    procedure(AResult: TReadResult)
    begin
      // main thread; nil when nothing was read (or the frame could not be decoded)
      if not Assigned(AResult) then
        Exit;
      if FWaitingResult then
        DeliverResult(FScanFrame, AResult)
      else
        AResult.Free; // scanning stopped meanwhile, or a code was already read
    end);
end;

procedure TMainDM.DeliverResult(const AFrame: TBitmap; const AResult: TReadResult);
// Takes ownership of AResult; AFrame is copied
begin
  if not FWaitingResult then
  begin
    AResult.Free;
    Exit;
  end;
  FWaitingResult := False;

  // TScanResult takes ownership of both the frame (a copy) and the read result;
  // TScanResultMessage (TObjectMessage) owns and frees the TScanResult.
  var LScanResult: TScanResult;
  var LFrame := TBitmap.Create;
  try
    LFrame.Assign(AFrame);
    LScanResult := TScanResult.Create(LFrame, AResult);
  except
    LFrame.Free;
    AResult.Free;
    raise;
  end;

  // Deferred: never stop (free) the camera from within one of its events.
  TThread.ForceQueue(nil,
    procedure
    begin
      StopScanning;
      TMessageManager.DefaultManager.SendMessage(Self,
        TScanResultMessage.Create(LScanResult));
    end);
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
  if not Assigned(FCameraComponent) then
  begin
    FCameraComponent := TCameraComponent.Create(nil);
    try
      SetCameraSettings(FCameraComponent);
      FCameraComponent.OnSampleBufferReady := CameraComponent1SampleBufferReady;
      FCameraComponent.Active := True;
    except
      FCameraComponent.OnSampleBufferReady := nil;
      FreeAndNil(FCameraComponent);
      raise;
    end;
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
  FreeAndNil(FFrame);
  FreeAndNil(FResult);

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
