unit Forms.Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.Objects, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Media,
  System.Actions, FMX.ActnList, FMX.StdActns, FMX.MediaLibrary.Actions, System.Math.Vectors
, ZXing.ScanManager, ZXing.BarcodeFormat, ZXing.ReadResult, ZXing.ResultPoint
, FrameStand
, Frames.Scanning, Frames.Data, Frames.Info, FMX.Platform
;

type
  TMainForm = class(TForm)
    CameraButton: TButton;
    ActionList1: TActionList;
    ToggleCameraAction: TAction;
    TakePhotoFromLibraryAction: TTakePhotoFromLibraryAction;
    LibraryButton: TButton;
    FrameStand1: TFrameStand;
    Stands: TStyleBook;
    ContentLayout: TLayout;
    TopToolBar: TToolBar;
    LoadFromFileAction: TAction;
    OpenButton: TButton;
    OpenDialog1: TOpenDialog;
    InfoButton: TButton;
    procedure ToggleCameraActionExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure TakePhotoFromLibraryActionDidFinishTaking(Image: TBitmap);
    procedure LoadFromFileActionExecute(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
    procedure InfoButtonClick(Sender: TObject);
    function AppEventHandler(AAppEvent: TApplicationEvent; AContext: TObject): Boolean;
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    FScanningFrameFI: TFrameInfo<TScanningFrame>;
    FDataFrameFI: TFrameInfo<TDataFrame>;
    FInfoFrameFI: TFrameInfo<TInfoFrame>;
//    FDataString: string;
    procedure UpdateGUI;
    function GetScanningFrameFI: TFrameInfo<TScanningFrame>;
    function GetDataFrameFI: TFrameInfo<TDataFrame>;
    function GetInfoFrameFI: TFrameInfo<TInfoFrame>;
    property ScanningFrameFI: TFrameInfo<TScanningFrame> read GetScanningFrameFI;
    property DataFrameFI: TFrameInfo<TDataFrame> read GetDataFrameFI;
    property InfoFrameFI: TFrameInfo<TInfoFrame> read GetInfoFrameFI;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

uses
  System.Threading, System.Diagnostics, System.Messaging
, DateUtils, Rtti, TypInfo, IOUtils, Math
{$IFDEF ANDROID}
, Androidapi.JNI.Media, Androidapi.Helpers, Androidapi.JNI.JavaTypes
, FMX.Platform.Android, Androidapi.JNI.GraphicsContentViewText, Androidapi.JNI.Os
, Androidapi.JNI.Net
{$ENDIF}
, FMX.Ani
, Data.Main
;


function TMainForm.AppEventHandler(AAppEvent: TApplicationEvent;
  AContext: TObject): Boolean;
begin
  Result := False;

  if AAppEvent in [TApplicationEvent.WillBecomeInactive, TApplicationEvent.EnteredBackground, TApplicationEvent.WillTerminate]
  then
    if MainDM.Scanning then
      MainDM.StopScanning;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  LAppEventService: IFMXApplicationEventService;
begin
{$IFDEF MSWINDOWS}
  ReportMemoryLeaksOnShutdown := True;
{$ENDIF}
  FScanningFrameFI := nil;
  FInfoFrameFI := nil;

  if TPlatformServices.Current.SupportsPlatformService(IFMXApplicationEventService, LAppEventService) then
    LAppEventService.SetApplicationEventHandler(AppEventHandler);

{  // WIP
  MainActivity.registerIntentAction(TJIntent.JavaClass.ACTION_SEND);

  TMessageManager.DefaultManager.SubscribeToMessage(TMessageReceivedNotification
  , procedure(const Sender: TObject; const M: TMessage)
    const IMAGES_MEDIA_DATA = 4;
    var
      LIntent: JIntent;
      LType, LDataString: string;
      LExtras: JBundle;
      LParcelable: JParcelable;
      LUri: Jnet_Uri;
      LContentResolver: JContentResolver;
      LCursor: JCursor;
      LIndex: Integer;
      LText: string;
    begin
      if M is TMessageReceivedNotification then
      begin
        FDataString := '';
        LIntent := TMessageReceivedNotification(M).Value;
        LType := JStringToString(LIntent.getType);
        LExtras := LIntent.getExtras;
        if LExtras.containsKey(TJIntent.JavaClass.EXTRA_STREAM) then
        begin
          LParcelable := LExtras.getParcelable(TJIntent.JavaClass.EXTRA_STREAM);
          LUri := TJnet_Uri.Wrap(LParcelable);
          if JStringToString(LURI.getScheme) = 'content' then
          begin
            LContentResolver := MainActivity.getContentResolver;
            LCursor := LContentResolver.query(LUri, nil, nil, nil, nil);
            LCursor.moveToFirst;
            LDataString := JStringToString(LCursor.getString(IMAGES_MEDIA_DATA));
            if (not LDataString.IsEmpty) and TFile.Exists(LDataString) then
            begin
              FDataString := '001:' + sLineBreak + LDataString;
              MainDM.Scan(LDataString);
            end
            else
            begin
              LText := '';
              for LIndex := 0 to LCursor.getColumnCount-1 do
                LText := string.Join(sLineBreak, [LText, JStringToString(LCursor.getString(LIndex))]);
              FDataString := 'File not found ' + LCursor.getColumnCount.ToString + LText + sLineBreak
               + 'URI: ' + JURIToStr(LUri);
            end;
          end;
        end
        else
          ShowMessage('Unsupported format: ' + LType);
      end;
    end
  );
}
  TMessageManager.DefaultManager.SubscribeToMessage(TScanningMessage
  , procedure(const Sender: TObject; const M: TMessage)
    begin
      UpdateGUI;
    end
  );

  TMessageManager.DefaultManager.SubscribeToMessage(TScanResultMessage
  , procedure(const Sender: TObject; const M: TMessage)
    begin
      if not DataFrameFI.IsVisible then
        DataFrameFI.Show();
    end
  );

  UpdateGUI;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FrameStand1.FrameInfos.Clear;
end;

procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
  if Key = vkHardwareBack then
  begin
    Key := 0;
    TMessageManager.DefaultManager.SendMessage(Self, THardwareBackMessage.Create(0));
  end;
end;

function TMainForm.GetDataFrameFI: TFrameInfo<TDataFrame>;
begin
  if not Assigned(FDataFrameFI) then
    FDataFrameFI := FrameStand1.New<TDataFrame>(ContentLayout, 'simple');
  Result := FDataFrameFI;
end;

function TMainForm.GetInfoFrameFI: TFrameInfo<TInfoFrame>;
begin
  if not Assigned(FInfoFrameFI) then
    FInfoFrameFI := FrameStand1.New<TInfoFrame>(nil, 'lightbox');
  Result := FInfoFrameFI;
end;

function TMainForm.GetScanningFrameFI: TFrameInfo<TScanningFrame>;
begin
  if not Assigned(FScanningFrameFI) then
    FScanningFrameFI := FrameStand1.New<TScanningFrame>(ContentLayout, 'lightbox');
  Result := FScanningFrameFI;
end;

procedure TMainForm.InfoButtonClick(Sender: TObject);
begin
  if InfoFrameFI.IsVisible then
    InfoFrameFI.Hide()
  else
    InfoFrameFI.Show();
end;

procedure TMainForm.LoadFromFileActionExecute(Sender: TObject);
var
  LBitmap: TBitmap;
begin
  if OpenDialog1.Execute then
  begin
    LBitmap := TBitmap.CreateFromFile(OpenDialog1.FileName);
    try
      MainDM.Scan(LBitmap, False);
    finally
      LBitmap.Free;
    end;
  end;
end;

procedure TMainForm.TakePhotoFromLibraryActionDidFinishTaking(Image: TBitmap);
begin
  MainDM.Scan(Image, False);
end;

procedure TMainForm.ToggleCameraActionExecute(Sender: TObject);
begin
  if MainDM.Scanning then
    MainDM.StopScanning
  else
  begin
    MainDM.StartScanning;
    ScanningFrameFI.Frame.PrepareToShow;
    ScanningFrameFI.Show()
  end;

  UpdateGUI;
end;

procedure TMainForm.UpdateGUI;
begin
  if MainDM.Scanning then
  begin
    if not ScanningFrameFI.IsVisible then
      ScanningFrameFI.Show()
  end
  else
  begin
    if ScanningFrameFI.IsVisible then
      ScanningFrameFI.Hide();
  end;
end;

end.
