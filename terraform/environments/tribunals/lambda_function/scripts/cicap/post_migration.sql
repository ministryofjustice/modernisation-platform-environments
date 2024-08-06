-- Check if the CaseDetails table exists
IF OBJECT_ID('dbo.CaseDetails', 'U') IS NOT NULL
BEGIN
    -- Step 1: Drop the primary key constraint if it exists
    DECLARE @ConstraintName NVARCHAR(255);

    -- Retrieve the primary key constraint name
    SELECT @ConstraintName = CONSTRAINT_NAME
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_NAME = 'CaseDetails' AND CONSTRAINT_TYPE = 'PRIMARY KEY';

    -- Drop the primary key constraint if it exists
    IF @ConstraintName IS NOT NULL
    BEGIN
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = 'ALTER TABLE CaseDetails DROP CONSTRAINT ' + QUOTENAME(@ConstraintName);
        EXEC sp_executesql @SQL;
    END

    -- Step 2: Add a new identity column
    ALTER TABLE CaseDetails ADD NewId BIGINT IDENTITY(1,1);

    -- Step 3: Drop the old CaseID column
    ALTER TABLE CaseDetails DROP COLUMN CaseID;

    -- Step 4: Rename the new identity column to id
    EXEC sp_rename 'CaseDetails.NewId', 'CaseID', 'COLUMN';

    -- Step 5: Recreate the primary key constraint
    ALTER TABLE CaseDetails ADD CONSTRAINT PK_CaseDetails PRIMARY KEY CLUSTERED (CaseID);
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

-- Check if the keywords table exists
IF OBJECT_ID('dbo.keywords', 'U') IS NOT NULL
BEGIN
    -- Step 1: Drop the primary key constraint if it exists
    DECLARE @ConstraintName NVARCHAR(255);

    -- Retrieve the primary key constraint name
    SELECT @ConstraintName = CONSTRAINT_NAME
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_NAME = 'keywords' AND CONSTRAINT_TYPE = 'PRIMARY KEY';

    -- Drop the primary key constraint if it exists
    IF @ConstraintName IS NOT NULL
    BEGIN
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = 'ALTER TABLE keywords DROP CONSTRAINT ' + QUOTENAME(@ConstraintName);
        EXEC sp_executesql @SQL;
    END

    -- Step 2: Add a new identity column
    ALTER TABLE keywords ADD NewId BIGINT IDENTITY(1,1);

    -- Step 3: Drop the old KeywordID column
    ALTER TABLE keywords DROP COLUMN KeywordID;

    -- Step 4: Rename the new identity column to id
    EXEC sp_rename 'keywords.NewId', 'KeywordID', 'COLUMN';

    -- Step 5: Recreate the primary key constraint
    ALTER TABLE keywords ADD CONSTRAINT PK_keywords PRIMARY KEY CLUSTERED (KeywordID);
END
go

-- Check if the Schemes table exists
IF OBJECT_ID('dbo.Schemes', 'U') IS NOT NULL
BEGIN
    -- Step 1: Drop the primary key constraint if it exists
    DECLARE @ConstraintName NVARCHAR(255);

    -- Retrieve the primary key constraint name
    SELECT @ConstraintName = CONSTRAINT_NAME
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_NAME = 'Schemes' AND CONSTRAINT_TYPE = 'PRIMARY KEY';

    -- Drop the primary key constraint if it exists
    IF @ConstraintName IS NOT NULL
    BEGIN
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = 'ALTER TABLE Schemes DROP CONSTRAINT ' + QUOTENAME(@ConstraintName);
        EXEC sp_executesql @SQL;
    END

    -- Step 2: Add a new identity column
    ALTER TABLE Schemes ADD NewId BIGINT IDENTITY(1,1);

    -- Step 3: Drop the old SchemeID column
    ALTER TABLE Schemes DROP COLUMN SchemeID;

    -- Step 4: Rename the new identity column to id
    EXEC sp_rename 'Schemes.NewId', 'SchemeID', 'COLUMN';

    -- Step 5: Recreate the primary key constraint
    ALTER TABLE Schemes ADD CONSTRAINT PK_Schemes PRIMARY KEY CLUSTERED (SchemeID);
END
go