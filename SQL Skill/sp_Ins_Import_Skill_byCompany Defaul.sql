USE [Skill]
GO
/****** Object:  StoredProcedure [dbo].[sp_Ins_Import_Skill_byCompany]    Script Date: 2/11/2026 11:50:26 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- ProcedureName: [dbo].[sp_Ins_Import_Skill_byCompany]
-- Function: Insert of Position Temp
-- Create date: 26-01-2026
-- Optimized: 02-02-2026
--  [dbo].[sp_Ins_Import_Skill_byCompany] @Skill_Name = '', @Company_ID = 3357 , @Software_ID = 1 , @User_ID = 999
-- =============================================
ALTER PROCEDURE [dbo].[sp_Ins_Import_Skill_byCompany] 
	@Skill_Name NVARCHAR(512) = NULL,
	@Company_ID INT = 0,
	@Software_ID int = 0,
	@User_ID INT = 0,

	@Map_Skill_ID INT = 0 OUTPUT,
	@Skill_Group_Name NVARCHAR(512) = NULL OUTPUT,
	@Sub_Skill_Group_Name NVARCHAR(512) = NULL OUTPUT,

	@Status_Code  NVARCHAR(100) = NULL OUTPUT,
	@Skill_By_Comp_ID INT = 0 OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	
BEGIN TRY 
	-- Validate input
	-- เข้ามาถ้าไม่มี ชื่อก็ออกเลย
	IF (@Skill_Name IS NULL OR LTRIM(RTRIM(@Skill_Name)) = '')
		BEGIN
			SET @Status_Code = '404';
			SET @Map_Skill_ID = 0;
			SET @Skill_Group_Name = NULL;
			SET @Sub_Skill_Group_Name = NULL;
			SET @Skill_By_Comp_ID = 0;
			RETURN;
		END

	-- Declare variables
	DECLARE @Skill_ID INT = 0,
			@Skill_Temp_ID INT = 0,
			@Map_Skill_Type INT = 0,
			@Skill_Group_ID INT = 0,
			@Company_Parent_ID INT = 0,
			@Map_Skill_Type_System INT = 0,
			@Map_Skill_Type_Company INT = 0,
			@Skill_Group_ID_INS INT = 0,
			@Skill_ID_INS INT = 0,
			@Map_Skill_ID_INS INT = 0,
			@Active_Skill INT = 0,
			@Active_Skill_Temp INT = 0,
			@Is_Active INT = 0,
			@Group_ID INT = 0,
			@Parent_Group_ID INT = 0,
			@Sub_Skill_Group_ID INT = 0;

	-- Cache Map_Skill_Type lookups (used multiple times)
	SELECT @Map_Skill_Type_System = [Map_Skill_Type_ID]
	FROM [Skill].[dbo].[Map_Skill_Type]
	WHERE [Is_Active] = 1
		AND [Map_Skill_Type_Name] = 'System';

	SELECT @Map_Skill_Type_Company = [Map_Skill_Type_ID]
	FROM [Skill].[dbo].[Map_Skill_Type]
	WHERE [Is_Active] = 1
		AND [Map_Skill_Type_Name] = 'Company';

	-- Get Company Parent ID (using ISNULL to avoid separate NULL check)
	SELECT @Company_Parent_ID = ISNULL([Company_Parent_ID], 0)
	FROM [Company].[dbo].[Company]
	WHERE [Company_ID] = @Company_ID
		AND [Is_Active] = 1
		AND [Is_Delete] = 0;

	-- Get Skill_ID (using ISNULL to avoid separate NULL check)
	SELECT @Skill_ID = ISNULL([Skill_ID], 0)
	FROM [Skill].[dbo].[Skill]
	WHERE [Is_Deleted] = 0
		AND [Skill_Name] = @Skill_Name;

	-- Get Skill_Temp_ID based on Company hierarchy
	IF (@Company_Parent_ID = 0)
		BEGIN
			SELECT TOP(1) @Skill_Temp_ID = [Skill_Temp_ID]
			FROM [Skill].[dbo].[Skill_Temp] ST
			WHERE [Skill_Name] = @Skill_Name
				AND [Is_Deleted] = 0
				AND ([Company_ID] = @Company_ID
					OR [Company_ID] IN (
						SELECT [Company_ID]
						FROM [Company].[dbo].[Company]
						WHERE [Company_Parent_ID] = @Company_ID
							AND [Is_Active] = 1
							AND [Is_Delete] = 0
					)
				);
		END
	ELSE
		BEGIN
			SELECT TOP(1) @Skill_Temp_ID = [Skill_Temp_ID]
			FROM [Skill].[dbo].[Skill_Temp] ST
			WHERE [Skill_Name] = @Skill_Name
				AND [Is_Deleted] = 0
				AND ([Company_ID] = @Company_Parent_ID
					OR [Company_ID] IN (
						SELECT [Company_ID]
						FROM [Company].[dbo].[Company]
						WHERE [Company_Parent_ID] = @Company_Parent_ID
							AND [Is_Active] = 1
							AND [Is_Delete] = 0
					)
				);
		END

	SET @Skill_Temp_ID = ISNULL(@Skill_Temp_ID, 0);

	-- Handle existing Skill (System type)
	IF (@Skill_ID <> 0)
		BEGIN
			SET @Map_Skill_Type = @Map_Skill_Type_System;

			-- Check and update Is_Active if needed
			SELECT @Active_Skill = [Is_Active]
			FROM [Skill].[dbo].[Skill]
			WHERE [Skill_ID] = @Skill_ID
				AND [Is_Deleted] = 0;

			IF (@Active_Skill = 0)
				BEGIN
					UPDATE [Skill].[dbo].[Skill]
					SET [Is_Active] = 1,
						[Updated_By] = @User_ID,
						[Updated_Date] = GETDATE()
					WHERE [Skill_ID] = @Skill_ID;
				END
		END
	-- Handle existing Skill_Temp (Company type)
	ELSE IF (@Skill_Temp_ID <> 0)
		BEGIN
			SET @Map_Skill_Type = @Map_Skill_Type_Company;

			-- Check and update Is_Active if needed
			SELECT @Active_Skill_Temp = [Is_Active]
			FROM [Skill].[dbo].[Skill_Temp]
			WHERE [Skill_Temp_ID] = @Skill_Temp_ID
				AND [Is_Deleted] = 0;

			IF (@Active_Skill_Temp = 0)
				BEGIN
					UPDATE [Skill].[dbo].[Skill_Temp]
					SET [Is_Active] = 1,
						[Updated_By] = @User_ID,
						[Updated_Date] = GETDATE()
					WHERE [Skill_Temp_ID] = @Skill_Temp_ID;
				END
		END

	-- Get existing Skill_By_Company record
	IF (@Company_Parent_ID <> 0)
		BEGIN
			IF (@Skill_ID <> 0)
				BEGIN
					SELECT @Map_Skill_ID = [Map_Skill_ID]
					FROM [Skill].[dbo].[Map_Skill]
					WHERE [Skill_ID] = @Skill_ID
						AND [Is_Delete] = 0
						AND [Is_Active] = 1;

					SELECT TOP(1) @Skill_By_Comp_ID = [Skill_By_Com_ID]
					FROM [Skill].[dbo].[Skill_By_Company] SBC
					WHERE [Map_Skill_ID] = @Map_Skill_ID
						AND [Map_Skill_Type_ID] = @Map_Skill_Type
						AND ([Company_ID] = @Company_Parent_ID
							OR [Company_ID] IN (
								SELECT [Company_ID]
								FROM [Company].[dbo].[Company]
								WHERE [Company_Parent_ID] = @Company_Parent_ID
									AND [Is_Active] = 1
									AND [Is_Delete] = 0
							)
						);
				END
			ELSE IF (@Skill_Temp_ID <> 0)
				BEGIN
					SELECT @Map_Skill_ID = [Map_Skill_Temp_ID]
					FROM [Skill].[dbo].[Map_Skill_Temp]
					WHERE [Skill_Temp_ID] = @Skill_Temp_ID
						AND [Is_Delete] = 0
						AND [Is_Active] = 1;

					SELECT TOP(1) @Skill_By_Comp_ID = [Skill_By_Com_ID]
					FROM [Skill].[dbo].[Skill_By_Company] SBC
					WHERE [Map_Skill_ID] = @Map_Skill_ID
						AND [Map_Skill_Type_ID] = @Map_Skill_Type
						AND ([Company_ID] = @Company_Parent_ID
							OR [Company_ID] IN (
								SELECT [Company_ID]
								FROM [Company].[dbo].[Company]
								WHERE [Company_Parent_ID] = @Company_Parent_ID
									AND [Is_Active] = 1
									AND [Is_Delete] = 0
							)
						);
				END

			SET @Skill_By_Comp_ID = ISNULL(@Skill_By_Comp_ID, 0);
		END
	ELSE
		BEGIN
			IF (@Skill_ID <> 0)
				BEGIN
					SELECT @Map_Skill_ID = [Map_Skill_ID]
					FROM [Skill].[dbo].[Map_Skill]
					WHERE [Skill_ID] = @Skill_ID
						AND [Is_Delete] = 0
						AND [Is_Active] = 1;

					SELECT TOP(1) @Skill_By_Comp_ID = [Skill_By_Com_ID]
					FROM [Skill].[dbo].[Skill_By_Company] SBC
					WHERE [Map_Skill_ID] = @Map_Skill_ID
						AND [Map_Skill_Type_ID] = @Map_Skill_Type
						AND ([Company_ID] = @Company_ID
							OR [Company_ID] IN (
								SELECT [Company_ID]
								FROM [Company].[dbo].[Company]
								WHERE [Company_Parent_ID] = @Company_ID
									AND [Is_Active] = 1
									AND [Is_Delete] = 0
							)
						);
				END
			ELSE IF (@Skill_Temp_ID <> 0)
				BEGIN
					SELECT @Map_Skill_ID = [Map_Skill_Temp_ID]
					FROM [Skill].[dbo].[Map_Skill_Temp]
					WHERE [Skill_Temp_ID] = @Skill_Temp_ID
						AND [Is_Delete] = 0
						AND [Is_Active] = 1;

					SELECT TOP(1) @Skill_By_Comp_ID = [Skill_By_Com_ID]
					FROM [Skill].[dbo].[Skill_By_Company] SBC
					WHERE [Map_Skill_ID] = @Map_Skill_ID
						AND [Map_Skill_Type_ID] = @Map_Skill_Type
						AND ([Company_ID] = @Company_ID
							OR [Company_ID] IN (
								SELECT [Company_ID]
								FROM [Company].[dbo].[Company]
								WHERE [Company_Parent_ID] = @Company_ID
									AND [Is_Active] = 1
									AND [Is_Delete] = 0
							)
						);
				END

			SET @Skill_By_Comp_ID = ISNULL(@Skill_By_Comp_ID, 0);
		END

	-- Get Skill_Group_ID for 'Other Skill' (used for new inserts)
	SELECT @Skill_Group_ID_INS = [Skill_Group_ID]
	FROM [Skill].[dbo].[Skill_Group]
	WHERE [Skill_Group_Name] = 'Other Skill'
		AND [Is_Active] = 1
		AND [Is_Delete] = 0;

	-- Create new Skill_Temp if neither Skill nor Skill_Temp exists
	IF (@Skill_ID = 0 AND @Skill_Temp_ID = 0)
		BEGIN
			SET @Map_Skill_Type = @Map_Skill_Type_Company;

			INSERT INTO [Skill].[dbo].[Skill_Temp]
				([Software_ID], [Company_ID], [Skill_Name], [Detail],
				 [Is_Active], [Is_Deleted], [Created_By], [Updated_By],
				 [Created_Date], [Updated_Date])
			VALUES
				(@Software_ID, @Company_ID, @Skill_Name, '',
				 1, 0, @User_ID, @User_ID, GETDATE(), GETDATE());

			SET @Skill_ID_INS = SCOPE_IDENTITY();

			INSERT INTO [dbo].[Map_Skill_Temp]
				([Skill_Group_ID], [Skill_Temp_ID], [Is_Active],
				 [Created_By], [Updated_By], [Created_Date], [Updated_Date], [Is_Delete])
			VALUES
				(@Skill_Group_ID_INS, @Skill_ID_INS, 1,
				 @User_ID, @User_ID, GETDATE(), GETDATE(), 0);

			SET @Map_Skill_ID_INS = SCOPE_IDENTITY();

			INSERT INTO [Skill].[dbo].[Skill_By_Company]
				([Map_Skill_ID], [Company_ID], [Map_Skill_Type_ID],
				 [Is_Active], [Is_Deleted], [Created_By], [Updated_By],
				 [Created_Date], [Updated_Date])
			VALUES
				(@Map_Skill_ID_INS, @Company_ID, @Map_Skill_Type,
				 1, 0, @User_ID, @User_ID, GETDATE(), GETDATE());

			SET @Skill_By_Comp_ID = SCOPE_IDENTITY();
			SET @Status_Code = '200';
			SET @Map_Skill_ID = @Map_Skill_ID_INS;

			SELECT @Skill_Group_Name = [Skill_Group_Name]
			FROM [Skill].[dbo].[Skill_Group]
			WHERE [Skill_Group_ID] = @Skill_Group_ID_INS
				AND [Is_Active] = 1
				AND [Is_Delete] = 0;

			SET @Sub_Skill_Group_Name = NULL;
		END
	ELSE
		BEGIN
			-- Handle existing Skill_By_Company record
			IF (@Skill_By_Comp_ID <> 0)
				BEGIN
					SELECT @Is_Active = [Is_Active]
					FROM [Skill].[dbo].[Skill_By_Company]
					WHERE [Is_Deleted] = 0
						AND [Skill_By_Com_ID] = @Skill_By_Comp_ID;

					IF (@Is_Active = 0)
						BEGIN
							UPDATE [Skill].[dbo].[Skill_By_Company]
							SET [Is_Active] = 1,
								[Updated_By] = @User_ID,
								[Updated_Date] = GETDATE()
							WHERE [Skill_By_Com_ID] = @Skill_By_Comp_ID;

							SET @Status_Code = '200';
						END
					ELSE
						BEGIN
							SET @Status_Code = '402';

							SELECT @Map_Skill_ID = [Map_Skill_ID]
							FROM [Skill].[dbo].[Skill_By_Company]
							WHERE [Skill_By_Com_ID] = @Skill_By_Comp_ID;

							-- Get Skill Group information
							IF (@Map_Skill_Type = 1) -- System
								BEGIN
									SELECT @Group_ID = [Skill_Group_ID]
									FROM [Skill].[dbo].[Map_Skill]
									WHERE [Map_Skill_ID] = @Map_Skill_ID
										AND [Is_Active] = 1
										AND [Is_Delete] = 0;

									SELECT @Parent_Group_ID = [Parent_Skill_Group_ID]
									FROM [Skill].[dbo].[Skill_Group]
									WHERE [Skill_Group_ID] = @Group_ID
										AND [Is_Active] = 1
										AND [Is_Delete] = 0;
								END
							ELSE IF (@Map_Skill_Type = 2) -- Company
								BEGIN
									SELECT @Group_ID = [Skill_Group_ID]
									FROM [Skill].[dbo].[Map_Skill_Temp]
									WHERE [Map_Skill_Temp_ID] = @Map_Skill_ID
										AND [Is_Active] = 1
										AND [Is_Delete] = 0;

									SELECT @Parent_Group_ID = [Parent_Skill_Group_ID]
									FROM [Skill].[dbo].[Skill_Group]
									WHERE [Skill_Group_ID] = @Group_ID
										AND [Is_Active] = 1
										AND [Is_Delete] = 0;
								END

							-- Set Skill Group Names based on hierarchy
							IF (@Parent_Group_ID = 0 OR @Parent_Group_ID IS NULL)
								BEGIN
									SET @Skill_Group_ID = @Group_ID;
									SELECT @Skill_Group_Name = [Skill_Group_Name]
									FROM [Skill].[dbo].[Skill_Group]
									WHERE [Skill_Group_ID] = @Skill_Group_ID
										AND [Is_Active] = 1
										AND [Is_Delete] = 0;
									SET @Sub_Skill_Group_Name = NULL;
								END
							ELSE
								BEGIN
									SET @Skill_Group_ID = @Parent_Group_ID;
									SELECT @Skill_Group_Name = [Skill_Group_Name]
									FROM [Skill].[dbo].[Skill_Group]
									WHERE [Skill_Group_ID] = @Skill_Group_ID
										AND [Is_Active] = 1
										AND [Is_Delete] = 0;

									SET @Sub_Skill_Group_ID = @Group_ID;
									SELECT @Sub_Skill_Group_Name = [Skill_Group_Name]
									FROM [Skill].[dbo].[Skill_Group]
									WHERE [Skill_Group_ID] = @Sub_Skill_Group_ID
										AND [Is_Active] = 1
										AND [Is_Delete] = 0;
								END
						END
				END
			ELSE
				BEGIN
					-- Create new Skill_By_Company record
					IF (@Skill_ID <> 0)
						BEGIN
							SELECT @Map_Skill_ID_INS = [Map_Skill_ID]
							FROM [Skill].[dbo].[Map_Skill]
							WHERE [Skill_ID] = @Skill_ID
								AND [Is_Active] = 1
								AND [Is_Delete] = 0;
						END
					ELSE IF (@Skill_Temp_ID <> 0)
						BEGIN
							SELECT @Map_Skill_ID_INS = [Map_Skill_Temp_ID]
							FROM [Skill].[dbo].[Map_Skill_Temp]
							WHERE [Skill_Temp_ID] = @Skill_Temp_ID
								AND [Is_Active] = 1
								AND [Is_Delete] = 0;
						END

					INSERT INTO [Skill].[dbo].[Skill_By_Company]
						([Map_Skill_ID], [Company_ID], [Map_Skill_Type_ID],
						 [Is_Active], [Is_Deleted], [Created_By], [Updated_By],
						 [Created_Date], [Updated_Date])
					VALUES
						(@Map_Skill_ID_INS, @Company_ID, @Map_Skill_Type,
						 1, 0, @User_ID, @User_ID, GETDATE(), GETDATE());

					SET @Skill_By_Comp_ID = SCOPE_IDENTITY();
					SET @Status_Code = '200';
				END
		END
END TRY
BEGIN CATCH  
	INSERT INTO [LOG].[dbo].[Log]
		([Software_ID], [Function_Name], [Detail], [Created By], [Created Date])
	VALUES
		('1', 'DB Map_Skill - sp_Ins_Import_Skill_byCompany', ERROR_MESSAGE(), 999, GETDATE());
	SET @Status_Code = '999';
END CATCH

END
