-- Check if the Decision table exists
IF OBJECT_ID('dbo.Decision', 'U') IS NOT NULL
BEGIN
    -- Step 1: Drop the primary key constraint if it exists
    DECLARE @ConstraintName NVARCHAR(255);

    -- Retrieve the primary key constraint name
    SELECT @ConstraintName = CONSTRAINT_NAME
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_NAME = 'Decision' AND CONSTRAINT_TYPE = 'PRIMARY KEY';

    -- Drop the primary key constraint if it exists
    IF @ConstraintName IS NOT NULL
    BEGIN
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = 'ALTER TABLE Decision DROP CONSTRAINT ' + QUOTENAME(@ConstraintName);
        EXEC sp_executesql @SQL;
    END

    -- Step 2: Add a new identity column
    ALTER TABLE Decision ADD NewId BIGINT IDENTITY(1,1);

    -- Step 3: Drop the old id column
    ALTER TABLE Decision DROP COLUMN id;

    -- Step 4: Rename the new identity column to id
    EXEC sp_rename 'Decision.NewId', 'id', 'COLUMN';

    -- Step 5: Recreate the primary key constraint
    ALTER TABLE Decision ADD CONSTRAINT PK_Decision PRIMARY KEY CLUSTERED (id);
END
go

-- Check if the Users table exists
IF OBJECT_ID('dbo.Users', 'U') IS NOT NULL
BEGIN
    -- Step 1: Drop the primary key constraint if it exists
    DECLARE @ConstraintName NVARCHAR(255);

    -- Retrieve the primary key constraint name
    SELECT @ConstraintName = CONSTRAINT_NAME
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_NAME = 'Users' AND CONSTRAINT_TYPE = 'PRIMARY KEY';

    -- Drop the primary key constraint if it exists
    IF @ConstraintName IS NOT NULL
    BEGIN
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = 'ALTER TABLE Users DROP CONSTRAINT ' + QUOTENAME(@ConstraintName);
        EXEC sp_executesql @SQL;
    END

    -- Step 2: Add a new identity column
    ALTER TABLE Users ADD NewId BIGINT IDENTITY(1,1);

    -- Step 3: Drop the old id column
    ALTER TABLE Users DROP COLUMN UserID;

    -- Step 4: Rename the new identity column to id
    EXEC sp_rename 'Users.NewId', 'UserID', 'COLUMN';

    -- Step 5: Recreate the primary key constraint
    ALTER TABLE Users ADD CONSTRAINT PK_Users PRIMARY KEY CLUSTERED (UserID);
END
go

-- Check if the Chairman table exists
IF OBJECT_ID('dbo.Chairman', 'U') IS NOT NULL
BEGIN
    -- Step 1: Drop the primary key constraint if it exists
    DECLARE @ConstraintName NVARCHAR(255);

    -- Retrieve the primary key constraint name
    SELECT @ConstraintName = CONSTRAINT_NAME
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_NAME = 'Chairman' AND CONSTRAINT_TYPE = 'PRIMARY KEY';

    -- Drop the primary key constraint if it exists
    IF @ConstraintName IS NOT NULL
    BEGIN
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = 'ALTER TABLE Chairman DROP CONSTRAINT ' + QUOTENAME(@ConstraintName);
        EXEC sp_executesql @SQL;
    END

    -- Step 2: Add a new identity column
    ALTER TABLE Chairman ADD NewId BIGINT IDENTITY(1,1);

    -- Step 3: Drop the old id column
    ALTER TABLE Chairman DROP COLUMN id;

    -- Step 4: Rename the new identity column to id
    EXEC sp_rename 'Chairman.NewId', 'id', 'COLUMN';

    -- Step 5: Recreate the primary key constraint
    ALTER TABLE Chairman ADD CONSTRAINT PK_Chairman PRIMARY KEY CLUSTERED (id);
END
go

