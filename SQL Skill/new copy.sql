USE [RMS_Position]
GO
/****** Object:  StoredProcedure [dbo].[sp_Ins_Import_Position_Bycom]    Script Date: 2/2/2026 3:10:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- ProcedureName: [dbo].[sp_Ins_Import_Position_Bycom]
-- Function: Insert of Position
-- Create date: 29-01-2026
-- Optimized: 02-02-2026
-- exec [dbo].[sp_Ins_Import_Position_Bycom]   @Position_By_AI = '' , @Software_ID = 1,@Company_ID = 3357, @User_ID = 999
-- =============================================
ALTER PROCEDURE [dbo].[sp_Ins_Import_Position_Bycom] 
	@Position_By_AI NVARCHAR(1024) = NULL,
	@Software_ID INT = 0,
	@Company_ID INT = 0,
	@User_ID INT = 0, 
	@Position_By_Comp_ID INT = 0 OUTPUT,
	@Status_Code NVARCHAR(100) = NULL OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	
BEGIN TRY
	-- Validate input
	IF (@Position_By_AI IS NULL OR LTRIM(RTRIM(@Position_By_AI)) = '')
		BEGIN
			SET @Status_Code = '404';
			SET @Position_By_Comp_ID = 0;
			RETURN;
		END

	-- Declare variables
	DECLARE @Position_ID INT = 0,
			@Position_Temp_ID INT = 0,
			@Company_Parent_ID INT = 0,
			@Position_Type_ID INT = 0,
			@ins_Position_Type_ID INT = 0,
			@Position_ID_INS INT = 0,
			@Position_ID_For_PBC INT = 0,
			@Active_Position INT = 0,
			@Active_Position_Temp INT = 0,
			@Is_Active INT = 0;

	-- Cache Position_By_Com_Type lookups (used multiple times)
	SELECT @Position_Type_ID = [Position_By_Com_Type_ID]
	FROM [RMS_Position].[dbo].[Position_By_Comp_Type]
	WHERE [Position_By_Com_Type_Name] = 'System'
		AND [Is_Active] = 1
		AND [Is_Deleted] = 0;

	SELECT @ins_Position_Type_ID = [Position_By_Com_Type_ID]
	FROM [RMS_Position].[dbo].[Position_By_Comp_Type]
	WHERE [Position_By_Com_Type_Name] = 'Company'
		AND [Is_Active] = 1
		AND [Is_Deleted] = 0;

	-- Get Company Parent ID (using ISNULL to avoid separate NULL check)
	SELECT @Company_Parent_ID = ISNULL([Company_Parent_ID], 0)
	FROM [Company].[dbo].[Company]
	WHERE [Company_ID] = @Company_ID
		AND [Is_Active] = 1
		AND [Is_Delete] = 0;

	-- Get Position_ID (using ISNULL to avoid separate NULL check)
	SELECT @Position_ID = ISNULL([Position_ID], 0)
	FROM [RMS_Position].[dbo].[Position]
	WHERE [Position_Name] = @Position_By_AI
		AND [Is_Deleted] = 0;

	-- Get Position_Temp_ID based on Company hierarchy
	IF (@Company_Parent_ID = 0)
		BEGIN
			SELECT TOP(1) @Position_Temp_ID = [Position_Temp_ID]
			FROM [RMS_Position].[dbo].[Position_Temp] PT
			WHERE [Position_Name] = @Position_By_AI
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
			SELECT TOP(1) @Position_Temp_ID = [Position_Temp_ID]
			FROM [RMS_Position].[dbo].[Position_Temp] PT
			WHERE [Position_Name] = @Position_By_AI
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

	SET @Position_Temp_ID = ISNULL(@Position_Temp_ID, 0);

	-- Handle existing Position (System type)
	IF (@Position_ID <> 0)
		BEGIN
			-- Check and update Is_Active if needed
			SELECT @Active_Position = [Is_Active]
			FROM [RMS_Position].[dbo].[Position]
			WHERE [Position_ID] = @Position_ID
				AND [Is_Deleted] = 0;

			IF (@Active_Position = 0)
				BEGIN
					UPDATE [RMS_Position].[dbo].[Position]
					SET [Is_Active] = 1,
						[Updated_By] = @User_ID,
						[Updated_Date] = GETDATE()
					WHERE [Position_ID] = @Position_ID;
				END
		END
	-- Handle existing Position_Temp (Company type)
	ELSE IF (@Position_Temp_ID <> 0)
		BEGIN
			-- Check and update Is_Active if needed
			SELECT @Active_Position_Temp = [Is_Active]
			FROM [RMS_Position].[dbo].[Position_Temp]
			WHERE [Position_Temp_ID] = @Position_Temp_ID
				AND [Is_Deleted] = 0;

			IF (@Active_Position_Temp = 0)
				BEGIN
					UPDATE [RMS_Position].[dbo].[Position_Temp]
					SET [Is_Active] = 1,
						[Updated_By] = @User_ID,
						[Updated_Date] = GETDATE()
					WHERE [Position_Temp_ID] = @Position_Temp_ID;
				END

			-- Set Position_Type_ID to Company type
			SET @Position_Type_ID = @ins_Position_Type_ID;
		END

	-- Get existing Position_By_Comp record
	IF (@Company_Parent_ID <> 0)
		BEGIN
			IF (@Position_ID <> 0)
				BEGIN
					SELECT TOP(1) @Position_By_Comp_ID = [Position_By_Com_ID]
					FROM [RMS_Position].[dbo].[Position_By_Comp] PBC
					WHERE [Position_ID] = @Position_ID
						AND [Position_By_Com_Type_ID] = @Position_Type_ID
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
			ELSE IF (@Position_Temp_ID <> 0)
				BEGIN
					SELECT TOP(1) @Position_By_Comp_ID = [Position_By_Com_ID]
					FROM [RMS_Position].[dbo].[Position_By_Comp] PBC
					WHERE [Position_ID] = @Position_Temp_ID
						AND [Position_By_Com_Type_ID] = @Position_Type_ID
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

			SET @Position_By_Comp_ID = ISNULL(@Position_By_Comp_ID, 0);
		END
	ELSE
		BEGIN
			IF (@Position_ID <> 0)
				BEGIN
					SELECT TOP(1) @Position_By_Comp_ID = [Position_By_Com_ID]
					FROM [RMS_Position].[dbo].[Position_By_Comp] PBC
					WHERE [Position_ID] = @Position_ID
						AND [Position_By_Com_Type_ID] = @Position_Type_ID
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
			ELSE IF (@Position_Temp_ID <> 0)
				BEGIN
					SELECT TOP(1) @Position_By_Comp_ID = [Position_By_Com_ID]
					FROM [RMS_Position].[dbo].[Position_By_Comp] PBC
					WHERE [Position_ID] = @Position_Temp_ID
						AND [Position_By_Com_Type_ID] = @Position_Type_ID
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

			SET @Position_By_Comp_ID = ISNULL(@Position_By_Comp_ID, 0);
		END

	-- Create new Position_Temp if neither Position nor Position_Temp exists
	IF (@Position_ID = 0 AND @Position_Temp_ID = 0)
		BEGIN
			INSERT INTO [dbo].[Position_Temp]
				([Position_Name], [Dup_Position_ID], [Software_ID], [Company_ID],
				 [Detail], [Is_Active], [Is_Deleted], [Created_By], [Updated_By],
				 [Created_Date], [Updated_Date])
			VALUES
				(@Position_By_AI, 0, @Software_ID, @Company_ID,
				 '', 1, 0, @User_ID, NULL, GETDATE(), NULL);

			SET @Position_ID_INS = SCOPE_IDENTITY();

			INSERT INTO [RMS_Position].[dbo].[Position_By_Comp]
				([Position_By_Com_Type_ID], [Position_ID], [Reference_ID], [Company_ID],
				 [Is_Active], [Is_Deleted], [Created_By], [Updated_By],
				 [Created_Date], [Updated_Date])
			VALUES
				(@ins_Position_Type_ID, @Position_ID_INS, 0, @Company_ID,
				 1, 0, @User_ID, @User_ID, GETDATE(), GETDATE());

			SET @Position_By_Comp_ID = SCOPE_IDENTITY();
			SET @Status_Code = '200';
		END
	ELSE
		BEGIN
			-- Handle existing Position_By_Comp record
			IF (@Position_By_Comp_ID <> 0)
				BEGIN
					SELECT @Is_Active = [Is_Active]
					FROM [RMS_Position].[dbo].[Position_By_Comp]
					WHERE [Is_Deleted] = 0
						AND [Position_By_Com_ID] = @Position_By_Comp_ID;

					IF (@Is_Active = 0)
						BEGIN
							UPDATE [RMS_Position].[dbo].[Position_By_Comp]
							SET [Is_Active] = 1,
								[Updated_By] = @User_ID,
								[Updated_Date] = GETDATE()
							WHERE [Position_By_Com_ID] = @Position_By_Comp_ID;

							SET @Status_Code = '200';
						END
					ELSE
						BEGIN
							SET @Status_Code = '402';
						END
				END
			ELSE
				BEGIN
					-- Determine Position_ID for Position_By_Comp
					IF (@Position_ID <> 0)
						BEGIN
							SET @Position_ID_For_PBC = @Position_ID;
						END
					ELSE IF (@Position_Temp_ID <> 0)
						BEGIN
							SET @Position_ID_For_PBC = @Position_Temp_ID;
						END

					INSERT INTO [RMS_Position].[dbo].[Position_By_Comp]
						([Position_By_Com_Type_ID], [Position_ID], [Reference_ID], [Company_ID],
						 [Is_Active], [Is_Deleted], [Created_By], [Updated_By],
						 [Created_Date], [Updated_Date])
					VALUES
						(@Position_Type_ID, @Position_ID_For_PBC, 0, @Company_ID,
						 1, 0, @User_ID, @User_ID, GETDATE(), GETDATE());

					SET @Position_By_Comp_ID = SCOPE_IDENTITY();
					SET @Status_Code = '200';
				END
		END
END TRY
BEGIN CATCH  
	INSERT INTO [LOG].[dbo].[Log]
		([Software_ID], [Function_Name], [Detail], [Created By], [Created Date])
	VALUES
		('1', 'DB RMS_Position - sp_Ins_Import_Position', ERROR_MESSAGE(), 999, GETDATE());
	SET @Status_Code = '999';
END CATCH

END
