USE [RMS_Position]
GO
/****** Object:  StoredProcedure [dbo].[sp_Ins_Import_Position_Bycom]    Script Date: 2/2/2026 3:10:04 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- ProcedureName: [dbo].[sp_Ins_Import_Position]
-- Function: Insert of Position
-- Create date: 29-01-2026
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
BEGIN TRY
	DECLARE @Position_ID INT = 0,
			@Position_Temp_ID INT = 0,
			@Company_Parent_ID INT = 0,
			@Position_Type_ID INT  = 0,
			@ins_Position_Type_ID INT  = 0;
	SET @Company_Parent_ID = (SELECT [COMP].[Company_Parent_ID]
							  FROM [Company].[dbo].[Company] COMP
							  WHERE [COMP].[Company_ID] = @Company_ID
							  AND [COMP].[Is_Active] = 1
							  AND [COMP].[Is_Delete] = 0)

	IF @Company_Parent_ID IS NULL
		BEGIN
			SET @Company_Parent_ID = 0;
		END

	SET @Position_ID = (SELECT TOP(1) [P].[Position_ID]
						FROM [RMS_Position].[dbo].[Position] P
						WHERE [P].[Position_Name] = @Position_By_AI
						AND [P].[Is_Deleted] = 0);

	SET @Position_Type_ID = (SELECT TOP(1) [PCT].[Position_By_Com_Type_ID]
							 FROM [RMS_Position].[dbo].[Position_By_Comp_Type] PCT
							 WHERE [PCT].[Position_By_Com_Type_Name] = 'System'
							 AND [PCT].[Is_Active] = 1
							 AND [PCT].[Is_Deleted] = 0);

	SET @ins_Position_Type_ID = (SELECT TOP(1) [PCT].[Position_By_Com_Type_ID]
							 FROM [RMS_Position].[dbo].[Position_By_Comp_Type] PCT
							 WHERE [PCT].[Position_By_Com_Type_Name] = 'Company'
							 AND [PCT].[Is_Active] = 1
							 AND [PCT].[Is_Deleted] = 0);

	IF @Position_ID IS NULL
		BEGIN
			SET @Position_ID = 0;
		END

	IF @Company_Parent_ID = 0
		BEGIN
			SET @Position_Temp_ID = (SELECT TOP(1) [PT].[Position_Temp_ID]
										FROM [RMS_Position].[dbo].[Position_Temp] PT 
										WHERE [PT].[Position_Name] = @Position_By_AI
										AND ([PT].[Company_ID] = @Company_ID
											OR [PT].[Company_ID] IN (SELECT [COM].[Company_ID] 
																	FROM [Company].[dbo].[Company] COM
																	WHERE [COM].[Company_Parent_ID] = @Company_ID))
										AND [PT].[Is_Deleted] = 0);
		END
	ELSE
		BEGIN
			SET @Position_Temp_ID = (SELECT TOP(1) [PT].[Position_Temp_ID]
										FROM [RMS_Position].[dbo].[Position_Temp] PT 
										WHERE [PT].[Position_Name] = @Position_By_AI
										AND ([PT].[Company_ID] = @Company_Parent_ID
											OR [PT].[Company_ID] IN (SELECT [COM].[Company_ID] 
																	FROM [Company].[dbo].[Company] COM 
																	WHERE [COM].[Company_Parent_ID] = @Company_Parent_ID))
										AND [PT].[Is_Deleted] = 0);
		END

	IF @Position_Temp_ID IS NULL
		BEGIN 
			SET @Position_Temp_ID = 0;
		END

	IF @Position_ID <> 0
		BEGIN
			DECLARE @Active_Position INT = 0;
			SET @Active_Position = (SELECT TOP(1) [P].[Is_Active]
									FROM [RMS_Position].[dbo].[Position] P
									WHERE [P].[Position_ID] = @Position_ID
									AND [P].[Is_Deleted] = 0);

			IF @Active_Position = 0
				BEGIN
					UPDATE [RMS_Position].[dbo].[Position]
					SET [Is_Active] = 1
						,[Updated_By] = @User_ID
						,[Updated_Date] = GETDATE()
					WHERE [RMS_Position].[dbo].[Position].[Position_ID] = @Position_ID;
				END
		END
	ELSE IF @Position_Temp_ID <> 0
		BEGIN 
			DECLARE @Active_Position_Temp INT = 0;
			SET @Active_Position_Temp = (SELECT TOP(1) [PT].[Is_Active]
										 FROM [RMS_Position].[dbo].[Position_Temp] PT
										 WHERE [PT].[Position_Temp_ID] = @Position_Temp_ID
										 AND [PT].[Is_Deleted] = 0);

			IF @Active_Position_Temp = 0
				BEGIN
					UPDATE [RMS_Position].[dbo].[Position_Temp]
					SET [Is_Active] = 1
						,[Updated_By] = @User_ID
						,[Updated_Date] = GETDATE()
					WHERE [RMS_Position].[dbo].[Position_Temp].[Position_Temp_ID] = @Position_Temp_ID;
				END

			SET @Position_Type_ID = (SELECT TOP(1) [PCT].[Position_By_Com_Type_ID]
									 FROM [RMS_Position].[dbo].[Position_By_Comp_Type] PCT
									 WHERE [PCT].[Position_By_Com_Type_Name] = 'Company'
									 AND [PCT].[Is_Active] = 1
									 AND [PCT].[Is_Deleted] = 0);
		END

	IF @Company_Parent_ID <> 0
		BEGIN
			IF @Position_ID <> 0
				BEGIN
					SET @Position_By_Comp_ID = (SELECT TOP(1) [PBC].[Position_By_Com_ID]
												FROM [RMS_Position].[dbo].[Position_By_Comp] PBC
												WHERE [PBC].[Position_ID] = @Position_ID
												AND [PBC].[Position_By_Com_Type_ID] = @Position_Type_ID
												AND ([PBC].[Company_ID] = @Company_Parent_ID
													 OR [PBC].[Company_ID] IN (SELECT [COM].[Company_ID] 
																			   FROM [Company].[dbo].[Company] COM 
																			   WHERE [COM].[Company_Parent_ID] = @Company_Parent_ID)));
				END
			ELSE IF @Position_Temp_ID <> 0
				BEGIN
					SET @Position_By_Comp_ID = (SELECT TOP(1) [PBC].[Position_By_Com_ID]
												FROM [RMS_Position].[dbo].[Position_By_Comp] PBC
												WHERE [PBC].[Position_ID] = @Position_Temp_ID
												AND [PBC].[Position_By_Com_Type_ID] = @Position_Type_ID
												AND ([PBC].[Company_ID] = @Company_Parent_ID
													 OR [PBC].[Company_ID] IN (SELECT [COM].[Company_ID] 
																			   FROM [Company].[dbo].[Company] COM 
																			   WHERE [COM].[Company_Parent_ID] = @Company_Parent_ID)));
				END
		
			IF @Position_By_Comp_ID IS NULL
				BEGIN
					SET @Position_By_Comp_ID = 0;
				END
		END
	ELSE
		BEGIN
			IF @Position_ID <> 0
				BEGIN
					SET @Position_By_Comp_ID = (SELECT TOP(1) [PBC].[Position_By_Com_ID]
												FROM [RMS_Position].[dbo].[Position_By_Comp] PBC
												WHERE [PBC].[Position_ID] = @Position_ID
												AND [PBC].[Position_By_Com_Type_ID] = @Position_Type_ID
												AND ([PBC].[Company_ID] = @Company_ID
													 OR [PBC].[Company_ID] IN (SELECT [COM].[Company_ID] 
																			   FROM [Company].[dbo].[Company] COM 
																			   WHERE [COM].[Company_Parent_ID] = @Company_ID)));
				END
			ELSE IF @Position_Temp_ID <> 0
				BEGIN
					SET @Position_By_Comp_ID = (SELECT TOP(1) [PBC].[Position_By_Com_ID]
												FROM [RMS_Position].[dbo].[Position_By_Comp] PBC
												WHERE [PBC].[Position_ID] = @Position_Temp_ID
												AND [PBC].[Position_By_Com_Type_ID] = @Position_Type_ID
												AND ([PBC].[Company_ID] = @Company_ID
													 OR [PBC].[Company_ID] IN (SELECT [COM].[Company_ID] 
																			   FROM [Company].[dbo].[Company] COM 
																			   WHERE [COM].[Company_Parent_ID] = @Company_ID)));
				END
		
			IF @Position_By_Comp_ID IS NULL
				BEGIN
					SET @Position_By_Comp_ID = 0;
				END
		END

	DECLARE @Position_ID_INS INT = 0;
	IF @Position_ID = 0 AND @Position_Temp_ID = 0
		BEGIN
			--INSERT INTO [RMS_Position].[dbo].[Position]
			--		   ([Position_Name]
			--		   ,[Software_ID]
			--		   ,[Detail]
			--		   ,[Is_Active]
			--		   ,[Is_Deleted]
			--		   ,[Created_By]
			--		   ,[Updated_By]
			--		   ,[Created_Date]
			--		   ,[Updated_Date])
			--	 VALUES
			--		   (@Position_By_AI
			--		   ,@Software_ID
			--		   ,NULL
			--		   ,1
			--		   ,0
			--		   ,@User_ID
			--		   ,@User_ID
			--		   ,GETDATE()
			--		   ,GETDATE());
			INSERT INTO [dbo].[Position_Temp] 
					(  [dbo].[Position_Temp].[Position_Name]
					  ,[dbo].[Position_Temp].[Dup_Position_ID]
					  ,[dbo].[Position_Temp].[Software_ID]
					  ,[dbo].[Position_Temp].[Company_ID]
					  ,[dbo].[Position_Temp].[Detail]
					  ,[dbo].[Position_Temp].[Is_Active]
					  ,[dbo].[Position_Temp].[Is_Deleted]
					  ,[dbo].[Position_Temp].[Created_By]
					  ,[dbo].[Position_Temp].[Updated_By]
					  ,[dbo].[Position_Temp].[Created_Date]
					  ,[dbo].[Position_Temp].[Updated_Date]
					  )
					  values
					  (
					  @Position_By_AI, 
					  0,
					  @Software_ID,
					  @Company_ID,
					  '', 
					  1,
					  0,
					  @User_ID,
					  NULL,
					  GETDATE(),
					  NULL
					  );
			SET @Position_ID_INS = SCOPE_IDENTITY();

			INSERT INTO [RMS_Position].[dbo].[Position_By_Comp]
					   ([Position_By_Com_Type_ID]
					   ,[Position_ID]
					   ,[Reference_ID]
					   ,[Company_ID]
					   ,[Is_Active]
					   ,[Is_Deleted]
					   ,[Created_By]
					   ,[Updated_By]
					   ,[Created_Date]
					   ,[Updated_Date])
				VALUES
					   (@ins_Position_Type_ID
					   ,@Position_ID_INS
					   ,0
					   ,@Company_ID
					   ,1
					   ,0
					   ,@User_ID
					   ,@User_ID
					   ,GETDATE()
					   ,GETDATE())
			SET @Position_By_Comp_ID = SCOPE_IDENTITY();
			SET @Status_Code = '200';
		END
	ELSE
		BEGIN
			IF @Position_By_Comp_ID <> 0
				BEGIN
					DECLARE @Is_Active INT = 0;

					SET @Is_Active = (SELECT TOP(1) [PBC].[Is_Active]
									  FROM [RMS_Position].[dbo].[Position_By_Comp] PBC
									  WHERE [PBC].[Is_Deleted] = 0
									  AND [PBC].[Position_By_Com_ID] = @Position_By_Comp_ID);

					IF @Is_Active = 0
						BEGIN
							UPDATE [RMS_Position].[dbo].[Position_By_Comp]
							SET [Is_Active] = 1
							   ,[Updated_By] = @User_ID
							   ,[Updated_Date] = GETDATE()
							WHERE [RMS_Position].[dbo].[Position_By_Comp].[Position_By_Com_ID] = @Position_By_Comp_ID;
							SET @Status_Code = '200';
						END
					ELSE
						BEGIN
							SET @Status_Code = '402';
						END
				END
			ELSE
				BEGIN
					DECLARE @Position_ID_For_PBC INT = 0;
					IF @Position_ID <> 0
						BEGIN
							SET @Position_ID_For_PBC = @Position_ID;
						END
					ELSE IF @Position_Temp_ID <> 0
						BEGIN
							SET @Position_ID_For_PBC = @Position_Temp_ID;
						END

					INSERT INTO [RMS_Position].[dbo].[Position_By_Comp]
							   ([Position_By_Com_Type_ID]
							   ,[Position_ID]
							   ,[Reference_ID]
							   ,[Company_ID]
							   ,[Is_Active]
							   ,[Is_Deleted]
							   ,[Created_By]
							   ,[Updated_By]
							   ,[Created_Date]
							   ,[Updated_Date])
						VALUES
							   (@Position_Type_ID
							   ,@Position_ID_For_PBC
							   ,0
							   ,@Company_ID
							   ,1
							   ,0
							   ,@User_ID
							   ,@User_ID
							   ,GETDATE()
							   ,GETDATE())
					SET @Position_By_Comp_ID = SCOPE_IDENTITY();
					SET @Status_Code = '200';
				END
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
				,'DB RMS_Position - sp_Ins_Import_Position'
				,ERROR_MESSAGE()
				,999
				,GETDATE());
	SET @Status_Code = '999';
END CATCH

