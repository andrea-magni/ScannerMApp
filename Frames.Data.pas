unit Frames.Data;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  Data.Main, FMX.ListView.Types, FMX.ListView.Appearances,
  FMX.ListView.Adapters.Base, FMX.ListView, System.Rtti,
  System.Bindings.Outputs, Fmx.Bind.Editors, Data.Bind.EngExt,
  Fmx.Bind.DBEngExt, Data.Bind.Components, Data.Bind.DBScope, FMX.Objects
, FrameStand
, Frames.ScanResult
;

type
  // Interposer: dark item colors, regardless of the platform style
  TListView = class(FMX.ListView.TListView)
  protected
    procedure ApplyStyle; override;
  end;

  TDataFrame = class(TFrame)
    DataListView: TListView;
    BindSourceDB1: TBindSourceDB;
    BindingsList1: TBindingsList;
    LinkListControlToField1: TLinkListControlToField;
    procedure DataListViewItemClick(const Sender: TObject;
      const AItem: TListViewItem);
  private
    { Private declarations }
  protected
    [FrameStandAttribute] FS: TFrameStand;
    FScanResultFI: TFrameInfo<TScanResultFrame>;
    FOverlayParent: TFmxObject;
  public
    { Public declarations }
    procedure AfterConstruction; override;
    procedure Refresh;
    /// <summary>Where the scan result is shown (within the safe area of the form)</summary>
    property OverlayParent: TFmxObject read FOverlayParent write FOverlayParent;
  end;

implementation

{$R *.fmx}

uses
  System.Messaging
, UI.Theme
;

{ TListView }

procedure TListView.ApplyStyle;

  procedure SetStyleColor(const AName: string; const AColor: TAlphaColor);
  begin
    var LObject := FindStyleResource(AName);
    if LObject is TColorObject then
      TColorObject(LObject).Color := AColor;
  end;

begin
  // TListViewBase.ApplyStyle reads these colors from the style resource
  SetStyleColor('background', COLOR_BACKGROUND);
  SetStyleColor('itembackground', COLOR_BACKGROUND);
  SetStyleColor('alternatingitembackground', COLOR_BACKGROUND);
  SetStyleColor('frame', COLOR_SURFACE_2);
  inherited;
end;

{ TDataFrame }

procedure TDataFrame.AfterConstruction;
begin
  inherited;

  TMessageManager.DefaultManager.SubscribeToMessage(TScanResultMessage
  , procedure(const Sender: TObject; const M: TMessage)
    begin
      Refresh;
    end
  );
end;

procedure TDataFrame.DataListViewItemClick(const Sender: TObject;
  const AItem: TListViewItem);
begin
  if not Assigned(FScanResultFI) then
   FScanResultFI := FS.New<TScanResultFrame>(FOverlayParent, 'lightbox');

  FScanResultFI.Show();
end;

procedure TDataFrame.Refresh;
begin
  LinkListControlToField1.Active := False;
  LinkListControlToField1.Active := True;
end;

end.
