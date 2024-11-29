
class SQLServer_Extract_Transform:

    QUERY_STR_DICT = {
    "g4s_emsys_tpims_dbo_CurfewSegment": """
    SELECT [CurfewSegmentID]
        ,[CurfewID]
        ,[CurfewSegmentType]
        ,[BeginDatetime]
        ,[EndDatetime]
        ,[LastModifiedDatetime]
        ,[DayFlags]
        ,[AdditionalInfo]
        ,[WeeksOn]
        ,[WeeksOff]
        ,[WeeksOffset]
        ,[ExportToGovernment]
        ,[PublicHolidaySegmentID]
        ,[IsPublicHoliday]
        ,[RowVersion]
        ,CAST(StartTime as varchar(8)) as StartTime
        ,CAST(EndTime as varchar(8)) as EndTime
        ,[SegmentCategoryLookupID]
        ,[ParentCurfewSegmentID]
        ,[TravelTimeBefore]
        ,[TravelTimeAfter]
    FROM [g4s_emsys_tpims].[dbo].[CurfewSegment]
    """.strip(),
    "g4s_emsys_tpims_dbo_GPSPositionLatest": """
    SELECT [GPSPositionID]
        ,[PersonID]
        ,[DeviceID]
        ,[Latitude]
        ,[Longitude]
        ,[RecordedDatetime]
        ,[Source]
        ,[Pdop]
        ,[Hdop]
        ,[Vdop]
        ,[Speed]
        ,[Direction]
        ,[SequenceNumber]
        ,[AuditDateTime]
        , SpatialPosition.STAsText() AS SpatialPosition
        ,[SeparationViolation]
    FROM [g4s_emsys_tpims].[dbo].[GPSPositionLatest]
    """.strip()
    }