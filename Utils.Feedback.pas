unit Utils.Feedback;

// The feedback when a code is read: a short sound and a vibration (haptic feedback).
// Both follow the system: no sound in silent mode, no vibration when the haptics are off.

interface

/// <summary>The sound and/or the vibration of a code read (in the main thread)</summary>
procedure ScanFeedback(const ASound, AVibrate: Boolean);
/// <summary>The device can vibrate (mobile)</summary>
function CanVibrate: Boolean;

implementation

uses
  System.SysUtils
{$IF Defined(ANDROID)}
, Androidapi.Helpers, Androidapi.JNI.Media, FMX.Helpers.Android
{$ELSEIF Defined(IOS)}
, iOSapi.AudioToolbox, iOSapi.UIKit
{$ELSEIF Defined(MACOS)}
, Macapi.Helpers
{$ELSEIF Defined(MSWINDOWS)}
, Winapi.Windows
{$ENDIF}
;

{$IF Defined(ANDROID)}
const
  HAPTIC_LONG_PRESS = 0; // HapticFeedbackConstants.LONG_PRESS (not imported by the RTL)

var
  GTone: JToneGenerator; // created once: creating it takes a while

procedure PlaySound;
begin
  if GTone = nil then
    // the notification stream: silent with the ringer off
    GTone := TJToneGenerator.JavaClass.init(TJAudioManager.JavaClass.STREAM_NOTIFICATION, 80);
  GTone.startTone(TJToneGenerator.JavaClass.TONE_PROP_BEEP, 120);
end;

procedure Vibrate;
begin
  // a View method: the Android UI thread
  CallInUIThread(
    procedure
    begin
      TAndroidHelper.Activity.getWindow.getDecorView.performHapticFeedback(HAPTIC_LONG_PRESS);
    end);
end;

{$ELSEIF Defined(IOS)}
const
  SOUND_TINK = 1057; // a short system sound, silent with the ring/silent switch off

var
  GHaptic: UINotificationFeedbackGenerator;

procedure PlaySound;
begin
  AudioServicesPlaySystemSound(SOUND_TINK);
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
