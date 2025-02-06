-- SET IDENTITY_INSERT g4s_cap_dw.dbo.D_Comments_V2 ON
-- ;

-- truncate table [g4s_cap_dw].[dbo].[D_Comments_V2];

-- INSERT INTO g4s_cap_dw.dbo.D_Comments_V2 (CommentSID, VisitID, ActivityID, Comments, CommentType)
--  SELECT CommentSID, VisitID, ActivityID, 
--         trim(replace(replace(Comments, char(141), ''), char(129), '')) AS Comments, 
--         CommentType
--   FROM g4s_cap_dw.dbo.D_Comments
-- ;

-- SET IDENTITY_INSERT g4s_cap_dw.dbo.D_Comments_V2 OFF;


-- -- TESTING QUERIES -- 
-- --
-- -- SELECT COUNT(*) FROM g4s_cap_dw.dbo.D_Comments_V2; -- 49695569
-- -- SELECT COUNT(*) FROM g4s_cap_dw.dbo.D_Comments; -- 49695569
-- --


-- --
-- -- SELECT 'D_Comments' AS TableName, Comments
-- --   FROM g4s_cap_dw.dbo.D_Comments
-- --  WHERE CommentSID = 26837791
-- -- UNION
-- -- SELECT 'D_Comments_V2' AS TableName, Comments
-- --   FROM g4s_cap_dw.dbo.D_Comments_V2
-- --  WHERE CommentSID = 26837791
-- --