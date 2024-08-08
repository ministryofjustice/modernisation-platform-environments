use carestandards
go

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

    exec @iReturn = master.dbo.sp_OACreate @VSSGUID, @iObjectId OUT
    if @iReturn <> 0 GOTO E_OAError


    /* Create Project in SS */
    exec @iReturn = master.dbo.sp_OAMethod @iObjectId,
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
    
    select @iObjectCount = 0;

CleanUp:
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

grant execute on dbo.dt_addtosourcecontrol to [public]
go

create proc dbo.dt_addtosourcecontrol_u
    @vchSourceSafeINI nvarchar(255) = '',
    @vchProjectName   nvarchar(255) ='',
    @vchComment       nvarchar(255) ='',
    @vchLoginName     nvarchar(255) ='',
    @vchPassword      nvarchar(255) =''

as
	-- This procedure should no longer be called;  dt_addtosourcecontrol should be called instead.
	-- Calls are forwarded to dt_addtosourcecontrol to maintain backward compatibility
	set nocount on
	exec dbo.dt_addtosourcecontrol 
		@vchSourceSafeINI, 
		@vchProjectName, 
		@vchComment, 
		@vchLoginName, 
		@vchPassword


go

grant execute on dbo.dt_addtosourcecontrol_u to [public]
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

grant execute on dbo.dt_adduserobject to [public]
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

grant execute on dbo.dt_adduserobject_vcs to [public]
go

create proc dbo.dt_checkinobject
    @chObjectType  char(4),
    @vchObjectName varchar(255),
    @vchComment    varchar(255)='',
    @vchLoginName  varchar(255),
    @vchPassword   varchar(255)='',
    @iVCSFlags     int = 0,
    @iActionFlag   int = 0,   /* 0 => AddFile, 1 => CheckIn */
    @txStream1     Text = '', /* drop stream   */ /* There is a bug that if items are NULL they do not pass to OLE servers */
    @txStream2     Text = '', /* create stream */
    @txStream3     Text = ''  /* grant stream  */


as

	set nocount on

	declare @iReturn int
	declare @iObjectId int
	select @iObjectId = 0
	declare @iStreamObjectId int

	declare @VSSGUID varchar(100)
	select @VSSGUID = 'SQLVersionControl.VCS_SQL'

	declare @iPropertyObjectId int
	select @iPropertyObjectId  = 0

    select @iPropertyObjectId = (select objectid from dbo.dtproperties where property = 'VCSProjectID')

    declare @vchProjectName   varchar(255)
    declare @vchSourceSafeINI varchar(255)
    declare @vchServerName    varchar(255)
    declare @vchDatabaseName  varchar(255)
    declare @iReturnValue	  int
    declare @pos			  int
    declare @vchProcLinePiece varchar(255)

    
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

        exec @iReturn = master.dbo.sp_OACreate @VSSGUID, @iObjectId OUT
        if @iReturn <> 0 GOTO E_OAError

        exec @iReturn = master.dbo.sp_OAGetProperty @iObjectId, 'GetStreamObject', @iStreamObjectId OUT
        if @iReturn <> 0 GOTO E_OAError
        
        if @iActionFlag = 1
        begin
            
            declare @iStreamLength int
			
			select @pos=1
			select @iStreamLength = datalength(@txStream2)
			
			if @iStreamLength > 0
			begin
			
				while @pos < @iStreamLength
				begin
						
					select @vchProcLinePiece = substring(@txStream2, @pos, 255)
					
					exec @iReturn = master.dbo.sp_OAMethod @iStreamObjectId, 'AddStream', @iReturnValue OUT, @vchProcLinePiece
            		if @iReturn <> 0 GOTO E_OAError
            		
					select @pos = @pos + 255
					
				end
            
				exec @iReturn = master.dbo.sp_OAMethod @iObjectId,
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
        end
        else
        begin
        
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
                select @pos = 1
                declare @iCurLineSize int
                select @iCurLineSize = len((select text from #ProcLines where colid = @iCurProcLine))
                while @pos <= @iCurLineSize
                begin                
                    select @vchProcLinePiece = convert(varchar(255),
                        substring((select text from #ProcLines where colid = @iCurProcLine),
                                  @pos, 255 ))
                    exec @iReturn = master.dbo.sp_OAMethod @iStreamObjectId, 'AddStream', @iReturnValue OUT, @vchProcLinePiece
                    if @iReturn <> 0 GOTO E_OAError
                    select @pos = @pos + 255                  
                end
                select @iCurProcLine = @iCurProcLine + 1
            end
            drop table #ProcLines

            exec @iReturn = master.dbo.sp_OAMethod @iObjectId,
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

grant execute on dbo.dt_checkinobject to [public]
go

create proc dbo.dt_checkinobject_u
    @chObjectType  char(4),
    @vchObjectName nvarchar(255),
    @vchComment    nvarchar(255)='',
    @vchLoginName  nvarchar(255),
    @vchPassword   nvarchar(255)='',
    @iVCSFlags     int = 0,
    @iActionFlag   int = 0,   /* 0 => AddFile, 1 => CheckIn */
    @txStream1     text = '',  /* drop stream   */ /* There is a bug that if items are NULL they do not pass to OLE servers */
    @txStream2     text = '',  /* create stream */
    @txStream3     text = ''   /* grant stream  */

as	
	-- This procedure should no longer be called;  dt_checkinobject should be called instead.
	-- Calls are forwarded to dt_checkinobject to maintain backward compatibility.
	set nocount on
	exec dbo.dt_checkinobject
		@chObjectType,
		@vchObjectName,
		@vchComment,
		@vchLoginName,
		@vchPassword,
		@iVCSFlags,
		@iActionFlag,   
		@txStream1,		
		@txStream2,		
		@txStream3


go

grant execute on dbo.dt_checkinobject_u to [public]
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

        exec @iReturn = master.dbo.sp_OACreate @VSSGUID, @iObjectId OUT

        if @iReturn <> 0 GOTO E_OAError

        exec @iReturn = master.dbo.sp_OAMethod @iObjectId,
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


        exec @iReturn = master.dbo.sp_OAGetProperty @iObjectId, 'GetStreamObject', @iStreamObjectId OUT

        if @iReturn <> 0 GOTO E_OAError

        create table #commenttext (id int identity, sourcecode varchar(255))


        select @vchTempText = 'STUB'
        while @vchTempText is not null
        begin
            exec @iReturn = master.dbo.sp_OAMethod @iStreamObjectId, 'GetStream', @iReturnValue OUT, @vchTempText OUT
            if @iReturn <> 0 GOTO E_OAError
            
            if (@vchTempText = '') set @vchTempText = null
            if (@vchTempText is not null) insert into #commenttext (sourcecode) select @vchTempText
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

grant execute on dbo.dt_checkoutobject to [public]
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

	-- This procedure should no longer be called;  dt_checkoutobject should be called instead.
	-- Calls are forwarded to dt_checkoutobject to maintain backward compatibility.
	set nocount on
	exec dbo.dt_checkoutobject
		@chObjectType,  
		@vchObjectName, 
		@vchComment,    
		@vchLoginName,  
		@vchPassword,  
		@iVCSFlags,    
		@iActionFlag


go

grant execute on dbo.dt_checkoutobject_u to [public]
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

    exec @hr = master.dbo.sp_OAGetErrorInfo @iObject, @vchSource OUT, @vchDescription OUT

    select @vchOutput = @vchSource + ': ' + @vchDescription
    raiserror (@vchOutput,16,-1)

    return

go

grant execute on dbo.dt_displayoaerror to [public]
go

CREATE PROCEDURE dbo.dt_displayoaerror_u
    @iObject int,
    @iresult int
as
	-- This procedure should no longer be called;  dt_displayoaerror should be called instead.
	-- Calls are forwarded to dt_displayoaerror to maintain backward compatibility.
	set nocount on
	exec dbo.dt_displayoaerror
		@iObject,
		@iresult


go

grant execute on dbo.dt_displayoaerror_u to [public]
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

grant execute on dbo.dt_droppropertiesbyid to [public]
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

grant execute on dbo.dt_dropuserobjectbyid to [public]
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

grant execute on dbo.dt_generateansiname to [public]
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

grant execute on dbo.dt_getobjwithprop to [public]
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

grant execute on dbo.dt_getobjwithprop_u to [public]
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

grant execute on dbo.dt_getpropertiesbyid to [public]
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

grant execute on dbo.dt_getpropertiesbyid_u to [public]
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

grant execute on dbo.dt_getpropertiesbyid_vcs to [public]
go

create procedure dbo.dt_getpropertiesbyid_vcs_u
    @id       int,
    @property varchar(64),
    @value    nvarchar(255) = NULL OUT

as

    -- This procedure should no longer be called;  dt_getpropertiesbyid_vcsshould be called instead.
	-- Calls are forwarded to dt_getpropertiesbyid_vcs to maintain backward compatibility.
	set nocount on
    exec dbo.dt_getpropertiesbyid_vcs
		@id,
		@property,
		@value output

go

grant execute on dbo.dt_getpropertiesbyid_vcs_u to [public]
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

    if (@vchProjectName = '')	set @vchProjectName		= null
    if (@vchSourceSafeINI = '') set @vchSourceSafeINI	= null
    if (@vchServerName = '')	set @vchServerName		= null
    if (@vchDatabaseName = '')	set @vchDatabaseName	= null
    
    if (@vchProjectName is null) or (@vchSourceSafeINI is null) or (@vchServerName is null) or (@vchDatabaseName is null)
    begin
        RAISERROR('Not Under Source Control',16,-1)
        return
    end

    if @iWhoToo = 1
    begin

        /* Get List of Procs in the project */
        exec @iReturn = master.dbo.sp_OACreate @VSSGUID, @iObjectId OUT
        if @iReturn <> 0 GOTO E_OAError

        exec @iReturn = master.dbo.sp_OAMethod @iObjectId,
												'GetListOfObjects',
												NULL,
												@vchProjectName,
												@vchSourceSafeINI,
												@vchServerName,
												@vchDatabaseName,
												@vchLoginName,
												@vchPassword

        if @iReturn <> 0 GOTO E_OAError

        exec @iReturn = master.dbo.sp_OAGetProperty @iObjectId, 'GetStreamObject', @iStreamObjectId OUT

        if @iReturn <> 0 GOTO E_OAError

        create table #ObjectList (id int identity, vchObjectlist varchar(255))

        select @vchTempText = 'STUB'
        while @vchTempText is not null
        begin
            exec @iReturn = master.dbo.sp_OAMethod @iStreamObjectId, 'GetStream', @iReturnValue OUT, @vchTempText OUT
            if @iReturn <> 0 GOTO E_OAError
            
            if (@vchTempText = '') set @vchTempText = null
            if (@vchTempText is not null) insert into #ObjectList (vchObjectlist ) select @vchTempText
        end

        select vchObjectlist from #ObjectList order by id
    end

CleanUp:
    return

E_OAError:
    exec dbo.dt_displayoaerror @iObjectId, @iReturn
    goto CleanUp


go

grant execute on dbo.dt_isundersourcecontrol to [public]
go

create proc dbo.dt_isundersourcecontrol_u
    @vchLoginName nvarchar(255) = '',
    @vchPassword  nvarchar(255) = '',
    @iWhoToo      int = 0 /* 0 => Just check project; 1 => get list of objs */

as
	-- This procedure should no longer be called;  dt_isundersourcecontrol should be called instead.
	-- Calls are forwarded to dt_isundersourcecontrol to maintain backward compatibility.
	set nocount on
	exec dbo.dt_isundersourcecontrol
		@vchLoginName,
		@vchPassword,
		@iWhoToo


go

grant execute on dbo.dt_isundersourcecontrol_u to [public]
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

grant execute on dbo.dt_removefromsourcecontrol to [public]
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

grant execute on dbo.dt_setpropertybyid to [public]
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

grant execute on dbo.dt_setpropertybyid_u to [public]
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

    exec @iReturn = master.dbo.sp_OACreate @VSSGUID, @iObjectId OUT
    if @iReturn <> 0 GOTO E_OAError

    exec @iReturn = master.dbo.sp_OAMethod @iObjectId,
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

grant execute on dbo.dt_validateloginparams to [public]
go

create proc dbo.dt_validateloginparams_u
    @vchLoginName  nvarchar(255),
    @vchPassword   nvarchar(255)
as

	-- This procedure should no longer be called;  dt_validateloginparams should be called instead.
	-- Calls are forwarded to dt_validateloginparams to maintain backward compatibility.
	set nocount on
	exec dbo.dt_validateloginparams
		@vchLoginName,
		@vchPassword


go

grant execute on dbo.dt_validateloginparams_u to [public]
go

create proc dbo.dt_vcsenabled

as

set nocount on

declare @iObjectId int
select @iObjectId = 0

declare @VSSGUID varchar(100)
select @VSSGUID = 'SQLVersionControl.VCS_SQL'

    declare @iReturn int
    exec @iReturn = master.dbo.sp_OACreate @VSSGUID, @iObjectId OUT
    if @iReturn <> 0 raiserror('', 16, -1) /* Can't Load Helper DLLC */


go

grant execute on dbo.dt_vcsenabled to [public]
go

/*
**	This procedure returns the version number of the stored
**    procedures used by legacy versions of the Microsoft
**	Visual Database Tools.  Version is 7.0.00.
*/
create procedure dbo.dt_verstamp006
as
	select 7000
go

grant execute on dbo.dt_verstamp006 to [public]
go

/*
**	This procedure returns the version number of the stored
**    procedures used by the the Microsoft Visual Database Tools.
**	Version is 7.0.05.
*/
create procedure dbo.dt_verstamp007
as
	select 7005
go

grant execute on dbo.dt_verstamp007 to [public]
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
        exec @iReturn = master.dbo.sp_OACreate @VSSGUID, @iObjectId OUT

        if @iReturn <> 0 GOTO E_OAError

        declare @vchReturnValue varchar(255)
        select @vchReturnValue = ''

        exec @iReturn = master.dbo.sp_OAMethod @iObjectId,
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

grant execute on dbo.dt_whocheckedout to [public]
go

create proc dbo.dt_whocheckedout_u
        @chObjectType  char(4),
        @vchObjectName nvarchar(255),
        @vchLoginName  nvarchar(255),
        @vchPassword   nvarchar(255)

as

	-- This procedure should no longer be called;  dt_whocheckedout should be called instead.
	-- Calls are forwarded to dt_whocheckedout to maintain backward compatibility.
	set nocount on
	exec dbo.dt_whocheckedout
		@chObjectType, 
		@vchObjectName,
		@vchLoginName, 
		@vchPassword


go

grant execute on dbo.dt_whocheckedout_u to [public]
go

CREATE PROCEDURE [dbo].[spAddCategory] 

@description varchar(100)

AS

INSERT
	Category
	(
		[description]
	)

VALUES
	(
		@description
	)


go

CREATE PROCEDURE [dbo].[spAddChairman] 

@Prefix varchar(100),
@Surname varchar(300),
@Suffix varchar(100)

AS

INSERT
	Chairman
	(
		prefix,
		surname,
		suffix
	)

VALUES
	(
		@Prefix,
		@surname,
		@suffix
	)


go

CREATE PROCEDURE [dbo].[spAddChairmanDecisionMap] 

@ChairmanID int,
@DecisionID int

AS

INSERT
	ChairmanDecisionMap
	(
		Chairman_ID,
		Decision_ID
	)
	
	VALUES
	(
		@ChairmanID,
		@DecisionID
	)


go

CREATE PROCEDURE [dbo].[spAddDecision]

               @id int OUTPUT,
	       @file_no_1 varchar(50),
               @file_no_2 varchar(50),
               @file_no_3 varchar(50),
               @decision_datetime datetime,
               @appellant varchar(500),
               @respondent varchar(500),
@chairman_id bigint,
               @schedule_id bigint, 
              @main_category_id bigint,
               @main_subcategory_id bigint,               
               @headnote_summary ntext,
               @Is_public bit
AS

DECLARE @publication_datetime  datetime

IF @Is_public = 1
        SELECT @publication_datetime = getdate()



INSERT
         DECISION
            (
              
               file_no_1,
               file_no_2,
               file_no_3,
               decision_datetime,
               appellant,
               respondent,
	chairman_id,
               schedule_id,
               main_category_id,
               main_subcategory_id,
               headnote_summary,
               created_datetime,
               last_updatedtime,
               publication_datetime,
               Is_public
              
          )
       VALUES
          (
          
               @file_no_1,
               @file_no_2,
               @file_no_3,
               @decision_datetime,
               @appellant,
               @respondent,
               @chairman_id,
               @schedule_id, 
               @main_category_id,
               @main_subcategory_id,
               @headnote_summary,
               getdate(),
               getdate(),
               --getdate(),
              @publication_datetime,
              @Is_public
             
          )
SELECT @id = SCOPE_IDENTITY()
go

CREATE PROCEDURE dbo.spAddSchedule 

@description varchar(100)

AS

INSERT
	Schedule
	(
		[description]
	)

VALUES
	(
		@description
	)


go

CREATE PROCEDURE [dbo].[spAddSubCategory] 
@parent_num tinyint,
@description varchar(100),
@num tinyint
AS
INSERT
	Subcategory
	(
		parent_num,
		[description],
		num
	)
VALUES
	(
		@parent_num,
		@description,
		@num
	)

go



CREATE PROCEDURE [dbo].[spAddUser] 

@UserID integer OUTPUT,
@Username varchar(50),
@Password varchar(50),
@Firstname varchar(50),
@Lastname varchar(50)

AS

INSERT 
	Users

	(
		Username,
		[Password],
		Firstname,
		Lastname
	)

VALUES

	(
		@Username,
		@Password,
		@Firstname,
		@Lastname
	)

SELECT @UserID = SCOPE_IDENTITY()


go

CREATE PROCEDURE dbo.spAllDecisionPublicArea
@CurrentPage int,
		@PageSize int,
		@TotalRecords int output
	AS
-- Create a temp table to hold the current page of data
-- Add and ID Column to count the decisions
Create TABLE #TempTable
(
ID int PRIMARY KEY,
decision_datetime datetime,
file_no_1 varchar(100),
file_no_2 varchar(100),
file_no_3 varchar(100),
respondent varchar(500),
appellant varchar(500),
headnote_summary ntext,
scheduleDescription varchar(100),
scheduleNum int
)
-- Fill the temp table with Decisions Data
INSERT INTO #TempTable
(
ID,
decision_datetime,
file_no_1,
file_no_2,
file_no_3,
respondent,
appellant,
headnote_summary,
scheduleDescription,
scheduleNum
)
SELECT ID, 
decision_datetime,
file_no_1,
file_no_2,
file_no_3,
respondent,
appellant,
headnote_summary,
description AS scheduleDescription,
num As scheduleNum
From dbo.DECISION inner join dbo.SCHEDULE ON dbo.DECISION.schedule_id = dbo.SCHEDULE.num 
-- Create variable to identify the first and last record that should be selected
DECLARE @FirstRec int, @LastRec int
SELECT @FirstRec = (@CurrentPage - 1) * @PageSize
SELECT @LastRec = (@CurrentPage * @PageSize + 1)
	-- Select one page of data based on the record numbers above
Select
ID,
decision_datetime,
file_no_1,
file_no_2,
file_no_3,
respondent,
appellant,
headnote_summary,
scheduleDescription,
scheduleNum
From #TempTable
WHERE
ID > @FirstRec
AND
ID < @LastRec
-- Return the total number of records availbale as an output parameter
SELECT @TotalRecords = COUNT(*) FROM dbo.DECISION inner join dbo.SCHEDULE ON dbo.DECISION.schedule_id = dbo.SCHEDULE.num
	/* SET NOCOUNT ON */
go

CREATE PROCEDURE [dbo].[spCountCategoryBySchedule] 
@ScheduleId int
AS
SELECT
	COUNT(*)
FROM
	Category
WHERE
	parent_num = @ScheduleId

go

CREATE PROCEDURE [dbo].[spCountDecisionsByChairman] 

@Id int

AS

SELECT
	COUNT(*) as chairman_id

FROM
	Decision inner join Chairman ON(Decision.chairman_id = Chairman.id)

WHERE
	Decision.chairman_id = @Id

go

CREATE PROCEDURE [dbo].[spCountSubCategoryByCategory] 
@CategoryId int
AS
SELECT
	COUNT(*)
FROM
	Subcategory
WHERE
	parent_num = @CategoryId

go

CREATE PROCEDURE [dbo].[spDefaultResults] 
AS
SELECT d.id AS ID , respondent, appellant, CONVERT(char(24),decision_datetime,101)AS decision_datetime,file_no_1, file_no_2, file_no_3,Description
                FROM DECISION d INNER JOIN Schedule  ON (d.schedule_id= Schedule.num) 
                ORDER BY d.decision_datetime DESC

go

CREATE PROCEDURE [dbo].[spDeleteCategory] 

@Id int

AS

DELETE
	Category

WHERE
	Num = @Id


go

CREATE PROCEDURE [dbo].[spDeleteChairman] 

@Id int

AS

DELETE
	Chairman

WHERE
	[Id] = @Id


go

CREATE PROCEDURE [dbo].[spDeleteChairmanDecisionMap] 

@DecisionID int

AS

DELETE
	ChairmanDecisionMap

WHERE
	Decision_Id = @DecisionID


go

CREATE PROCEDURE [dbo].[spDeleteSchedule] 

@Id int

AS

DELETE
	Schedule

WHERE
	Num = @Id


go

CREATE PROCEDURE [dbo].[spDeleteUser] 

@UserID int

AS

DECLARE
@Count int

SELECT @Count = COUNT(*) FROM Users

IF @Count > 1
	BEGIN
		DELETE
			Users
		
		WHERE
			UserID = @UserID
	END

go

CREATE PROCEDURE [dbo].[spGetCategoryList] 
AS
SELECT [id], parent_num, num, [description]
FROM category
ORDER BY parent_num , num
go

CREATE PROCEDURE dbo.spGetCategoryListBySchedule 
@ScheduleId int
AS
SELECT [id], parent_num, c.num, c.[description], s.[description] as schedulename
FROM category c
inner join schedule s on c.parent_num = s.num
WHERE parent_num = @ScheduleId
ORDER BY c. num


go

CREATE PROCEDURE [dbo].[spGetChairmanList] 

AS

select [id], prefix, surname, suffix
from chairman
order by surname
go

CREATE PROCEDURE [dbo].[spGetChairmanSelected] 
@DecisionId int
AS
select [id], prefix, surname, suffix, isnull(m.commid, 0) as commid
from chairman c 
left join
	(
	select chairman_id as commid
	from chairmandecisionmap cdm
	where decision_id = @DecisionId
	) as m
on c.[id] = m.commid
order by commid desc, c.surname

go

CREATE PROCEDURE dbo.spGetDecision
@DecisionId int
As
select Decision.schedule_id,main_category_id,main_subcategory_id,chairman_id, Is_public,last_updatedtime,created_datetime,publication_datetime, Decision.id,appellant,respondent, Schedule.description As SchDescription,Category.description As CatDescription,file_no_1,file_no_2,file_no_3,decision_datetime,headnote_summary,SubCategory.description As SubDescription From Decision
inner join SCHEDULE ON (Decision.schedule_id = Schedule.num) inner join
Category ON (Decision.main_category_id = Category.id) inner join
SubCategory ON (Decision.main_subcategory_id = SubCategory.id) inner join
Chairman ON (Decision.chairman_id = Chairman.[id])
WHERE Decision.id = @DecisionId
go

CREATE PROCEDURE dbo.spGetDecisionAllWithID
@DecisionId int
As
select Users.Firstname,Users.Lastname,Decision.schedule_id,main_category_id,main_subcategory_id,chairman_id, Is_public,last_updatedtime,created_datetime,publication_datetime, Decision.id,appellant,respondent, Schedule.description As SchDescription,Category.description As CatDescription,file_no_1,file_no_2,file_no_3,CONVERT(char(24),decision_datetime,101)AS decision_datetime,headnote_summary,SubCategory.description As SubDescription From Decision
inner join SCHEDULE ON (Decision.schedule_id = Schedule.num) inner join
Category ON (Decision.main_category_id = Category.id) inner join
SubCategory ON (Decision.main_subcategory_id = SubCategory.id) inner join
Chairman ON (Decision.chairman_id = Chairman.[id]) inner join Users ON (Decision.usersID = Users.UserID)
WHERE Decision.id = @DecisionId
go

CREATE PROCEDURE dbo.spGetDecisionAllWithoutID
As
select Users.Firstname,Users.Lastname,Decision.schedule_id,main_category_id,main_subcategory_id,chairman_id, Is_public,last_updatedtime,created_datetime,publication_datetime, Decision.id,appellant,respondent, Schedule.description As SchDescription,Category.description As CatDescription,file_no_1,file_no_2,file_no_3,CONVERT(char(24),decision_datetime,101)AS decision_datetime,headnote_summary,SubCategory.description As SubDescription From Decision
inner join SCHEDULE ON (Decision.schedule_id = Schedule.num) inner join
Category ON (Decision.main_category_id = Category.id) inner join
SubCategory ON (Decision.main_subcategory_id = SubCategory.id) inner join
Chairman ON (Decision.chairman_id = Chairman.[id]) inner join Users ON (Decision.usersID = Users.UserID)
go

CREATE PROCEDURE [dbo].[spGetDecisionPublished] 

@DecisionId  int,
@Is_Public bit

AS

select *  from decision d

where d.[id] = @DecisionId
and is_public = @Is_Public

go

CREATE PROCEDURE [dbo].[spGetDecisionsByChairman] 

@Id int

AS

SELECT
	Decision.id,respondent, appellant, decision_datetime, Description

FROM
	Decision inner join Chairman ON(Decision.chairman_id = Chairman.id) inner join Schedule ON (Decision.schedule_id = Schedule.num)

WHERE
	Decision.chairman_id = @Id

go

CREATE PROCEDURE [dbo].[spGetScheduleList] 

AS

SELECT num, [description]
FROM Schedule
ORDER BY num
go

CREATE PROCEDURE [dbo].[spGetSubCategoryList] 
AS
SELECT [id], parent_num, num, [description]
FROM subcategory
ORDER BY parent_num, num

go

CREATE PROCEDURE [dbo].[spGetSubCategoryListByCategory] 
@CategoryId int,
@ScheduleId int
AS
select s.[id], s.parent_id,s.num,s.[description], c.[description] as categoryname, c.num as categorynumber,s.schedule_id as schedulenumber
From subcategory s
inner join category c on s.parent_id = c.[id]
WHERE schedule_id = @ScheduleId AND c.num = @CategoryId
-----c.[id] = @CategoryId
-- AND c.parent_num = @ScheduleId
Order By s.num
go

CREATE PROCEDURE [dbo].[spGetSubCategoryListByCategory1] 
@CategoryId int

AS
SELECT s.[id], s.parent_id, s.num, s.[description], c.[description] as categoryname
FROM subcategory s
-- changes made to the equality sign of the join, changed c.num to c.id
inner join category c on s.parent_id = c.id
WHERE s.parent_id = @CategoryId
ORDER BY s. num
go

CREATE PROCEDURE [dbo].[spGetUser] 

@UserID int

AS

SELECT
	UserID, Username, [Password], Firstname, Lastname

FROM
	Users

WHERE
	UserID = @UserID


go

CREATE PROCEDURE [dbo].[spGetUserList] 

AS

SELECT
	UserID, Username, [Password], Firstname, Lastname

FROM
	Users


go

CREATE PROCEDURE [dbo].[spLoginUser]

@Username varchar(50),
@Password varchar(50)

AS

SELECT
	*

FROM
	Users

WHERE
	Username = @Username

AND
	[Password] = @Password


go

CREATE PROCEDURE [dbo].[spRecentDecisions] 
AS
SELECT d.id AS ID , respondent, appellant, CONVERT(char(24),decision_datetime,101)AS decision_datetime,file_no_1, file_no_2, file_no_3,Description
FROM DECISION d INNER JOIN Schedule ON (d.schedule_id = Schedule.num)
where decision_datetime > DATEADD(MONTH, -2, GETDATE())
ORDER BY d.decision_datetime DESC
go

CREATE PROCEDURE [dbo].[spSearchDecision]
@DecisionDate datetime,
@FromDate datetime,
@ToDate datetime,
@Appellant varchar(500),
@Respondent varchar(500),
@Category varchar(150),
@Year varchar(50),
@caseNo varchar(50),
@Prefix varchar(50)
As
select * From Decision
WHERE file_no_1 = @Prefix OR
file_no_2 = @CaseNo OR
file_no_3 = @Year OR
main_subcategory_id = @Category OR
appellant LIKE '%' + @Appellant + '%' OR
respondent LIKE '%' + @Respondent + '%' OR
decision_datetime Between @FromDate AND @ToDate

go

Create PROC [spSearchDecisionPage]
As
Select distinct d.id, d.decision_datetime As [Decision Datetime],sch.description AS [Schedule], d.respondent,d.appellant From
Decision As d inner join Chairman ch ON (d.chairman_id = ch.id) inner join
Schedule As sch ON (d.schedule_id = sch.num) inner join Category As c ON (sch.num = c.parent_num) inner join
Subcategory As s ON (c.id = s.parent_id)

go

CREATE PROC [spSearchDecisionPage1]

@Prefix varchar(100),
@CaseNo varchar(100),
@Year varchar(100),
@decision_datetime datetime,
@FromDate datetime,
@ToDate datetime,
@appellant varchar(500),
@respondent varchar(500),
@chairman_id int,
@schedule_id int,
@main_category_id int,
@main_subcategory_id int,
@startIndex int,
@endIndex int
As
Select distinct d.id, d.decision_datetime As [decision_datetime],sch.description AS [Schedule], d.respondent,d.appellant From
Decision As d inner join Chairman ch ON (d.chairman_id = ch.id) inner join
Schedule As sch ON (d.schedule_id = sch.num) inner join Category As c ON (sch.num = c.parent_num) inner join
Subcategory As s ON (c.id = s.parent_id)
WHERE ( d.id  > @startIndex AND d.id <= @endIndex) OR
file_no_1 = @Prefix OR
file_no_2 = @CaseNo OR
file_no_3 = @Year OR
appellant LIKE  @appellant 
OR
respondent LIKE @respondent OR
d.chairman_id = @chairman_id OR
d.schedule_id = @schedule_id  OR
d.main_category_id = @main_category_id OR
d.main_subcategory_id = @main_subcategory_id OR
d.decision_datetime Between @FromDate AND @ToDate
ORDER BY d.id
go

CREATE PROCEDURE [dbo].[spUpdateCategory] 

@id int,
@description varchar(100)

AS

UPDATE
	Category

SET
	[description] = @description

WHERE
	num = @id


go

CREATE PROCEDURE [dbo].[spUpdateChairman] 

@id int,
@Prefix varchar(100),
@Surname varchar(300),
@Suffix varchar(100)

AS

UPDATE
	Chairman

SET
	prefix = @Prefix,
	surname = @surname,
	suffix = @suffix

WHERE
	[id] = @id


go

CREATE PROCEDURE [dbo].[spUpdateDecision] 
@Id int,
@file_no_1 varchar(50),
@file_no_2 varchar(50),
@file_no_3 varchar(50),
@decision_datetime datetime,
@appellant varchar(500),
@respondent varchar(500),
@chairman_id int,
@schedule_id int,
@main_category_id int,
@main_subcategory_id int,
@headnote_summary ntext,
@Is_public bit

AS

DECLARE
@Publication_datetime datetime,
@CurrentlyPublished bit
SELECT @CurrentlyPublished = Is_public FROM Decision WHERE [id] = @Id
IF (@CurrentlyPublished = 0 AND @Is_public = 1)
	BEGIN
		SELECT @Publication_datetime = getdate()
	END
IF @CurrentlyPublished = 1
	BEGIN
		SELECT @Publication_datetime = Publication_datetime FROM Decision WHERE [id] = @Id
	END
IF @Is_public = 0
	BEGIN
		SELECT @Publication_datetime = NULL
	END
	UPDATE
		Decision
	
	SET
		Is_public = @Is_public,
		File_no_1 = @File_no_1,
		File_no_2 = @File_no_2,
		File_no_3 = @File_no_3,
		decision_datetime = @decision_datetime,
		Appellant = @Appellant,
		Respondent = @Respondent,
	chairman_id = @chairman_id ,
	schedule_id = @schedule_id,
	main_category_id = @main_category_id,
	main_subcategory_id = @main_subcategory_id,
		Headnote_summary = @Headnote_summary,
		Last_updatedtime = getdate(),
		Publication_datetime = @Publication_datetime
		
                                               
	
	WHERE
		[Id] = @Id
go

CREATE PROCEDURE [dbo].[spUpdateSchedule] 

@id int,
@description varchar(100)

AS

UPDATE
	Schedule

SET
	[description] = @description

WHERE
	num = @id


go

CREATE PROCEDURE [dbo].[spUpdateSubCategory] 
@id int,
@parent_num tinyint,
@description varchar(100),
@num tinyint
AS
UPDATE
	Subcategory
SET
	parent_num = @parent_num,
	[description] = @description,
	num = @num
WHERE
	[id] = @id

go

CREATE PROCEDURE [dbo].[spUpdateUser] 

@UserID int,
@Username varchar(50),
@Password varchar(50),
@Firstname varchar(50),
@Lastname varchar(50)

AS

UPDATE
	Users

SET
	Username = @Username,
	Firstname = @Firstname,
	Lastname = @Lastname

WHERE
	UserID = @UserID

-- Update the password ONLY if provided
IF @Password IS NOT NULL AND 0 < LEN(@Password)
	UPDATE Users
	SET [Password] = @Password
	WHERE UserID = @UserID


go

