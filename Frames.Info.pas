unit Frames.Info;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls
, FrameStand, FMX.Layouts, FMX.Objects, FMX.Controls.Presentation
;

type
  TInfoFrame = class(TFrame)
    GridPanelLayout1: TGridPanelLayout;
    ZXingLayout: TLayout;
    TFrameStandLayout: TLayout;
    Image1: TImage;
    Image2: TImage;
    Label1: TLabel;
    Label2: TLabel;
    AndreaMagniLayout: TLayout;
    Image3: TImage;
    Label3: TLabel;
    DelphiLayout: TLayout;
    Image4: TImage;
    Label4: TLabel;
    Label5: TLabel;
    BackgroundRectangle: TRectangle;
    procedure FrameClick(Sender: TObject);
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
  Data.Main
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

procedure TInfoFrame.FrameClick(Sender: TObject);
begin
  FI.Hide;
end;

end.
