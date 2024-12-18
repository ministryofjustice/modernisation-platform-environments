
class SQLServer_Extract_Transform:

    QUERY_STR_DICT = {

    "g4s_cap_dw_dbo_D_Comments": """
    SELECT [CommentSID]
        ,[VisitID]
        ,[ActivityID]
        ,trim(replace(replace(Comments, char(141), ''), char(129), '')) AS Comments
        ,[CommentType]
    FROM [g4s_cap_dw].[dbo].[D_Comments]
    """.strip(),

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

    TRANSFORM_COLS_FOR_HASHING_DICT = {
    'g4s_emsys_mvp_dbo_GPSPosition': {
        'Latitude': "CAST(FORMAT(Latitude, '0.0######') AS VARCHAR)", 
        'Longitude': "CAST(FORMAT(Longitude, '0.0######') AS VARCHAR)", 
        'RecordedDatetime':'CONVERT(VARCHAR, RecordedDatetime, 120)', 
        'AuditDateTime': """
        CAST(
        CASE 
            WHEN RIGHT(FORMAT(AuditDateTime, 'fff'), 1) = '0' THEN 
                FORMAT(AuditDateTime, 'yyyy-MM-dd HH:mm:ss.ff')
            ELSE 
                FORMAT(AuditDateTime, 'yyyy-MM-dd HH:mm:ss.fff')
        END 
        AS VARCHAR)
        """.strip()
        }
    }
