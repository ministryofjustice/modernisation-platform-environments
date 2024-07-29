use hmlands
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

-- adds category
CREATE PROCEDURE [dbo].[spAddCat]

@catID int OUTPUT,
@catdescription varchar(200)

AS BEGIN TRANSACTION

INSERT INTO CATEGORY (catdescription)
VALUES (@catdescription)
SELECT @catID = SCOPE_IDENTITY()

INSERT INTO CATEGORY1 (catdescription)
VALUES (@catdescription)
SELECT @catID = SCOPE_IDENTITY()

IF @@ERROR <>0
BEGIN ROLLBACK TRANSACTION
RETURN 1
END

COMMIT TRANSACTION
go

-- adds deputy adjudicator
CREATE PROCEDURE [dbo].[spAddDepAdj]

@depadjID int OUTPUT,
@depadjtitle varchar(50),
@depadjfirst varchar(100),
@depadjsecond varchar(100)

AS INSERT INTO DEPUTYADJUDICATORS (depadjtitle,depadjfirst,depadjsecond)
VALUES (@depadjtitle,@depadjfirst,@depadjsecond)
SELECT @depadjID = SCOPE_IDENTITY()

go

-- adds sub category
CREATE PROCEDURE [dbo].[spAddSubCat]

@catID int OUTPUT,
@subdescription varchar(200),
@num int

AS BEGIN TRANSACTION
INSERT INTO SUBCATEGORY (catID,subdescription,num)
VALUES (@catID,@subdescription,@num)

INSERT INTO SUBCATEGORY1 (catID,subdescription,num)
VALUES (@catID,@subdescription,@num)

IF @@ERROR<>0
BEGIN
ROLLBACK TRANSACTION
RETURN 1
END

COMMIT TRANSACTION
go

-- adds user
CREATE PROCEDURE [dbo].[spAddUser]

@userID int OUTPUT,
@firstname varchar(250),
@lastname varchar(250),
@username varchar(250),
@password varchar(250)

AS INSERT INTO USERS (firstname,lastname,username,[password])
VALUES (@firstname,@lastname,@username,@password)
SELECT @userID = SCOPE_IDENTITY()
go

CREATE PROCEDURE [dbo].[spAdjList] 
AS
SELECT [depadjID],[depadjtitle],[depadjfirst],[depadjsecond] FROM DEPUTYADJUDICATORS
ORDER BY depadjID
go

-- delete category
CREATE PROCEDURE [dbo].[spDeleteCat]

@catID int  --OUTPUT

AS BEGIN TRANSACTION

DELETE FROM CATEGORY WHERE catID = @catID
--SELECT @catID = SCOPE_IDENTITY()

DELETE FROM CATEGORY1 WHERE catID = @catID
--SELECT @catID = SCOPE_IDENTITY()

IF @@ERROR <>0
BEGIN
ROLLBACK TRANSACTION
RETURN 1
END

COMMIT TRANSACTION
go

-- delete decision
CREATE PROCEDURE [dbo].[spDeleteDecision]

@id int OUTPUT,
@caseref1 varchar(50),
@caseref2 varchar(50),
@caseref3 varchar(50),
@hearingdate datetime,
@depadj int,
@applicant varchar(200),
@respondent varchar(200),
@cat1 int,
@subcat1 int,
@cat2 int,
@subcat2 int,
@notes ntext

AS DELETE FROM DECISIONS

WHERE [id] = @id

go

-- delete deputy adjudicator
CREATE PROCEDURE [dbo].[spDeleteDepAdj]

@depadjID int OUTPUT,
@depadjtitle varchar(50),
@depadjfirst varchar(100),
@depadjsecond varchar(100)

AS DELETE FROM DEPUTYADJUDICATORS WHERE depadjID = @depadjID
SELECT @depadjID = SCOPE_IDENTITY()

go

-- delete sub category
CREATE PROCEDURE [dbo].[spDeleteSubCat]

@ID int 

AS BEGIN TRANSACTION

DELETE SUBCATEGORY WHERE subcatID = @ID

DELETE SUBCATEGORY1 WHERE subcatID = @ID

IF @@ERROR <>0
BEGIN
ROLLBACK TRANSACTION
RETURN 1
END

COMMIT TRANSACTION
go

-- delete user
CREATE PROCEDURE [dbo].[spDeleteUser]

@userID int 

AS DECLARE @Count int
SELECT @Count = Count(*) FROM USERS
IF @Count >1 BEGIN DELETE USERS WHERE userID = @userID END

go

-- gets all decisions
CREATE PROCEDURE [dbo].[spGetAllDecisions] AS

SELECT [id],[caseref1],[caseref2],[caseref3],
CONVERT(char(24),[hearingdate],103) AS [hearingdate],[depadj],[applicant],[respondent],[cat1],[subcat1],[cat2],[subcat2],[depadjtitle],
[depadjfirst],[depadjsecond],[catdescription],[subdescription],[hearingdate] AS HD
FROM DECISIONS AS d
inner join DeputyAdjudicators AS da on (d.depadj = da.depadjID)
inner join Category AS cat on (d.cat1 = cat.catID)
inner join SubCategory AS scat on (d.subcat1 = scat.subcatID)
ORDER BY HD DESC
go

-- returns list of categories from the catergory1 table
CREATE PROCEDURE [dbo].[spGetCat1List] AS

SELECT [catID],[catdescription] FROM CATEGORY1
ORDER BY catID
go

-- returns list of categories from the category table
CREATE PROCEDURE [dbo].[spGetCatList] AS

SELECT [catID],[catdescription] FROM CATEGORY
ORDER BY catID
go

-- get a decision based on it ID for the decision summary page
CREATE PROCEDURE dbo.spGetDecisionByID

@id int

AS

SELECT id, caseref1, caseref2, caseref3, hearingdate, depadjtitle, depadjfirst, depadjsecond, applicant, respondent, d.depadj, d.cat1, d.subcat1, d.cat2, d.subcat2,
c.catdescription AS firstCategory, 
s.subdescription AS fisrtSubCategory,  
cc.catdescription AS secondCategory,
ss.subdescription AS secondSubCategory, 
notes

FROM DECISIONS AS d

INNER JOIN DEPUTYADJUDICATORS AS da ON (d.depadj = da.depadjID)

INNER JOIN CATEGORY AS c ON (d.cat1 = c.catID)
INNER JOIN SUBCATEGORY AS s ON (d.subcat1 = s.subcatID)

INNER JOIN CATEGORY1 AS cc ON (d.cat2 = cc.catID)
INNER JOIN SUBCATEGORY1 AS ss ON (d.subcat2 = ss.subcatID)

WHERE [id] = @id

go

-- get a decisions details based on its ID the result is used to populate the edit page for updating 
CREATE PROCEDURE [dbo].[spGetDecisionForUpdate]

@decisionID int

AS SELECT id,caseref1,caseref2,caseref3,hearingdate,depadjtitle,depadjfirst,depadjsecond,applicant,respondent,cat1,subcat1,cat2,subcat2,notes
FROM DECISIONS AS d 
INNER JOIN DEPUTYADJUDICATORS AS da ON (d.depadj = da.depadjID)

WHERE id = @decisionID
go

-- returns deput adjudicators
CREATE PROCEDURE [dbo].[spGetDepAdjList]

AS
SELECT depadjID,depadjtitle,depadjfirst,depadjsecond
FROM DEPUTYADJUDICATORS

go

-- returns list of sub categories from the subcategory1 table
CREATE PROCEDURE [dbo].[spGetSubCat1List] AS

SELECT [subcatID],[catID],[subdescription],[num] FROM SUBCATEGORY1
ORDER BY subcatID
go

CREATE PROCEDURE [dbo].[spGetSubCatByCatID] 

@catID int

AS

SELECT sc.subdescription, sc.subcatID,sc.catID, num
FROM SUBCATEGORY AS sc INNER JOIN CATEGORY AS c
ON sc.catID = c.catID
WHERE sc.catID = @catID

go

-- returns list of sub categories from the category table
CREATE PROCEDURE [dbo].[spGetSubCatList] AS

SELECT [subcatID],[catID],[subdescription],[num] FROM SUBCATEGORY
ORDER BY subcatID
go

CREATE PROCEDURE [dbo].[spGetSubCategoryListByCategory] 

@catID int

AS

SELECT subcatID, s.catID, s.num, s.subdescription, c.catID, c.catdescription as categoryname
FROM SUBCATEGORY s
inner join CATEGORY c on s.catID = c.catID
WHERE s.catID = @catID
ORDER BY s.num

go

CREATE PROCEDURE [dbo].[spGetUser] 

@userID int

AS
SELECT userID, username, [password], firstname, lastname FROM USERS WHERE userID = @userID

go

-- returns list of users
CREATE PROCEDURE [dbo].[spGetUserList]

AS SELECT userID,firstname,lastname,username,[password] FROM USERS

ORDER BY firstname
go

-- insert decision
CREATE PROCEDURE [dbo].[spInsertDecision]

@id int OUTPUT,
@caseref1 varchar(50),
@caseref2 varchar(50),
@caseref3 varchar(50),
@hearingdate datetime,
@depadj int,
@applicant varchar(200),
@respondent varchar(200),
@cat1 int,
@subcat1 int,
@cat2 int,
@subcat2 int,
@notes ntext

AS BEGIN TRANSACTION 
INSERT INTO DECISIONS 
(caseref1,caseref2,caseref3,hearingdate,depadj,applicant,respondent,cat1,subcat1,cat2,subcat2,notes)
VALUES
(@caseref1,@caseref2,@caseref3,@hearingdate,@depadj,@applicant,@respondent,@cat1,@subcat1,@cat2,@subcat2,@notes)
IF @@ERROR<>0
BEGIN ROLLBACK TRANSACTION
RETURN 1 END

SELECT @id = SCOPE_IDENTITY()

COMMIT TRANSACTION

go

-- Check if the DECISIONS table exists, if not, create it
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DECISIONS]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[DECISIONS](
        [id] [int] IDENTITY(1,1) NOT NULL,
        [caseref1] [varchar](50) NULL,
        [caseref2] [varchar](50) NULL,
        [caseref3] [varchar](50) NULL,
        [hearingdate] [datetime] NULL,
        [depadj] [int] NULL,
        [applicant] [varchar](200) NULL,
        [respondent] [varchar](200) NULL,
        [cat1] [int] NULL,
        [subcat1] [int] NULL,
        [cat2] [int] NULL,
        [subcat2] [int] NULL,
        [notes] [ntext] NULL,
        CONSTRAINT [PK_DECISIONS] PRIMARY KEY CLUSTERED ([id] ASC)
    )
END
ELSE
BEGIN
    -- If the table exists but the id column is not an identity column, modify it
    IF NOT EXISTS (SELECT * FROM sys.identity_columns WHERE object_id = OBJECT_ID('DECISIONS') AND name = 'id')
    BEGIN
        -- First, we need to drop the primary key if it exists
        IF EXISTS (SELECT * FROM sys.key_constraints WHERE object_id = OBJECT_ID('PK_DECISIONS'))
        BEGIN
            ALTER TABLE DECISIONS DROP CONSTRAINT PK_DECISIONS
        END

        -- Now we can modify the column to be an identity column
        ALTER TABLE DECISIONS DROP COLUMN id
        ALTER TABLE DECISIONS ADD id INT IDENTITY(1,1) NOT NULL

        -- Re-add the primary key
        ALTER TABLE DECISIONS ADD CONSTRAINT PK_DECISIONS PRIMARY KEY CLUSTERED (id ASC)
    END
END

go

CREATE PROCEDURE [dbo].[spLoginUser]

@username varchar (250),
@password varchar (250)

AS

SELECT * FROM USERS

WHERE username = @username AND [password] = @password
go

-- update category
CREATE PROCEDURE [dbo].[spUpdateCategory]

@catID int,
@catdescription varchar(200)

AS BEGIN TRANSACTION
UPDATE CATEGORY
SET catdescription = @catdescription
WHERE catID = @catID

UPDATE CATEGORY1
SET catdescription = @catdescription
WHERE catID = @catID

IF @@ERROR<>0
BEGIN
ROLLBACK TRANSACTION
RETURN 1
END

COMMIT TRANSACTION
go

-- update decision
CREATE PROCEDURE [dbo].[spUpdateDecision]

@id int,
@caseref1 varchar(50),
@caseref2 varchar(50),
@caseref3 varchar(50),
@hearingdate datetime,
@depadj int,
@applicant varchar(200),
@respondent varchar(200),
@cat1 int,
@subcat1 int,
@cat2 int,
@subcat2 int,
@notes ntext

AS UPDATE DECISIONS SET

caseref1 = @caseref1,
caseref2 = @caseref2,
caseref3 = @caseref3,
hearingdate = @hearingdate,
depadj = @depadj,
applicant = @applicant,
respondent = @respondent,
cat1 = @cat1,
subcat1 = @subcat1,
cat2 = @cat2,
subcat2 = @subcat2,
notes = @notes 

WHERE [id] = @id

go

-- update deputy adjudicators entry
CREATE PROCEDURE [dbo].[spUpdateDepAdj]

@depadjID int,
@depadjtitle varchar(50),
@depadjfirst varchar(100),
@depadjsecond varchar(100)

AS UPDATE DEPUTYADJUDICATORS 
SET depadjtitle = @depadjtitle,depadjfirst = @depadjfirst,depadjsecond = @depadjsecond
WHERE depadjID = @depadjID

go

-- update sub category
CREATE PROCEDURE [dbo].[spUpdateSubCategory]

@subcatID int,
@subdescription varchar(200),
@num int

AS BEGIN TRANSACTION 
UPDATE SUBCATEGORY
SET subdescription = @subdescription, num = @num
WHERE subcatID = @subcatID

UPDATE SUBCATEGORY1
SET subdescription = @subdescription, num = @num
WHERE subcatID = @subcatID

IF @@ERROR<>0
BEGIN
ROLLBACK TRANSACTION
RETURN 1
END

COMMIT TRANSACTION
go

-- update users entry
CREATE PROCEDURE [dbo].[spUpdateUser]

@userID int,
@firstname varchar(250),
@lastname varchar(250),
@username varchar(250),
@password varchar(250)

AS UPDATE USERS 
SET firstname = @firstname,lastname=@lastname,username = @username
WHERE userID = @userID

-- update the password if provided
IF @password IS NOT NULL AND 0 < LEN(@password)
UPDATE USERS SET [password] = @password
WHERE userID = @userID
go

