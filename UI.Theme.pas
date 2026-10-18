unit UI.Theme;

// Palette and icons shared by the app's forms and frames.
// Icons: Material Icons path data (24x24 viewbox, Apache License 2.0).

interface

uses
  System.UITypes, FMX.Types, FMX.Controls;

const
  COLOR_BACKGROUND  = TAlphaColor($FF101216);
  COLOR_SURFACE     = TAlphaColor($FF1A1D23);
  COLOR_SURFACE_2   = TAlphaColor($FF262A33);
  COLOR_ACCENT      = TAlphaColor($FF2EE6A6);
  COLOR_ON_ACCENT   = TAlphaColor($FF062016);
  COLOR_ACCENT_TINT = TAlphaColor($FF16362C);
  COLOR_TEXT        = TAlphaColor($FFF2F4F7);
  COLOR_TEXT_2      = TAlphaColor($FF9AA3AF);
  COLOR_DANGER      = TAlphaColor($FFFF6B6B);

  ICON_QR = 'M9.5 6.5v3h-3v-3h3M11 5H5v6h6V5zm-1.5 9.5v3h-3v-3h3M11 13H5v6h6v-6zm6.5-6.5v3h-3v-3h3M19 5h-6v6h6V5zm-6 8h1.5v1.5H13V13zm1.5 1.5H16V16h-1.5v-1.5zM16 13h1.5v1.5H16V13zm-3 3h1.5v1.5H13V16zm1.5 1.5H16V19h-1.5v-1.5zM16 16h1.5v1.5H16V16zm1.5-1.5H19V16h-1.5v-1.5zm0 3H19V19h-1.5v-1.5zM22 7h-2V4h-3V2h5v5zm0 15v-5h-2v3h-3v2h5zM2 22h5v-2H4v-3H2v5zM2 2v5h2V4h3V2H2z';
  ICON_STOP = 'M6 6h12v12H6z';
  ICON_COPY = 'M16 1H4c-1.1 0-2 .9-2 2v14h2V3h12V1zm3 4H8c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h11c1.1 0 2-.9 2-2V7c0-1.1-.9-2-2-2zm0 16H8V7h11v14z';
  ICON_CHECK = 'M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z';

/// <summary>Visual feedback for controls used as buttons (OnMouseDown/OnMouseUp/OnMouseLeave)</summary>
procedure SetPressed(const ASender: TObject; const APressed: Boolean);

{$IFDEF ANDROID}
/// <summary>Light status/navigation bar icons, for a dark background (Android 11+)</summary>
procedure UseLightSystemBarIcons;
{$ENDIF}

implementation

uses
  System.SysUtils, System.Math
{$IFDEF ANDROID}
, Androidapi.Helpers, Androidapi.JNI.App, Androidapi.JNI.GraphicsContentViewText, Androidapi.JNI.Os
, FMX.Helpers.Android
{$ENDIF}
;

procedure SetPressed(const ASender: TObject; const APressed: Boolean);
begin
  if ASender is TControl then
    TControl(ASender).Opacity := IfThen(APressed, 0.6, 1);
end;

{$IFDEF ANDROID}
procedure UseLightSystemBarIcons;
begin
  if TJBuild_VERSION.JavaClass.SDK_INT < 30 then
    Exit;

  CallInUIThread(
    procedure
    begin
      var LController := TAndroidHelper.Activity.getWindow.getInsetsController;
      if Assigned(LController) then
        // appearance = 0 within the mask: status and navigation bar icons are drawn light
        LController.setSystemBarsAppearance(0,
          TJWindowInsetsController.JavaClass.APPEARANCE_LIGHT_STATUS_BARS
          or TJWindowInsetsController.JavaClass.APPEARANCE_LIGHT_NAVIGATION_BARS);
    end
  );
end;
{$ENDIF}

end.
