use it
go

-- Check if the DECISIONS1 table exists, if not, create it
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DECISIONS1]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[DECISIONS1](
        [DecisionID] [int] IDENTITY(1,1) NOT NULL,
        [JurisdictionID] [int] NULL,
        [Jurisdiction1ID] [int] NULL,
        [Date] [datetime] NULL,
        [AppealNumber] [varchar](100) NULL,
        [Appellant] [varchar](250) NULL,
        [Respondent] [varchar](500) NULL,
        [AddParties] [varchar](500) NULL,
        [SubjectDetail] [ntext] NULL,
        [Appealed] [varchar](50) NULL,
        [Disabled] [bit] NULL,
        [File1_Name] [varchar](250) NULL,
        [File2_Name] [varchar](250) NULL,
        [File2_Title] [varchar](250) NULL,
        [File3_Name] [varchar](250) NULL,
        [File3_Title] [varchar](250) NULL,
        [AppealURL] [varchar](1000) NULL,
        [TextURL] [varchar](250) NULL,
        CONSTRAINT [PK_DECISIONS1] PRIMARY KEY CLUSTERED ([DecisionID] ASC)
    )
END
ELSE
BEGIN
    -- If the table exists but the DecisionID column is not an identity column, modify it
    IF NOT EXISTS (SELECT * FROM sys.identity_columns WHERE object_id = OBJECT_ID('DECISIONS1') AND name = 'DecisionID')
    BEGIN
        -- First, we need to drop the primary key if it exists
        IF EXISTS (SELECT * FROM sys.key_constraints WHERE object_id = OBJECT_ID('PK_DECISIONS1'))
        BEGIN
            ALTER TABLE DECISIONS1 DROP CONSTRAINT PK_DECISIONS1
        END

        -- Now we can modify the column to be an identity column
        ALTER TABLE DECISIONS1 DROP COLUMN DecisionID
        ALTER TABLE DECISIONS1 ADD DecisionID BIGINT IDENTITY(1,1) NOT NULL

        -- Re-add the primary key
        ALTER TABLE DECISIONS1 ADD CONSTRAINT PK_DECISIONS1 PRIMARY KEY CLUSTERED (DecisionID ASC)
    END
END

GO

create proc dbo.dt_addtosourcecontrol
    @vchSourceSafeINI varchar(255) = '',
    @vchProjectName   varchar(255) ='',
    @vchComment       varchar(255) ='',
    @vchLoginName     varchar(255) ='',
    @vchPassword      varchar(255) =''

as

set nocount on

declare @iReturn int
declare @iObjectId int
select @iObjectId = 0

declare @iStreamObjectId int
select @iStreamObjectId = 0

declare @VSSGUID varchar(100)
select @VSSGUID = 'SQLVersionControl.VCS_SQL'

declare @vchDatabaseName varchar(255)
select @vchDatabaseName = db_name()

declare @iReturnValue int
select @iReturnValue = 0

declare @iPropertyObjectId int
declare @vchParentId varchar(255)

declare @iObjectCount int
select @iObjectCount = 0

    exec @iReturn = sp_OACreate @VSSGUID, @iObjectId OUT
    if @iReturn <> 0 GOTO E_OAError


    /* Create Project in SS */
    exec @iReturn = sp_OAMethod @iObjectId,
                                'AddProjectToSourceSafe',
                                NULL,
                                @vchSourceSafeINI,
                                @vchProjectName output,
                                @@SERVERNAME,
                                @vchDatabaseName,
                                @vchLoginName,
                                @vchPassword,
                                @vchComment


    if @iReturn <> 0 GOTO E_OAError

    exec @iReturn = sp_OAGetProperty @iObjectId, 'GetStreamObject', @iStreamObjectId OUT

    if @iReturn <> 0 GOTO E_OAError

    /* Set Database Properties */

    begin tran SetProperties

    /* add high level object */

    exec @iPropertyObjectId = dbo.dt_adduserobject_vcs 'VCSProjectID'

    select @vchParentId = CONVERT(varchar(255),@iPropertyObjectId)

    exec dbo.dt_setpropertybyid @iPropertyObjectId, 'VCSProjectID', @vchParentId , NULL
    exec dbo.dt_setpropertybyid @iPropertyObjectId, 'VCSProject' , @vchProjectName , NULL
    exec dbo.dt_setpropertybyid @iPropertyObjectId, 'VCSSourceSafeINI' , @vchSourceSafeINI , NULL
    exec dbo.dt_setpropertybyid @iPropertyObjectId, 'VCSSQLServer', @@SERVERNAME, NULL
    exec dbo.dt_setpropertybyid @iPropertyObjectId, 'VCSSQLDatabase', @vchDatabaseName, NULL

    if @@error <> 0 GOTO E_General_Error

    commit tran SetProperties

    declare cursorProcNames cursor for
        select convert(varchar(255), name) from sysobjects where type = 'P' and name not like 'dt_%'
    open cursorProcNames

    while 1 = 1
    begin
        declare @vchProcName varchar(255)
        fetch next from cursorProcNames into @vchProcName
        if @@fetch_status <> 0
            break

        select colid, text into #ProcLines
        from syscomments
        where id = object_id(@vchProcName)
        order by colid

        declare @iCurProcLine int
        declare @iProcLines int
        select @iCurProcLine = 1
        select @iProcLines = (select count(*) from #ProcLines)
        while @iCurProcLine <= @iProcLines
        begin
            declare @pos int
            select @pos = 1
            declare @iCurLineSize int
            select @iCurLineSize = len((select text from #ProcLines where colid = @iCurProcLine))
            while @pos <= @iCurLineSize
            begin
                declare @vchProcLinePiece varchar(255)
                select @vchProcLinePiece = convert(varchar(255),
                    substring((select text from #ProcLines where colid = @iCurProcLine),
                              @pos, 255 ))
                exec @iReturn = sp_OAMethod @iStreamObjectId, 'AddStream', @iReturnValue OUT, @vchProcLinePiece
                if @iReturn <> 0 GOTO E_OAError
                select @pos = @pos + 255
            end
            select @iCurProcLine = @iCurProcLine + 1
        end
        drop table #ProcLines

        exec @iReturn = sp_OAMethod @iObjectId,
                                    'CheckIn_StoredProcedure',
                                    NULL,
                                    @sProjectName = @vchProjectName,
                                    @sSourceSafeINI = @vchSourceSafeINI,
                                    @sServerName = @@SERVERNAME,
                                    @sDatabaseName = @vchDatabaseName,
                                    @sObjectName = @vchProcName,
                                    @sComment = @vchComment,
                                    @sLoginName = @vchLoginName,
                                    @sPassword = @vchPassword,
                                    @iVCSFlags = 0,
                                    @iActionFlag = 0,
                                    @sStream = ''

        if @iReturn = 0 select @iObjectCount = @iObjectCount + 1

    end

CleanUp:
	close cursorProcNames
	deallocate cursorProcNames
    select @vchProjectName
    select @iObjectCount
    return

E_General_Error:
    /* this is an all or nothing.  No specific error messages */
    goto CleanUp

E_OAError:
    exec dbo.dt_displayoaerror @iObjectId, @iReturn
    goto CleanUp


go

create proc dbo.dt_addtosourcecontrol_u
    @vchSourceSafeINI nvarchar(255) = '',
    @vchProjectName   nvarchar(255) ='',
    @vchComment       nvarchar(255) ='',
    @vchLoginName     nvarchar(255) ='',
    @vchPassword      nvarchar(255) =''

as

set nocount on

declare @iReturn int
declare @iObjectId int
select @iObjectId = 0

declare @iStreamObjectId int
select @iStreamObjectId = 0

declare @VSSGUID nvarchar(100)
select @VSSGUID = N'SQLVersionControl.VCS_SQL'

declare @vchDatabaseName varchar(255)
select @vchDatabaseName = db_name()

declare @iReturnValue int
select @iReturnValue = 0

declare @iPropertyObjectId int
declare @vchParentId nvarchar(255)

declare @iObjectCount int
select @iObjectCount = 0

    exec @iReturn = sp_OACreate @VSSGUID, @iObjectId OUT
    if @iReturn <> 0 GOTO E_OAError


    /* Create Project in SS */
    exec @iReturn = sp_OAMethod @iObjectId,
                                'AddProjectToSourceSafe',
                                NULL,
                                @vchSourceSafeINI,
                                @vchProjectName output,
                                @@SERVERNAME,
                                @vchDatabaseName,
                                @vchLoginName,
                                @vchPassword,
                                @vchComment


    if @iReturn <> 0 GOTO E_OAError

    exec @iReturn = sp_OAGetProperty @iObjectId, N'GetStreamObject', @iStreamObjectId OUT

    if @iReturn <> 0 GOTO E_OAError

    /* Set Database Properties */

    begin tran SetProperties

    /* add high level object */

    exec @iPropertyObjectId = dbo.dt_adduserobject_vcs 'VCSProjectID'

    select @vchParentId = CONVERT(nvarchar(255),@iPropertyObjectId)

    exec dbo.dt_setpropertybyid_u @iPropertyObjectId, 'VCSProjectID', @vchParentId , NULL
    exec dbo.dt_setpropertybyid_u @iPropertyObjectId, 'VCSProject' , @vchProjectName , NULL
    exec dbo.dt_setpropertybyid_u @iPropertyObjectId, 'VCSSourceSafeINI' , @vchSourceSafeINI , NULL
    exec dbo.dt_setpropertybyid_u @iPropertyObjectId, 'VCSSQLServer', @@SERVERNAME, NULL
    exec dbo.dt_setpropertybyid_u @iPropertyObjectId, 'VCSSQLDatabase', @vchDatabaseName, NULL

    if @@error <> 0 GOTO E_General_Error

    commit tran SetProperties

    declare cursorProcNames cursor for
        select convert(nvarchar(255), name) from sysobjects where type = N'P' and name not like N'dt_%'
    open cursorProcNames

    while 1 = 1
    begin
        declare @vchProcName nvarchar(255)
        fetch next from cursorProcNames into @vchProcName
        if @@fetch_status <> 0
            break

        select colid, text into #ProcLines
        from syscomments
        where id = object_id(@vchProcName)
        order by colid

        declare @iCurProcLine int
        declare @iProcLines int
        select @iCurProcLine = 1
        select @iProcLines = (select count(*) from #ProcLines)
        while @iCurProcLine <= @iProcLines
        begin
            declare @pos int
            select @pos = 1
            declare @iCurLineSize int
            select @iCurLineSize = len((select text from #ProcLines where colid = @iCurProcLine))
            while @pos <= @iCurLineSize
            begin
                declare @vchProcLinePiece nvarchar(255)
                select @vchProcLinePiece = convert(nvarchar(255),
                    substring((select text from #ProcLines where colid = @iCurProcLine),
                              @pos, 255 ))
                exec @iReturn = sp_OAMethod @iStreamObjectId, N'AddStream', @iReturnValue OUT, @vchProcLinePiece
                if @iReturn <> 0 GOTO E_OAError
                select @pos = @pos + 255
            end
            select @iCurProcLine = @iCurProcLine + 1
        end
        drop table #ProcLines

        exec @iReturn = sp_OAMethod @iObjectId,
                                    'CheckIn_StoredProcedure',
                                    NULL,
                                    @sProjectName = @vchProjectName,
                                    @sSourceSafeINI = @vchSourceSafeINI,
                                    @sServerName = @@SERVERNAME,
                                    @sDatabaseName = @vchDatabaseName,
                                    @sObjectName = @vchProcName,
                                    @sComment = @vchComment,
                                    @sLoginName = @vchLoginName,
                                    @sPassword = @vchPassword,
                                    @iVCSFlags = 0,
                                    @iActionFlag = 0,
                                    @sStream = ''

        if @iReturn = 0 select @iObjectCount = @iObjectCount + 1

    end

CleanUp:
	close cursorProcNames
	deallocate cursorProcNames
    select @vchProjectName
    select @iObjectCount
    return

E_General_Error:
    /* this is an all or nothing.  No specific error messages */
    goto CleanUp

E_OAError:
    exec dbo.dt_displayoaerror_u @iObjectId, @iReturn
    goto CleanUp


go

/*
**	Add an object to the dtproperties table
*/
create procedure dbo.dt_adduserobject
as
	set nocount on
	/*
	** Create the user object if it does not exist already
	*/
	begin transaction
		insert dbo.dtproperties (property) VALUES ('DtgSchemaOBJECT')
		update dbo.dtproperties set objectid=@@identity 
			where id=@@identity and property='DtgSchemaOBJECT'
	commit
	return @@identity
go

create procedure dbo.dt_adduserobject_vcs
    @vchProperty varchar(64)

as

set nocount on

declare @iReturn int
    /*
    ** Create the user object if it does not exist already
    */
    begin transaction
        select @iReturn = objectid from dbo.dtproperties where property = @vchProperty
        if @iReturn IS NULL
        begin
            insert dbo.dtproperties (property) VALUES (@vchProperty)
            update dbo.dtproperties set objectid=@@identity
                    where id=@@identity and property=@vchProperty
            select @iReturn = @@identity
        end
    commit
    return @iReturn


go

create proc dbo.dt_checkinobject
    @chObjectType  char(4),
    @vchObjectName varchar(255),
    @vchComment    varchar(255)='',
    @vchLoginName  varchar(255),
    @vchPassword   varchar(255)='',
    @iVCSFlags     int = 0,
    @iActionFlag   int = 0,   /* 0 => AddFile, 1 => CheckIn */
    @txStream1     Text = '', /* There is a bug that if items are NULL they do not pass to OLE servers */
    @txStream2     Text = '',
    @txStream3     Text = ''


as

set nocount on

declare @iReturn int
declare @iObjectId int
select @iObjectId = 0

declare @VSSGUID varchar(100)
select @VSSGUID = 'SQLVersionControl.VCS_SQL'


declare @iPropertyObjectId int
select @iPropertyObjectId  = 0

    select @iPropertyObjectId = (select objectid from dbo.dtproperties where property = 'VCSProjectID')

    declare @vchProjectName   varchar(255)
    declare @vchSourceSafeINI varchar(255)
    declare @vchServerName    varchar(255)
    declare @vchDatabaseName  varchar(255)
    exec dbo.dt_getpropertiesbyid_vcs @iPropertyObjectId, 'VCSProject',       @vchProjectName   OUT
    exec dbo.dt_getpropertiesbyid_vcs @iPropertyObjectId, 'VCSSourceSafeINI', @vchSourceSafeINI OUT
    exec dbo.dt_getpropertiesbyid_vcs @iPropertyObjectId, 'VCSSQLServer',     @vchServerName    OUT
    exec dbo.dt_getpropertiesbyid_vcs @iPropertyObjectId, 'VCSSQLDatabase',   @vchDatabaseName  OUT

    if @chObjectType = 'PROC'
    begin
        if @iActionFlag = 1
        begin
            /* Procedure Can have up to three streams
            Drop Stream, Create Stream, GRANT stream */

            begin tran compile_all

            /* try to compile the streams */
            exec (@txStream1)
            if @@error <> 0 GOTO E_Compile_Fail

            exec (@txStream2)
            if @@error <> 0 GOTO E_Compile_Fail

            exec (@txStream3)
            if @@error <> 0 GOTO E_Compile_Fail
        end

        exec @iReturn = sp_OACreate @VSSGUID, @iObjectId OUT
        if @iReturn <> 0 GOTO E_OAError

        if @iActionFlag = 1
        begin
            exec @iReturn = sp_OAMethod @iObjectId,
                                        'CheckIn_StoredProcedure',
                                        NULL,
                                        @sProjectName = @vchProjectName,
                                        @sSourceSafeINI = @vchSourceSafeINI,
                                        @sServerName = @vchServerName,
                                        @sDatabaseName = @vchDatabaseName,
                                        @sObjectName = @vchObjectName,
                                        @sComment = @vchComment,
                                        @sLoginName = @vchLoginName,
                                        @sPassword = @vchPassword,
                                        @iVCSFlags = @iVCSFlags,
                                        @iActionFlag = @iActionFlag,
                                        @sStream = @txStream2
        end
        else
        begin
            declare @iStreamObjectId int
            declare @iReturnValue int

            exec @iReturn = sp_OAGetProperty @iObjectId, 'GetStreamObject', @iStreamObjectId OUT
            if @iReturn <> 0 GOTO E_OAError

            select colid, text into #ProcLines
            from syscomments
            where id = object_id(@vchObjectName)
            order by colid

            declare @iCurProcLine int
            declare @iProcLines int
            select @iCurProcLine = 1
            select @iProcLines = (select count(*) from #ProcLines)
            while @iCurProcLine <= @iProcLines
            begin
                declare @pos int
                select @pos = 1
                declare @iCurLineSize int
                select @iCurLineSize = len((select text from #ProcLines where colid = @iCurProcLine))
                while @pos <= @iCurLineSize
                begin
                    declare @vchProcLinePiece varchar(255)
                    select @vchProcLinePiece = convert(varchar(255),
                        substring((select text from #ProcLines where colid = @iCurProcLine),
                                  @pos, 255 ))
                    exec @iReturn = sp_OAMethod @iStreamObjectId, 'AddStream', @iReturnValue OUT, @vchProcLinePiece
                    if @iReturn <> 0 GOTO E_OAError
                    select @pos = @pos + 255
                end
                select @iCurProcLine = @iCurProcLine + 1
            end
            drop table #ProcLines

            exec @iReturn = sp_OAMethod @iObjectId,
                                        'CheckIn_StoredProcedure',
                                        NULL,
                                        @sProjectName = @vchProjectName,
                                        @sSourceSafeINI = @vchSourceSafeINI,
                                        @sServerName = @vchServerName,
                                        @sDatabaseName = @vchDatabaseName,
                                        @sObjectName = @vchObjectName,
                                        @sComment = @vchComment,
                                        @sLoginName = @vchLoginName,
                                        @sPassword = @vchPassword,
                                        @iVCSFlags = @iVCSFlags,
                                        @iActionFlag = @iActionFlag,
                                        @sStream = ''
        end

        if @iReturn <> 0 GOTO E_OAError

        if @iActionFlag = 1
        begin
            commit tran compile_all
            if @@error <> 0 GOTO E_Compile_Fail
        end

    end

CleanUp:
    return

E_Compile_Fail:
    declare @lerror int
    select @lerror = @@error
    rollback tran compile_all
    RAISERROR (@lerror,16,-1)
    goto CleanUp

E_OAError:
    if @iActionFlag = 1 rollback tran compile_all
    exec dbo.dt_displayoaerror @iObjectId, @iReturn
    goto CleanUp


go

create proc dbo.dt_checkinobject_u
    @chObjectType  char(4),
    @vchObjectName nvarchar(255),
    @vchComment    nvarchar(255)='',
    @vchLoginName  nvarchar(255),
    @vchPassword   nvarchar(255)='',
    @iVCSFlags     int = 0,
    @iActionFlag   int = 0,   /* 0 => AddFile, 1 => CheckIn */
    @txStream1     Text = '', /* There is a bug that if items are NULL they do not pass to OLE servers */
    @txStream2     Text = '',
    @txStream3     Text = ''


as

set nocount on

declare @iReturn int
declare @iObjectId int
select @iObjectId = 0

declare @VSSGUID nvarchar(100)
select @VSSGUID = N'SQLVersionControl.VCS_SQL'


declare @iPropertyObjectId int
select @iPropertyObjectId  = 0

    select @iPropertyObjectId = (select objectid from dbo.dtproperties where property = 'VCSProjectID')

    declare @vchProjectName   nvarchar(255)
    declare @vchSourceSafeINI nvarchar(255)
    declare @vchServerName    nvarchar(255)
    declare @vchDatabaseName  nvarchar(255)
    exec dbo.dt_getpropertiesbyid_vcs_u @iPropertyObjectId, 'VCSProject',       @vchProjectName   OUT
    exec dbo.dt_getpropertiesbyid_vcs_u @iPropertyObjectId, 'VCSSourceSafeINI', @vchSourceSafeINI OUT
    exec dbo.dt_getpropertiesbyid_vcs_u @iPropertyObjectId, 'VCSSQLServer',     @vchServerName    OUT
    exec dbo.dt_getpropertiesbyid_vcs_u @iPropertyObjectId, 'VCSSQLDatabase',   @vchDatabaseName  OUT

    if @chObjectType = 'PROC'
    begin
        if @iActionFlag = 1
        begin
            /* Procedure Can have up to three streams
            Drop Stream, Create Stream, GRANT stream */

            begin tran compile_all

            /* try to compile the streams */
            exec (@txStream1)
            if @@error <> 0 GOTO E_Compile_Fail

            exec (@txStream2)
            if @@error <> 0 GOTO E_Compile_Fail

            exec (@txStream3)
            if @@error <> 0 GOTO E_Compile_Fail
        end

        exec @iReturn = sp_OACreate @VSSGUID, @iObjectId OUT
        if @iReturn <> 0 GOTO E_OAError

        if @iActionFlag = 1
        begin
            exec @iReturn = sp_OAMethod @iObjectId,
                                        N'CheckIn_StoredProcedure',
                                        NULL,
                                        @sProjectName = @vchProjectName,
                                        @sSourceSafeINI = @vchSourceSafeINI,
                                        @sServerName = @vchServerName,
                                        @sDatabaseName = @vchDatabaseName,
                                        @sObjectName = @vchObjectName,
                                        @sComment = @vchComment,
                                        @sLoginName = @vchLoginName,
                                        @sPassword = @vchPassword,
                                        @iVCSFlags = @iVCSFlags,
                                        @iActionFlag = @iActionFlag,
                                        @sStream = @txStream2
        end
        else
        begin
            declare @iStreamObjectId int
            declare @iReturnValue int

            exec @iReturn = sp_OAGetProperty @iObjectId, N'GetStreamObject', @iStreamObjectId OUT
            if @iReturn <> 0 GOTO E_OAError

            select colid, text into #ProcLines
            from syscomments
            where id = object_id(@vchObjectName)
            order by colid

            declare @iCurProcLine int
            declare @iProcLines int
            select @iCurProcLine = 1
            select @iProcLines = (select count(*) from #ProcLines)
            while @iCurProcLine <= @iProcLines
            begin
                declare @pos int
                select @pos = 1
                declare @iCurLineSize int
                select @iCurLineSize = len((select text from #ProcLines where colid = @iCurProcLine))
                while @pos <= @iCurLineSize
                begin
                    declare @vchProcLinePiece nvarchar(255)
                    select @vchProcLinePiece = convert(nvarchar(255),
                        substring((select text from #ProcLines where colid = @iCurProcLine),
                                  @pos, 255 ))
                    exec @iReturn = sp_OAMethod @iStreamObjectId, N'AddStream', @iReturnValue OUT, @vchProcLinePiece
                    if @iReturn <> 0 GOTO E_OAError
                    select @pos = @pos + 255
                end
                select @iCurProcLine = @iCurProcLine + 1
            end
            drop table #ProcLines

            exec @iReturn = sp_OAMethod @iObjectId,
                                        N'CheckIn_StoredProcedure',
                                        NULL,
                                        @sProjectName = @vchProjectName,
                                        @sSourceSafeINI = @vchSourceSafeINI,
                                        @sServerName = @vchServerName,
                                        @sDatabaseName = @vchDatabaseName,
                                        @sObjectName = @vchObjectName,
                                        @sComment = @vchComment,
                                        @sLoginName = @vchLoginName,
                                        @sPassword = @vchPassword,
                                        @iVCSFlags = @iVCSFlags,
                                        @iActionFlag = @iActionFlag,
                                        @sStream = ''
        end

        if @iReturn <> 0 GOTO E_OAError

        if @iActionFlag = 1
        begin
            commit tran compile_all
            if @@error <> 0 GOTO E_Compile_Fail
        end

    end

CleanUp:
    return

E_Compile_Fail:
    declare @lerror int
    select @lerror = @@error
    rollback tran compile_all
    RAISERROR (@lerror,16,-1)
    goto CleanUp

E_OAError:
    if @iActionFlag = 1 rollback tran compile_all
    exec dbo.dt_displayoaerror_u @iObjectId, @iReturn
    goto CleanUp


go

create proc dbo.dt_checkoutobject
    @chObjectType  char(4),
    @vchObjectName varchar(255),
    @vchComment    varchar(255),
    @vchLoginName  varchar(255),
    @vchPassword   varchar(255),
    @iVCSFlags     int = 0,
    @iActionFlag   int = 0/* 0 => Checkout, 1 => GetLatest, 2 => UndoCheckOut */

as

set nocount on

declare @iReturn int
declare @iObjectId int
select @iObjectId =0

declare @VSSGUID varchar(100)
select @VSSGUID = 'SQLVersionControl.VCS_SQL'

declare @iReturnValue int
select @iReturnValue = 0

declare @vchTempText varchar(255)

/* this is for our strings */
declare @iStreamObjectId int
select @iStreamObjectId = 0

    declare @iPropertyObjectId int
    select @iPropertyObjectId = (select objectid from dbo.dtproperties where property = 'VCSProjectID')

    declare @vchProjectName   varchar(255)
    declare @vchSourceSafeINI varchar(255)
    declare @vchServerName    varchar(255)
    declare @vchDatabaseName  varchar(255)
    exec dbo.dt_getpropertiesbyid_vcs @iPropertyObjectId, 'VCSProject',       @vchProjectName   OUT
    exec dbo.dt_getpropertiesbyid_vcs @iPropertyObjectId, 'VCSSourceSafeINI', @vchSourceSafeINI OUT
    exec dbo.dt_getpropertiesbyid_vcs @iPropertyObjectId, 'VCSSQLServer',     @vchServerName    OUT
    exec dbo.dt_getpropertiesbyid_vcs @iPropertyObjectId, 'VCSSQLDatabase',   @vchDatabaseName  OUT

    if @chObjectType = 'PROC'
    begin
        /* Procedure Can have up to three streams
           Drop Stream, Create Stream, GRANT stream */

        exec @iReturn = sp_OACreate @VSSGUID, @iObjectId OUT

        if @iReturn <> 0 GOTO E_OAError

        exec @iReturn = sp_OAMethod @iObjectId,
                                    'CheckOut_StoredProcedure',
                                    NULL,
                                    @sProjectName = @vchProjectName,
                                    @sSourceSafeINI = @vchSourceSafeINI,
                                    @sObjectName = @vchObjectName,
                                    @sServerName = @vchServerName,
                                    @sDatabaseName = @vchDatabaseName,
                                    @sComment = @vchComment,
                                    @sLoginName = @vchLoginName,
                                    @sPassword = @vchPassword,
                                    @iVCSFlags = @iVCSFlags,
                                    @iActionFlag = @iActionFlag

        if @iReturn <> 0 GOTO E_OAError


        exec @iReturn = sp_OAGetProperty @iObjectId, 'GetStreamObject', @iStreamObjectId OUT

        if @iReturn <> 0 GOTO E_OAError

        create table #commenttext (id int identity, sourcecode varchar(255))


        select @vchTempText = 'STUB'
        while @vchTempText IS NOT NULL
        begin
            exec @iReturn = sp_OAMethod @iStreamObjectId, 'GetStream', @iReturnValue OUT, @vchTempText OUT
            if @iReturn <> 0 GOTO E_OAError

            if (@vchTempText IS NOT NULL) insert into #commenttext (sourcecode) select @vchTempText
        end

        select 'VCS'=sourcecode from #commenttext order by id
        select 'SQL'=text from syscomments where id = object_id(@vchObjectName) order by colid

    end

CleanUp:
    return

E_OAError:
    exec dbo.dt_displayoaerror @iObjectId, @iReturn
    GOTO CleanUp


go

create proc dbo.dt_checkoutobject_u
    @chObjectType  char(4),
    @vchObjectName nvarchar(255),
    @vchComment    nvarchar(255),
    @vchLoginName  nvarchar(255),
    @vchPassword   nvarchar(255),
    @iVCSFlags     int = 0,
    @iActionFlag   int = 0/* 0 => Checkout, 1 => GetLatest, 2 => UndoCheckOut */

as

set nocount on

declare @iReturn int
declare @iObjectId int
select @iObjectId =0

declare @VSSGUID nvarchar(100)
select @VSSGUID = N'SQLVersionControl.VCS_SQL'

declare @iReturnValue int
select @iReturnValue = 0

declare @vchTempText nvarchar(255)

/* this is for our strings */
declare @iStreamObjectId int
select @iStreamObjectId = 0

    declare @iPropertyObjectId int
    select @iPropertyObjectId = (select objectid from dbo.dtproperties where property = 'VCSProjectID')

    declare @vchProjectName   nvarchar(255)
    declare @vchSourceSafeINI nvarchar(255)
    declare @vchServerName    nvarchar(255)
    declare @vchDatabaseName  nvarchar(255)
    exec dbo.dt_getpropertiesbyid_vcs_u @iPropertyObjectId, 'VCSProject',       @vchProjectName   OUT
    exec dbo.dt_getpropertiesbyid_vcs_u @iPropertyObjectId, 'VCSSourceSafeINI', @vchSourceSafeINI OUT
    exec dbo.dt_getpropertiesbyid_vcs_u @iPropertyObjectId, 'VCSSQLServer',     @vchServerName    OUT
    exec dbo.dt_getpropertiesbyid_vcs_u @iPropertyObjectId, 'VCSSQLDatabase',   @vchDatabaseName  OUT

    if @chObjectType = 'PROC'
    begin
        /* Procedure Can have up to three streams
           Drop Stream, Create Stream, GRANT stream */

        exec @iReturn = sp_OACreate @VSSGUID, @iObjectId OUT

        if @iReturn <> 0 GOTO E_OAError

        exec @iReturn = sp_OAMethod @iObjectId,
                                    N'CheckOut_StoredProcedure',
                                    NULL,
                                    @sProjectName = @vchProjectName,
                                    @sSourceSafeINI = @vchSourceSafeINI,
                                    @sObjectName = @vchObjectName,
                                    @sServerName = @vchServerName,
                                    @sDatabaseName = @vchDatabaseName,
                                    @sComment = @vchComment,
                                    @sLoginName = @vchLoginName,
                                    @sPassword = @vchPassword,
                                    @iVCSFlags = @iVCSFlags,
                                    @iActionFlag = @iActionFlag

        if @iReturn <> 0 GOTO E_OAError


        exec @iReturn = sp_OAGetProperty @iObjectId, N'GetStreamObject', @iStreamObjectId OUT

        if @iReturn <> 0 GOTO E_OAError

        create table #commenttext (id int identity, sourcecode nvarchar(255))


        select @vchTempText = N'STUB'
        while @vchTempText IS NOT NULL
        begin
            exec @iReturn = sp_OAMethod @iStreamObjectId, N'GetStream', @iReturnValue OUT, @vchTempText OUT
            if @iReturn <> 0 GOTO E_OAError

            if (@vchTempText IS NOT NULL) insert into #commenttext (sourcecode) select @vchTempText
        end

        select N'VCS'=sourcecode from #commenttext order by id
        select N'SQL'=text from syscomments where id = object_id(@vchObjectName) order by colid

    end

CleanUp:
    return

E_OAError:
    exec dbo.dt_displayoaerror_u @iObjectId, @iReturn
    GOTO CleanUp


go

CREATE PROCEDURE dbo.dt_displayoaerror
    @iObject int,
    @iresult int
as

set nocount on

declare @vchOutput      varchar(255)
declare @hr             int
declare @vchSource      varchar(255)
declare @vchDescription varchar(255)

    exec @hr = sp_OAGetErrorInfo @iObject, @vchSource OUT, @vchDescription OUT

    select @vchOutput = @vchSource + ': ' + @vchDescription
    raiserror (@vchOutput,16,-1)

    return

go

CREATE PROCEDURE dbo.dt_displayoaerror_u
    @iObject int,
    @iresult int
as

set nocount on

declare @vchOutput      nvarchar(255)
declare @hr             int
declare @vchSource      nvarchar(255)
declare @vchDescription nvarchar(255)

    exec @hr = sp_OAGetErrorInfo @iObject, @vchSource OUT, @vchDescription OUT

    select @vchOutput = @vchSource + ': ' + @vchDescription
    raiserror (@vchOutput,16,-1)

    return

go

/*
**	Drop one or all the associated properties of an object or an attribute 
**
**	dt_dropproperties objid, null or '' -- drop all properties of the object itself
**	dt_dropproperties objid, property -- drop the property
*/
create procedure dbo.dt_droppropertiesbyid
	@id int,
	@property varchar(64)
as
	set nocount on

	if (@property is null) or (@property = '')
		delete from dbo.dtproperties where objectid=@id
	else
		delete from dbo.dtproperties 
			where objectid=@id and property=@property

go

/*
**	Drop an object from the dbo.dtproperties table
*/
create procedure dbo.dt_dropuserobjectbyid
	@id int
as
	set nocount on
	delete from dbo.dtproperties where objectid=@id
go

/* 
**	Generate an ansi name that is unique in the dtproperties.value column 
*/ 
create procedure dbo.dt_generateansiname(@name varchar(255) output) 
as 
	declare @prologue varchar(20) 
	declare @indexstring varchar(20) 
	declare @index integer 
 
	set @prologue = 'MSDT-A-' 
	set @index = 1 
 
	while 1 = 1 
	begin 
		set @indexstring = cast(@index as varchar(20)) 
		set @name = @prologue + @indexstring 
		if not exists (select value from dtproperties where value = @name) 
			break 
		 
		set @index = @index + 1 
 
		if (@index = 10000) 
			goto TooMany 
	end 
 
Leave: 
 
	return 
 
TooMany: 
 
	set @name = 'DIAGRAM' 
	goto Leave
go

/*
**	Retrieve the owner object(s) of a given property
*/
create procedure dbo.dt_getobjwithprop
	@property varchar(30),
	@value varchar(255)
as
	set nocount on

	if (@property is null) or (@property = '')
	begin
		raiserror('Must specify a property name.',-1,-1)
		return (1)
	end

	if (@value is null)
		select objectid id from dbo.dtproperties
			where property=@property

	else
		select objectid id from dbo.dtproperties
			where property=@property and value=@value
go

/*
**	Retrieve the owner object(s) of a given property
*/
create procedure dbo.dt_getobjwithprop_u
	@property varchar(30),
	@uvalue nvarchar(255)
as
	set nocount on

	if (@property is null) or (@property = '')
	begin
		raiserror('Must specify a property name.',-1,-1)
		return (1)
	end

	if (@uvalue is null)
		select objectid id from dbo.dtproperties
			where property=@property

	else
		select objectid id from dbo.dtproperties
			where property=@property and uvalue=@uvalue
go

/*
**	Retrieve properties by id's
**
**	dt_getproperties objid, null or '' -- retrieve all properties of the object itself
**	dt_getproperties objid, property -- retrieve the property specified
*/
create procedure dbo.dt_getpropertiesbyid
	@id int,
	@property varchar(64)
as
	set nocount on

	if (@property is null) or (@property = '')
		select property, version, value, lvalue
			from dbo.dtproperties
			where  @id=objectid
	else
		select property, version, value, lvalue
			from dbo.dtproperties
			where  @id=objectid and @property=property
go

/*
**	Retrieve properties by id's
**
**	dt_getproperties objid, null or '' -- retrieve all properties of the object itself
**	dt_getproperties objid, property -- retrieve the property specified
*/
create procedure dbo.dt_getpropertiesbyid_u
	@id int,
	@property varchar(64)
as
	set nocount on

	if (@property is null) or (@property = '')
		select property, version, uvalue, lvalue
			from dbo.dtproperties
			where  @id=objectid
	else
		select property, version, uvalue, lvalue
			from dbo.dtproperties
			where  @id=objectid and @property=property
go

create procedure dbo.dt_getpropertiesbyid_vcs
    @id       int,
    @property varchar(64),
    @value    varchar(255) = NULL OUT

as

    set nocount on

    select @value = (
        select value
                from dbo.dtproperties
                where @id=objectid and @property=property
                )

go

create procedure dbo.dt_getpropertiesbyid_vcs_u
    @id       int,
    @property varchar(64),
    @value    nvarchar(255) = NULL OUT

as

    set nocount on

    select @value = (
        select uvalue
                from dbo.dtproperties
                where @id=objectid and @property=property
                )

go

create proc dbo.dt_isundersourcecontrol
    @vchLoginName varchar(255) = '',
    @vchPassword  varchar(255) = '',
    @iWhoToo      int = 0 /* 0 => Just check project; 1 => get list of objs */

as

set nocount on

declare @iReturn int
declare @iObjectId int
select @iObjectId = 0

declare @VSSGUID varchar(100)
select @VSSGUID = 'SQLVersionControl.VCS_SQL'

declare @iReturnValue int
select @iReturnValue = 0

declare @iStreamObjectId int
select @iStreamObjectId   = 0

declare @vchTempText varchar(255)

    declare @iPropertyObjectId int
    select @iPropertyObjectId = (select objectid from dbo.dtproperties where property = 'VCSProjectID')

    declare @vchProjectName   varchar(255)
    declare @vchSourceSafeINI varchar(255)
    declare @vchServerName    varchar(255)
    declare @vchDatabaseName  varchar(255)
    exec dbo.dt_getpropertiesbyid_vcs @iPropertyObjectId, 'VCSProject',       @vchProjectName   OUT
    exec dbo.dt_getpropertiesbyid_vcs @iPropertyObjectId, 'VCSSourceSafeINI', @vchSourceSafeINI OUT
    exec dbo.dt_getpropertiesbyid_vcs @iPropertyObjectId, 'VCSSQLServer',     @vchServerName    OUT
    exec dbo.dt_getpropertiesbyid_vcs @iPropertyObjectId, 'VCSSQLDatabase',   @vchDatabaseName  OUT

    if (@vchProjectName IS NULL) or (@vchSourceSafeINI  IS NULL) or (@vchServerName IS NULL) or (@vchDatabaseName IS NULL)
    begin
        RAISERROR('Not Under Source Control',16,-1)
        return
    end

    if @iWhoToo = 1
    begin

        /* Get List of Procs in the project */
        exec @iReturn = sp_OACreate @VSSGUID, @iObjectId OUT
        if @iReturn <> 0 GOTO E_OAError

        exec @iReturn = sp_OAMethod @iObjectId,
                                    'GetListOfObjects',
                                    NULL,
                                    @vchProjectName,
                                    @vchSourceSafeINI,
                                    @vchServerName,
                                    @vchDatabaseName,
                                    @vchLoginName,
                                    @vchPassword

        if @iReturn <> 0 GOTO E_OAError

        exec @iReturn = sp_OAGetProperty @iObjectId, 'GetStreamObject', @iStreamObjectId OUT

        if @iReturn <> 0 GOTO E_OAError

        create table #ObjectList (id int identity, vchObjectlist varchar(255))

        select @vchTempText = 'STUB'
        while @vchTempText IS NOT NULL
        begin
            exec @iReturn = sp_OAMethod @iStreamObjectId, 'GetStream', @iReturnValue OUT, @vchTempText OUT
            if @iReturn <> 0 GOTO E_OAError

            if (@vchTempText IS NOT NULL) insert into #ObjectList (vchObjectlist ) select @vchTempText
        end

        select vchObjectlist from #ObjectList order by id
    end

CleanUp:
    return

E_OAError:
    exec dbo.dt_displayoaerror @iObjectId, @iReturn
    goto CleanUp


go

create proc dbo.dt_isundersourcecontrol_u
    @vchLoginName nvarchar(255) = '',
    @vchPassword  nvarchar(255) = '',
    @iWhoToo      int = 0 /* 0 => Just check project; 1 => get list of objs */

as

	set nocount on

	declare @iReturn int
	declare @iObjectId int
	select @iObjectId = 0

	declare @VSSGUID nvarchar(100)
	select @VSSGUID = N'SQLVersionControl.VCS_SQL'

	declare @iReturnValue int
	select @iReturnValue = 0

	declare @iStreamObjectId int
	select @iStreamObjectId   = 0

	declare @vchTempText nvarchar(255)

    declare @iPropertyObjectId int
    select @iPropertyObjectId = (select objectid from dbo.dtproperties where property = 'VCSProjectID')

    declare @vchProjectName   nvarchar(255)
    declare @vchSourceSafeINI nvarchar(255)
    declare @vchServerName    nvarchar(255)
    declare @vchDatabaseName  nvarchar(255)
    exec dbo.dt_getpropertiesbyid_vcs_u @iPropertyObjectId, 'VCSProject',       @vchProjectName   OUT
    exec dbo.dt_getpropertiesbyid_vcs_u @iPropertyObjectId, 'VCSSourceSafeINI', @vchSourceSafeINI OUT
    exec dbo.dt_getpropertiesbyid_vcs_u @iPropertyObjectId, 'VCSSQLServer',     @vchServerName    OUT
    exec dbo.dt_getpropertiesbyid_vcs_u @iPropertyObjectId, 'VCSSQLDatabase',   @vchDatabaseName  OUT

    if (@vchProjectName IS NULL) or (@vchSourceSafeINI  IS NULL) or (@vchServerName IS NULL) or (@vchDatabaseName IS NULL)
    begin
        RAISERROR(N'Not Under Source Control',16,-1)
        return
    end

    if @iWhoToo = 1
    begin

        /* Get List of Procs in the project */
        exec @iReturn = sp_OACreate @VSSGUID, @iObjectId OUT
        if @iReturn <> 0 GOTO E_OAError

        exec @iReturn = sp_OAMethod @iObjectId,
                                    N'GetListOfObjects',
                                    NULL,
                                    @vchProjectName,
                                    @vchSourceSafeINI,
                                    @vchServerName,
                                    @vchDatabaseName,
                                    @vchLoginName,
                                    @vchPassword

        if @iReturn <> 0 GOTO E_OAError

        exec @iReturn = sp_OAGetProperty @iObjectId, N'GetStreamObject', @iStreamObjectId OUT

        if @iReturn <> 0 GOTO E_OAError

        create table #ObjectList (id int identity, vchObjectlist nvarchar(255))

        select @vchTempText = N'STUB'
        while @vchTempText IS NOT NULL
        begin
            exec @iReturn = sp_OAMethod @iStreamObjectId, N'GetStream', @iReturnValue OUT, @vchTempText OUT
            if @iReturn <> 0 GOTO E_OAError

            if (@vchTempText IS NOT NULL) insert into #ObjectList (vchObjectlist ) select @vchTempText
        end

        select vchObjectlist from #ObjectList order by id
    end

CleanUp:
    return

E_OAError:
    exec dbo.dt_displayoaerror_u @iObjectId, @iReturn
    goto CleanUp


go

create procedure dbo.dt_removefromsourcecontrol

as

    set nocount on

    declare @iPropertyObjectId int
    select @iPropertyObjectId = (select objectid from dbo.dtproperties where property = 'VCSProjectID')

    exec dbo.dt_droppropertiesbyid @iPropertyObjectId, null

    /* -1 is returned by dt_droppopertiesbyid */
    if @@error <> 0 and @@error <> -1 return 1

    return 0


go

/*
**	If the property already exists, reset the value; otherwise add property
**		id -- the id in sysobjects of the object
**		property -- the name of the property
**		value -- the text value of the property
**		lvalue -- the binary value of the property (image)
*/
create procedure dbo.dt_setpropertybyid
	@id int,
	@property varchar(64),
	@value varchar(255),
	@lvalue image
as
	set nocount on
	declare @uvalue nvarchar(255) 
	set @uvalue = convert(nvarchar(255), @value) 
	if exists (select * from dbo.dtproperties 
			where objectid=@id and property=@property)
	begin
		--
		-- bump the version count for this row as we update it
		--
		update dbo.dtproperties set value=@value, uvalue=@uvalue, lvalue=@lvalue, version=version+1
			where objectid=@id and property=@property
	end
	else
	begin
		--
		-- version count is auto-set to 0 on initial insert
		--
		insert dbo.dtproperties (property, objectid, value, uvalue, lvalue)
			values (@property, @id, @value, @uvalue, @lvalue)
	end

go

/*
**	If the property already exists, reset the value; otherwise add property
**		id -- the id in sysobjects of the object
**		property -- the name of the property
**		uvalue -- the text value of the property
**		lvalue -- the binary value of the property (image)
*/
create procedure dbo.dt_setpropertybyid_u
	@id int,
	@property varchar(64),
	@uvalue nvarchar(255),
	@lvalue image
as
	set nocount on
	-- 
	-- If we are writing the name property, find the ansi equivalent. 
	-- If there is no lossless translation, generate an ansi name. 
	-- 
	declare @avalue varchar(255) 
	set @avalue = null 
	if (@uvalue is not null) 
	begin 
		if (convert(nvarchar(255), convert(varchar(255), @uvalue)) = @uvalue) 
		begin 
			set @avalue = convert(varchar(255), @uvalue) 
		end 
		else 
		begin 
			if 'DtgSchemaNAME' = @property 
			begin 
				exec dbo.dt_generateansiname @avalue output 
			end 
		end 
	end 
	if exists (select * from dbo.dtproperties 
			where objectid=@id and property=@property)
	begin
		--
		-- bump the version count for this row as we update it
		--
		update dbo.dtproperties set value=@avalue, uvalue=@uvalue, lvalue=@lvalue, version=version+1
			where objectid=@id and property=@property
	end
	else
	begin
		--
		-- version count is auto-set to 0 on initial insert
		--
		insert dbo.dtproperties (property, objectid, value, uvalue, lvalue)
			values (@property, @id, @avalue, @uvalue, @lvalue)
	end
go

create proc dbo.dt_validateloginparams
    @vchLoginName  varchar(255),
    @vchPassword   varchar(255)
as

set nocount on

declare @iReturn int
declare @iObjectId int
select @iObjectId =0

declare @VSSGUID varchar(100)
select @VSSGUID = 'SQLVersionControl.VCS_SQL'

    declare @iPropertyObjectId int
    select @iPropertyObjectId = (select objectid from dbo.dtproperties where property = 'VCSProjectID')

    declare @vchSourceSafeINI varchar(255)
    exec dbo.dt_getpropertiesbyid_vcs @iPropertyObjectId, 'VCSSourceSafeINI', @vchSourceSafeINI OUT

    exec @iReturn = sp_OACreate @VSSGUID, @iObjectId OUT
    if @iReturn <> 0 GOTO E_OAError

    exec @iReturn = sp_OAMethod @iObjectId,
                                'ValidateLoginParams',
                                NULL,
                                @sSourceSafeINI = @vchSourceSafeINI,
                                @sLoginName = @vchLoginName,
                                @sPassword = @vchPassword
    if @iReturn <> 0 GOTO E_OAError

CleanUp:
    return

E_OAError:
    exec dbo.dt_displayoaerror @iObjectId, @iReturn
    GOTO CleanUp


go

create proc dbo.dt_validateloginparams_u
    @vchLoginName  nvarchar(255),
    @vchPassword   nvarchar(255)
as

set nocount on

declare @iReturn int
declare @iObjectId int
select @iObjectId =0

declare @VSSGUID nvarchar(100)
select @VSSGUID = N'SQLVersionControl.VCS_SQL'

    declare @iPropertyObjectId int
    select @iPropertyObjectId = (select objectid from dbo.dtproperties where property = 'VCSProjectID')

    declare @vchSourceSafeINI nvarchar(255)
    exec dbo.dt_getpropertiesbyid_vcs_u @iPropertyObjectId, 'VCSSourceSafeINI', @vchSourceSafeINI OUT

    exec @iReturn = sp_OACreate @VSSGUID, @iObjectId OUT
    if @iReturn <> 0 GOTO E_OAError

    exec @iReturn = sp_OAMethod @iObjectId,
                                N'ValidateLoginParams',
                                NULL,
                                @sSourceSafeINI = @vchSourceSafeINI,
                                @sLoginName = @vchLoginName,
                                @sPassword = @vchPassword
    if @iReturn <> 0 GOTO E_OAError

CleanUp:
    return

E_OAError:
    exec dbo.dt_displayoaerror_u @iObjectId, @iReturn
    GOTO CleanUp


go

create proc dbo.dt_vcsenabled

as

set nocount on

declare @iObjectId int
select @iObjectId = 0

declare @VSSGUID varchar(100)
select @VSSGUID = 'SQLVersionControl.VCS_SQL'

    declare @iReturn int
    exec @iReturn = sp_OACreate @VSSGUID, @iObjectId OUT
    if @iReturn <> 0 raiserror('', 16, -1) /* Can't Load Helper DLLC */


go

/*
**	This procedure returns the version number of the stored
**    procedures used by the Microsoft Visual Database Tools.
**    Current version is 7.0.00.
*/
create procedure dbo.dt_verstamp006
as
	select 7000
go

create proc dbo.dt_whocheckedout
        @chObjectType  char(4),
        @vchObjectName varchar(255),
        @vchLoginName  varchar(255),
        @vchPassword   varchar(255)

as

set nocount on

declare @iReturn int
declare @iObjectId int
select @iObjectId =0

declare @VSSGUID varchar(100)
select @VSSGUID = 'SQLVersionControl.VCS_SQL'

    declare @iPropertyObjectId int

    select @iPropertyObjectId = (select objectid from dbo.dtproperties where property = 'VCSProjectID')

    declare @vchProjectName   varchar(255)
    declare @vchSourceSafeINI varchar(255)
    declare @vchServerName    varchar(255)
    declare @vchDatabaseName  varchar(255)
    exec dbo.dt_getpropertiesbyid_vcs @iPropertyObjectId, 'VCSProject',       @vchProjectName   OUT
    exec dbo.dt_getpropertiesbyid_vcs @iPropertyObjectId, 'VCSSourceSafeINI', @vchSourceSafeINI OUT
    exec dbo.dt_getpropertiesbyid_vcs @iPropertyObjectId, 'VCSSQLServer',     @vchServerName    OUT
    exec dbo.dt_getpropertiesbyid_vcs @iPropertyObjectId, 'VCSSQLDatabase',   @vchDatabaseName  OUT

    if @chObjectType = 'PROC'
    begin
        exec @iReturn = sp_OACreate @VSSGUID, @iObjectId OUT

        if @iReturn <> 0 GOTO E_OAError

        declare @vchReturnValue varchar(255)
        select @vchReturnValue = ''

        exec @iReturn = sp_OAMethod @iObjectId,
                                    'WhoCheckedOut',
                                    @vchReturnValue OUT,
                                    @sProjectName = @vchProjectName,
                                    @sSourceSafeINI = @vchSourceSafeINI,
                                    @sObjectName = @vchObjectName,
                                    @sServerName = @vchServerName,
                                    @sDatabaseName = @vchDatabaseName,
                                    @sLoginName = @vchLoginName,
                                    @sPassword = @vchPassword

        if @iReturn <> 0 GOTO E_OAError

        select @vchReturnValue

    end

CleanUp:
    return

E_OAError:
    exec dbo.dt_displayoaerror @iObjectId, @iReturn
    GOTO CleanUp


go

create proc dbo.dt_whocheckedout_u
        @chObjectType  char(4),
        @vchObjectName nvarchar(255),
        @vchLoginName  nvarchar(255),
        @vchPassword   nvarchar(255)

as

set nocount on

declare @iReturn int
declare @iObjectId int
select @iObjectId =0

declare @VSSGUID nvarchar(100)
select @VSSGUID = N'SQLVersionControl.VCS_SQL'

    declare @iPropertyObjectId int

    select @iPropertyObjectId = (select objectid from dbo.dtproperties where property = 'VCSProjectID')

    declare @vchProjectName   nvarchar(255)
    declare @vchSourceSafeINI nvarchar(255)
    declare @vchServerName    nvarchar(255)
    declare @vchDatabaseName  nvarchar(255)
    exec dbo.dt_getpropertiesbyid_vcs_u @iPropertyObjectId, 'VCSProject',       @vchProjectName   OUT
    exec dbo.dt_getpropertiesbyid_vcs_u @iPropertyObjectId, 'VCSSourceSafeINI', @vchSourceSafeINI OUT
    exec dbo.dt_getpropertiesbyid_vcs_u @iPropertyObjectId, 'VCSSQLServer',     @vchServerName    OUT
    exec dbo.dt_getpropertiesbyid_vcs_u @iPropertyObjectId, 'VCSSQLDatabase',   @vchDatabaseName  OUT

    if @chObjectType = 'PROC'
    begin
        exec @iReturn = sp_OACreate @VSSGUID, @iObjectId OUT

        if @iReturn <> 0 GOTO E_OAError

        declare @vchReturnValue nvarchar(255)
        select @vchReturnValue = ''

        exec @iReturn = sp_OAMethod @iObjectId,
                                    N'WhoCheckedOut',
                                    @vchReturnValue OUT,
                                    @sProjectName = @vchProjectName,
                                    @sSourceSafeINI = @vchSourceSafeINI,
                                    @sObjectName = @vchObjectName,
                                    @sServerName = @vchServerName,
                                    @sDatabaseName = @vchDatabaseName,
                                    @sLoginName = @vchLoginName,
                                    @sPassword = @vchPassword

        if @iReturn <> 0 GOTO E_OAError

        select @vchReturnValue

    end

CleanUp:
    return

E_OAError:
    exec dbo.dt_displayoaerror_u @iObjectId, @iReturn
    GOTO CleanUp


go

CREATE PROCEDURE [dbo].[spDelete]

@DecisionID int  

AS 

DELETE FROM DECISIONS WHERE DecisionID = @DecisionID

go

CREATE PROCEDURE dbo.spGetAllDCs

AS

SELECT
	[MemberID],
	[Prefix],
	[Member],
	[Disabled]
FROM MEMBERS
WHERE IsDC = 1
ORDER BY Member
go

CREATE PROCEDURE [dbo].[spGetAllDecisions] 

AS

SELECT 
	[DecisionID],
	D.[TypeID],
	[Reference],
	CONVERT(char(24),[PromulgatedDate],103) AS [PromulgatedDate],
	[PresidentID],
	M.Member AS P,
	[QC1ID],
	M1.Member AS QC1,
	[QC2ID],
	M2.Member AS QC2,
	[DepChairID],
	M3.Member AS DC,
	[LayMember1ID],
	M4.Member AS LM1,
	[LayMember2ID],
	M5.Member AS LM2,
	[Appellant],
	[Respondent],
	[Parties],
	[Summary],
	D.[Disabled],
	[PromulgatedDate] AS PromulgatedDate,
	[Type]

FROM DECISIONS AS D

INNER JOIN TYPES AS T ON (D.TypeID = T.TypeID)
LEFT OUTER JOIN MEMBERS AS M ON (D.PresidentID = M.MemberID)
LEFT OUTER JOIN MEMBERS AS M1 ON (D.QC1ID = M1.MemberID)
LEFT OUTER JOIN MEMBERS AS M2 ON (D.QC2ID = M2.MemberID)
LEFT OUTER JOIN MEMBERS AS M3 ON (D.DepChairID = M3.MemberID)
LEFT OUTER JOIN MEMBERS AS M4 ON (D.LayMember1ID = M4.MemberID)
LEFT OUTER JOIN MEMBERS AS M5 ON (D.LayMember2ID = M5.MemberID)

ORDER BY PromulgatedDate DESC

go

CREATE PROCEDURE dbo.spGetAllLMs

AS

SELECT
	[MemberID],
	[Prefix],
	[Member],
	[Disabled]
FROM MEMBERS
WHERE IsLM = 1
ORDER BY Member
go

CREATE PROCEDURE dbo.spGetAllNSAPs

AS

SELECT
	[MemberID],
	[Prefix],
	[Member],
	[Disabled]
FROM MEMBERS
WHERE IsNSAP = 1
ORDER BY Member
go

CREATE PROCEDURE [dbo].[spGetAllPublicDecisions] 

AS

SELECT 
	[DecisionID],
	D.[TypeID],
	[Reference],
	CONVERT(char(24),[PromulgatedDate],103) AS [PromulgatedDate],
	[PresidentID],
	M.Member AS P,
	[QC1ID],
	M1.Member AS QC1,
	[QC2ID],
	M2.Member AS QC2,
	[DepChairID],
	M3.Member AS DC,
	[LayMember1ID],
	M4.Member AS LM1,
	[LayMember2ID],
	M5.Member AS LM2,
	[Appellant],
	[Respondent],
	[Parties],
	[Summary],
	D.[Disabled],
	[PromulgatedDate] AS PromulgatedDate,
	[Type]

FROM DECISIONS AS D

INNER JOIN TYPES AS T ON (D.TypeID = T.TypeID)
LEFT OUTER JOIN MEMBERS AS M ON (D.PresidentID = M.MemberID)
LEFT OUTER JOIN MEMBERS AS M1 ON (D.QC1ID = M1.MemberID)
LEFT OUTER JOIN MEMBERS AS M2 ON (D.QC2ID = M2.MemberID)
LEFT OUTER JOIN MEMBERS AS M3 ON (D.DepChairID = M3.MemberID)
LEFT OUTER JOIN MEMBERS AS M4 ON (D.LayMember1ID = M4.MemberID)
LEFT OUTER JOIN MEMBERS AS M5 ON (D.LayMember2ID = M5.MemberID)

WHERE D.[Disabled] = 0

ORDER BY PromulgatedDate DESC


go

CREATE PROCEDURE dbo.spGetAllTypes

AS

SELECT
	[TypeID],
	[Type],
	[Disabled]
FROM TYPES

ORDER BY Type ASC
go

CREATE PROCEDURE dbo.spGetDCsForUse

AS

SELECT
	[MemberID],
	[Prefix],
	[Member],
	[Disabled]
FROM MEMBERS
WHERE IsDC = 1 AND Disabled = 0 
ORDER BY Member
go

CREATE PROCEDURE [dbo].[spGetDecisionByID] 
	
	@DecisionId int	

AS

SELECT 
	[DecisionID],
	D.[TypeID],
	[Reference],
	CONVERT(char(24),[PromulgatedDate],103) AS [PromulgatedDate],
	[PresidentID],
	M.Member AS P,
	[QC1ID],
	M1.Member AS QC1,
	[QC2ID],
	M2.Member AS QC2,
	[DepChairID],
	M3.Member AS DC,
	[LayMember1ID],
	M4.Member AS LM1,
	[LayMember2ID],
	M5.Member AS LM2,
	[Appellant],
	[Respondent],
	[Parties],
	[Summary],
	D.[Disabled],
	[HigherCourt],
	[PromulgatedDate] AS PromulgatedDate,
	[Type]

FROM DECISIONS AS D

INNER JOIN TYPES AS T ON (D.TypeID = T.TypeID)
LEFT OUTER JOIN MEMBERS AS M ON (D.PresidentID = M.MemberID)
LEFT OUTER JOIN MEMBERS AS M1 ON (D.QC1ID = M1.MemberID)
LEFT OUTER JOIN MEMBERS AS M2 ON (D.QC2ID = M2.MemberID)
LEFT OUTER JOIN MEMBERS AS M3 ON (D.DepChairID = M3.MemberID)
LEFT OUTER JOIN MEMBERS AS M4 ON (D.LayMember1ID = M4.MemberID)
LEFT OUTER JOIN MEMBERS AS M5 ON (D.LayMember2ID = M5.MemberID)

WHERE [DecisionId]=@DecisionID

ORDER BY PromulgatedDate DESC
go

CREATE PROCEDURE dbo.spGetLMsForUse

AS

SELECT
	[MemberID],
	[Prefix],
	[Member],
	[Disabled]
FROM MEMBERS
WHERE IsLM = 1 AND Disabled = 0
ORDER BY Member
go

CREATE PROCEDURE dbo.spGetMembers
AS

SELECT
	[MemberID],
	[Prefix],
	[Member],
	[IsNSAP],
	[IsDC],
	[IsLM],
	[Disabled]
FROM MEMBERS
ORDER BY Member ASC
go

CREATE PROCEDURE dbo.spGetNSAPsForUse

AS

SELECT
	[MemberID],
	[Prefix],
	[Member],
	[Disabled]
FROM MEMBERS
WHERE IsNSAP = 1 AND Disabled = 0
ORDER BY Member
go

CREATE PROCEDURE dbo.spGetTypes
AS

SELECT
	[TypeID],
	[Type],
	[Disabled]
FROM Types

go

CREATE PROCEDURE dbo.spGetTypesForUse

AS

SELECT
	[TypeID],
	[Type],
	[Disabled]
FROM TYPES
WHERE Disabled = 0
ORDER BY Type ASC
go

CREATE PROCEDURE dbo.spGetUsers
AS

SELECT
	[UserID],
	[FirstName],
	[LastName],
	[UserName],
	[Password],
	[Disabled]
FROM Users
go

CREATE PROCEDURE dbo.spGetUsersDetails
	@UserID int
	
AS

SELECT
	[UserID],
	[FirstName],
	[LastName],
	[UserName],
	[Password],
	[Disabled]
FROM Users
WHERE
	[UserID] = @UserID
go

CREATE PROCEDURE dbo.spInsert
	
	@DecisionID bigint OUTPUT,
	@JurisdictionID int,
	@Jurisdiction1ID int,
	@Date datetime,
	@AppealNumber varchar (100),
	@Appellant varchar (250),
	@Respondent varchar (500),
	@AddParties varchar (500),
	@SubjectDetail ntext,
	@Appealed varchar (50),
	@Disabled bit,
	@File1_Name varchar (250),
	@File2_Name varchar (250),
	@File2_Title varchar (250),
	@File3_Name varchar (250),
	@File3_Title varchar (250),
	@AppealURL varchar (1000),
	@TextURL varchar (250)
AS

INSERT INTO DECISIONS1 (
	[JurisdictionID],
	[Jurisdiction1ID],
	[Date],
	[AppealNumber],
	[Appellant],
	[Respondent],
	[AddParties],
	[SubjectDetail],
	[Appealed],
	[Disabled],
	[File1_Name],
	[File2_Name],
	[File2_Title],
	[File3_Name],
	[File3_Title],
	[AppealURL],
	[TextURL]
) VALUES (
	@JurisdictionID,
	@Jurisdiction1ID,
	@Date,
	@AppealNumber,
	@Appellant,
	@Respondent,
	@AddParties,
	@SubjectDetail,
	@Appealed,
	@Disabled,
	@File1_Name,
	@File2_Name,
	@File2_Title,
	@File3_Name,
	@File3_Title,
	@AppealURL,
	@TextURL
)

SELECT @DecisionID = SCOPE_IDENTITY()
go

CREATE PROCEDURE dbo.spInsertDecision
	
	@DecisionID bigint OUTPUT,
	@TypeID int,
	@Reference varchar (50),
	@PromulgatedDate datetime,
	@PresidentID int,
	@QC1ID int,
	@QC2ID int,
	@DepChairID int,
	@LayMember1ID int,
	@LayMember2ID int,
	@Appellant varchar (250),
	@Respondent varchar (500),
	@Parties varchar (750),
	@Summary ntext,
	@Disabled bit,
	@HigherCourt bit
AS

INSERT INTO Decisions (
	[TypeID],
	[Reference],
	[PromulgatedDate],
	[PresidentID],
	[QC1ID],
	[QC2ID],
	[DepChairID],
	[LayMember1ID],
	[LayMember2ID],
	[Appellant],
	[Respondent],
	[Parties],
	[Summary],
	[Disabled],
	[HigherCourt]
) VALUES (
	@TypeID,
	@Reference,
	@PromulgatedDate,
	@PresidentID,
	@QC1ID,
	@QC2ID,
	@DepChairID,
	@LayMember1ID,
	@LayMember2ID,
	@Appellant,
	@Respondent,
	@Parties,
	@Summary,
	@Disabled,
	@HigherCourt
)

SELECT @DecisionID = SCOPE_IDENTITY()
go

CREATE PROCEDURE dbo.spInsertMember
	@MemberID int OUTPUT,
	@Prefix varchar (50),
	@Member varchar(250),
	@IsNSAP bit,
	@IsDC bit,
	@IsLM bit,
	@Disabled bit
AS

INSERT INTO Members (
	[Prefix],
	[Member],
	[IsNSAP],
	[IsDC],
	[IsLM],
	[Disabled]
) VALUES (
	@Prefix,
	@Member,
	@IsNSAP,
	@IsDC,
	@IsLM,
	@Disabled
)

select SCOPE_IDENTITY()
go

CREATE PROCEDURE dbo.spInsertType
	@TypeID int OUTPUT,
	@Type varchar(250),
	@Disabled bit
AS

INSERT INTO Types (
	[Type],
	[Disabled]
) VALUES (
	@Type,
	@Disabled
)

select SCOPE_IDENTITY()


go

CREATE PROCEDURE dbo.spInsertUser
	@UserID int OUTPUT,
	@FirstName varchar(250),
	@LastName varchar(250),
	@UserName varchar(250),
	@Password varchar (250),
	@Disabled bit
AS

INSERT INTO Users (
	[FirstName],
	[LastName],
	[UserName],
	[Password],
	[Disabled]
) VALUES (
	@FirstName,
	@LastName,
	@UserName,
	@Password,
	@Disabled
)

select SCOPE_IDENTITY()
go

CREATE PROCEDURE dbo.spPopulateDetails

	@SubjectID int

AS

SELECT
	[DetailID],
	d.[SubjectID],
	[Detail],
	d.[Disabled]

FROM DETAIL AS d 

INNER JOIN SUBJECT AS s ON d.SubjectID = s.SubjectID

WHERE d.SubjectID = @SubjectID

ORDER BY Detail ASC
go

CREATE PROCEDURE dbo.spPopulateDetailsDataGrid

	@SubjectID int

AS

SELECT
	[DetailID],
	d.[SubjectID],
	[Detail],
	d.[Disabled],
	s.Subject

FROM DETAIL AS d 

INNER JOIN SUBJECT AS s ON d.SubjectID = s.SubjectID

WHERE d.SubjectID = @SubjectID

ORDER BY Detail ASC
go

CREATE PROCEDURE dbo.spPopulateDetailsList

AS

SELECT
	[DetailID],
	[SubjectID],
	[Detail],
	[Disabled]

FROM DETAIL 

WHERE Disabled = 0

ORDER BY Detail ASC
go

CREATE PROCEDURE [dbo].[spPopulateForm] 
	
	@DecisionId int	

AS

SELECT 
	[DecisionID],
	D.[JurisdictionID],
	D.[Jurisdiction1ID],
	[Date],
	[AppealNumber],
	[Appellant],
	[Respondent],
	[AddParties],
	[SubjectDetail],
	[Appealed],
	D.[Disabled],
	[File1_Name],
	[File2_Name],
	[File2_Title],
	[File3_Name],
	[File3_Title],
	[AppealURL],
	[TextURL],
	T.[tax1id],
	T.[description] AS [Description],
	T1.[description] AS [Description1]

FROM DECISIONS1 AS D

INNER JOIN TAXONOMY1 AS T ON (D.JurisdictionID = T.tax1id)
LEFT OUTER JOIN TAXONOMY1 AS T1 ON (D.Jurisdiction1ID = T1.tax1id)

WHERE [DecisionId]=@DecisionID
go

CREATE PROCEDURE dbo.spPopulateJurisdictions

AS

SELECT
	[JurisdictionID],
	[Jurisdiction],
	[Disabled]
FROM JURISDICTIONS
WHERE Disabled = 0
ORDER BY JurisdictionID ASC
go

CREATE PROCEDURE dbo.spPopulateJurisdictionsDataGrid

AS

SELECT
	[JurisdictionID],
	[Jurisdiction],
	[Disabled]
FROM JURISDICTIONS
ORDER BY Jurisdiction ASC
go

CREATE PROCEDURE dbo.spPopulateJurisdictionsPublic

AS

SELECT
	[JurisdictionID],
	[Jurisdiction],
	[Disabled]
FROM JURISDICTIONS
ORDER BY JurisdictionID ASC
go

CREATE PROCEDURE [dbo].[spPopulateRepeaterTable] 

AS

SELECT 
	[DecisionID],
	D.[JurisdictionID],
	D.[Jurisdiction1ID],
	 CONVERT(char(24),[Date],103) AS [Date],
	[AppealNumber],
	[Appellant],
	[Respondent],
	[AddParties],
	[SubjectDetail],
	[Appealed],
	D.[Disabled],
	T.[tax1id],
	T.[description] AS [Description],
	T1.[description] AS [Description1]
	
FROM DECISIONS1 AS D

INNER JOIN TAXONOMY1 AS T ON (D.JurisdictionID = T.tax1id)
LEFT OUTER JOIN TAXONOMY1 AS T1 ON (D.Jurisdiction1ID = T1.tax1id)

ORDER BY [Date] DESC
go

CREATE PROCEDURE [dbo].[spPopulateRepeaterTablePublic] 

AS

SELECT 
	[DecisionID],
	D.[JurisdictionID],
	D.[Jurisdiction1ID],
	CONVERT(char(24),[Date],103) AS [Date],
	[AppealNumber],
	[Appellant],
	[Respondent],
	[AddParties],
	[SubjectDetail],
	[Appealed],
	D.[Disabled],
	[File1_Name],
	[File2_Name],
	[File2_Title],
	[File3_Name],
	[File3_Title],
	[AppealURL],
	[TextURL],
	T.[tax1id],
	T.[description] AS [Description],
	T1.[description] AS [Description1],
	[Date] as [d]

FROM DECISIONS1 AS D

INNER JOIN TAXONOMY1 AS T ON (D.JurisdictionID = T.tax1id)
LEFT OUTER JOIN TAXONOMY1 AS T1 ON (D.Jurisdiction1ID = T1.tax1id)

WHERE D.[Disabled] = 0

ORDER BY [d] DESC
go

CREATE PROCEDURE dbo.spPopulateSubjects

AS

SELECT
	[SubjectID],
	[Subject],
	[Disabled]
FROM SUBJECT
WHERE Disabled = 0
ORDER BY Subject ASC
go

CREATE PROCEDURE dbo.spPopulateSubjectsDataGrid

AS

SELECT
	[SubjectID],
	[Subject],
	[Disabled]
FROM SUBJECT
ORDER BY Subject ASC
go

CREATE PROCEDURE dbo.spPopulateTaxonomy1

AS

SELECT
	[tax1ID],
	[description],
	[disabled]
FROM Taxonomy1
WHERE Disabled = 0
ORDER BY [description] ASC
go

CREATE PROCEDURE dbo.spPopulateTaxonomy1DataGrid

AS

SELECT
	[tax1id],
	[description],
	[disabled]
FROM TAXONOMY1
ORDER BY [description] ASC
go

CREATE PROCEDURE dbo.spPopulateTaxonomy2

@tax1id int

AS

SELECT
	t2.[tax2id],
	t2.[description],
	t2.[tax1id],
	t1.[tax1id],
	t2.[disabled]
FROM Taxonomy2 t2
INNER JOIN Taxonomy1 t1 ON t2.tax1id = t1.tax1id
WHERE t2.tax1id = @tax1id AND t2.disabled = 0
ORDER BY t2.[description] ASC
go

CREATE PROCEDURE dbo.spPopulateTaxonomy2DataGrid

@tax1id int

AS

SELECT
	t2.[tax2id],
	t2.[description],
	t1.[description] AS Jurisdiction,
	t2.[tax1id],
	t1.[tax1id],
	t2.[disabled]
FROM Taxonomy2 t2
INNER JOIN Taxonomy1 t1 ON t2.tax1id = t1.tax1id
WHERE t2.tax1id = @tax1id AND t2.disabled = 0
ORDER BY t2.[description] ASC
go

CREATE PROCEDURE dbo.spPopulateTaxonomy3

@tax2id int,
@tax1id int

AS

SELECT
	t3.[tax3id],
	t3.[tax2id],
	t2.[tax2id],
	t3.[description],
	t3.[tax1id],
	t3.[disabled]
FROM Taxonomy3 t3
INNER JOIN Taxonomy2 t2 ON t3.tax2id = t2.tax2id
WHERE t3.tax1id = @tax1id AND t3.tax2id = @tax2id AND  t3.disabled = 0
ORDER BY t3.[description] ASC
go

CREATE PROCEDURE dbo.spPopulateTaxonomy3DataGrid

@tax2id int

AS

SELECT
	t3.[tax3id],
	t3.[tax2id],
	t2.[tax2id],
	t2.[description] AS Subject,
	t3.[description],
	t3.[tax1id],
	t3.[disabled],
	t1.[description] AS Jurisdiction,
	t2.[tax1id],
	t1.[tax1id]
FROM Taxonomy3 t3
INNER JOIN Taxonomy1 t1 ON t3.tax1id = t1.tax1id
INNER JOIN Taxonomy2 t2 ON t3.tax2id = t2.tax2id
WHERE  t3.tax2id = @tax2id
ORDER BY t3.[description] ASC
go

CREATE PROCEDURE dbo.spSaveDetail

	@SubjectID int,
	@Detail varchar (300),
	@Disabled bit
AS

INSERT INTO DETAIL (
	[SubjectID],
	[Detail],
	[Disabled]
) VALUES (
	@SubjectID,
	@Detail,
	@Disabled
)

select SCOPE_IDENTITY()
go

CREATE PROCEDURE dbo.spSaveJurisdiction

	@JurisdictionID int OUTPUT,
	@Jurisdiction varchar (300),
	@Disabled bit
AS

INSERT INTO Jurisdictions (
	[Jurisdiction],
	[Disabled]
) VALUES (
	@Jurisdiction,
	@Disabled
)

select SCOPE_IDENTITY()
go

CREATE PROCEDURE dbo.spSaveSubject

	@SubjectID int OUTPUT,
	@Subject varchar (300),
	@Disabled bit
AS

INSERT INTO SUBJECT (
	[Subject],
	[Disabled]
) VALUES (
	@Subject,
	@Disabled
)

select SCOPE_IDENTITY()
go

CREATE PROCEDURE dbo.spSaveTaxonomy1

	@tax1id  int OUTPUT,
	@description varchar (1000),
	@Disabled bit
AS

INSERT INTO Taxonomy1 (
	[description],
	[Disabled]
) VALUES (
	@description,
	@Disabled
)

select SCOPE_IDENTITY()
go

CREATE PROCEDURE dbo.spUpdate
	
	@DecisionID bigint OUTPUT,
	@JurisdictionID int,
	@Jurisdiction1ID int,
	@Date datetime,
	@AppealNumber varchar (100),
	@Appellant varchar (250),
	@Respondent varchar (500),
	@AddParties varchar (500),
	@SubjectDetail ntext,
	@Appealed varchar (50),
	@Disabled bit,
	@File1_Name varchar (250),
	@File2_Name varchar (250),
	@File2_Title varchar (250),
	@File3_Name varchar (250),
	@File3_Title varchar (250),
	@AppealURL varchar (1000),
	@TextURL varchar (250)
AS

UPDATE DECISIONS1 SET 
	[JurisdictionID] = @JurisdictionID,
	[Jurisdiction1ID] = @Jurisdiction1ID,
	[Date] = @Date,
	[AppealNumber] = @AppealNumber,
	[Appellant] = @Appellant,
	[Respondent] = @Respondent,
	[AddParties] = @AddParties,
	[SubjectDetail] = @SubjectDetail,
	[Appealed] = @Appealed,
	[Disabled] = @Disabled,
	[File1_Name] = @File1_Name,
	[File2_Name] = @File2_Name,
	[File2_Title] = @File2_Title,
	[File3_Name] = @File3_Name,
	[File3_Title] = @File3_Title,
	[AppealURL] = @AppealURL,
	[TextURL] = @TextURL

WHERE [DecisionID] = @DecisionID
go

CREATE PROCEDURE dbo.spUpdateDecision
	
	@DecisionID bigint,
	@TypeID int,
	@Reference varchar (50),
	@PromulgatedDate datetime,
	@PresidentID int,
	@QC1ID int,
	@QC2ID int,
	@DepChairID int,
	@LayMember1ID int,
	@LayMember2ID int,
	@Appellant varchar (250),
	@Respondent varchar (500),
	@Parties varchar (750),
	@Summary ntext,
	@Disabled bit,
	@HigherCourt bit
AS

UPDATE Decisions SET 
	[TypeID] = @TypeID,
	[Reference] = @Reference,
	[PromulgatedDate] = @PromulgatedDate,
	[PresidentID] = @PresidentID,
	[QC1ID] = @QC1ID,
	[QC2ID] = @QC2ID,
	[DepChairID] = @DepChairID,
	[LayMember1ID] = @LayMember1ID,
	[LayMember2ID] = @LayMember2ID,
	[Appellant] = @Appellant,
	[Respondent] = @Respondent,
	[Parties] = @Parties,
	[Summary] = @Summary,
	[Disabled] = @Disabled,
	[HigherCourt] = @HigherCourt
WHERE 
	[DecisionID] = @DecisionID
go

CREATE PROCEDURE dbo.spUpdateDetail

	@DetailID int, 
	@Detail varchar (300),
	@Disabled bit
AS

UPDATE DETAIL SET

	[Detail] = @Detail,
	[Disabled] = @Disabled

WHERE [DetailID] = @DetailID
go

CREATE PROCEDURE dbo.spUpdateJurisdiction

	@JurisdictionID int, 
	@Jurisdiction varchar (300),
	@Disabled bit
AS

UPDATE Jurisdictions SET

	[Jurisdiction] = @Jurisdiction,
	[Disabled] = @Disabled

WHERE [JurisdictionID] = @JurisdictionID
go

CREATE PROCEDURE dbo.spUpdateMember
	@MemberID int, 
	@Prefix varchar (50),
	@Member varchar(250),
	@IsNSAP bit,
	@IsDC bit,
	@IsLM bit,
	@Disabled bit
AS

UPDATE Members SET
	[Prefix] = @Prefix,
	[Member] = @Member,
	[IsNSAP] = @IsNSAP,
	[IsDC] = @IsDC,
	[IsLM] = @IsLM,
	[Disabled] = @Disabled
WHERE
	[MemberID] = @MemberID
go

CREATE PROCEDURE dbo.spUpdateSubject

	@SubjectID int, 
	@Subject varchar (300),
	@Disabled bit
AS

UPDATE SUBJECT SET

	[Subject] = @Subject,
	[Disabled] = @Disabled

WHERE [SubjectID] = @SubjectID
go

CREATE PROCEDURE dbo.spUpdateTaxonomy1
	@tax1id int, 
	@description varchar (1000),
	@Disabled bit
AS

UPDATE Taxonomy1 SET

	[description] = @description,
	[Disabled] = @Disabled

WHERE [tax1id] = @tax1id
go

CREATE PROCEDURE dbo.spUpdateType
	@TypeID int, 
	@Type varchar(250),
	@Disabled bit
AS

UPDATE Types SET
	[Type] = @Type,
	[Disabled] = @Disabled
WHERE
	[TypeID] = @TypeID


go

CREATE PROCEDURE dbo.spUpdateUser
	@UserID int, 
	@FirstName varchar(250), 
	@LastName varchar(250), 
	@UserName varchar(250), 
	@Password varchar(250), 
	@Disabled bit
AS

UPDATE Users SET
	[FirstName] = @FirstName,
	[LastName] = @LastName,
	[UserName] = @UserName,
	[Password] = @Password,
	[Disabled] = @Disabled
WHERE
	[UserID] = @UserID
go

CREATE PROCEDURE [dbo].[spUsersAuthenticate]

@UserName varchar (250),
@Password varchar (250)

AS SELECT * FROM USERS
WHERE UserName = @UserName AND [Password] = @Password
go

