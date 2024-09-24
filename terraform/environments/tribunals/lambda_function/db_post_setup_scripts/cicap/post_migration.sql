-- Check if the CaseDetails table exists
IF OBJECT_ID('dbo.CaseDetails', 'U') IS NOT NULL
BEGIN
    -- Step 1: Create a new table with the IDENTITY property
    CREATE TABLE CaseDetails_New (
        CaseID INT IDENTITY(1,1) PRIMARY KEY,
        Citation1 VARCHAR(50),
        Citation2 VARCHAR(50),
        Citation3 VARCHAR(50),
        Citation4 VARCHAR(50),
        DecisionDate DATETIME,
        CaseName VARCHAR(500),
        Scheme INT,
        ParaNumber VARCHAR(50),
        Keywords NTEXT,
        Summary NTEXT,
        Disabled BIT
    );

    -- Step 2: Set IDENTITY_INSERT to ON to allow explicit values to be inserted into the identity column
    SET IDENTITY_INSERT CaseDetails_New ON;

    -- Step 3: Copy data from the old table to the new table, including the identity values
    INSERT INTO CaseDetails_New (
        CaseID,
        Citation1,
        Citation2,
        Citation3,
        Citation4,
        DecisionDate,
        CaseName,
        Scheme,
        ParaNumber,
        Keywords,
        Summary,
        Disabled
    )
    SELECT
        CaseID,
        Citation1,
        Citation2,
        Citation3,
        Citation4,
        DecisionDate,
        CaseName,
        Scheme,
        ParaNumber,
        Keywords,
        Summary,
        Disabled
    FROM CaseDetails;

    -- Step 4: Set IDENTITY_INSERT to OFF
    SET IDENTITY_INSERT CaseDetails_New OFF;

    -- Step 5: Drop the old table
    DROP TABLE CaseDetails;

    -- Step 6: Rename the new table to the original table name
    EXEC sp_rename 'CaseDetails_New', 'CaseDetails';
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