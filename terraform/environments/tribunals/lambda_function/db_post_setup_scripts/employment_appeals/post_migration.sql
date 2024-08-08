-- Check if the Judgment table exists
IF OBJECT_ID('dbo.Judgment', 'U') IS NOT NULL
BEGIN
    -- Step 1: Drop the primary key constraint if it exists
    DECLARE @ConstraintName NVARCHAR(255);

    -- Retrieve the primary key constraint name
    SELECT @ConstraintName = CONSTRAINT_NAME
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_NAME = 'Judgment' AND CONSTRAINT_TYPE = 'PRIMARY KEY';

    -- Drop the primary key constraint if it exists
    IF @ConstraintName IS NOT NULL
    BEGIN
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = 'ALTER TABLE Judgment DROP CONSTRAINT ' + QUOTENAME(@ConstraintName);
        EXEC sp_executesql @SQL;
    END

    -- Step 2: Add a new identity column
    ALTER TABLE Judgment ADD NewId BIGINT IDENTITY(1,1);

    -- Step 3: Drop the old id column
    ALTER TABLE Judgment DROP COLUMN id;

    -- Step 4: Rename the new identity column to id
    EXEC sp_rename 'Judgment.NewId', 'id', 'COLUMN';

    -- Step 5: Recreate the primary key constraint
    ALTER TABLE Judgment ADD CONSTRAINT PK_Judgment PRIMARY KEY CLUSTERED (id);
END
go

-- Check if the ValidUsers table exists
IF OBJECT_ID('dbo.ValidUsers', 'U') IS NOT NULL
BEGIN
    -- Step 1: Drop the primary key constraint if it exists
    DECLARE @ConstraintName NVARCHAR(255);

    -- Retrieve the primary key constraint name
    SELECT @ConstraintName = CONSTRAINT_NAME
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_NAME = 'ValidUsers' AND CONSTRAINT_TYPE = 'PRIMARY KEY';

    -- Drop the primary key constraint if it exists
    IF @ConstraintName IS NOT NULL
    BEGIN
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = 'ALTER TABLE ValidUsers DROP CONSTRAINT ' + QUOTENAME(@ConstraintName);
        EXEC sp_executesql @SQL;
    END

    -- Step 2: Add a new identity column
    ALTER TABLE ValidUsers ADD NewId BIGINT IDENTITY(1,1);

    -- Step 3: Drop the old id column
    ALTER TABLE ValidUsers DROP COLUMN id;

    -- Step 4: Rename the new identity column to id
    EXEC sp_rename 'ValidUsers.NewId', 'id', 'COLUMN';

    -- Step 5: Recreate the primary key constraint
    ALTER TABLE ValidUsers ADD CONSTRAINT PK_ValidUsers PRIMARY KEY CLUSTERED (id);
END
go


-- Check if the causelist table exists
IF OBJECT_ID('dbo.causelist', 'U') IS NOT NULL
BEGIN
    -- Step 1: Drop the primary key constraint if it exists
    DECLARE @ConstraintName NVARCHAR(255);

    -- Retrieve the primary key constraint name
    SELECT @ConstraintName = CONSTRAINT_NAME
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_NAME = 'causelist' AND CONSTRAINT_TYPE = 'PRIMARY KEY';

    -- Drop the primary key constraint if it exists
    IF @ConstraintName IS NOT NULL
    BEGIN
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = 'ALTER TABLE causelist DROP CONSTRAINT ' + QUOTENAME(@ConstraintName);
        EXEC sp_executesql @SQL;
    END

    -- Step 2: Add a new identity column
    ALTER TABLE causelist ADD NewId BIGINT IDENTITY(1,1);

    -- Step 3: Drop the old id column
    ALTER TABLE causelist DROP COLUMN id;

    -- Step 4: Rename the new identity column to id
    EXEC sp_rename 'causelist.NewId', 'id', 'COLUMN';

    -- Step 5: Recreate the primary key constraint
    ALTER TABLE causelist ADD CONSTRAINT PK_causelist PRIMARY KEY CLUSTERED (id);
END
go
