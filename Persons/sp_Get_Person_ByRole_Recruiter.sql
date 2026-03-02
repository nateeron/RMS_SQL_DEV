USE [Person]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Get persons by role \"Recruiter\" for a company
-- Returns: Person_ID, Username, Full_Name, Is_Active, User_Login_ID
-- [dbo].[sp_Get_Person_ByRole_Recruiter] 3357
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[sp_Get_Person_ByRole_Recruiter]
    @Company_ID INT
AS
BEGIN TRY
    SET NOCOUNT ON;
   Declare @Role_Name NVARCHAR(500) =  N'Recruiter'
   ;WITH Company_ID AS (
		SELECT [COM].[Company_ID] 
		FROM [Company].[dbo].[Company] COM
		WHERE ([COM].[Company_ID] = @Company_ID
		OR [COM].[Company_Parent_ID] = @Company_ID)
		AND [COM].[Is_Active] = 1
		AND [COM].[Is_Delete] = 0

	),whereRole AS (
	
	SELECT Role_ID from  [Role].[dbo].[Role]
	where Role_Name like '%'+@Role_Name+'%'
	
	),
    UserRoles AS (
        SELECT DISTINCT
            P.Person_ID,
            UL.Username,
            P.Full_Name,
            Is_Active = UL.Is_Active,
            UL.User_Login_ID,
            R.Role_Name
        FROM [User_Login].[dbo].[User_Login] UL
        INNER JOIN [User_Login].[dbo].[Map_User_Company] MUC
            ON MUC.User_Login_ID = UL.User_Login_ID
           AND MUC.Company_ID IN (SELECT Company_ID FROM Company_ID)
           AND MUC.Is_Active = 1
        INNER JOIN [Role].[dbo].[Map_Role_User] MRU
            ON MRU.User_Login_ID = UL.User_Login_ID
           AND MRU.Is_Active = 1
        INNER JOIN [Role].[dbo].[Role] R
            ON R.Role_ID = MRU.Role_ID
			 AND R.Role_ID IN (select Role_ID From whereRole)
           --AND R.Role_Name IN (
           --     SELECT LTRIM(RTRIM(value))
           --     FROM STRING_SPLIT(@Role_Name, ',')
           --     WHERE LTRIM(RTRIM(value)) <> ''
           --)
           AND R.Is_Active = 1
           AND R.Is_Delete = 0
        INNER JOIN [Person].[dbo].[Map_Person] MP
            ON MP.User_Login_ID = UL.User_Login_ID
           AND MP.Is_Active = 1
        INNER JOIN [Person].[dbo].[Person] P
            ON P.Person_ID = MP.Person_ID
           AND P.Is_Active = 1
    )
    SELECT
        ur.Person_ID,
        ur.Username,
        ur.Full_Name,
        ur.Is_Active,
        ur.User_Login_ID,
        Role_Name = STUFF((
            SELECT DISTINCT ',' + ur2.Role_Name
            FROM UserRoles ur2
            WHERE ur2.Person_ID     = ur.Person_ID
              AND ur2.Username      = ur.Username
              AND ur2.User_Login_ID = ur.User_Login_ID
            FOR XML PATH(''), TYPE
        ).value('.', 'NVARCHAR(MAX)'), 1, 1, '')
    FROM UserRoles ur
    GROUP BY
        ur.Person_ID,
        ur.Username,
        ur.Full_Name,
        ur.Is_Active,
        ur.User_Login_ID
    ORDER BY
        ur.Full_Name,
        ur.Username;

END TRY
BEGIN CATCH
    INSERT INTO [LOG].[dbo].[Log]
                ([Software_ID]
                ,[Function_Name]
                ,[Detail]
                ,[Created By]
                ,[Created Date])
        VALUES  ('1'
                ,'DB Person - sp_Get_Person_ByRole_Recruiter'
                ,ERROR_MESSAGE()
                ,999
                ,GETDATE());
END CATCH
GO

