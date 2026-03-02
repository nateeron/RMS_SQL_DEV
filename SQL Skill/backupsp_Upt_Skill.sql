USE [Skill]
GO
/****** Object:  StoredProcedure [dbo].[sp_Upt_Skill]    Script Date: 2/6/2026 5:36:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- ProcedureName: [dbo].[sp_Upt_Skill]
-- Function: Update of National
-- Create date: 1/4/23
-- =============================================
ALTER PROCEDURE [dbo].[sp_Upt_Skill] 
	-- Add the parameters for the stored procedure here
	@Skill_ID INT = 0, 
	@Skill_Name NVARCHAR(512) = NULL, 
	@Is_Active INT = 0, 
	@User_ID INT = 0, 
	@Status_Code NVARCHAR(100) = NULL OUTPUT
AS
DECLARE @Numrows INT = 0;
BEGIN TRY
	SET @Numrows = (SELECT COUNT([dbo].[Map_Skill].[Map_Skill_ID]) 
					FROM [dbo].[Map_Skill]
					WHERE [dbo].[Map_Skill].[Is_Active] = 1
					AND [dbo].[Map_Skill].[Is_Delete] = 0
					AND [dbo].[Map_Skill].[Skill_ID] = @Skill_ID);
	IF (@Numrows = 0)
		BEGIN
			IF(@Is_Active = 0)
			BEGIN 
				SET @Status_Code = '722';
			END
			ELSE
				BEGIN
				UPDATE [dbo].[Skill] 
				SET  [dbo].[Skill].[Skill_Name] = @Skill_Name
					,[dbo].[Skill].[Is_Active] = @Is_Active
					,[dbo].[Skill].[Updated_By] = @User_ID
					,[dbo].[Skill].[Updated_Date] = GETDATE()
				WHERE [dbo].[Skill].[Skill_ID] = @Skill_ID
				AND [dbo].[Skill].[Is_Deleted] = 0; 
				SET @Status_Code = '200';
			END
		END
	ELSE
	    BEGIN
			UPDATE [dbo].[Skill] 
			SET  [dbo].[Skill].[Skill_Name] = @Skill_Name
				,[dbo].[Skill].[Is_Active] = @Is_Active
				,[dbo].[Skill].[Updated_By] = @User_ID
				,[dbo].[Skill].[Updated_Date] = GETDATE()
			WHERE [dbo].[Skill].[Skill_ID] = @Skill_ID
			AND [dbo].[Skill].[Is_Deleted] = 0; 
			SET @Status_Code = '200';
		END
END TRY
BEGIN CATCH  
	INSERT INTO [LOG].[dbo].[Log]
				([Software_ID]
				,[Function_Name]
				,[Detail]
				,[Created By]
				,[Created Date])
			VALUES
				('1'
				,'DB Skill - sp_Upt_Skill'
				,ERROR_MESSAGE()
				,999
				,GETDATE());
	SET @Status_Code = '999';  
END CATCH



