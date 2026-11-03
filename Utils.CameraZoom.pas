unit Utils.CameraZoom;

// The zoom of the camera (Android, iOS): the camera crops the sensor before scaling it to
// the frames, so a code far away gets more detail than enlarging the frames would give.
// Desktop webcams: no zoom (MaxZoom = 1).

interface

uses
  FMX.Media;

/// <summary>The highest zoom factor of the active camera (1: no zoom)</summary>
function MaxZoom(const ACamera: TCameraComponent): Single;
/// <summary>Sets the zoom (1..MaxZoom) of the active camera; returns the factor applied</summary>
function SetZoom(const ACamera: TCameraComponent; const AFactor: Single): Single;

implementation

uses
  System.SysUtils, System.Math
{$IF Defined(ANDROID)}
, System.Rtti, Androidapi.JNI.Hardware, Androidapi.JNI.JavaTypes, Androidapi.JNIBridge
{$ELSEIF Defined(IOS)}
, iOSapi.AVFoundation, Macapi.Helpers
{$ENDIF}
;

const
  ZOOM_LIMIT = 8; // beyond it the frames are too blurry to read a code

type
  TCameraComponentAccess = class(TCameraComponent); // Device is protected

function CaptureDevice(const ACamera: TCameraComponent): TVideoCaptureDevice;
begin
  Result := nil;
  if ACamera <> nil then
    Result := TCameraComponentAccess(ACamera).Device;
end;

{$IF Defined(ANDROID)}
function AndroidCamera(const ACamera: TCameraComponent): JCamera;
begin
  // shortcut: TAndroidVideoCaptureDevice is in the implementation of FMX.Media.Android,
  // its public property Camera is reached through RTTI; no property: no zoom
  Result := nil;
  var LDevice := CaptureDevice(ACamera);
  if LDevice = nil then
    Exit;
  var LContext: TRttiContext;
  var LProperty := LContext.GetType(LDevice.ClassType).GetProperty('Camera');
  if LProperty <> nil then
    Result := LProperty.GetValue(LDevice).AsType<JCamera>;
end;

function ZoomRatio(const ARatios: JList; const AIndex: Integer): Single;
begin
  Result := TJInteger.Wrap(ARatios.get(AIndex)).intValue / 100; // the ratios are x100
end;

function MaxZoom(const ACamera: TCameraComponent): Single;
begin
  Result := 1;
  var LCamera := AndroidCamera(ACamera);
  if LCamera = nil then
    Exit;
  var LParams := LCamera.getParameters;
  if LParams.isZoomSupported then
    Result := Min(ZoomRatio(LParams.getZoomRatios, LParams.getMaxZoom), ZOOM_LIMIT);
end;

function SetZoom(const ACamera: TCameraComponent; const AFactor: Single): Single;
begin
  Result := 1;
  var LCamera := AndroidCamera(ACamera);
  if LCamera = nil then
    Exit;
  var LParams := LCamera.getParameters;
  if not LParams.isZoomSupported then
    Exit;
  // the zoom step of the camera nearest to AFactor (2x may be 1.9 or 2.1)
  var LRatios := LParams.getZoomRatios;
  var LFactor := EnsureRange(AFactor, 1, ZOOM_LIMIT);
  var LIndex := 0;
  for var I := 1 to LParams.getMaxZoom do
    if Abs(ZoomRatio(LRatios, I) - LFactor) < Abs(ZoomRatio(LRatios, LIndex) - LFactor) then
      LIndex := I;
  if LParams.getZoom <> LIndex then
  begin
    LParams.setZoom(LIndex);
    LCamera.setParameters(LParams);
  end;
  Result := ZoomRatio(LRatios, LIndex);
end;

{$ELSEIF Defined(IOS)}
function AppleDevice(const ACamera: TCameraComponent): AVCaptureDevice;
begin
  // the AVCaptureDevice of FMX is private: the same device, by its unique ID
  Result := nil;
  var LDevice := CaptureDevice(ACamera);
  if LDevice <> nil then
    Result := TAVCaptureDevice.OCClass.deviceWithUniqueID(StrToNSStr(LDevice.UniqueID));
end;

function MaxZoom(const ACamera: TCameraComponent): Single;
begin
  Result := 1;
  var LDevice := AppleDevice(ACamera);
  if (LDevice <> nil) and (LDevice.activeFormat <> nil) then
    Result := Max(1, Min(LDevice.activeFormat.videoMaxZoomFactor, ZOOM_LIMIT));
end;

function SetZoom(const ACamera: TCameraComponent; const AFactor: Single): Single;
begin
  Result := 1;
  var LDevice := AppleDevice(ACamera);
  if (LDevice = nil) or (LDevice.activeFormat = nil) then
    Exit;
  Result := EnsureRange(AFactor, 1, Max(1, Min(LDevice.activeFormat.videoMaxZoomFactor, ZOOM_LIMIT)));
  // the device is shared by the sessions: its zoom outlives the camera component
  if LDevice.lockForConfiguration(nil) then
  try
    LDevice.setVideoZoomFactor(Result);
  finally
    LDevice.unlockForConfiguration;
  end;
end;

{$ELSE}
function MaxZoom(const ACamera: TCameraComponent): Single;
begin
  Result := 1;
end;

function SetZoom(const ACamera: TCameraComponent; const AFactor: Single): Single;
begin
  Result := 1;
end;
{$ENDIF}

end.
