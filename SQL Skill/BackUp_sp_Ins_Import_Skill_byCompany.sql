USE [Skill]
GO
/****** Object:  StoredProcedure [dbo].[sp_Ins_Import_Skill_byCompany]    Script Date: 2/2/2026 5:56:49 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- ProcedureName: [dbo].[sp_Ins_Import_Skill_byCompany]
-- Function: Insert of Position Temp
-- Create date: 26-01-2026
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
BEGIN TRY 
	IF (@Skill_Name IS NOT NULL OR @Skill_Name <> '')
		BEGIN
		DECLARE @Skill_ID INT = 0,
				@Skill_Temp_ID INT = 0,
				@Map_Skill_Type INT = 0,
				@Last_Skill_ID INT = 0,
				@Skill_Group_ID INT = 0,
				@Company_Parent_ID INT = 0;

		SET @Company_Parent_ID = (SELECT [COMP].[Company_Parent_ID]
								  FROM [Company].[dbo].[Company] COMP
								  WHERE [COMP].[Company_ID] = @Company_ID
								  AND [COMP].[Is_Active] = 1
								  AND [COMP].[Is_Delete] = 0);

		IF @Company_Parent_ID IS NULL
		BEGIN
			SET @Company_Parent_ID = 0;
		END

		SET @Skill_ID = (SELECT TOP(1) [SK].[Skill_ID]
				         FROM [Skill].[dbo].[Skill] SK 
						 WHERE [SK].[Is_Deleted] = 0
				         AND [SK].[Skill_Name] = @Skill_Name);

		IF (@Skill_ID IS NULL)
		BEGIN
				SET @Skill_ID = 0;
		END

		SET @Map_Skill_Type = (SELECT TOP(1) [MST].[Map_Skill_Type_ID]
							   FROM [Skill].[dbo].[Map_Skill_Type] MST
							   WHERE [MST].[Is_Active] = 1
							   AND [MST].[Map_Skill_Type_Name] = 'System');

		IF (@Company_Parent_ID = 0)
			BEGIN	
					SET @Skill_Temp_ID = (SELECT TOP(1) [ST].[Skill_Temp_ID]
										  FROM [Skill].[dbo].[Skill_Temp] ST
										  WHERE [ST].[Skill_Name] = @Skill_Name
										  AND ([ST].[Company_ID] = @Company_ID
											  OR [ST].[Company_ID] IN (SELECT [C].[Company_ID]
																	   FROM [Company].[dbo].[Company] C
																	   WHERE [C].[Company_Parent_ID] = @Company_ID))
										  AND [ST].[Is_Deleted] = 0);
			END
		ELSE
			BEGIN
					SET @Skill_Temp_ID = (SELECT TOP(1) [ST].[Skill_Temp_ID]
										  FROM [Skill].[dbo].[Skill_Temp] ST
										  WHERE [ST].[Skill_Name] = @Skill_Name
										  AND ([ST].[Company_ID] =  @Company_Parent_ID
											   OR [ST].[Company_ID] IN (SELECT [C].[Company_ID]
																	    FROM [Company].[dbo].[Company] C 
																		WHERE [C].[Company_Parent_ID] = @Company_Parent_ID)) 
										  AND [ST].[Is_Deleted] = 0);
			END

		IF (@Skill_Temp_ID IS NULL)
			BEGIN 
					SET @Skill_Temp_ID = 0;
			END

		IF (@Skill_ID <> 0)
			BEGIN
					DECLARE @Active_Skill INT = 0;
					SET @Active_Skill = (SELECT TOP(1) [SK].[Is_Active]
										 FROM [Skill].[dbo].[Skill] SK
										 WHERE [SK].[Skill_ID] = @Skill_ID
										 AND [SK].[Is_Deleted] = 0);

					IF (@Active_Skill = 0)
						BEGIN
							UPDATE [Skill].[dbo].[Skill] 
							SET [Is_Active] = 1,
								[Updated_By] = @User_ID,
								[Updated_Date] = GETDATE()
							WHERE [Skill].[dbo].[Skill].[Skill_ID] = @Skill_ID;
						END
			END
		ELSE IF (@Skill_Temp_ID <> 0)
			BEGIN
					DECLARE @Active_Skill_Temp INT = 0;
					SET @Active_Skill_Temp = (SELECT TOP(1) [ST].[Is_Active]
											  FROM [Skill].[dbo].[Skill_Temp] ST 
											  WHERE [ST].[Skill_Temp_ID] = @Skill_Temp_ID
											  AND [ST].[Is_Deleted] = 0);

					IF (@Active_Skill_Temp = 0)
						BEGIN
								UPDATE [Skill].[dbo].[Skill_Temp]
								SET [Is_Active] = 1,
									[Updated_By] = @User_ID,
									[Updated_Date] = GETDATE()
								WHERE [SKill].[dbo].[Skill_Temp].[Skill_Temp_ID] = @Skill_Temp_ID
						END

					SET @Map_Skill_Type = (SELECT TOP(1) [MST].[Map_Skill_Type_ID]
										   FROM [Skill].[dbo].[Map_Skill_Type] MST
										   WHERE [MST].[Is_Active] = 1
										   AND [MST].[Map_Skill_Type_Name] = 'Company');
			END

		IF (@Company_Parent_ID <> 0)
			BEGIN
					IF (@Skill_ID <> 0)
						BEGIN
								SET @Map_Skill_ID = (SELECT TOP(1) [MSK].[Map_Skill_ID]
													 FROM [Skill].[dbo].[Map_Skill] MSK
													 WHERE [MSK].[Skill_ID] = @Skill_ID
													 AND [MSK].[Is_Delete] = 0
													 AND [MSK].[Is_Active] = 1);
								
								SET @Skill_By_Comp_ID = (SELECT TOP(1) [SBC].[Skill_By_Com_ID]
														 FROM [Skill].[dbo].[Skill_By_Company] SBC
														 WHERE [SBC].[Map_Skill_ID] = @Map_Skill_ID
														 AND [SBC].[Map_Skill_Type_ID] = @Map_Skill_Type
														 AND ([SBC].[Company_ID] = @Company_Parent_ID 
															  OR [SBC].[Company_ID] IN (SELECT [C].[Company_ID]
																						FROM [Company].[dbo].[Company] C 
																						WHERE [C].[Company_Parent_ID] = @Company_Parent_ID)));
						END
					ELSE IF (@Skill_Temp_ID <> 0)
						BEGIN
								SET @Map_Skill_ID = (SELECT TOP(1) [MST].[Map_Skill_Temp_ID]
													 FROM [Skill].[dbo].[Map_Skill_Temp] MST
													 WHERE [MST].[Skill_Temp_ID] = @Skill_Temp_ID
													 AND [MST].[Is_Delete] = 0
													 AND [MST].[Is_Active] = 1);

								SET @Skill_By_Comp_ID = (SELECT TOP(1) [SBC].[Skill_By_Com_ID]
														 FROM [Skill].[dbo].[Skill_By_Company] SBC
														 WHERE [SBC].[Map_Skill_ID] = @Map_Skill_ID
														 AND [SBC].[Map_Skill_Type_ID] = @Map_Skill_Type
														 AND ([SBC].[Company_ID] = @Company_Parent_ID
															  OR [SBC].[Company_ID] IN (SELECT [C].[Company_ID]
																						FROM [Company].[dbo].[Company] C
																						WHERE [C].[Company_ID] = @Company_Parent_ID)));
						END

						IF @Skill_By_Comp_ID IS NULL
							BEGIN
									SET @Skill_By_Comp_ID = 0;
							END
			END
		ELSE 
			BEGIN
					IF (@Skill_ID <> 0)
						BEGIN
								SET @Map_Skill_ID = (SELECT TOP(1) [MSK].[Map_Skill_ID]
													 FROM [Skill].[dbo].[Map_Skill] MSK
													 WHERE [MSK].[Skill_ID] = @Skill_ID
													 AND [MSK].[Is_Delete] = 0
													 AND [MSK].[Is_Active] = 1);

								SET @Skill_By_Comp_ID = (SELECT TOP(1) [SBC].[Skill_By_Com_ID]
														 FROM [Skill].[dbo].[Skill_By_Company] SBC
														 WHERE [SBC].[Map_Skill_ID] = @Map_Skill_ID
														 AND [SBC].[Map_Skill_Type_ID] = @Map_Skill_Type
														 AND ([SBC].[Company_ID] = @Company_ID
															  OR [SBC].[Company_ID] IN (SELECT [C].[Company_ID]
																						FROM [Company].[dbo].[Company] C
																						WHERE [C].[Company_Parent_ID] = @Company_ID)));
						END
					ELSE IF (@Skill_Temp_ID <> 0)
						BEGIN
								SET @Map_Skill_ID = (SELECT TOP(1) [MST].[Map_Skill_Temp_ID]
													 FROM [Skill].[dbo].[Map_Skill_Temp] MST
													 WHERE [MST].[Skill_Temp_ID] = @Skill_Temp_ID
													 AND [MST].[Is_Delete] = 0
													 AND [MST].[Is_Active] = 1);

								SET @Skill_By_Comp_ID = (SELECT TOP(1) [SBC].[Skill_By_Com_ID]
														 FROM [Skill].[dbo].[Skill_By_Company] SBC 
														 WHERE [SBC].[Map_Skill_ID] = @Map_Skill_ID
														 AND [SBC].[Map_Skill_Type_ID] = @Map_Skill_Type
														 AND ([SBC].[Company_ID] = @Company_ID
															 OR [SBC].[Company_ID] IN (SELECT [C].[Company_ID]
																					   FROM [Company].[dbo].[Company] C 
																					   WHERE [C].[Company_ID] = @Company_ID)));
						END
					IF (@Skill_By_Comp_ID IS NULL)
						BEGIN
								SET @Skill_By_Comp_ID = 0;
						END
			END

		DECLARE @Skill_ID_INS INT = 0,
				@Map_Skill_ID_INS INT = 0,
				@Skill_Group_ID_INS INT = 0;

		SET @Skill_Group_ID_INS = (SELECT TOP(1) [SG].[Skill_Group_ID]
								   FROM [Skill].[dbo].[Skill_Group] SG 
								   WHERE [SG].[Skill_Group_Name] = 'Other Skill'
								   AND [SG].[Is_Active] = 1 
								   AND [SG].[Is_Delete] = 0);

		SET @Map_Skill_Type = (SELECT TOP(1) [MST].[Map_Skill_Type_ID]
							   FROM [Skill].[dbo].[Map_Skill_Type] MST
							   WHERE [MST].[Is_Active] = 1
							   AND [MST].[Map_Skill_Type_Name] = 'Company');

		IF (@Skill_ID = 0 AND @Skill_Temp_ID = 0)
			BEGIN
					--INSERT INTO [Skill].[dbo].[Skill]
					--			  ([Skill_Name]
					--			  ,[Is_Active]
					--			  ,[Is_Deleted]
					--			  ,[Created_By]
					--			  ,[Updated_By]
					--			  ,[Created_Date]
					--			  ,[Updated_Date])
					--		 VALUES
					--			   (@Skill_Name
					--			   ,1
					--			   ,0
					--			   ,@User_ID
					--			   ,@User_ID
					--			   ,GETDATE()
					--			   ,GETDATE());


							INSERT INTO	 [Skill].[dbo].[Skill_Temp]
										([Software_ID]
										 ,[Company_ID]
										 ,[Skill_Name]
										 ,[Detail]
										 ,[Is_Active]
										 ,[Is_Deleted]
										 ,[Created_By]
										 ,[Updated_By]
										 ,[Created_Date]
										 ,[Updated_Date])
										 VALUES
										  (@Software_ID,
											@Company_ID,
											@Skill_Name
											,''
											,1
											,0
											,@User_ID
											,@User_ID
											,GETDATE()
											,GETDATE());
					SET @Skill_ID_INS = SCOPE_IDENTITY();
					
						
					--INSERT INTO [Skill].[dbo].[Map_Skill]
					--		   ([Skill_Group_ID]
					--		   ,[Skill_ID]
					--		   ,[Is_Active]
					--		   ,[Created_By]
					--		   ,[Updated_By]
					--		   ,[Created_Date]
					--		   ,[Updated_Date]
					--		   ,[Is_Delete])
					--	 VALUES
					--		   (@Skill_Group_ID_INS
					--		   ,@Skill_ID_INS
					--		   ,1
					--		   ,@User_ID
					--		   ,@User_ID
					--		   ,GETDATE()
					--		   ,GETDATE()
					--		   ,0)
						INSERT INTO [dbo].[Map_Skill_Temp]
						   ([Skill_Group_ID]
						   ,[Skill_Temp_ID]
						   ,[Is_Active]
						   ,[Created_By]
						   ,[Updated_By]
						   ,[Created_Date]
						   ,[Updated_Date]
						   ,[Is_Delete])
					 VALUES
						   (@Skill_Group_ID_INS
						   ,@Skill_ID_INS
						   ,1
						   ,@User_ID
						   ,@User_ID
						   ,GETDATE()
						   ,GETDATE()
						   ,0)
					SET @Map_Skill_ID_INS = SCOPE_IDENTITY();

					INSERT INTO [Skill].[dbo].[Skill_By_Company]
								([Map_Skill_ID]
								,[Company_ID]
								,[Map_Skill_Type_ID]
								,[Is_Active]
								,[Is_Deleted]
								,[Created_By]
								,[Updated_By]
								,[Created_Date]
								,[Updated_Date])
							VALUES
								(@Map_Skill_ID_INS
								,@Company_ID
								,@Map_Skill_Type
								,1
								,0
								,@User_ID
								,@User_ID
								,GETDATE()
								,GETDATE())

					SET @Skill_By_Comp_ID = SCOPE_IDENTITY();
					SET @Status_Code = '200';
					SET @Map_Skill_ID = @Map_Skill_ID_INS;
					SET @Skill_Group_Name  = (SELECT TOP(1) [SG].[Skill_Group_Name]
												 FROM [Skill].[dbo].[Skill_Group] SG
												 WHERE [SG].[Skill_Group_ID] = @Skill_Group_ID_INS
												 AND [SG].[Is_Active] = 1
												 AND [SG].[Is_Delete] = 0);
					SET @Sub_Skill_Group_Name = NULL;
			END
		ELSE
			BEGIN
					IF (@Skill_By_Comp_ID <> 0)
						BEGIN
								DECLARE @Is_Active INT = 0;

								SET @Is_Active = (SELECT TOP(1) [SBC].[Is_Active] 
												  FROM [Skill].[dbo].[Skill_By_Company] SBC
												  WHERE [SBC].[Is_Deleted] = 0
												  AND [SBC].[Skill_By_Com_ID] = @Skill_By_Comp_ID);

								IF (@Is_Active = 0)
									BEGIN
											UPDATE [Skill].[dbo].[Skill_By_Company]
											SET [Is_Active] = 1
											   ,[Updated_By] = @User_ID
											   ,[Updated_Date] = GETDATE()
											WHERE [Skill].[dbo].[Skill_By_Company].[Skill_By_Com_ID] = @Skill_By_Comp_ID
											SET @Status_Code = '200';
									END
								ELSE
									BEGIN
										SET @Status_Code = '402';
										SET @Map_Skill_ID = (SELECT TOP(1) [SBC].[Map_Skill_ID]
															 FROM [SKill].[dbo].[Skill_By_Company] SBC 
															 WHERE [SBC].[Skill_By_Com_ID] = @Skill_By_Comp_ID)

										DECLARE @Group_ID INT = 0,
												@Parent_Group_ID INT = 0,
												@Sub_Skill_Group_ID INT = 0

										IF (@Map_Skill_Type = 1)
											BEGIN
													SET @Group_ID = (SELECT TOP(1) [MSK].[Skill_Group_ID]
																	 FROM [Skill].[dbo].[Map_Skill] MSK
																	 WHERE [MSK].[Map_Skill_ID] = @Map_Skill_ID
																	 AND [MSK].[Is_Active] = 1
																	 AND [MSK].[Is_Delete] = 0);

													SET @Parent_Group_ID = (SELECT TOP(1) [SG].[Parent_Skill_Group_ID]
																			FROM [Skill].[dbo].[Skill_Group] SG
																			WHERE [SG].[Skill_Group_ID] = @Group_ID
																			AND [SG].[Is_Active] = 1
																			AND [SG].[Is_Delete] = 0);

													IF (@Parent_Group_ID = 0 OR @Parent_Group_ID IS NULL)
														BEGIN
																SET @Skill_Group_ID = @Group_ID
																SET @Skill_Group_Name = (SELECT TOP(1) [SG].[Skill_Group_Name]
																						 FROM [Skill].[dbo].[Skill_Group] SG
																						 WHERE [SG].[Skill_Group_ID] = @Skill_Group_ID
																						 AND [SG].[Is_Active] = 1
																						 AND [SG].[Is_Delete] = 0);
																SET @Sub_Skill_Group_Name = NULL;
														END
													ELSE IF (@Parent_Group_ID <> 0 AND @Parent_Group_ID IS NOT NULL)
														BEGIN
															SET @Skill_Group_ID = (SELECT TOP(1) [SG].[Skill_Group_ID]
																				   FROM [Skill].[dbo].[Skill_Group] SG
																				   WHERE [SG].[Skill_Group_ID] = @Parent_Group_ID
																				   AND [SG].[Is_Active] = 1
																				   AND [SG].[Is_Delete] = 0);

															SET @Skill_Group_Name = (SELECT TOP(1) [SG].[Skill_Group_Name]
																					 FROM [Skill].[dbo].[Skill_Group] SG
																					 WHERE [SG].[Skill_Group_ID] = @Skill_Group_ID
																					 AND [SG].[Is_Active] = 1
																					 AND [SG].[Is_Delete] = 0);

															SET @Sub_Skill_Group_ID = (SELECT TOP(1) [SG].[Skill_Group_ID]
																					   FROM [Skill].[dbo].[Skill_Group] SG
																					   WHERE [SG].[Skill_Group_ID] = @Group_ID
																					   AND [SG].[Is_Active] = 1
																					   AND [SG].[Is_Delete] = 0);

															SET @Sub_Skill_Group_Name = (SELECT TOP(1) [SG].[Skill_Group_Name]
																						 FROM [Skill].[dbo].[Skill_Group] SG
																						 WHERE [SG].[Skill_Group_ID] = @Sub_Skill_Group_ID
																						 AND [SG].[Is_Active] = 1
																						 AND [SG].[Is_Delete] = 0);
														END
											END
											ELSE IF (@Map_Skill_Type = 2)
												BEGIN
														SET @Group_ID = (SELECT TOP(1) [MST].[Skill_Group_ID]
																		 FROM [Skill].[dbo].[Map_Skill_Temp] MST
																		 WHERE [MST].[Map_Skill_Temp_ID] = @Map_Skill_ID
																		 AND [MST].[Is_Active] = 1
																		 AND [MST].[Is_Delete] = 0);

														SET @Parent_Group_ID = (SELECT TOP(1) [SG].[Parent_Skill_Group_ID]
																				FROM [Skill].[dbo].[Skill_Group] SG
																				WHERE [SG].[Skill_Group_ID] = @Group_ID
																				AND [SG].[Is_Active] = 1
																				AND [SG].[Is_Delete] = 0);

														IF (@Parent_Group_ID = 0 OR @Parent_Group_ID IS NULL)
															BEGIN
																	SET @Skill_Group_ID = @Group_ID
																	SET @Skill_Group_Name = (SELECT TOP(1) [SG].[Skill_Group_Name]
																							 FROM [Skill].[dbo].[Skill_Group] SG
																							 WHERE [SG].[Skill_Group_ID] = @Skill_Group_ID
																							 AND [SG].[Is_Active] = 1
																							 AND [SG].[Is_Delete] = 0);
																	SET @Sub_Skill_Group_Name = NULL;
															END
														ELSE IF (@Parent_Group_ID <> 0 AND @Parent_Group_ID IS NOT NULL)
															BEGIN
																SET @Skill_Group_ID = (SELECT TOP(1) [SG].[Skill_Group_ID]
																					   FROM [Skill].[dbo].[Skill_Group] SG
																					   WHERE [SG].[Skill_Group_ID] = @Parent_Group_ID
																					   AND [SG].[Is_Active] = 1
																					   AND [SG].[Is_Delete] = 0);

																SET @Skill_Group_Name = (SELECT TOP(1) [SG].[Skill_Group_Name]
																						 FROM [Skill].[dbo].[Skill_Group] SG
																						 WHERE [SG].[Skill_Group_ID] = @Skill_Group_ID
																						 AND [SG].[Is_Active] = 1
																						 AND [SG].[Is_Delete] = 0);

																SET @Sub_Skill_Group_ID = (SELECT TOP(1) [SG].[Skill_Group_ID]
																						   FROM [Skill].[dbo].[Skill_Group] SG
																						   WHERE [SG].[Skill_Group_ID] = @Group_ID
																						   AND [SG].[Is_Active] = 1
																						   AND [SG].[Is_Delete] = 0);

																SET @Sub_Skill_Group_Name = (SELECT TOP(1) [SG].[Skill_Group_Name]
																							 FROM [Skill].[dbo].[Skill_Group] SG
																							 WHERE [SG].[Skill_Group_ID] = @Sub_Skill_Group_ID
																							 AND [SG].[Is_Active] = 1
																							 AND [SG].[Is_Delete] = 0);
															END
												END
									END
						END
					ELSE
						BEGIN
								IF (@Skill_ID <> 0)
									BEGIN
											SET @Map_Skill_ID_INS = (SELECT TOP(1) [MSK].[Map_Skill_ID]
																	 FROM [Skill].[dbo].[Map_Skill] MSK
																	 WHERE [MSK].[Skill_ID] = @Skill_ID
																	 AND [MSK].[Is_Active] = 1 
																	 AND [MSK].[Is_Delete] = 0);
									END
								ELSE IF (@Skill_Temp_ID <> 0)
									BEGIN
											SET @Map_Skill_ID_INS = (SELECT TOP(1) [MST].[Map_Skill_Temp_ID]
																	 FROM [Skill].[dbo].[Map_Skill_Temp] MST
																	 WHERE [MST].[Skill_Temp_ID] = @Skill_Temp_ID
																	 AND [MST].[Is_Active] = 1
																	 AND [MST].[Is_Delete] = 0);
									END
								INSERT INTO [Skill].[dbo].[Skill_By_Company]
											([Map_Skill_ID]
											,[Company_ID]
											,[Map_Skill_Type_ID]
											,[Is_Active]
											,[Is_Deleted]
											,[Created_By]
											,[Updated_By]
											,[Created_Date]
											,[Updated_Date])
										VALUES
											(@Map_Skill_ID_INS
											,@Company_ID
											,@Map_Skill_Type
											,1
											,0
											,@User_ID
											,@User_ID
											,GETDATE()
											,GETDATE())
								SET @Skill_By_Comp_ID = SCOPE_IDENTITY();
								SET @Status_Code = '200';
						END
			END
	END
	ELSE
		BEGIN
			SET @Status_Code = '404';
			SET @Map_Skill_ID = 0;
			SET @Skill_Group_Name = NULL;
			SET @Sub_Skill_Group_Name = NULL;
			SET @Skill_By_Comp_ID = 0;
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
				,'DB Map_Skill - sp_Ins_Import_Skill_byCompany'
				,ERROR_MESSAGE()
				,@User_ID
				,GETDATE());
	SET @Status_Code = '999';
END CATCH

