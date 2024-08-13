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

    -- Step 3: Drop the old id column
    ALTER TABLE Decisions DROP COLUMN id;

    -- Step 4: Rename the new identity column to id
    EXEC sp_rename 'Decisions.NewId', 'id', 'COLUMN';

    -- Step 5: Recreate the primary key constraint
    ALTER TABLE Decisions ADD CONSTRAINT PK_Decisions PRIMARY KEY CLUSTERED (id);
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


-- Check if the Category table exists
IF OBJECT_ID('dbo.Category', 'U') IS NOT NULL
BEGIN
    -- Step 1: Drop the primary key constraint if it exists
    DECLARE @ConstraintName NVARCHAR(255);

    -- Retrieve the primary key constraint name
    SELECT @ConstraintName = CONSTRAINT_NAME
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_NAME = 'Category' AND CONSTRAINT_TYPE = 'PRIMARY KEY';

    -- Drop the primary key constraint if it exists
    IF @ConstraintName IS NOT NULL
    BEGIN
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = 'ALTER TABLE Category DROP CONSTRAINT ' + QUOTENAME(@ConstraintName);
        EXEC sp_executesql @SQL;
    END

    -- Step 2: Add a new identity column
    ALTER TABLE Category ADD NewId BIGINT IDENTITY(1,1);

    -- Step 3: Drop the old catID column
    ALTER TABLE Category DROP COLUMN catID;

    -- Step 4: Rename the new identity column to catID
    EXEC sp_rename 'Category.NewId', 'catID', 'COLUMN';

    -- Step 5: Recreate the primary key constraint
    ALTER TABLE Category ADD CONSTRAINT PK_Category PRIMARY KEY CLUSTERED (catID);
END
go


-- Check if the Category1 table exists
IF OBJECT_ID('dbo.Category1', 'U') IS NOT NULL
BEGIN
    -- Step 1: Drop the primary key constraint if it exists
    DECLARE @ConstraintName NVARCHAR(255);

    -- Retrieve the primary key constraint name
    SELECT @ConstraintName = CONSTRAINT_NAME
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_NAME = 'Category1' AND CONSTRAINT_TYPE = 'PRIMARY KEY';

    -- Drop the primary key constraint if it exists
    IF @ConstraintName IS NOT NULL
    BEGIN
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = 'ALTER TABLE Category1 DROP CONSTRAINT ' + QUOTENAME(@ConstraintName);
        EXEC sp_executesql @SQL;
    END

    -- Step 2: Add a new identity column
    ALTER TABLE Category1 ADD NewId BIGINT IDENTITY(1,1);

    -- Step 3: Drop the old catID column
    ALTER TABLE Category1 DROP COLUMN catID;

    -- Step 4: Rename the new identity column to catID
    EXEC sp_rename 'Category1.NewId', 'catID', 'COLUMN';

    -- Step 5: Recreate the primary key constraint
    ALTER TABLE Category1 ADD CONSTRAINT PK_Category1 PRIMARY KEY CLUSTERED (catID);
END
go

-- Check if the Subcategory table exists
IF OBJECT_ID('dbo.Subcategory', 'U') IS NOT NULL
BEGIN
    -- Step 1: Drop the primary key constraint if it exists
    DECLARE @ConstraintName NVARCHAR(255);

    -- Retrieve the primary key constraint name
    SELECT @ConstraintName = CONSTRAINT_NAME
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_NAME = 'Subcategory' AND CONSTRAINT_TYPE = 'PRIMARY KEY';

    -- Drop the primary key constraint if it exists
    IF @ConstraintName IS NOT NULL
    BEGIN
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = 'ALTER TABLE Subcategory DROP CONSTRAINT ' + QUOTENAME(@ConstraintName);
        EXEC sp_executesql @SQL;
    END

    -- Step 2: Add a new identity column
    ALTER TABLE Subcategory ADD NewId BIGINT IDENTITY(1,1);

    -- Step 3: Drop the old subcatID column
    ALTER TABLE Subcategory DROP COLUMN subcatID;

    -- Step 4: Rename the new identity column to subcatID
    EXEC sp_rename 'Subcategory.NewId', 'subcatID', 'COLUMN';

    -- Step 5: Recreate the primary key constraint
    ALTER TABLE Subcategory ADD CONSTRAINT PK_Subcategory PRIMARY KEY CLUSTERED (subcatID);
END
go


-- Check if the Subcategory1 table exists
IF OBJECT_ID('dbo.Subcategory1', 'U') IS NOT NULL
BEGIN
    -- Step 1: Drop the primary key constraint if it exists
    DECLARE @ConstraintName NVARCHAR(255);

    -- Retrieve the primary key constraint name
    SELECT @ConstraintName = CONSTRAINT_NAME
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_NAME = 'Subcategory1' AND CONSTRAINT_TYPE = 'PRIMARY KEY';

    -- Drop the primary key constraint if it exists
    IF @ConstraintName IS NOT NULL
    BEGIN
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = 'ALTER TABLE Subcategory1 DROP CONSTRAINT ' + QUOTENAME(@ConstraintName);
        EXEC sp_executesql @SQL;
    END

    -- Step 2: Add a new identity column
    ALTER TABLE Subcategory1 ADD NewId BIGINT IDENTITY(1,1);

    -- Step 3: Drop the old subcatID column
    ALTER TABLE Subcategory1 DROP COLUMN subcatID;

    -- Step 4: Rename the new identity column to subcatID
    EXEC sp_rename 'Subcategory1.NewId', 'subcatID', 'COLUMN';

    -- Step 5: Recreate the primary key constraint
    ALTER TABLE Subcategory1 ADD CONSTRAINT PK_Subcategory1 PRIMARY KEY CLUSTERED (subcatID);
END
go

-- Check if the deputyadjudicators table exists
IF OBJECT_ID('dbo.deputyadjudicators', 'U') IS NOT NULL
BEGIN
    -- Step 1: Drop the primary key constraint if it exists
    DECLARE @ConstraintName NVARCHAR(255);

    -- Retrieve the primary key constraint name
    SELECT @ConstraintName = CONSTRAINT_NAME
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_NAME = 'deputyadjudicators' AND CONSTRAINT_TYPE = 'PRIMARY KEY';

    -- Drop the primary key constraint if it exists
    IF @ConstraintName IS NOT NULL
    BEGIN
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = 'ALTER TABLE deputyadjudicators DROP CONSTRAINT ' + QUOTENAME(@ConstraintName);
        EXEC sp_executesql @SQL;
    END

    -- Step 2: Add a new identity column
    ALTER TABLE deputyadjudicators ADD NewId BIGINT IDENTITY(1,1);

    -- Step 3: Drop the old depadjID column
    ALTER TABLE deputyadjudicators DROP COLUMN depadjID;

    -- Step 4: Rename the new identity column to depadjID
    EXEC sp_rename 'deputyadjudicators.NewId', 'depadjID', 'COLUMN';

    -- Step 5: Recreate the primary key constraint
    ALTER TABLE deputyadjudicators ADD CONSTRAINT PK_deputyadjudicators PRIMARY KEY CLUSTERED (depadjID);
END
go


