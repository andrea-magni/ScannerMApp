unit Frames.Info;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls
, FrameStand, FMX.Layouts, FMX.Objects, FMX.Controls.Presentation
;

type
  TInfoFrame = class(TFrame)
    CardRectangle: TRectangle;
    HeaderRow: TLayout;
    CloseButton: TCircle;
    CloseIcon: TPath;
    TitleLabel: TLabel;
    AppRow: TLayout;
    AppIconCircle: TCircle;
    AppIcon: TPath;
    AppTextLayout: TLayout;
    AppNameLabel: TLabel;
    AppDescLabel: TLabel;
    BuiltWithLabel: TLabel;
    Row1Layout: TLayout;
    Row1Tile: TRectangle;
    Image4: TImage;
    Row1TextLayout: TLayout;
    Row1TitleLabel: TLabel;
    Row1SubtitleLabel: TLabel;
    Row2Layout: TLayout;
    Row2Tile: TRectangle;
    Image1: TImage;
    Row2TextLayout: TLayout;
    Row2TitleLabel: TLabel;
    Row2SubtitleLabel: TLabel;
    Row3Layout: TLayout;
    Row3Tile: TRectangle;
    Image2: TImage;
    Row3TextLayout: TLayout;
    Row3TitleLabel: TLabel;
    Row3SubtitleLabel: TLabel;
    Row4Layout: TLayout;
    Row4Tile: TRectangle;
    Image3: TImage;
    Row4TextLayout: TLayout;
    Row4TitleLabel: TLabel;
    Row4SubtitleLabel: TLabel;
    procedure FrameClick(Sender: TObject);
    procedure CloseButtonClick(Sender: TObject);
    procedure PressableMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure PressableMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure PressableMouseLeave(Sender: TObject);
  private
    { Private declarations }
    [FrameInfo] FI: TFrameInfo<TInfoFrame>;
  public
    { Public declarations }
    procedure AfterConstruction; override;
  end;

implementation

{$R *.fmx}

uses
  Data.Main, UI.Theme
, System.Messaging
;

{ TInfoFrame }

procedure TInfoFrame.AfterConstruction;
begin
  inherited;

  TMessageManager.DefaultManager.SubscribeToMessage(THardwareBackMessage
  , procedure(const Sender: TObject; const M: TMessage)
    begin
      FI.Hide;
    end
  );
end;

procedure TInfoFrame.CloseButtonClick(Sender: TObject);
begin
  FI.Hide;
end;

procedure TInfoFrame.FrameClick(Sender: TObject);
begin
  FI.Hide;
end;

procedure TInfoFrame.PressableMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  SetPressed(Sender, True);
end;

procedure TInfoFrame.PressableMouseLeave(Sender: TObject);
begin
  SetPressed(Sender, False);
end;

procedure TInfoFrame.PressableMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  SetPressed(Sender, False);
end;

end.
