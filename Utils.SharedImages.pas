unit Utils.SharedImages;

// Images shared with the app (Android: ACTION_SEND, ACTION_SEND_MULTIPLE) or opened
// with it (ACTION_VIEW), see the intent filters in AndroidManifest.template.xml:
// both the intent that started the app and the ones that come while it runs.
// Other platforms: nothing (the desktop gets images on the command line).

interface

uses
  System.SysUtils, FMX.Graphics;

type
  /// <summary>The images of an intent, in the main thread; they are freed after the call.
  /// AReceived: the images in the intent (more than Length(AImages) when some could not be read)</summary>
  TSharedImagesProc = reference to procedure(const AImages: TArray<TBitmap>; const AReceived: Integer);

/// <summary>Starts listening; the intent that started the app (if it carries images)
/// is handled once the main loop runs</summary>
procedure ListenForSharedImages(const AHandler: TSharedImagesProc);
/// <summary>Stops listening (before the handler's object goes away)</summary>
procedure StopListeningForSharedImages;

implementation

uses
  System.Classes, System.Messaging, System.Math
{$IFDEF ANDROID}
, Androidapi.JNIBridge, Androidapi.Helpers, Androidapi.JNI.JavaTypes
, Androidapi.JNI.GraphicsContentViewText, Androidapi.JNI.Net, Androidapi.JNI.Os, Androidapi.JNI.App
, Androidapi.JNI.Embarcadero, FMX.Platform.Android
{$ENDIF}
;

const
  /// <summary>Largest side of a received image (a photo can be 4000+ px): as the photo library</summary>
  MAX_IMAGE_SIZE = 3072;

var
  GHandler: TSharedImagesProc;
  GSubscription: Integer = -1;

{$IFDEF ANDROID}
function LoadBitmap(const AUri: Jnet_Uri): TBitmap;
var
  LInput: JInputStream;
  LBuffer: TJavaArray<Byte>;
  LStream: TMemoryStream;
  LRead: Integer;
begin
  Result := nil;
  LInput := TAndroidHelper.Context.getContentResolver.openInputStream(AUri);
  if LInput = nil then
    Exit;
  LStream := TMemoryStream.Create;
  LBuffer := TJavaArray<Byte>.Create(64 * 1024);
  try
    repeat
      LRead := LInput.read(LBuffer);
      if LRead > 0 then
        LStream.WriteBuffer(LBuffer.Data^, LRead);
    until LRead <= 0;
    LInput.close;
    LStream.Position := 0;
    Result := TBitmap.Create;
    try
      Result.LoadFromStream(LStream);
      if Max(Result.Width, Result.Height) > MAX_IMAGE_SIZE then
      begin
        var LScale := MAX_IMAGE_SIZE / Max(Result.Width, Result.Height);
        var LSmall := Result.CreateThumbnail(Round(Result.Width * LScale), Round(Result.Height * LScale));
        Result.Free;
        Result := LSmall;
      end;
    except
      FreeAndNil(Result); // not an image FMX can read
    end;
  finally
    LBuffer.Free;
    LStream.Free;
  end;
end;

function UriOf(const AParcelable: JParcelable): Jnet_Uri;
begin
  Result := nil;
  if AParcelable <> nil then
    Result := TJnet_Uri.Wrap((AParcelable as ILocalObject).GetObjectID);
end;

function UrisOf(const AIntent: JIntent): TArray<Jnet_Uri>;
begin
  Result := [];
  if (AIntent = nil) or (AIntent.getAction = nil) then
    Exit;
  var LAction := JStringToString(AIntent.getAction);
  if LAction = JStringToString(TJIntent.JavaClass.ACTION_SEND) then
  begin
    var LUri := UriOf(AIntent.getParcelableExtra(TJIntent.JavaClass.EXTRA_STREAM));
    if LUri <> nil then
      Result := [LUri];
  end
  else if LAction = JStringToString(TJIntent.JavaClass.ACTION_SEND_MULTIPLE) then
  begin
    var LList := AIntent.getParcelableArrayListExtra(TJIntent.JavaClass.EXTRA_STREAM);
    if LList <> nil then
      for var I := 0 to LList.size - 1 do
      begin
        var LUri := TJnet_Uri.Wrap((LList.get(I) as ILocalObject).GetObjectID);
        if LUri <> nil then
          Result := Result + [LUri];
      end;
  end
  else if LAction = JStringToString(TJIntent.JavaClass.ACTION_VIEW) then
  begin
    if AIntent.getData <> nil then
      Result := [AIntent.getData];
  end;
end;

procedure HandleIntent(const AIntent: JIntent);
begin
  var LUris := UrisOf(AIntent);
  if (Length(LUris) = 0) or not Assigned(GHandler) then
    Exit;
  var LImages: TArray<TBitmap> := [];
  try
    for var LUri in LUris do
    try
      var LBitmap := LoadBitmap(LUri);
      if Assigned(LBitmap) then
        LImages := LImages + [LBitmap];
    except
      // a stream that cannot be read (permission revoked, file gone): the others still count
    end;
    GHandler(LImages, Length(LUris));
  finally
    for var LImage in LImages do
      LImage.Free;
  end;
end;
{$ENDIF}

procedure ListenForSharedImages(const AHandler: TSharedImagesProc);
begin
  GHandler := AHandler;
{$IFDEF ANDROID}
  // the intents that come while the app runs (launchMode singleTask: onNewIntent)
  for var LAction in [TJIntent.JavaClass.ACTION_SEND, TJIntent.JavaClass.ACTION_SEND_MULTIPLE,
    TJIntent.JavaClass.ACTION_VIEW] do
    MainActivity.registerIntentAction(LAction);
  GSubscription := TMessageManager.DefaultManager.SubscribeToMessage(TMessageReceivedNotification,
    procedure(const Sender: TObject; const M: TMessage)
    begin
      var LIntent := TMessageReceivedNotification(M).Value;
      // in the main thread, after the current message
      TThread.ForceQueue(nil,
        procedure
        begin
          HandleIntent(LIntent);
        end);
    end);

  // the intent that started the app, once the form is shown
  var LIntent := TAndroidHelper.Activity.getIntent;
  TThread.ForceQueue(nil,
    procedure
    begin
      HandleIntent(LIntent);
      // handled: not again if the activity is created again with the same intent
      TAndroidHelper.Activity.setIntent(TJIntent.JavaClass.init);
    end);
{$ENDIF}
end;

procedure StopListeningForSharedImages;
begin
  if GSubscription <> -1 then
  begin
{$IFDEF ANDROID}
    TMessageManager.DefaultManager.Unsubscribe(TMessageReceivedNotification, GSubscription);
{$ENDIF}
    GSubscription := -1;
  end;
  GHandler := nil;
end;

end.
