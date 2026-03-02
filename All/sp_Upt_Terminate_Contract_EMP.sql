USE [Employee]
GO
/****** Object:  StoredProcedure [dbo].[sp_Upt_Terminate_Contract_EMP]    Script Date: 12/17/2025 2:21:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- ProcedureName: [dbo].[sp_Upt_Terminate_Contract_EMP]
-- Function: Update of Faculty
-- Create date: 1/4/23
-- =============================================
ALTER PROCEDURE [dbo].[sp_Upt_Terminate_Contract_EMP] 
	-- Add the parameters for the stored procedure here
	@Contract_EMP_ID int = 0,
	@Candidate_ID int = 0,
	@Terminate_Status_ID int = 0,
	@Terminate_Remark nvarchar(1024) = null,
	@Terminate_Date nvarchar(512) = null,
	@User_ID int = 0, 
	@Project_Position_ID int = 0,
	@Last_Salary int = 0,
	@Company_ID int = 0,
	@Status_Code nvarchar(100) = NULL OUTPUT
AS
declare @Terminate_Date_D datetime = GETDATE(),
		@Employee_ID INT = 0,
		@Status_Contract_EMP_ID INT = 0,
		@Pipeline_ID_Terminate INT = 0,
		@Status_New_ID int = 0;
	
BEGIN TRANSACTION
IF (@Contract_EMP_ID = 0)
	BEGIN
		SET @Employee_ID = (SELECT TOP (1) [E].[Employee_ID] FROM [dbo].[Employee] E WHERE [E].[Candidate_ID] = @Candidate_ID AND [E].[Is_Active] = 1 AND [E].[Is_Deleted] = 0);
		SET @Status_New_ID = (SELECT TOP 1 [SC].[Status_Contract_EMP_ID] 
								FROM [DBO].[Status_Contract_EMP] SC
								WHERE [SC].[Status_Contract_EMP_Name] = 'New' );
		SET @Contract_EMP_ID = (SELECT 
									[CTEMP].[Contract_EMP_ID]
								FROM [DBO].[Contract_EMP] CTEMP
								WHERE [CTEMP].[Employee_ID] = @Employee_ID
								AND [CTEMP].[Contract_EMP_ID] = case when (SELECT count([ct].[Employee_ID] ) FROM [DBO].[Contract_EMP] CT
																		WHERE [CT].[Employee_ID] = @Employee_ID AND [CT].[Status_Contract_EMP_ID] = @Status_New_ID  ) <> 0  
																THEN  (SELECT [CT].[Contract_EMP_ID] FROM [DBO].[Contract_EMP] CT
																		WHERE [CT].[Employee_ID] = @Employee_ID AND [CT].[Status_Contract_EMP_ID] = @Status_New_ID)
																ELSE
																	(
																		SELECT [CEMP].[Contract_EMP_ID]
																		FROM [DBO].[Contract_EMP] CEMP
																		WHERE [CEMP].[Contract_EMP_ID] = (SELECT MAX([CT].[Contract_EMP_ID] ) FROM [DBO].[Contract_EMP] CT
																											WHERE [CT].[Employee_ID] = @Employee_ID
																											AND [CT].[Is_Active] = 1
																											GROUP BY [CT].[Employee_ID] )
																	)
																END)
	END

IF (@Contract_EMP_ID <> 0) 
	BEGIN TRY
		IF @Terminate_Date IS NOT NULL
			BEGIN
				SET @Terminate_Date_D = convert(datetime, @Terminate_Date, 106);
			END

		SET @Status_Contract_EMP_ID = (SELECT TOP (1)
										[dbo].[Status_Contract_EMP].[Status_Contract_EMP_ID]
									FROM [dbo].[Status_Contract_EMP]
									WHERE [dbo].[Status_Contract_EMP].[Status_Contract_EMP_Name] = 'Terminate'
									AND [dbo].[Status_Contract_EMP].[Is_Active] = 1
									AND [dbo].[Status_Contract_EMP].[Is_Delete] = 0);

		SET @Employee_ID = (SELECT TOP 1 [CON].[Employee_ID] 
							FROM [DBO].[Contract_EMP] CON 
							WHERE [CON].[Contract_EMP_ID] = @Contract_EMP_ID );
		SET @Candidate_ID = (SELECT TOP 1 [EMP].[Candidate_ID]
							FROM [DBO].[Employee] EMP
							WHERE [EMP].[Employee_ID] = @Employee_ID );

		IF (@Project_Position_ID = 0)
			BEGIN
				SET @Project_Position_ID = (SELECT
												[Project_Position_ID] = CASE WHEN [CTE].[Project_Position_ID] IS NOT NULL THEN [CTE].[Project_Position_ID]
																		ELSE 0 END
											FROM [dbo].[Contract_EMP] CTE
											WHERE [CTE].[Contract_EMP_ID] = @Contract_EMP_ID);
			END

		--Insert History Map Candidate Pipeline
		INSERT INTO [Pipeline].[dbo].[His_Can_Pile_Com] 
		(
			[dbo].[His_Can_Pile_Com].[Map_Can_Pile_Com_ID]
			,[dbo].[His_Can_Pile_Com].[Candidate_ID]
			,[dbo].[His_Can_Pile_Com].[Pipeline_ID]
			,[dbo].[His_Can_Pile_Com].[Company_ID]
			,[dbo].[His_Can_Pile_Com].[Project_Position_ID]
			,[dbo].[His_Can_Pile_Com].[Is_Active]
			,[dbo].[His_Can_Pile_Com].[Is_Delete]
			,[dbo].[His_Can_Pile_Com].[Created_By]
			,[dbo].[His_Can_Pile_Com].[Created_Date]
			,[dbo].[His_Can_Pile_Com].[Updated_By]
			,[dbo].[His_Can_Pile_Com].[Updated_Date]
			,[dbo].[His_Can_Pile_Com].[Created_By_His]
			,[dbo].[His_Can_Pile_Com].[Created_Date_His]
		)
		SELECT
			[MCP].[Map_Can_Pile_Com_ID]
			,[MCP].[Candidate_ID]
			,[MCP].[Pipeline_ID]
			,[MCP].[Company_ID]
			,[MCP].[Project_Position_ID]
			,[MCP].[Is_Active]
			,[MCP].[Is_Delete]
			,[MCP].[Created_By]
			,[MCP].[Created_Date]
			,[MCP].[Updated_By]
			,[MCP].[Updated_Date]
			,@User_ID
			,GETDATE()
		FROM [Pipeline].[dbo].[Map_Can_Pile_Com] MCP 
		WHERE [MCP].[Candidate_ID] = @Candidate_ID 
		AND [MCP].[Project_Position_ID] = @Project_Position_ID;

		--Delete Map Candidate Pipeline
		DELETE FROM [Pipeline].[dbo].[Map_Can_Pile_Com] 
		WHERE [Pipeline].[dbo].[Map_Can_Pile_Com].[Candidate_ID]= @Candidate_ID 
		AND [Pipeline].[dbo].[Map_Can_Pile_Com].[Project_Position_ID] = @Project_Position_ID;

		SET @Pipeline_ID_Terminate = (SELECT TOP (1) 
											[P].[Pipeline_ID]
										FROM [Pipeline].[dbo].[Pipeline] P
										LEFT JOIN [Pipeline].[dbo].[Pipeline_Type] PT ON [PT].[Pipeline_Type_ID] = [P].[Pipeline_Type_ID]
										WHERE [P].[Pipeline_Name] = 'Terminate'
										AND [P].[Is_Active] = 1
										AND [P].[Is_Delete] = 0
										AND [PT].[Pipeline_Type_Name] = 'System');

		INSERT INTO [Pipeline].[dbo].[Map_Can_Pile_Com] 
				(    [dbo].[Map_Can_Pile_Com].[Candidate_ID]
					,[dbo].[Map_Can_Pile_Com].[Pipeline_ID]
					,[dbo].[Map_Can_Pile_Com].[Project_Position_ID]
					,[dbo].[Map_Can_Pile_Com].[Company_ID]
					,[dbo].[Map_Can_Pile_Com].[Is_Active]
					,[dbo].[Map_Can_Pile_Com].[Created_By]
					,[dbo].[Map_Can_Pile_Com].[Updated_By]
					,[dbo].[Map_Can_Pile_Com].[Created_Date]
					,[dbo].[Map_Can_Pile_Com].[Updated_Date]
					,[dbo].[Map_Can_Pile_Com].[Is_Delete]
				)
				VALUES
				(
					@Candidate_ID
					,@Pipeline_ID_Terminate
					,@Project_Position_ID
					,@Company_ID
					,1
					,@User_ID
					,@User_ID
					,GETDATE()
					,GETDATE()
					,0
				)

		INSERT INTO [Pipeline].[dbo].[Note_Pipeline] 
				(  [dbo].[Note_Pipeline].[Candidate_ID]
					,[dbo].[Note_Pipeline].[Employee_ID]
					,[dbo].[Note_Pipeline].[Company_ID]
					,[dbo].[Note_Pipeline].[Project_Position_ID]
					,[dbo].[Note_Pipeline].[Pipeline_ID]
					,[dbo].[Note_Pipeline].[Reason_Drop_ID]
					,[dbo].[Note_Pipeline].[Detail]
					,[dbo].[Note_Pipeline].[Is_Active]
					,[dbo].[Note_Pipeline].[Created_By]
					,[dbo].[Note_Pipeline].[Updated_By]
					,[dbo].[Note_Pipeline].[Created_Date]
					,[dbo].[Note_Pipeline].[Updated_Date]
					,[dbo].[Note_Pipeline].[Is_Delete]
				)
				VALUES
				(
					@Candidate_ID,
					@Employee_ID,
					@Company_ID,
					@Project_Position_ID,
					@Pipeline_ID_Terminate,
					0,
					@Terminate_Remark,
					1,
					@User_ID,
					@User_ID,
					GETDATE(),
					GETDATE(),
					0
				);

		UPDATE [dbo].[Contract_EMP] 
		SET [dbo].[Contract_EMP].[Status_Contract_EMP_ID] = @Status_Contract_EMP_ID
			,[dbo].[Contract_EMP].[Terminate_Status_ID] = @Terminate_Status_ID
			,[dbo].[Contract_EMP].[Terminate_Remark] = @Terminate_Remark
			,[dbo].[Contract_EMP].[Terminate_Date] = @Terminate_Date_D
			,[dbo].[Contract_EMP].[Updated_By] = @User_ID
			,[dbo].[Contract_EMP].[Updated_Date] = GETDATE()
		WHERE [dbo].[Contract_EMP].[Contract_EMP_ID] = @Contract_EMP_ID
		AND [dbo].[Contract_EMP].[Is_Deleted] = 0;

		UPDATE [DBO].[Employee]
		SET [DBO].[Employee].[Is_Deleted] = 1
			,[Updated_By] = @User_ID
			,[Updated_Date] = GETDATE()
		WHERE [DBO].[Employee].[Employee_ID] = @Employee_ID;

		UPDATE [Candidate].[DBO].[Candidate]
		SET [Is_Employee] = 0
			,[Updated_By] = @User_ID
			,[Updated_Date] = GETDATE()
		WHERE [Candidate_ID] = @Candidate_ID;

		UPDATE [Candidate].[DBO].[Map_Candidadte_Company]
		SET [Is_Employee] = 0
			,[Update_By] = @User_ID
			,[Update_Date] = GETDATE()
		WHERE [Candidate_ID] = @Candidate_ID;

		UPDATE [Accounting].[dbo].[Billing] 
		SET [Accounting].[dbo].[Billing].[Is_Active] = 0
			,[Accounting].[dbo].[Billing].[Is_Deleted] = 1
			,[Accounting].[dbo].[Billing].[Updated_By] = @User_ID
			,[Accounting].[dbo].[Billing].[Updated_Date] = GETDATE()
		WHERE [Accounting].[dbo].[Billing].[Employee_ID] = @Employee_ID;

		DECLARE @COUNT_Company_Name INT = 0;
		SET @COUNT_Company_Name = ( SELECT COUNT([BILL].[Client_ID]) 
									FROM [Accounting].[dbo].[Billing] BILL
									WHERE [BILL].[Employee_ID] = @Employee_ID )

		INSERT INTO [Candidate].[dbo].[Experiences_Candidate]
			   ([Candidate_ID]
			   ,[Exper_Name]
			   ,[Position_ID]
			   ,[Start_Date]
			   ,[End_Date]
			   ,[Present]
			   ,[Last_Salary]
			   ,[Responsibilities]
			   ,[Detail]
			   ,[Is_Deleted]
			   ,[Is_Active]
			   ,[Created_By]
			   ,[Updated_By]
			   ,[Created_Date]
			   ,[Updated_Date]
			   ,[Position_By_Comp_ID]) 
			SELECT @Candidate_ID
				   ,[Exper_Name] = CASE WHEN [CONE].[Company_ID] <> 0 AND @COUNT_Company_Name <> 0 THEN
									(
										SELECT [COM].[Company_Name] FROM [Company].[DBO].[Company] COM WHERE [COM].[Company_ID] = (SELECT TOP 1 [BILL].[Client_ID]
																																		FROM [Accounting].[dbo].[Billing] BILL
																																		WHERE [BILL].[Employee_ID] = @Employee_ID
																																		ORDER BY [BILL].[Created_Date] DESC )
									) 
								   ELSE
										'Not Company'
								   END
				   ,[CONE].[Position_ID_OF_Com] AS [Position_ID] 
				   ,[CONE].[Start_Date]
				   ,[CONE].[Terminate_Date]
				   ,0
				   --,[CONE].[Salary]
				   ,@Last_Salary
				   ,'Responsibilities'
				   ,NULL
				   ,0
				   ,1
				   ,@User_ID
				   ,@User_ID
				   ,GETDATE()
				   ,GETDATE()
				   ,[CONE].[Position_By_Com_ID] AS [Position_By_Comp_ID]
			FROM [dbo].[Contract_EMP] CONE
			WHERE [CONE].[Contract_EMP_ID] = @Contract_EMP_ID; 

			INSERT INTO [Candidate].[dbo].[Log_Update_Candidate]
			(  [Candidate].[dbo].[Log_Update_Candidate].[Candidate_ID]
				,[Candidate].[dbo].[Log_Update_Candidate].[Table_Name]
				,[Candidate].[dbo].[Log_Update_Candidate].[Is_Employee]
				,[Candidate].[dbo].[Log_Update_Candidate].[Is_Terminate]
				,[Candidate].[dbo].[Log_Update_Candidate].[Update_By]
			)
			values
			(
				@Candidate_ID, 
				'Experiences_Candidate',
				0,
				1,
				@User_ID
			);
		SET @Status_Code = '200';
		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH  
		ROLLBACK TRANSACTION ;
		INSERT INTO [LOG].[dbo].[Log]
					([Software_ID]
					,[Function_Name]
					,[Detail]
					,[Created By]
					,[Created Date])
				VALUES
					('1'
					,'DB Employee - sp_Upt_Terminate_Contract_EMP'
					,ERROR_MESSAGE()
					,999
					,GETDATE());
		SET @Status_Code = '999';
	END CATCH
ELSE
	BEGIN
		SET @Status_Code = '402';
	END

