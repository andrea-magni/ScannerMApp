unit Data.Settings;

// Where the app keeps its data, and the scan settings (the formats to read),
// saved as JSON next to the scans.

interface

uses
  System.SysUtils, System.Generics.Collections
, ZXing.BarcodeFormat, ZXing.DecodeHintType
;

type
  /// <summary>A group of formats as the user sees it (e.g. "EAN / UPC")</summary>
  TFormatGroup = record
    Key: string;   // stored in the settings file
    Name: string;  // shown
    Formats: TArray<TBarcodeFormat>;
  end;

  TScanSettings = class
  private
    FDisabledGroups: TList<string>;
    function GetFileName: string;
  public
    constructor Create;
    destructor Destroy; override;

    function IsEnabled(const AGroupKey: string): Boolean;
    procedure SetEnabled(const AGroupKey: string; const AEnabled: Boolean);
    function EnabledCount: Integer;
    /// <summary>All the groups enabled: the default readers of ZXing (Auto)</summary>
    function AllEnabled: Boolean;

    /// <summary>The format and the hints for a TScanManager with the enabled groups.
    /// AHints is created when nil; the scan manager frees it (and the format list).</summary>
    procedure GetScanFormat(out AFormat: TBarcodeFormat;
      var AHints: TDictionary<TDecodeHintType, TObject>);

    procedure Load;
    procedure Save;
    property FileName: string read GetFileName;
  end;

const
  FORMAT_GROUPS: array[0..11] of TFormatGroup = (
    (Key: 'qr';        Name: 'QR Code';           Formats: [TBarcodeFormat.QR_CODE, TBarcodeFormat.MICRO_QR_CODE, TBarcodeFormat.RMQR_CODE])
  , (Key: 'datamatrix'; Name: 'Data Matrix';      Formats: [TBarcodeFormat.DATA_MATRIX])
  , (Key: 'aztec';     Name: 'Aztec';             Formats: [TBarcodeFormat.AZTEC])
  , (Key: 'pdf417';    Name: 'PDF417';            Formats: [TBarcodeFormat.PDF_417, TBarcodeFormat.MICRO_PDF417])
  , (Key: 'maxicode';  Name: 'MaxiCode';          Formats: [TBarcodeFormat.MAXICODE])
  , (Key: 'eanupc';    Name: 'EAN / UPC';         Formats: [TBarcodeFormat.EAN_8, TBarcodeFormat.EAN_13, TBarcodeFormat.UPC_A, TBarcodeFormat.UPC_E])
  , (Key: 'code128';   Name: 'Code 128';          Formats: [TBarcodeFormat.CODE_128])
  , (Key: 'code39';    Name: 'Code 39 / Code 93'; Formats: [TBarcodeFormat.CODE_39, TBarcodeFormat.CODE_93])
  , (Key: 'itf';       Name: 'ITF';               Formats: [TBarcodeFormat.ITF])
  , (Key: 'codabar';   Name: 'Codabar';           Formats: [TBarcodeFormat.CODABAR])
  , (Key: 'databar';   Name: 'GS1 DataBar';       Formats: [TBarcodeFormat.RSS_14, TBarcodeFormat.RSS_EXPANDED, TBarcodeFormat.RSS_LIMITED])
  , (Key: 'other';     Name: 'Other 1D and stacked codes';
                                                  Formats: [TBarcodeFormat.TELEPEN, TBarcodeFormat.DX_FILM_EDGE,
                                                    TBarcodeFormat.CODABLOCK_F, TBarcodeFormat.CODE_16K,
                                                    TBarcodeFormat.CODE_49, TBarcodeFormat.GS1_COMPOSITE])
  );

/// <summary>The folder of the app's data (created if missing): the documents folder
/// of the app on mobile, a ScannerMApp folder in the user's application data on desktop</summary>
function AppDataFolder: string;

implementation

uses
  System.IOUtils, System.JSON
;

function AppDataFolder: string;
begin
{$IF Defined(ANDROID) or Defined(IOS)}
  Result := TPath.GetDocumentsPath;
{$ELSEIF Defined(MACOS)}
  Result := TPath.Combine(TPath.GetHomePath, 'Library/Application Support/ScannerMApp');
{$ELSE}
  Result := TPath.Combine(TPath.GetHomePath, 'ScannerMApp');
{$ENDIF}
  ForceDirectories(Result);
end;

{ TScanSettings }

constructor TScanSettings.Create;
begin
  inherited Create;
  FDisabledGroups := TList<string>.Create;
end;

destructor TScanSettings.Destroy;
begin
  FDisabledGroups.Free;
  inherited;
end;

function TScanSettings.GetFileName: string;
begin
  Result := TPath.Combine(AppDataFolder, 'settings.json');
end;

function TScanSettings.IsEnabled(const AGroupKey: string): Boolean;
begin
  Result := not FDisabledGroups.Contains(AGroupKey);
end;

procedure TScanSettings.SetEnabled(const AGroupKey: string; const AEnabled: Boolean);
begin
  if AEnabled then
    FDisabledGroups.Remove(AGroupKey)
  else if not FDisabledGroups.Contains(AGroupKey) then
    FDisabledGroups.Add(AGroupKey);
end;

function TScanSettings.EnabledCount: Integer;
begin
  Result := 0;
  for var LGroup in FORMAT_GROUPS do
    if IsEnabled(LGroup.Key) then
      Inc(Result);
end;

function TScanSettings.AllEnabled: Boolean;
begin
  Result := EnabledCount = Length(FORMAT_GROUPS);
end;

procedure TScanSettings.GetScanFormat(out AFormat: TBarcodeFormat;
  var AHints: TDictionary<TDecodeHintType, TObject>);
begin
  // every group: the default readers (Auto), nothing to list
  AFormat := TBarcodeFormat.Auto;
  if AllEnabled then
    Exit;

  // else the formats of the enabled groups, as the hint POSSIBLE_FORMATS
  var LFormats := TList<TBarcodeFormat>.Create;
  for var LGroup in FORMAT_GROUPS do
    if IsEnabled(LGroup.Key) then
      LFormats.AddRange(LGroup.Formats);
  if not Assigned(AHints) then
    AHints := TDictionary<TDecodeHintType, TObject>.Create;
  AHints.Add(TDecodeHintType.POSSIBLE_FORMATS, LFormats);
end;

procedure TScanSettings.Load;
begin
  FDisabledGroups.Clear;
  if not TFile.Exists(FileName) then
    Exit;
  try
    var LJSON := TJSONObject.ParseJSONValue(TFile.ReadAllText(FileName, TEncoding.UTF8));
    try
      var LDisabled: TJSONArray;
      if (LJSON is TJSONObject) and TJSONObject(LJSON).TryGetValue<TJSONArray>('disabledFormats', LDisabled) then
        for var LItem in LDisabled do
          FDisabledGroups.Add(LItem.Value);
    finally
      LJSON.Free;
    end;
  except
    FDisabledGroups.Clear; // an unreadable file: the defaults
  end;
end;

procedure TScanSettings.Save;
begin
  var LJSON := TJSONObject.Create;
  try
    var LDisabled := TJSONArray.Create;
    LJSON.AddPair('disabledFormats', LDisabled);
    for var LKey in FDisabledGroups do
      LDisabled.Add(LKey);
    TFile.WriteAllText(FileName, LJSON.Format, TEncoding.UTF8);
  finally
    LJSON.Free;
  end;
end;

end.
