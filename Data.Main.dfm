object MainDM: TMainDM
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  Height = 275
  Width = 307
  object DataTable: TFDMemTable
    Active = True
    FieldDefs = <
      item
        Name = 'ScannedAt'
        DataType = ftDateTime
      end
      item
        Name = 'Kind'
        DataType = ftString
        Size = 256
      end
      item
        Name = 'Value'
        DataType = ftString
        Size = 4096
      end
      item
        Name = 'Thumb'
        DataType = ftBlob
      end
      item
        Name = 'Bitmap'
        DataType = ftBlob
      end
      item
        Name = 'ScanCount'
        DataType = ftInteger
      end>
    IndexDefs = <>
    FetchOptions.AssignedValues = [evMode]
    FetchOptions.Mode = fmAll
    ResourceOptions.AssignedValues = [rvSilentMode]
    ResourceOptions.SilentMode = True
    UpdateOptions.AssignedValues = [uvCheckRequired, uvAutoCommitUpdates]
    UpdateOptions.CheckRequired = False
    UpdateOptions.AutoCommitUpdates = True
    StoreDefs = True
    Left = 56
    Top = 120
    object DataTableScannedAt: TDateTimeField
      FieldName = 'ScannedAt'
    end
    object DataTableKind: TStringField
      FieldName = 'Kind'
      Size = 256
    end
    object DataTableValue: TStringField
      FieldName = 'Value'
      Size = 4096
    end
    object DataTableThumb: TGraphicField
      FieldName = 'Thumb'
      BlobType = ftGraphic
    end
    object DataTableBitmap: TGraphicField
      FieldName = 'Bitmap'
      BlobType = ftGraphic
    end
    object DataTableScanCount: TIntegerField
      FieldName = 'ScanCount'
    end
  end
end
