unit Frames.ScanResult;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Layouts, FMX.Controls.Presentation,
  Data.Bind.EngExt, Fmx.Bind.DBEngExt, System.Rtti, System.Bindings.Outputs,
  Fmx.Bind.Editors, Data.Bind.Components, Data.Bind.DBScope
, FrameStand, System.Actions, FMX.ActnList, FMX.StdActns,
  FMX.MediaLibrary.Actions, Fmx.Bind.Navigator
;

type
  TScanResultFrame = class(TFrame)
    ResultLayout: TLayout;
    ResultLabel: TLabel;
    KindLabel: TLabel;
    BindSourceDB1: TBindSourceDB;
    BindingsList1: TBindingsList;
    InfoBottomLayout: TLayout;
    TimeStampLabel: TLabel;
    LinkPropertyToFieldText: TLinkPropertyToField;
    LinkPropertyToFieldText2: TLinkPropertyToField;
    LinkPropertyToFieldText3: TLinkPropertyToField;
    ShareButton: TButton;
    ActionList1: TActionList;
    ShareAction: TShowShareSheetAction;
    FrameLayout: TLayout;
    InfoTopLayout: TLayout;
    Label1: TLabel;
    ScanCountLabel: TLabel;
    LinkPropertyToFieldText4: TLinkPropertyToField;
    BackgroundRectangle: TRectangle;
    FrameImage: TImage;
    LinkPropertyToFieldBitmap: TLinkPropertyToField;
    ActionsLayout: TGridLayout;
    DeleteButton: TButton;
    DeleteAction: TAction;
    procedure FrameClick(Sender: TObject);
    procedure ShareActionBeforeExecute(Sender: TObject);
    procedure DeleteActionExecute(Sender: TObject);
  private
    { Private declarations }
    [FrameInfo] FI: TFrameInfo<TScanResultFrame>;
  protected
  public
    { Public declarations }
    procedure AfterConstruction; override;
  end;

implementation

{$R *.fmx}

uses
  System.Messaging
, Data.Main
;

procedure TScanResultFrame.AfterConstruction;
begin
  inherited;

  TMessageManager.DefaultManager.SubscribeToMessage(THardwareBackMessage
  , procedure(const Sender: TObject; const M: TMessage)
    begin
      FI.Hide;
    end
  );
end;

procedure TScanResultFrame.DeleteActionExecute(Sender: TObject);
begin
  BindSourceDB1.DataSet.Delete;
  FI.Hide;
end;

procedure TScanResultFrame.FrameClick(Sender: TObject);
begin
  FI.Hide;
end;

procedure TScanResultFrame.ShareActionBeforeExecute(Sender: TObject);
begin
  ShareAction.TextMessage := MainDM.DataTable.FieldByName('Value').AsString;
end;

end.
