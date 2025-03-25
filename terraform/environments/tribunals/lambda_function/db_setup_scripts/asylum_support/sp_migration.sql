use asadj
GO
/****** Object:  StoredProcedure [dbo].[spSearchDecisionFinal]    Script Date: 11/25/2024 14:26:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSearchDecisionFinal]

		@CurrentPage int,
		@PageSize int,
		@TotalRecords int output,
        @strWhere nVarChar(4000)
	AS
-- Create a temp table to hold the current page of data
-- Add and ID Column to count the decisions
Declare @sql As nVarChar(4000)
Select @sql = 'Create TABLE #TempTable
(
ID int PRIMARY KEY,
FirstName varchar(250),
LastName varchar(250),
DecisionDate datetime,
Ref1 varchar(100),
Ref2 varchar(100),
Ref3 varchar(100),
Ref4 varchar(100),
Landmark bit, CatDescription varChar(200), SubDescription varchar(200)
)
-- Fill the temp table with Decisions Data
INSERT INTO #TempTable
(
ID,
FirstName,
LastName,
DecisionDate,
Ref1,
Ref2,
Ref3,
Ref4,
Landmark, CatDescription, SubDescription 
)
SELECT d.id AS ID , FirstName, LastName, DecisionDate, 
     Ref1, Ref2, Ref3, Ref4, Landmark, CatDescription, SubDescription 
FROM decisions d INNER JOIN 
category cat ON (d.CatID= cat.CatID) INNER JOIN 
            subcategory s ON (d.SubCatID =s.SubCatID) 
   WHERE 1 = 1
ORDER BY d.DecisionDate DESC
-- Create variable to identify the first and last record that should be selected
DECLARE @FirstRec int, @LastRec int
SELECT @FirstRec = (@CurrentPage - 1) * @PageSize
SELECT @LastRec = (@CurrentPage * @PageSize + 1)

Select
ID,FirstName,LastName,DecisionDate,Ref1,Ref2,Ref3,Ref4,Landmark, CatDescription, SubDescription 
From #TempTable
WHERE
ID > @FirstRec
AND
ID < @LastRec

SELECT @TotalRecords = COUNT(*) FROM decisions inner join adjudicator ON decisions.AdjID=adjudicator.AdjID' 
	/* SET NOCOUNT ON */
	EXEC sp_executesql @sql,@strWhere
GO
/****** Object:  Table [dbo].[USERS]    Script Date: 11/25/2024 14:26:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[USERS](
	[UserID] [int] IDENTITY(1,1) NOT NULL,
	[Firstname] [varchar](250) NULL,
	[Lastname] [varchar](250) NULL,
	[Username] [varchar](250) NULL,
	[Password] [varchar](250) NULL,
 CONSTRAINT [PK_USERS1] PRIMARY KEY CLUSTERED 
(
	[UserID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[decisions]    Script Date: 11/25/2024 14:26:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[decisions](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[AdjID] [int] NULL,
	[CatID] [int] NULL,
	[SubCatID] [int] NULL,
	[DecisionDate] [datetime] NULL,
	[Ref1] [varchar](200) NULL,
	[Ref2] [varchar](200) NULL,
	[Ref3] [varchar](200) NULL,
	[Ref4] [varchar](200) NULL,
	[Landmark] [bit] NULL,
	[SubmitBy] [int] NULL,
	[Summary] [ntext] NULL,
	[Document] [image] NULL,
	[DocType] [varchar](50) NULL,
	[Doc_name] [varchar](200) NULL,
 CONSTRAINT [PK_decisions1] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[category]    Script Date: 11/25/2024 14:26:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[category](
	[CatID] [int] IDENTITY(1,1) NOT NULL,
	[CatDescription] [varchar](200) NULL,
 CONSTRAINT [PK_category] PRIMARY KEY CLUSTERED 
(
	[CatID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[adjudicator]    Script Date: 11/25/2024 14:26:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[adjudicator](
	[AdjID] [int] IDENTITY(1,1) NOT NULL,
	[FirstName] [varchar](300) NULL,
	[LastName] [varchar](300) NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[FEEDBACK]    Script Date: 11/25/2024 14:26:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[FEEDBACK](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Question1] [varchar](200) NULL,
	[Question2] [varchar](200) NULL,
	[Question3] [varchar](200) NULL,
	[Question4] [bit] NULL,
	[Question5] [ntext] NULL,
	[Question6] [datetime] NULL,
	[Question7] [varchar](200) NULL,
	[Question8] [varchar](200) NULL,
	[Question9] [varchar](200) NULL,
	[Question10] [varchar](200) NULL,
 CONSTRAINT [PK_FEEDBACK] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  StoredProcedure [dbo].[spAddCategory]    Script Date: 11/25/2024 14:26:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Adds a new category into the category table

CREATE PROCEDURE [dbo].[spAddCategory]

@CatID int OUTPUT,
@CatDescription varchar(200)

AS INSERT INTO category (CatDescription)

VALUES (@CatDescription)

SELECT @CatID = SCOPE_IDENTITY()
GO
/****** Object:  StoredProcedure [dbo].[spAddAjudicator1]    Script Date: 11/25/2024 14:26:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spAddAjudicator1] 

@FirstName varchar(300),
@LastName varchar(300)

AS

INSERT
	adjudicator
	(
		FirstName,
		LastName
	)

VALUES
	(
		@FirstName,
		@LastName
	)
GO
/****** Object:  StoredProcedure [dbo].[spAddAdjudicator]    Script Date: 11/25/2024 14:26:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- adds an adjudicator to the adjudicator table by entering a firstname an a lastname

CREATE PROCEDURE [dbo].[spAddAdjudicator]
@AdjID int OUTPUT,
@Firstname varchar(50),
@Lastname varchar(50)

AS INSERT INTO adjudicator (Firstname, Lastname)

VALUES (@Firstname, @Lastname)

SELECT @AdjID = SCOPE_IDENTITY()
GO
/****** Object:  StoredProcedure [dbo].[spCategoryList]    Script Date: 11/25/2024 14:26:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- calls all categories from the category table, used for category dropdownlists etc

CREATE PROC [dbo].[spCategoryList] AS
SELECT CatID, CatDescription FROM category
Order By CatID
GO
/****** Object:  StoredProcedure [dbo].[spAdjudicator]    Script Date: 11/25/2024 14:26:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- selects firsname and lastname of adjudicators from adjudicator tabel, will be used for dropdownlists etc

CREATE PROCEDURE [dbo].[spAdjudicator] AS
SELECT AdjID,Firstname, Lastname 
FROM adjudicator
GO
/****** Object:  StoredProcedure [dbo].[spAddUser]    Script Date: 11/25/2024 14:26:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
GO
/****** Object:  StoredProcedure [dbo].[spDeleteDecision]    Script Date: 11/25/2024 14:26:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- deletes a decision from the decisions table

CREATE PROCEDURE [dbo].[spDeleteDecision]

@ID int OUTPUT,
@AdjID int,
@CatID int,
@SubCatID int,
@DecisionDate datetime,
@Ref1 varchar(10),
@Ref2 varchar(10),
@Ref3 varchar(10),
@Ref4 varchar(10),
@Landmark bit,
@SubmitBy varchar(100)

AS DELETE FROM decisions 

WHERE [ID] = @ID
GO
/****** Object:  StoredProcedure [dbo].[spDeleteCategory]    Script Date: 11/25/2024 14:26:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- deletes a category from the category table

CREATE PROCEDURE [dbo].[spDeleteCategory]

@CatID int OUTPUT,
@CatDescription varchar(200)

AS DELETE FROM category 

WHERE CatID = @CatID

SELECT @CatID = SCOPE_IDENTITY()
GO
/****** Object:  StoredProcedure [dbo].[spDeleteAdjudicator]    Script Date: 11/25/2024 14:26:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- deletes an adjudicator form the adjudicator table

CREATE PROCEDURE [dbo].[spDeleteAdjudicator]

@AdjID int OUTPUT,
@Firstname varchar(50),
@Lastname varchar(50)

AS DELETE FROM adjudicator 

WHERE AdjID = @AdjID

SELECT @AdjID = SCOPE_IDENTITY()
GO
/****** Object:  StoredProcedure [dbo].[spGetCategoryList]    Script Date: 11/25/2024 14:26:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spGetCategoryList] 
AS
SELECT [CatID],[CatDescription]
FROM category
ORDER BY CatID
GO
/****** Object:  StoredProcedure [dbo].[spDeleteUser]    Script Date: 11/25/2024 14:26:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
GO
/****** Object:  StoredProcedure [dbo].[spSearchDecision]    Script Date: 11/25/2024 14:26:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[spSearchDecision]

		@CurrentPage int,
		@PageSize int,
		@TotalRecords int output
	AS
-- Create a temp table to hold the current page of data
-- Add and ID Column to count the decisions

Create TABLE #TempTable
(
ID int PRIMARY KEY,
FirstName varchar(250),
LastName varchar(250),
DecisionDate datetime,
Ref1 varchar(100),
Ref2 varchar(100),
Ref3 varchar(100),
Ref4 varchar(100),
Landmark bit,
UserFName varchar(250),
UserLName varchar(250)
)
-- Fill the temp table with Decisions Data
INSERT INTO #TempTable
(
ID,
FirstName,
LastName,
DecisionDate,
Ref1,
Ref2,
Ref3,
Ref4,
Landmark,
UserFName,
UserLName
)
SELECT ID, 
adjudicator.FirstName,adjudicator.LastName, DecisionDate,Ref1,Ref2,Ref3,Ref4,Landmark,Users.FirstName As UserFName,Users.LastName As UserLName
From decisions inner join adjudicator ON (decisions.AdjID=adjudicator.AdjID) inner join Users ON (decisions.SubmitBy=Users.UserID) 
-- Create variable to identify the first and last record that should be selected
DECLARE @FirstRec int, @LastRec int
SELECT @FirstRec = (@CurrentPage - 1) * @PageSize
SELECT @LastRec = (@CurrentPage * @PageSize + 1)

-- Select one page of data based on the record numbers above
Select
ID,FirstName,LastName,DecisionDate,Ref1,Ref2,Ref3,Ref4,Landmark,UserFName,UserLName
From #TempTable
WHERE
ID > @FirstRec
AND
ID < @LastRec
-- Return the total number of records availbale as an output parameter
SELECT @TotalRecords = COUNT(*) FROM decisions inner join adjudicator ON (decisions.AdjID=adjudicator.AdjID) inner join Users ON (decisions.SubmitBy=Users.UserID)
	/* SET NOCOUNT ON */
GO
/****** Object:  StoredProcedure [dbo].[spLoginUser]    Script Date: 11/25/2024 14:26:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
GO
/****** Object:  StoredProcedure [dbo].[spLandmarkDecisions]    Script Date: 11/25/2024 14:26:10 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[spLandmarkDecisions] AS
SELECT ID, 
FirstName,LastName, CONVERT(char(24),DecisionDate,101) AS DecisionDate,Ref1,Ref2,Ref3,Ref4,
'Landmark' = CASE Landmark WHEN 1 THEN 'Landmark'
WHEN 0 THEN ' ' END
From decisions inner join adjudicator ON decisions.AdjID=adjudicator.AdjID 
WHERE landmark = 1
GO
/****** Object:  StoredProcedure [dbo].[spLandmark]    Script Date: 11/25/2024 14:26:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spLandmark]

		@CurrentPage int,
		@PageSize int,
		@TotalRecords int output
	AS
-- Create a temp table to hold the current page of data
-- Add and ID Column to count the decisions

Create TABLE #TempTable
(
ID int PRIMARY KEY,
FirstName varchar(250),
LastName varchar(250),
DecisionDate datetime,
Ref1 varchar(100),
Ref2 varchar(100),
Ref3 varchar(100),
Ref4 varchar(100),
Landmark bit
)
-- Fill the temp table with Decisions Data
INSERT INTO #TempTable
(
ID,
FirstName,
LastName,
DecisionDate,
Ref1,
Ref2,
Ref3,
Ref4,
Landmark
)


SELECT ID, 
FirstName,LastName, DecisionDate,Ref1,Ref2,Ref3,Ref4,Landmark
From decisions inner join adjudicator ON decisions.AdjID=adjudicator.AdjID WHERE landmark = 1
-- Create variable to identify the first and last record that should be selected
DECLARE @FirstRec int, @LastRec int
SELECT @FirstRec = (@CurrentPage - 1) * @PageSize
SELECT @LastRec = (@CurrentPage * @PageSize + 1)

-- Select one page of data based on the record numbers above
Select
ID,FirstName,LastName,DecisionDate,Ref1,Ref2,Ref3,Ref4,Landmark
From #TempTable
WHERE
ID > @FirstRec
AND
ID < @LastRec
-- Return the total number of records availbale as an output parameter
SELECT @TotalRecords = COUNT(*) FROM decisions inner join adjudicator ON decisions.AdjID=adjudicator.AdjID 
	 /*SET NOCOUNT ON*/
GO
/****** Object:  StoredProcedure [dbo].[spInsertDecision]    Script Date: 11/25/2024 14:26:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- inserts a decision into the decisions table

CREATE PROCEDURE [dbo].[spInsertDecision]

@ID int OUTPUT,
@AdjudicatorID int,
@CategoryID int,
@SubCategoryID int,
@decision_date datetime,
@Ref1 varchar(50),
@Ref2 varchar(50),
@Ref3 varchar(50),
@Ref4 varchar(50),
@Landmark bit,
@SubmitID int,
@Summary ntext,
@Document image = Null,
@DocType varChar(50)='',
@Doc_name varChar(200)=''
--@SubmitBy varchar(100)

AS 
BEGIN TRANSACTION
INSERT INTO decisions (AdjID, CatID, SubCatID, DecisionDate, Ref1, Ref2, Ref3, Ref4, Landmark, 
SubmitBy, Summary,Document,DocType,Doc_name)

VALUES (@AdjudicatorID, 
@CategoryID, 
@SubCategoryID, 
@decision_date, @Ref1, @Ref2, @Ref3, @Ref4, @Landmark, @SubmitID,@Summary,@Document,@DocType,@Doc_name
)
IF @@ERROR <>0
BEGIN
ROLLBACK TRANSACTION
RETURN 1
END

SELECT @ID = SCOPE_IDENTITY()

COMMIT TRANSACTION
GO
/****** Object:  StoredProcedure [dbo].[spGetUserList]    Script Date: 11/25/2024 14:26:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[spGetUserList]
As
Select UserID,Username,[Password],Firstname, Lastname
FROM USERS
Order By Firstname
GO
/****** Object:  StoredProcedure [dbo].[spGetUser]    Script Date: 11/25/2024 14:26:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spGetUser] 

@UserID int

AS

SELECT
	UserID, Username, [Password], Firstname, Lastname

FROM
	Users

WHERE
	UserID = @UserID
GO
/****** Object:  Table [dbo].[subcategory]    Script Date: 11/25/2024 14:26:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[subcategory](
	[SubCatID] [int] IDENTITY(1,1) NOT NULL,
	[CatID] [int] NULL,
	[SubDescription] [varchar](300) NULL,
	[num] [int] NULL,
 CONSTRAINT [PK_subcategory] PRIMARY KEY CLUSTERED 
(
	[SubCatID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  StoredProcedure [dbo].[spUpdateUser]    Script Date: 11/25/2024 14:26:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
GO
/****** Object:  StoredProcedure [dbo].[spUpdateDecision]    Script Date: 11/25/2024 14:26:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
-- updates a decision within the decisions table

CREATE PROCEDURE [dbo].[spUpdateDecision] 

@ID int,
@AdjudicatorID int,
@CategoryID int,
@SubCategoryID int,
@decision_date datetime,
@Ref1 varchar(50),
@Ref2 varchar(50),
@Ref3 varchar(50),
@Ref4 varchar(50),
@Landmark bit,
@SubmitID int,
@Summary ntext,
@Document image = Null,
@DocType varChar(50)='',
@Doc_name varChar(200)=''

AS UPDATE decisions SET
 
--[ID]=@ID,
AdjID=@AdjudicatorID, 
CatID=@CategoryID,
SubCatID=@SubCategoryID, 
DecisionDate=@decision_date, 
Ref1=@Ref1, 
Ref2=@Ref2, 
Ref3=@Ref3, 
Ref4=@Ref4, 
Landmark=@Landmark, 
SubmitBy=@SubmitID,
Summary = @Summary,
Document = @Document,
DocType = @DocType,
Doc_name = @Doc_name

WHERE [ID]=@ID
GO
/****** Object:  StoredProcedure [dbo].[spUpdateCategory]    Script Date: 11/25/2024 14:26:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- updates categories within the category table

CREATE PROCEDURE [dbo].[spUpdateCategory] 

@CatID int,
@CatDescription varchar(200)

AS UPDATE category

SET CatDescription = @CatDescription

WHERE CatID = @CatID
GO
/****** Object:  StoredProcedure [dbo].[spUpdateAdjudicator]    Script Date: 11/25/2024 14:26:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- updates adjudicators firstname and lastname within the adjudicators table

CREATE PROCEDURE [dbo].[spUpdateAdjudicator] 

@AdjID int,
@FirstName varchar(50),
@LastName varchar(50)

AS UPDATE adjudicator

SET FirstName = @FirstName, LastName = @LastName

WHERE AdjID = @AdjID
GO
/****** Object:  StoredProcedure [dbo].[spSearchDecisionAllCriteria]    Script Date: 11/25/2024 14:26:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spSearchDecisionAllCriteria]
     		  @CurrentPage int,
		@PageSize int,
		@Ref1 Varchar(200),
		@Ref2 Varchar(200),
		@Ref3 Varchar(200),
		@Ref4 Varchar(200),
		--@FromDate datetime,
		--@EndDate datetime,
		@CatID int,
		@SubCatID int,
		@AdjId int,
		@TotalRecords int output
	AS
-- Create a temp table to hold the current page of data
-- Add and ID Column to count the decisions

Create TABLE #TempTable
(
ID int PRIMARY KEY,
FirstName varchar(250),
LastName varchar(250),
DecisionDate datetime,
Ref1 varchar(100),
Ref2 varchar(100),
Ref3 varchar(100),
Ref4 varchar(100),
Landmark bit,
CatDescription varchar(200),
SubDescription varchar(200)
)
-- Fill the temp table with Decisions Data
INSERT INTO #TempTable
(
ID,
FirstName,
LastName,
DecisionDate,
Ref1,
Ref2,
Ref3,
Ref4,
Landmark,
CatDescription,
SubDescription
)


SELECT ID, 
FirstName,LastName, DecisionDate,Ref1,Ref2,Ref3,Ref4,Landmark,CatDescription,SubDescription
From decisions As d inner join adjudicator As adj ON (d.AdjID=adj.AdjID)
inner join category As cat ON (d.CatID= cat.CatID)
inner join subcategory As s ON (d.SubCatID =s.SubCatID)
WHERE  Ref1 = @Ref1 OR Ref2 = @Ref2 OR Ref3 =@Ref3 OR Ref4 = @Ref4 OR d.CatID = @CatID OR 
d.AdjID = @AdjID 

--DecisionDate Between @FromDate AND @EndDate OR
-- Create variable to identify the first and last record that should be selected
DECLARE @FirstRec int, @LastRec int
SELECT @FirstRec = (@CurrentPage - 1) * @PageSize
SELECT @LastRec = (@CurrentPage * @PageSize + 1)

-- Select one page of data based on the record numbers above
Select
ID,FirstName,LastName,DecisionDate,Ref1,Ref2,Ref3,Ref4,Landmark,CatDescription,SubDescription
From #TempTable
WHERE
ID > @FirstRec
AND
ID < @LastRec
-- Return the total number of records availbale as an output parameter
SELECT @TotalRecords = COUNT(*) From decisions As d inner join adjudicator As adj ON (d.AdjID=adj.AdjID)
inner join category As cat ON (d.CatID= cat.CatID)
inner join subcategory As s ON (d.SubCatID =s.SubCatID)
WHERE Ref1 = @Ref1 OR Ref2 = @Ref2 OR Ref3 =@Ref3 OR Ref4 = @Ref4 OR d.CatID = @CatID  OR
d.AdjID = @AdjID 
	/* SET NOCOUNT ON */
	--OR  (DecisionDate Between @FromDate AND @EndDate)
GO
/****** Object:  StoredProcedure [dbo].[spUpdateSubCategory]    Script Date: 11/25/2024 14:26:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- updates the name of a sub category within a category

CREATE PROCEDURE [dbo].[spUpdateSubCategory] 

@SubCatID int,
@SubDescription varchar(300)

AS UPDATE subcategory

SET SubDescription = @SubDescription

WHERE SubCatID = @SubCatID
GO
/****** Object:  StoredProcedure [dbo].[spGetSubCategoryListByCategory]    Script Date: 11/25/2024 14:26:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spGetSubCategoryListByCategory] 

@CategoryId int

AS

SELECT SubcatID, s.CatID,c.CatID, s.num, s.SubDescription, c.CatDescription as categoryname
FROM subcategory s
inner join category c on s.CatID = c.CatID
WHERE s.CatID = @CategoryId
ORDER BY s. num
GO
/****** Object:  StoredProcedure [dbo].[spGetSubCategoryList]    Script Date: 11/25/2024 14:26:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spGetSubCategoryList] 

AS

SELECT SubcatID, CatID, num, [SubDescription]
FROM subcategory
ORDER BY CatID, num
GO
/****** Object:  StoredProcedure [dbo].[spGetSubCategoryByCat]    Script Date: 11/25/2024 14:26:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spGetSubCategoryByCat] 

@CatID int

AS
SELECT sc.SubDescription, sc.SubCatID,sc.CatID, num
FROM subcategory AS sc INNER JOIN category AS c
ON sc.CatID = c.CatID
WHERE sc.CatID = @CatID
GO
/****** Object:  StoredProcedure [dbo].[spGetSubCategory]    Script Date: 11/25/2024 14:26:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Procedure [dbo].[spGetSubCategory]
AS
Select SubDescription
FROM subcategory
ORDER BY catID,subcatID
GO
/****** Object:  StoredProcedure [dbo].[spGetDecisionForIndex]    Script Date: 11/25/2024 14:26:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spGetDecisionForIndex]
@CatId int,
@SubCatId int
 AS
Select d.ID,Ref1,Ref2,Ref3,Ref4,FirstName,LastName,DecisionDate,cat.CatDescription, s.SubDescription,Landmark,Summary
 From  decisions As d 
inner join adjudicator As adj on (d.AdjID = adj.AdjID)
 inner join category As cat ON (d.CatID= cat.CatID)
 inner join subcategory As s ON (d.SubCatID =s.SubCatID)
WHERE cat.CatID = @CatId AND s.SubCatID = @SubCatId
GO
/****** Object:  StoredProcedure [dbo].[spGetDecisionAllIncludingLandmarkWithoutID]    Script Date: 11/25/2024 14:26:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spGetDecisionAllIncludingLandmarkWithoutID]
---This sp returns all the decision details including the users who entered the result, this sp also changes the bit 0 or 1 to Landmark string, without a ID parameter
 AS
Select d.ID, d.AdjID,d.SubmitBy,Ref1,Ref2,Ref3,Ref4,adj.FirstName As AdjFirstName,adj.LastName As AdjLastName,CONVERT(char(24),DecisionDate,101)AS DecisionDate,d.CatID,d.SubCatID,cat.CatDescription, s.SubDescription,Summary,Users.FirstName As UFirstName,Users.LastName As ULastName,
'Landmark'=
CASE Landmark WHEN 1 THEN 'Landmark'
WHEN 0 THEN 'NO Landmark ' END
 From  decisions As d 
inner join adjudicator As adj on (d.AdjID = adj.AdjID)
 inner join category As cat ON (d.CatID= cat.CatID)
 inner join subcategory As s ON (d.SubCatID =s.SubCatID)inner join
 USERS ON (d.SubmitBy = USERS.UserID)
GO
/****** Object:  StoredProcedure [dbo].[spGetDecisionAllIncludingLandmark]    Script Date: 11/25/2024 14:26:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spGetDecisionAllIncludingLandmark]
---This sp returns all the decision details including the users who entered the result, this sp also changes the bit 0 or 1 to Landmark string
@DecisionId int
 AS
Select d.ID, d.AdjID,d.SubmitBy,Ref1,Ref2,Ref3,Ref4,adj.FirstName As AdjFirstName,adj.LastName As AdjLastName,CONVERT(char(24),DecisionDate,101)AS DecisionDate,d.CatID,d.SubCatID,cat.CatDescription, s.SubDescription,Summary,Users.FirstName As UFirstName,Users.LastName As ULastName,
'Landmark'=
CASE Landmark WHEN 1 THEN 'Landmark'
WHEN 0 THEN 'NO Landmark ' END
 From  decisions As d 
inner join adjudicator As adj on (d.AdjID = adj.AdjID)
 inner join category As cat ON (d.CatID= cat.CatID)
 inner join subcategory As s ON (d.SubCatID =s.SubCatID)inner join
 USERS ON (d.SubmitBy = USERS.UserID)
WHERE id=@DecisionId
GO
/****** Object:  StoredProcedure [dbo].[spGetDecisionAll]    Script Date: 11/25/2024 14:26:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spGetDecisionAll]
---This sp returns all the decision details including the users who entered the result
@DecisionId int
 AS
Select d.ID, d.AdjID,d.SubmitBy,Ref1,Ref2,Ref3,Ref4,adj.FirstName As AdjFirstName,adj.LastName As AdjLastName,DecisionDate,d.CatID,d.SubCatID,cat.CatDescription, s.SubDescription,Landmark,Summary,Users.FirstName As UFirstName,Users.LastName As ULastName
 From  decisions As d 
inner join adjudicator As adj on (d.AdjID = adj.AdjID)
 inner join category As cat ON (d.CatID= cat.CatID)
 inner join subcategory As s ON (d.SubCatID =s.SubCatID)inner join
 USERS ON (d.SubmitBy = USERS.UserID)
WHERE id=@DecisionId
GO
/****** Object:  StoredProcedure [dbo].[spGetDecision]    Script Date: 11/25/2024 14:26:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
---Added by Osai to Get a Decision's details based on Id
--- The result is used to populate the Edit page for Update

CREATE PROCEDURE [dbo].[spGetDecision]
@DecisionId int
 AS
Select d.ID, d.AdjID,d.SubmitBy,Ref1,Ref2,Ref3,Ref4,FirstName,LastName,DecisionDate,d.CatID,d.SubCatID,cat.CatDescription, s.SubDescription,Landmark,Summary
 From  decisions As d 
inner join adjudicator As adj on (d.AdjID = adj.AdjID)
 inner join category As cat ON (d.CatID= cat.CatID)
 inner join subcategory As s ON (d.SubCatID =s.SubCatID)
WHERE id=@DecisionId
GO
/****** Object:  StoredProcedure [dbo].[spDeleteSubCategory]    Script Date: 11/25/2024 14:26:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spDeleteSubCategory] 

@Id int

AS

DELETE
	SubCategory

WHERE
	SubCatID = @Id
GO
/****** Object:  Table [dbo].[decisions2]    Script Date: 11/25/2024 14:26:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[decisions2](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[AdjID] [int] NULL,
	[CatID] [int] NULL,
	[SubCatID] [int] NULL,
	[DecisionDate] [datetime] NULL,
	[Ref1] [varchar](200) NULL,
	[Ref2] [varchar](200) NULL,
	[Ref3] [varchar](200) NULL,
	[Ref4] [varchar](200) NULL,
	[Landmark] [bit] NULL,
	[SubmitBy] [int] NULL,
	[Summary] [ntext] NULL,
	[Document] [image] NULL,
	[DocType] [varchar](50) NULL,
	[Doc_name] [varchar](200) NULL,
 CONSTRAINT [PK_decisions] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO
/****** Object:  StoredProcedure [dbo].[spCat-SubCat]    Script Date: 11/25/2024 14:26:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- returns the sub category where the subcatID = the catID from different tables

CREATE PROCEDURE [dbo].[spCat-SubCat] 

@CatID int

AS
SELECT sc.SubDescription
FROM subcategory AS sc INNER JOIN category AS c
ON sc.CatID = c.CatID
WHERE sc.CatID = @CatID
GO
/****** Object:  StoredProcedure [dbo].[spAddSubCategory]    Script Date: 11/25/2024 14:26:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spAddSubCategory] 

@description varchar(300),
@CatID  int,
@num  int

AS

INSERT
	Subcategory
	(
		CatID,
		SubDescription,
		num
	)

VALUES
	(
		@CatID,
		@description,
		@num
	)
GO
/****** Object:  StoredProcedure [dbo].[GetCategoryAndSubCategory]    Script Date: 11/25/2024 14:26:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetCategoryAndSubCategory]
/*
	(
		@parameter1 datatype = default value,
		@parameter2 datatype OUTPUT
	)
*/
AS
	select c.CatID As pnum,CatDescription,sc.SubDescription,sc.num
FROM 
subcategory AS sc INNER JOIN category AS c
ON sc.CatID = c.CatID

Group By c.CatID,c.CatDescription,sc.SubDescription,sc.num
GO
/****** Object:  ForeignKey [FK_decisions_category]    Script Date: 11/25/2024 14:26:09 ******/
ALTER TABLE [dbo].[decisions2]  WITH NOCHECK ADD  CONSTRAINT [FK_decisions_category] FOREIGN KEY([CatID])
REFERENCES [dbo].[category] ([CatID])
GO
ALTER TABLE [dbo].[decisions2] CHECK CONSTRAINT [FK_decisions_category]
GO
/****** Object:  ForeignKey [FK_decisions_subcategory]    Script Date: 11/25/2024 14:26:09 ******/
ALTER TABLE [dbo].[decisions2]  WITH NOCHECK ADD  CONSTRAINT [FK_decisions_subcategory] FOREIGN KEY([SubCatID])
REFERENCES [dbo].[subcategory] ([SubCatID])
GO
ALTER TABLE [dbo].[decisions2] CHECK CONSTRAINT [FK_decisions_subcategory]
GO
/****** Object:  ForeignKey [FK_subcategory_category]    Script Date: 11/25/2024 14:26:09 ******/
ALTER TABLE [dbo].[subcategory]  WITH CHECK ADD  CONSTRAINT [FK_subcategory_category] FOREIGN KEY([CatID])
REFERENCES [dbo].[category] ([CatID])
GO
ALTER TABLE [dbo].[subcategory] CHECK CONSTRAINT [FK_subcategory_category]
GO
