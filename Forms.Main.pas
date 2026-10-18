unit Forms.Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.Objects, FMX.Controls.Presentation, FMX.StdCtrls, FMX.Media,
  System.Actions, FMX.ActnList, FMX.StdActns, FMX.MediaLibrary.Actions, System.Math.Vectors
, System.Threading, System.Diagnostics, System.Messaging,  System.Permissions
, ZXing.ScanManager, ZXing.BarcodeFormat, ZXing.ReadResult, ZXing.ResultPoint
, FrameStand, SubjectStand
, Frames.Scanning, Frames.Data, Frames.Info, FMX.Platform, FMX.MediaLibrary,
  FMX.ApplicationEvents
;

type
  TMainForm = class(TForm)
    ActionList1: TActionList;
    ToggleCameraAction: TAction;
    TakePhotoFromLibraryAction: TTakePhotoFromLibraryAction;
    FrameStand1: TFrameStand;
    Stands: TStyleBook;
    LoadFromFileAction: TAction;
    OpenDialog1: TOpenDialog;
    ApplicationEvents1: TApplicationEvents;
    RootLayout: TLayout;
    HeaderLayout: TLayout;
    TitleLabel: TLabel;
    InfoButton: TRectangle;
    InfoIcon: TPath;
    ContentLayout: TLayout;
    EmptyLayout: TLayout;
    EmptyCircle: TCircle;
    EmptyIcon: TPath;
    EmptyTitleLabel: TLabel;
    EmptyHintLabel: TLabel;
    BottomBar: TRectangle;
    LibraryButton: TRectangle;
    LibraryIcon: TPath;
    LibraryLabel: TLabel;
    OpenButton: TRectangle;
    OpenIcon: TPath;
    OpenLabel: TLabel;
    CenterLayout: TLayout;
    CameraButton: TRectangle;
    CameraContentLayout: TLayout;
    CameraIcon: TPath;
    CameraLabel: TLabel;
    procedure ToggleCameraActionExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure TakePhotoFromLibraryActionDidFinishTaking(Image: TBitmap);
    procedure LoadFromFileActionExecute(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
    procedure InfoButtonClick(Sender: TObject);
    function ApplicationEvents1StateChanged(Sender: TObject;
      const AAppEvent: TApplicationEvent; const AContext: TObject): Boolean;
    procedure FormSafeAreaChanged(Sender: TObject; const AInsets: TRectF);
    procedure CameraButtonClick(Sender: TObject);
    procedure LibraryButtonClick(Sender: TObject);
    procedure OpenButtonClick(Sender: TObject);
    procedure PressableMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure PressableMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure PressableMouseLeave(Sender: TObject);
  private
    { Private declarations }
    FScanningFrameFI: TFrameInfo<TScanningFrame>;
    FDataFrameFI: TFrameInfo<TDataFrame>;
    FInfoFrameFI: TFrameInfo<TInfoFrame>;

//    FDataString: string;
    procedure UpdateGUI;
    procedure StartCamera;
    function GetScanningFrameFI: TFrameInfo<TScanningFrame>;
    function GetDataFrameFI: TFrameInfo<TDataFrame>;
    function GetInfoFrameFI: TFrameInfo<TInfoFrame>;
    property ScanningFrameFI: TFrameInfo<TScanningFrame> read GetScanningFrameFI;
    property DataFrameFI: TFrameInfo<TDataFrame> read GetDataFrameFI;
    property InfoFrameFI: TFrameInfo<TInfoFrame> read GetInfoFrameFI;
{$IFDEF ANDROID}
  private
    procedure PermissionRequestResult(Sender: TObject; const APermissions: TClassicStringDynArray;
      const AGrantResults: TClassicPermissionStatusDynArray);
    procedure DisplayRationale(Sender: TObject; const APermissions: TClassicStringDynArray; const APostRationaleProc: TProc);
{$ENDIF}
  public
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

uses
  DateUtils, Rtti, TypInfo, IOUtils, Math, Data.DB
{$IFDEF ANDROID}
, Androidapi.JNI.Media, Androidapi.Helpers, Androidapi.JNI.JavaTypes
, FMX.Platform.Android, Androidapi.JNI.GraphicsContentViewText, Androidapi.JNI.Os
, Androidapi.JNI.Net
{$ENDIF}
, FMX.Ani, FMX.DialogService
, Data.Main, UI.Theme
;


{$IFDEF ANDROID}
procedure TMainForm.PermissionRequestResult(Sender: TObject; const APermissions: TClassicStringDynArray;
    const AGrantResults: TClassicPermissionStatusDynArray);
begin
  var LAllGranted := Length(AGrantResults) > 0;
  for var LStatus in AGrantResults do
    if LStatus <> TPermissionStatus.Granted then
      LAllGranted := False;

  if LAllGranted then
    StartCamera
  else
    TDialogService.ShowMessage('Camera permission is required to scan codes');
end;
{$ENDIF}

function TMainForm.ApplicationEvents1StateChanged(Sender: TObject;
  const AAppEvent: TApplicationEvent; const AContext: TObject): Boolean;
begin
  if AAppEvent
     in [TApplicationEvent.WillBecomeInactive, TApplicationEvent.EnteredBackground, TApplicationEvent.WillTerminate]
  then
    if MainDM.Scanning then
      MainDM.StopScanning;
  Result := False;
end;

{$IFDEF ANDROID}
procedure TMainForm.DisplayRationale(Sender: TObject; const APermissions: TClassicStringDynArray; const APostRationaleProc: TProc);
begin
  // Show an explanation to the user *asynchronously* - don't block this thread waiting for the user's response!
  // After the user sees the explanation, invoke the post-rationale routine to request the permissions
  TDialogService.ShowMessage(
    'The app needs to access the camera in order to scan codes'
  , procedure(const AResult: TModalResult)
    begin
      APostRationaleProc;
    end
  );
end;
{$ENDIF}

procedure TMainForm.FormCreate(Sender: TObject);
begin
{$IFDEF MSWINDOWS}
  ReportMemoryLeaksOnShutdown := True;
{$ENDIF}
  FScanningFrameFI := nil;
  FInfoFrameFI := nil;

  // Permissions: CAMERA is requested when the camera is first toggled on (see StartCamera).
  // READ/WRITE_EXTERNAL_STORAGE are not needed (and always denied with targetSdk >= 33):
  // TTakePhotoFromLibraryAction relies on the system photo picker.

{$IFDEF ANDROID}
  UseLightSystemBarIcons;
{$ENDIF}
{$IF Defined(ANDROID) or Defined(IOS)}
  OpenButton.Visible := False; // LoadFromFileAction is not supported on mobile
{$ELSE}
  LibraryButton.Visible := False; // no photo library on desktop
{$ENDIF}

  TMessageManager.DefaultManager.SubscribeToMessage(
    TDataChangedMessage
  , procedure(const Sender: TObject; const M: TMessage)
    begin
      UpdateGUI;
    end
  );

  TMessageManager.DefaultManager.SubscribeToMessage(
    TScanningMessage
  , procedure(const Sender: TObject; const M: TMessage)
    begin
      UpdateGUI;
    end
  );

  TMessageManager.DefaultManager.SubscribeToMessage(
    TScanResultMessage
  , procedure(const Sender: TObject; const M: TMessage)
    begin
      if not DataFrameFI.IsVisible then
        DataFrameFI.Show();
    end
  );

  UpdateGUI;
end;

procedure TMainForm.CameraButtonClick(Sender: TObject);
begin
  ToggleCameraAction.Execute;
end;

procedure TMainForm.LibraryButtonClick(Sender: TObject);
begin
  TakePhotoFromLibraryAction.Execute;
end;

procedure TMainForm.OpenButtonClick(Sender: TObject);
begin
  LoadFromFileAction.Execute;
end;

procedure TMainForm.PressableMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  SetPressed(Sender, True);
end;

procedure TMainForm.PressableMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  SetPressed(Sender, False);
end;

procedure TMainForm.PressableMouseLeave(Sender: TObject);
begin
  SetPressed(Sender, False);
end;

procedure TMainForm.FormSafeAreaChanged(Sender: TObject; const AInsets: TRectF);
begin
  // Android 15+ (targetSdk >= 35) forces edge-to-edge: the form covers the status bar
  // and the navigation bar. Keep the content within the safe area.
  Padding.Rect := AInsets;
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
  begin
    FDataFrameFI := FrameStand1.New<TDataFrame>(ContentLayout, 'simple');
    FDataFrameFI.Frame.OverlayParent := RootLayout;
  end;
  Result := FDataFrameFI;
end;

function TMainForm.GetInfoFrameFI: TFrameInfo<TInfoFrame>;
begin
  if not Assigned(FInfoFrameFI) then
    FInfoFrameFI := FrameStand1.New<TInfoFrame>(RootLayout, 'lightbox');
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
begin
  if OpenDialog1.Execute then
  begin
    var LBitmap := TBitmap.CreateFromFile(OpenDialog1.FileName);
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
    StartCamera;

  UpdateGUI;
end;

procedure TMainForm.StartCamera;
begin
{$IFDEF ANDROID}
  const LPermissionCamera = JStringToString(TJManifest_permission.JavaClass.CAMERA);
  if not PermissionsService.IsPermissionGranted(LPermissionCamera) then
  begin
    // StartCamera is called again by PermissionRequestResult once granted
    PermissionsService.RequestPermissions([LPermissionCamera], PermissionRequestResult, DisplayRationale);
    Exit;
  end;
{$ENDIF}

  MainDM.StartScanning;
  ScanningFrameFI.Frame.PrepareToShow;
  UpdateGUI;
end;

procedure TMainForm.UpdateGUI;
begin
  EmptyLayout.Visible := MainDM.DataTable.IsEmpty and not MainDM.Scanning;

  if MainDM.Scanning then
  begin
    CameraLabel.Text := 'Stop';
    CameraIcon.Data.Data := ICON_STOP;
  end
  else
  begin
    CameraLabel.Text := 'Scan';
    CameraIcon.Data.Data := ICON_QR;
  end;

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
