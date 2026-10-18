unit Frames.Settings;

// The formats to read: one row per format group of Data.Settings, built at runtime.

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Layouts, FMX.Controls.Presentation
, FrameStand
;

type
  TSettingsFrame = class(TFrame)
    CardRectangle: TRectangle;
    HeaderRow: TLayout;
    CloseButton: TCircle;
    CloseIcon: TPath;
    TitleLabel: TLabel;
    SubtitleLabel: TLabel;
    FooterRow: TLayout;
    AllButton: TRectangle;
    AllLabel: TLabel;
    DoneButton: TRectangle;
    DoneLabel: TLabel;
    GroupsScrollBox: TVertScrollBox;
    procedure FrameClick(Sender: TObject);
    procedure CloseButtonClick(Sender: TObject);
    procedure DoneButtonClick(Sender: TObject);
    procedure AllButtonClick(Sender: TObject);
    procedure PressableMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure PressableMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure PressableMouseLeave(Sender: TObject);
  private
    { Private declarations }
    [FrameInfo] FI: TFrameInfo<TSettingsFrame>;
    FChanged: Boolean;
    procedure BuildRows;
    procedure UpdateRow(const ARow: TRectangle);
    procedure UpdateRows;
    procedure RowClick(Sender: TObject);
  public
    { Public declarations }
    procedure AfterConstruction; override;
    /// <summary>Applies the changes (if any) and hides the frame</summary>
    procedure Close;
  end;

implementation

{$R *.fmx}

uses
  Data.Main, Data.Settings, UI.Theme
;

const
  ROW_HEIGHT = 48;

{ TSettingsFrame }

procedure TSettingsFrame.AfterConstruction;
begin
  inherited;
  BuildRows;
end;

procedure TSettingsFrame.BuildRows;
begin
  for var I := 0 to High(FORMAT_GROUPS) do
  begin
    var LGroup := FORMAT_GROUPS[I];

    var LRow := TRectangle.Create(Self);
    LRow.Parent := GroupsScrollBox;
    LRow.Align := TAlignLayout.Top;
    LRow.Position.Y := I * (ROW_HEIGHT + 6); // the order of the groups
    LRow.Height := ROW_HEIGHT;
    LRow.Margins.Bottom := 6;
    LRow.Fill.Color := COLOR_SURFACE_2;
    LRow.Stroke.Kind := TBrushKind.None;
    LRow.XRadius := 12;
    LRow.YRadius := 12;
    LRow.Cursor := crHandPoint;
    LRow.TagString := LGroup.Key;
    LRow.OnClick := RowClick;
    LRow.OnMouseDown := PressableMouseDown;
    LRow.OnMouseUp := PressableMouseUp;
    LRow.OnMouseLeave := PressableMouseLeave;

    var LCheck := TCircle.Create(Self);
    LCheck.Parent := LRow;
    LCheck.Align := TAlignLayout.Right;
    LCheck.Width := 24;
    LCheck.Margins.Rect := RectF(0, 12, 14, 12);
    LCheck.HitTest := False;
    LCheck.Stroke.Thickness := 2;

    var LCheckIcon := TPath.Create(Self);
    LCheckIcon.Parent := LCheck;
    LCheckIcon.Align := TAlignLayout.Center;
    LCheckIcon.SetBounds(0, 0, 14, 14);
    LCheckIcon.WrapMode := TPathWrapMode.Fit;
    LCheckIcon.Data.Data := ICON_CHECK;
    LCheckIcon.Fill.Color := COLOR_ON_ACCENT;
    LCheckIcon.Stroke.Kind := TBrushKind.None;
    LCheckIcon.HitTest := False;

    var LLabel := TLabel.Create(Self);
    LLabel.Parent := LRow;
    LLabel.Align := TAlignLayout.Client;
    LLabel.Margins.Left := 16;
    LLabel.HitTest := False;
    LLabel.StyledSettings := [TStyledSetting.Family];
    LLabel.TextSettings.Font.Size := 16;
    LLabel.TextSettings.FontColor := COLOR_TEXT;
    LLabel.TextSettings.WordWrap := False;
    LLabel.Text := LGroup.Name;
  end;
  UpdateRows;
end;

procedure TSettingsFrame.UpdateRow(const ARow: TRectangle);
begin
  var LEnabled := MainDM.Settings.IsEnabled(ARow.TagString);
  for var LChild in ARow.Children do
    if LChild is TCircle then
    begin
      var LCheck := TCircle(LChild);
      if LEnabled then
      begin
        LCheck.Fill.Kind := TBrushKind.Solid;
        LCheck.Fill.Color := COLOR_ACCENT;
        LCheck.Stroke.Kind := TBrushKind.None;
      end
      else
      begin
        LCheck.Fill.Kind := TBrushKind.None;
        LCheck.Stroke.Kind := TBrushKind.Solid;
        LCheck.Stroke.Color := COLOR_TEXT_2;
      end;
      for var LIcon in LCheck.Children do
        if LIcon is TPath then
          TPath(LIcon).Visible := LEnabled;
    end;
end;

procedure TSettingsFrame.UpdateRows;
begin
  for var LChild in GroupsScrollBox.Content.Children do
    if LChild is TRectangle then
      UpdateRow(TRectangle(LChild));
end;

procedure TSettingsFrame.RowClick(Sender: TObject);
begin
  var LRow := Sender as TRectangle;
  var LEnabled := MainDM.Settings.IsEnabled(LRow.TagString);
  // at least one group: nothing to read otherwise
  if LEnabled and (MainDM.Settings.EnabledCount = 1) then
    Exit;
  MainDM.Settings.SetEnabled(LRow.TagString, not LEnabled);
  FChanged := True;
  UpdateRow(LRow);
end;

procedure TSettingsFrame.AllButtonClick(Sender: TObject);
begin
  for var LGroup in FORMAT_GROUPS do
    MainDM.Settings.SetEnabled(LGroup.Key, True);
  FChanged := True;
  UpdateRows;
end;

procedure TSettingsFrame.Close;
begin
  if FChanged then
  begin
    MainDM.ApplySettings;
    FChanged := False;
  end;
  FI.Hide;
end;

procedure TSettingsFrame.CloseButtonClick(Sender: TObject);
begin
  Close;
end;

procedure TSettingsFrame.DoneButtonClick(Sender: TObject);
begin
  Close;
end;

procedure TSettingsFrame.FrameClick(Sender: TObject);
begin
  Close;
end;

procedure TSettingsFrame.PressableMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  SetPressed(Sender, True);
end;

procedure TSettingsFrame.PressableMouseLeave(Sender: TObject);
begin
  SetPressed(Sender, False);
end;

procedure TSettingsFrame.PressableMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  SetPressed(Sender, False);
end;

end.
