-- Check if the Decisions table exists
IF OBJECT_ID('dbo.Decisions', 'U') IS NOT NULL
BEGIN
    -- Step 1: Drop the primary key constraint if it exists
    DECLARE @ConstraintName NVARCHAR(255);

    -- Retrieve the primary key constraint name
    SELECT @ConstraintName = CONSTRAINT_NAME
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_NAME = 'Decisions' AND CONSTRAINT_TYPE = 'PRIMARY KEY';

    -- Drop the primary key constraint if it exists
    IF @ConstraintName IS NOT NULL
    BEGIN
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = 'ALTER TABLE Decisions DROP CONSTRAINT ' + QUOTENAME(@ConstraintName);
        EXEC sp_executesql @SQL;
    END

    -- Step 2: Add a new identity column
    ALTER TABLE Decisions ADD NewId BIGINT IDENTITY(1,1);

    -- Step 3: Drop the old DecisionID column
    ALTER TABLE Decisions DROP COLUMN DecisionID;

    -- Step 4: Rename the new identity column to DecisionID
    EXEC sp_rename 'Decisions.NewId', 'DecisionID', 'COLUMN';

    -- Step 5: Recreate the primary key constraint
    ALTER TABLE Decisions ADD CONSTRAINT PK_Decisions PRIMARY KEY CLUSTERED (DecisionID);
END
go

-- Check if the DECISIONS1 table exists
IF OBJECT_ID('dbo.DECISIONS1', 'U') IS NOT NULL
BEGIN
    -- Step 1: Drop the primary key constraint if it exists
    DECLARE @ConstraintName NVARCHAR(255);

    -- Retrieve the primary key constraint name
    SELECT @ConstraintName = CONSTRAINT_NAME
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_NAME = 'DECISIONS1' AND CONSTRAINT_TYPE = 'PRIMARY KEY';

    -- Drop the primary key constraint if it exists
    IF @ConstraintName IS NOT NULL
    BEGIN
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = 'ALTER TABLE DECISIONS1 DROP CONSTRAINT ' + QUOTENAME(@ConstraintName);
        EXEC sp_executesql @SQL;
    END

    -- Step 2: Add a new identity column
    ALTER TABLE DECISIONS1 ADD NewId BIGINT IDENTITY(1,1);

    -- Step 3: Drop the old DecisionID column
    ALTER TABLE DECISIONS1 DROP COLUMN DecisionID;

    -- Step 4: Rename the new identity column to DecisionID
    EXEC sp_rename 'DECISIONS1.NewId', 'DecisionID', 'COLUMN';

    -- Step 5: Recreate the primary key constraint
    ALTER TABLE DECISIONS1 ADD CONSTRAINT PK_DECISIONS1 PRIMARY KEY CLUSTERED (DecisionID);
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

-- Check if the Taxonomy1 table exists
IF OBJECT_ID('dbo.Taxonomy1', 'U') IS NOT NULL
BEGIN
    -- Step 1: Drop the primary key constraint if it exists
    DECLARE @ConstraintName NVARCHAR(255);

    -- Retrieve the primary key constraint name
    SELECT @ConstraintName = CONSTRAINT_NAME
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_NAME = 'Taxonomy1' AND CONSTRAINT_TYPE = 'PRIMARY KEY';

    -- Drop the primary key constraint if it exists
    IF @ConstraintName IS NOT NULL
    BEGIN
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = 'ALTER TABLE Taxonomy1 DROP CONSTRAINT ' + QUOTENAME(@ConstraintName);
        EXEC sp_executesql @SQL;
    END

    -- Step 2: Add a new identity column
    ALTER TABLE Taxonomy1 ADD NewId BIGINT IDENTITY(1,1);

    -- Step 3: Drop the old tax1id column
    ALTER TABLE Taxonomy1 DROP COLUMN tax1id;

    -- Step 4: Rename the new identity column to tax1id
    EXEC sp_rename 'Taxonomy1.NewId', 'tax1id', 'COLUMN';

    -- Step 5: Recreate the primary key constraint
    ALTER TABLE Taxonomy1 ADD CONSTRAINT PK_Taxonomy1 PRIMARY KEY CLUSTERED (tax1id);
END
go

-- Check if the Taxonomy2 table exists
IF OBJECT_ID('dbo.Taxonomy2', 'U') IS NOT NULL
BEGIN
    -- Step 1: Drop the primary key constraint if it exists
    DECLARE @ConstraintName NVARCHAR(255);

    -- Retrieve the primary key constraint name
    SELECT @ConstraintName = CONSTRAINT_NAME
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_NAME = 'Taxonomy2' AND CONSTRAINT_TYPE = 'PRIMARY KEY';

    -- Drop the primary key constraint if it exists
    IF @ConstraintName IS NOT NULL
    BEGIN
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = 'ALTER TABLE Taxonomy2 DROP CONSTRAINT ' + QUOTENAME(@ConstraintName);
        EXEC sp_executesql @SQL;
    END

    -- Step 2: Add a new identity column
    ALTER TABLE Taxonomy2 ADD NewId BIGINT IDENTITY(1,1);

    -- Step 3: Drop the old tax2id column
    ALTER TABLE Taxonomy2 DROP COLUMN tax2id;

    -- Step 4: Rename the new identity column to tax2id
    EXEC sp_rename 'Taxonomy2.NewId', 'tax2id', 'COLUMN';

    -- Step 5: Recreate the primary key constraint
    ALTER TABLE Taxonomy2 ADD CONSTRAINT PK_Taxonomy2 PRIMARY KEY CLUSTERED (tax2id);
END
go

-- Check if the Taxonomy3 table exists
IF OBJECT_ID('dbo.Taxonomy3', 'U') IS NOT NULL
BEGIN
    -- Step 1: Drop the primary key constraint if it exists
    DECLARE @ConstraintName NVARCHAR(255);

    -- Retrieve the primary key constraint name
    SELECT @ConstraintName = CONSTRAINT_NAME
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_NAME = 'Taxonomy3' AND CONSTRAINT_TYPE = 'PRIMARY KEY';

    -- Drop the primary key constraint if it exists
    IF @ConstraintName IS NOT NULL
    BEGIN
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = 'ALTER TABLE Taxonomy3 DROP CONSTRAINT ' + QUOTENAME(@ConstraintName);
        EXEC sp_executesql @SQL;
    END

    -- Step 2: Add a new identity column
    ALTER TABLE Taxonomy3 ADD NewId BIGINT IDENTITY(1,1);

    -- Step 3: Drop the old tax3id column
    ALTER TABLE Taxonomy3 DROP COLUMN tax3id;

    -- Step 4: Rename the new identity column to tax3id
    EXEC sp_rename 'Taxonomy3.NewId', 'tax3id', 'COLUMN';

    -- Step 5: Recreate the primary key constraint
    ALTER TABLE Taxonomy3 ADD CONSTRAINT PK_Taxonomy3 PRIMARY KEY CLUSTERED (tax3id);
END
go