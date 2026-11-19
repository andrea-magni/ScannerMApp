unit Utils.ContentActions;

// What can be done with the content of a code: open a link, call a number, write an
// email or a message, show a place on a map, add a contact or an event. Only the
// kinds below are offered (a code never makes the app launch anything else).
// Icons: Material Icons path data (24x24 viewbox, Apache License 2.0).

interface

uses
  System.SysUtils, FMX.Controls;

type
  TContentKind = (None, Link, Email, Phone, Sms, Geo, Contact, Event);

  TContentAction = record
    Kind: TContentKind;
    Caption: string;  // for the button: Open, Email, Call...
    Icon: string;     // SVG path data
    Target: string;   // the URI (or the vCard / iCalendar text)
    function IsAvailable: Boolean;
  end;

/// <summary>The action for the text of a code (Kind = None: nothing to open)</summary>
function ContentAction(const AText: string): TContentAction;
/// <summary>Opens the content with the app of the system (browser, dialer, mail,
/// maps, contacts, calendar); False when nothing can handle it. AControl: where the
/// share sheet of iOS points to on iPad (contacts and events)</summary>
function OpenContent(const AAction: TContentAction; const AControl: TControl = nil): Boolean;

implementation

uses
  System.Classes, System.IOUtils, System.NetEncoding, System.StrUtils
{$IFDEF ANDROID}
, Androidapi.Helpers, Androidapi.JNI.GraphicsContentViewText, Androidapi.JNI.JavaTypes
, Androidapi.JNI.Net, Androidapi.JNI.App, Androidapi.JNI.Support
{$ENDIF}
{$IFDEF MSWINDOWS}
, Winapi.Windows, Winapi.ShellAPI
{$ENDIF}
{$IFDEF IOS}
, iOSapi.Foundation, iOSapi.Helpers, Macapi.Helpers, FMX.Platform, FMX.MediaLibrary
{$ELSEIF Defined(MACOS)}
, Macapi.AppKit, Macapi.Foundation, Macapi.Helpers
{$ENDIF}
;

const
  ICON_OPEN = 'M19 19H5V5h7V3H5c-1.11 0-2 .9-2 2v14c0 1.1.89 2 2 2h14c1.1 0 2-.9 2-2v-7h-2v7zM14 3v2h3.59l-9.83 9.83 1.41 1.41L19 6.41V10h2V3h-7z';
  ICON_EMAIL = 'M20 4H4c-1.1 0-1.99.9-1.99 2L2 18c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 4l-8 5-8-5V6l8 5 8-5v2z';
  ICON_CALL = 'M6.62 10.79c1.44 2.83 3.76 5.14 6.59 6.59l2.2-2.2c.27-.27.67-.36 1.02-.24 1.12.37 2.33.57 3.57.57.55 0 1 .45 1 1V20c0 .55-.45 1-1 1-9.39 0-17-7.61-17-17 0-.55.45-1 1-1h3.5c.55 0 1 .45 1 1 0 1.25.2 2.45.57 3.57.11.35.03.74-.25 1.02l-2.2 2.2z';
  ICON_SMS = 'M20 2H4c-1.1 0-1.99.9-1.99 2L2 22l4-4h14c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zM9 11H7V9h2v2zm4 0h-2V9h2v2zm4 0h-2V9h2v2z';
  ICON_PLACE = 'M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z';
  ICON_CONTACT = 'M15 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm-9-2V7H4v3H1v2h3v3h2v-3h3v-2H6zm9 4c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z';
  ICON_EVENT = 'M17 12h-5v5h5v-5zM16 1v2H8V1H6v2H5c-1.11 0-1.99.9-1.99 2L3 19c0 1.1.89 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2h-1V1h-2zm3 18H5V8h14v11z';

{ TContentAction }

function TContentAction.IsAvailable: Boolean;
begin
  Result := Kind <> TContentKind.None;
end;

function MakeAction(const AKind: TContentKind; const ACaption, AIcon, ATarget: string): TContentAction;
begin
  Result.Kind := AKind;
  Result.Caption := ACaption;
  Result.Icon := AIcon;
  Result.Target := ATarget;
end;

function Encode(const AValue: string): string;
begin
  Result := TNetEncoding.URL.Encode(AValue);
end;

/// <summary>The fields of MECARD / MATMSG / SMSTO style codes (KEY:value;KEY:value;;)</summary>
function FieldOf(const AText, AKey: string): string;
begin
  Result := '';
  var LPos := Pos(';' + UpperCase(AKey) + ':', ';' + UpperCase(AText));
  if LPos = 0 then
    Exit;
  var LStart := LPos + Length(AKey) + 1; // ';' added in front, ':' after the key
  var LEnd := LStart;
  while (LEnd <= Length(AText)) and (AText[LEnd] <> ';') do
  begin
    if (AText[LEnd] = '\') and (LEnd < Length(AText)) then
      Inc(LEnd); // escaped character
    Inc(LEnd);
  end;
  Result := Copy(AText, LStart, LEnd - LStart).Replace('\;', ';').Replace('\:', ':').Replace('\,', ',').Replace('\\', '\');
end;

const
  // MECARD field -> vCard line prefix (ADR: the street in the third component)
  MECARD_FIELDS: array[0..5, 0..1] of string = (
    ('TEL', 'TEL:'), ('EMAIL', 'EMAIL:'), ('URL', 'URL:'), ('ADR', 'ADR:;;'), ('NOTE', 'NOTE:'), ('ORG', 'ORG:'));

function MeCardToVCard(const AText: string): string;
var
  LBody: string;
begin
  // MECARD:N:Doe,John;TEL:123;EMAIL:a@b.c;URL:...;ADR:...;NOTE:...;;
  LBody := Copy(AText, Length('MECARD:') + 1, MaxInt);
  var LName := FieldOf(LBody, 'N');
  var LParts := LName.Split([',']);
  var LFamily := '';
  var LGiven := '';
  if Length(LParts) > 0 then
    LFamily := LParts[0].Trim;
  if Length(LParts) > 1 then
    LGiven := LParts[1].Trim;
  Result := 'BEGIN:VCARD'#13#10'VERSION:3.0'#13#10 +
    'N:' + LFamily + ';' + LGiven + ';;;'#13#10 +
    'FN:' + (LGiven + ' ' + LFamily).Trim + #13#10;
  for var I := Low(MECARD_FIELDS) to High(MECARD_FIELDS) do
  begin
    var LValue := FieldOf(LBody, MECARD_FIELDS[I, 0]);
    if LValue <> '' then
      Result := Result + MECARD_FIELDS[I, 1] + LValue + #13#10;
  end;
  Result := Result + 'END:VCARD'#13#10;
end;

function ContentAction(const AText: string): TContentAction;
var
  LText: string;
begin
  Result := MakeAction(TContentKind.None, '', '', '');
  LText := AText.Trim;
  if LText = '' then
    Exit;

  if StartsText('http://', LText) or StartsText('https://', LText) then
    Result := MakeAction(TContentKind.Link, 'Open', ICON_OPEN, LText)
  else if StartsText('www.', LText) and not LText.Contains(' ') then
    Result := MakeAction(TContentKind.Link, 'Open', ICON_OPEN, 'https://' + LText)
  else if StartsText('market://', LText) then
    Result := MakeAction(TContentKind.Link, 'Open', ICON_OPEN, LText)
  else if StartsText('mailto:', LText) then
    Result := MakeAction(TContentKind.Email, 'Email', ICON_EMAIL, LText)
  else if StartsText('MATMSG:', LText) then
  begin
    // MATMSG:TO:a@b.c;SUB:subject;BODY:text;;
    var LBody := Copy(LText, Length('MATMSG:') + 1, MaxInt);
    Result := MakeAction(TContentKind.Email, 'Email', ICON_EMAIL,
      'mailto:' + FieldOf(LBody, 'TO') + '?subject=' + Encode(FieldOf(LBody, 'SUB')) +
      '&body=' + Encode(FieldOf(LBody, 'BODY')));
  end
  else if StartsText('tel:', LText) then
    Result := MakeAction(TContentKind.Phone, 'Call', ICON_CALL, LText)
  else if StartsText('smsto:', LText) then
  begin
    // SMSTO:number:message
    var LParts := Copy(LText, Length('smsto:') + 1, MaxInt).Split([':'], 2);
    var LTarget := 'smsto:' + LParts[0];
    if Length(LParts) > 1 then
      LTarget := LTarget + '?body=' + Encode(LParts[1]);
    Result := MakeAction(TContentKind.Sms, 'Message', ICON_SMS, LTarget);
  end
  else if StartsText('sms:', LText) then
    Result := MakeAction(TContentKind.Sms, 'Message', ICON_SMS, LText)
  else if StartsText('geo:', LText) then
    Result := MakeAction(TContentKind.Geo, 'Map', ICON_PLACE, LText)
  else if StartsText('BEGIN:VCARD', LText) then
    Result := MakeAction(TContentKind.Contact, 'Contact', ICON_CONTACT, LText)
  else if StartsText('MECARD:', LText) then
    Result := MakeAction(TContentKind.Contact, 'Contact', ICON_CONTACT, MeCardToVCard(LText))
  else if StartsText('BEGIN:VCALENDAR', LText) then
    Result := MakeAction(TContentKind.Event, 'Event', ICON_EVENT, LText)
  else if StartsText('BEGIN:VEVENT', LText) then
    Result := MakeAction(TContentKind.Event, 'Event', ICON_EVENT,
      'BEGIN:VCALENDAR'#13#10'VERSION:2.0'#13#10 + LText + #13#10'END:VCALENDAR'#13#10);
end;

/// <summary>vCard and iCalendar content: a file the system apps can open</summary>
function SaveToTempFile(const AContent, AExtension: string): string;
begin
  Result := TPath.Combine(TPath.GetTempPath, 'scannermapp' + AExtension);
  TFile.WriteAllText(Result, AContent, TEncoding.UTF8);
end;

/// <summary>geo:lat,lon (desktop: a map in the browser)</summary>
function GeoToMapsURL(const AGeo: string): string;
begin
  // geo:lat,lon[,alt][;u=...][?q=...]
  var LLatLon := Copy(AGeo, Length('geo:') + 1, MaxInt).Split(['?', ';'])[0].Split([',']);
  if Length(LLatLon) < 2 then
    Exit('https://www.openstreetmap.org/');
  Result := 'https://www.openstreetmap.org/?mlat=' + Encode(LLatLon[0].Trim) +
    '&mlon=' + Encode(LLatLon[1].Trim) + '#map=16/' + Encode(LLatLon[0].Trim) + '/' + Encode(LLatLon[1].Trim);
end;

{$IFDEF ANDROID}
function OpenContentAndroid(const AAction: TContentAction): Boolean;
var
  LIntent: JIntent;
begin
  case AAction.Kind of
    TContentKind.Phone:
      LIntent := TJIntent.JavaClass.init(TJIntent.JavaClass.ACTION_DIAL,
        TJnet_Uri.JavaClass.parse(StringToJString(AAction.Target)));
    TContentKind.Email, TContentKind.Sms:
      LIntent := TJIntent.JavaClass.init(TJIntent.JavaClass.ACTION_SENDTO,
        TJnet_Uri.JavaClass.parse(StringToJString(AAction.Target)));
    TContentKind.Contact, TContentKind.Event:
    begin
      // a file of the app cache, shared through the FileProvider of the app
      var LExt := '.vcf';
      var LType := 'text/x-vcard';
      if AAction.Kind = TContentKind.Event then
      begin
        LExt := '.ics';
        LType := 'text/calendar';
      end;
      var LFile := TJFile.JavaClass.init(StringToJString(SaveToTempFile(AAction.Target, LExt)));
      LIntent := TJIntent.JavaClass.init(TJIntent.JavaClass.ACTION_VIEW);
      LIntent.setDataAndType(TAndroidHelper.JFileToJURI(LFile), StringToJString(LType));
      LIntent.addFlags(TJIntent.JavaClass.FLAG_GRANT_READ_URI_PERMISSION);
    end;
  else // Link, Geo
    LIntent := TJIntent.JavaClass.init(TJIntent.JavaClass.ACTION_VIEW,
      TJnet_Uri.JavaClass.parse(StringToJString(AAction.Target)));
  end;
  try
    TAndroidHelper.Activity.startActivity(LIntent);
    Result := True;
  except
    Result := False; // ActivityNotFoundException: no app for it
  end;
end;
{$ENDIF}

{$IFDEF MSWINDOWS}
function OpenContentWindows(const AAction: TContentAction): Boolean;
var
  LTarget: string;
begin
  case AAction.Kind of
    TContentKind.Contact:
      LTarget := SaveToTempFile(AAction.Target, '.vcf');
    TContentKind.Event:
      LTarget := SaveToTempFile(AAction.Target, '.ics');
    TContentKind.Geo:
      LTarget := GeoToMapsURL(AAction.Target);
  else
    LTarget := AAction.Target;
  end;
  Result := ShellExecute(0, 'open', PChar(LTarget), nil, nil, SW_SHOWNORMAL) > 32;
end;
{$ENDIF}

{$IF Defined(IOS) or Defined(MACOS)}
function OpenContentApple(const AAction: TContentAction; const AControl: TControl): Boolean;
var
  LTarget: string;
begin
  Result := False;
  case AAction.Kind of
    TContentKind.Contact, TContentKind.Event:
    begin
      // no URL opens them: a .vcf / .ics file, for the app the user picks
      if AAction.Kind = TContentKind.Contact then
        LTarget := SaveToTempFile(AAction.Target, '.vcf')
      else
        LTarget := SaveToTempFile(AAction.Target, '.ics');
{$IFDEF IOS}
      // the share sheet: Contacts, Calendar, Files, Mail...
      var LShare: IFMXShareSheetActionsService;
      if TPlatformServices.Current.SupportsPlatformService(IFMXShareSheetActionsService, LShare) then
      begin
        LShare.Share(AControl, '', [LTarget]);
        Result := True;
      end;
{$ELSE}
      // macOS: the default app of the file (Contacts, Calendar)
      Result := TNSWorkspace.Wrap(TNSWorkspace.OCClass.sharedWorkspace).openURL(
        TNSURL.Wrap(TNSURL.OCClass.fileURLWithPath(StrToNSStr(LTarget))));
{$ENDIF}
      Exit;
    end;
    TContentKind.Geo:
      LTarget := 'https://maps.apple.com/?ll=' + Copy(AAction.Target, Length('geo:') + 1, MaxInt).Split(['?', ';'])[0];
  else
    LTarget := AAction.Target;
  end;
  var LURL := TNSURL.Wrap(TNSURL.OCClass.URLWithString(StrToNSStr(LTarget)));
  if LURL = nil then
    Exit;
{$IFDEF IOS}
  // openURL(url) without options does nothing since iOS 18
  TiOSHelper.SharedApplication.openURL(LURL, nil, nil);
  Result := True;
{$ELSE}
  Result := TNSWorkspace.Wrap(TNSWorkspace.OCClass.sharedWorkspace).openURL(LURL);
{$ENDIF}
end;
{$ENDIF}

function OpenContent(const AAction: TContentAction; const AControl: TControl): Boolean;
begin
  Result := False;
  if not AAction.IsAvailable then
    Exit;
  try
{$IF Defined(ANDROID)}
    Result := OpenContentAndroid(AAction);
{$ELSEIF Defined(MSWINDOWS)}
    Result := OpenContentWindows(AAction);
{$ELSEIF Defined(IOS) or Defined(MACOS)}
    Result := OpenContentApple(AAction, AControl);
{$ENDIF}
  except
    Result := False;
  end;
end;

end.
