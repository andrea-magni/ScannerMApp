unit Utils.Feedback;

// The feedback when a code is read: a short sound and a vibration.
// Mobile: the sound is scan.wav (Sounds\make_scan_sound.py), deployed in the documents
// folder of the app; no sound in silent mode, on Android it follows the media volume.

interface

/// <summary>The sound and/or the vibration of a code read (in the main thread)</summary>
procedure ScanFeedback(const ASound, AVibrate: Boolean);
/// <summary>The device can vibrate (mobile)</summary>
function CanVibrate: Boolean;

implementation

uses
  System.SysUtils, System.IOUtils
{$IF Defined(ANDROID)}
, Androidapi.Helpers, Androidapi.JNI.JavaTypes, Androidapi.JNI.Media, Androidapi.JNI.Os
, Androidapi.JNI.GraphicsContentViewText, Androidapi.JNIBridge
{$ELSEIF Defined(IOS)}
, iOSapi.AudioToolbox, iOSapi.UIKit, iOSapi.Foundation, Macapi.CoreFoundation, Macapi.Helpers, Macapi.ObjectiveC
{$ELSEIF Defined(MACOS)}
, Macapi.Helpers
{$ELSEIF Defined(MSWINDOWS)}
, Winapi.Windows
{$ENDIF}
;

function SoundFile: string;
begin
  Result := TPath.Combine(TPath.GetDocumentsPath, 'scan.wav');
end;

{$IF Defined(ANDROID)}
const
  VIBRATION_MS = 120;
  VIBRATION_AMPLITUDE = 255; // the strongest (1..255)

var
  GPlayer: JMediaPlayer; // prepared once, played again from the start

procedure PlaySound;
begin
  // the media stream (the volume keys while the app is open), but silent with the ringer off
  var LAudio := TJAudioManager.Wrap(TAndroidHelper.Context.getSystemService(TJContext.JavaClass.AUDIO_SERVICE));
  if LAudio.getRingerMode <> TJAudioManager.JavaClass.RINGER_MODE_NORMAL then
    Exit;
  if GPlayer = nil then
  begin
    GPlayer := TJMediaPlayer.JavaClass.init;
    GPlayer.setAudioStreamType(TJAudioManager.JavaClass.STREAM_MUSIC);
    GPlayer.setDataSource(StringToJString(SoundFile));
    GPlayer.prepare;
  end;
  GPlayer.seekTo(0);
  GPlayer.start;
end;

procedure Vibrate;
begin
  // the Vibrator (permission VIBRATE): stronger than the haptic feedback of a View,
  // which follows the touch feedback intensity of the system
  var LVibrator := TJVibrator.Wrap(TAndroidHelper.Context.getSystemService(TJContext.JavaClass.VIBRATOR_SERVICE));
  if (LVibrator = nil) or not LVibrator.hasVibrator then
    Exit;
  if TOSVersion.Check(8) then // VibrationEffect: API 26
    LVibrator.vibrate(TJVibrationEffect.JavaClass.createOneShot(VIBRATION_MS, VIBRATION_AMPLITUDE))
  else
    LVibrator.vibrate(VIBRATION_MS);
end;

{$ELSEIF Defined(IOS)}
var
  GHaptic: UINotificationFeedbackGenerator;
  GSound: SystemSoundID; // 0: not created yet

procedure PlaySound;
begin
  // a system sound: silent with the ring/silent switch off
  if GSound = 0 then
    AudioServicesCreateSystemSoundID(
      CFURLRef(NSObjectToID(TNSURL.OCClass.fileURLWithPath(StrToNSStr(SoundFile)))), @GSound);
  AudioServicesPlaySystemSound(GSound);
end;

procedure Vibrate;
begin
  if GHaptic = nil then
    GHaptic := TUINotificationFeedbackGenerator.Create;
  GHaptic.notificationOccurred(UINotificationFeedbackTypeSuccess);
end;

{$ELSEIF Defined(MACOS)}
const
  _PU = {$IFDEF UNDERSCOREIMPORTNAME}'_'{$ELSE}''{$ENDIF}; // as in the RTL imports

procedure NSBeep; cdecl; external '/System/Library/Frameworks/AppKit.framework/AppKit' name _PU + 'NSBeep';

procedure PlaySound;
begin
  NSBeep;
end;

procedure Vibrate;
begin
end;

{$ELSEIF Defined(MSWINDOWS)}
procedure PlaySound;
begin
  MessageBeep(MB_OK);
end;

procedure Vibrate;
begin
end;
{$ENDIF}

function CanVibrate: Boolean;
begin
{$IF Defined(ANDROID) or Defined(IOS)}
  Result := True;
{$ELSE}
  Result := False;
{$ENDIF}
end;

procedure ScanFeedback(const ASound, AVibrate: Boolean);
begin
  // feedback only: never in the way of the scan
  try
    if ASound then
      PlaySound;
    if AVibrate and CanVibrate then
      Vibrate;
  except
  end;
end;

end.
