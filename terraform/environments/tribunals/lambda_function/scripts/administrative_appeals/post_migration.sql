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
    go

    -- Step 2: Add a new identity column
    ALTER TABLE Judgment ADD NewId BIGINT IDENTITY(1,1);
    go

    -- Step 3: Drop the old id column
    ALTER TABLE Judgment DROP COLUMN id;
    go

    -- Step 4: Rename the new identity column to id
    EXEC sp_rename 'Judgment.NewId', 'id', 'COLUMN';
    go

    -- Step 5: Recreate the primary key constraint
    ALTER TABLE Judgment ADD CONSTRAINT PK_Judgment PRIMARY KEY CLUSTERED (id);
END
go