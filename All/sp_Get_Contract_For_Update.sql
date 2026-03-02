USE [Employee]
GO
/****** Object:  StoredProcedure [dbo].[sp_Get_Contract_For_Update]    Script Date: 12/12/2025 11:53:18 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Procedure name: [dbo].[sp_Get_Contract_For_Update]
-- Function: GetAll of Faculty
-- Create date: 1/4/23
-- Description:	Select function seach getall
-- sp_Get_Contract_For_Update 1780
-- =============================================
ALTER PROCEDURE [dbo].[sp_Get_Contract_For_Update]
@Contract_EMP_ID int = 0,
@Status_Code nvarchar(100) = NULL OUTPUT
AS
DECLARE @Other_Income_Amount nvarchar(1024) = null,
		@Total_Amount int = 0;
BEGIN TRY
		BEGIN
			SET @Total_Amount = (SELECT SUM(CAST([Other_Income].[dbo].[Other_Income].[Amount] AS float)) 
						FROM [Other_Income].[dbo].[Other_Income]
						WHERE [Other_Income].[dbo].[Other_Income].[Reference_ID] = @Contract_EMP_ID
						AND [Other_Income].[dbo].[Other_Income].[Is_Active] = 1
						AND [Other_Income].[dbo].[Other_Income].[Is_Deleted] = 0);

			SET @Other_Income_Amount = CAST(@Total_Amount AS nvarchar);

			SELECT [ConEMP].[Position_ID_OF_Com]
					,[ConEMP].[Position_By_Com_ID]
					,[ConEMP].[Contract_Type_ID_OF_Com]
					,[ConEMP].[Contract_Type_By_Comp_ID]
					,[ConEMP].[Salary]
					,[ConEMP].[DOJ]
					,[Date_Of_Join_STR] = case when [ConEMP].[DOJ] is null 
									then '-'
									else
									FORMAT([ConEMP].[DOJ],'dd MMM yyyy')
									end
					,[ConEMP].[Start_Date]
					,[Start_Date_STR] = case when [ConEMP].[Start_Date] is null 
									then '-'
									else
									FORMAT([ConEMP].[Start_Date],'dd MMM yyyy')
									end
					,[ConEMP].[End_Date]
					,[End_Date_STR] = case when [ConEMP].[End_Date] is null 
									then '-'
									else
									FORMAT([ConEMP].[End_Date],'dd MMM yyyy')
									end
					,[ConEMP].[File_Name_Original]
					,[ConEMP].[File_Name_Convert]
					,[ConEMP].[Payment_Seq_ID]
					,[ConEMP].[Currency_ID]
					,[ConEMP].[Refer_By]
					,[PS].[Refer_By_Name]
					,[ConEMP].[Project_Position_ID]
					,[PP].[Project_Client_ID]
					,[PP].[Site_ID]
					,[PP].[Branch_ID]
					,[PP].[Company_ID]
					,[BL].[Billing_Rate]
					,[ConEMP].[Benefit]
					,@Other_Income_Amount AS [Other_Income_Amount]
			FROM [dbo].[Contract_EMP] ConEMP 
			LEFT JOIN [Accounting].[dbo].[Billing] BL ON [BL].[Billing_ID] = [ConEMP].[Billing_ID]
			LEFT JOIN (
				SELECT 
					[EMP].[Employee_ID]
					,[Refer_By_Name] = CASE WHEN [T].[Title_Name] IS NOT NULL THEN TRIM([T].[Title_Name]) + ' ' + [P].[Full_Name]
												ELSE [P].[Full_Name] END
				FROM [dbo].[Employee] EMP
				LEFT JOIN [Candidate].[dbo].[Candidate] C ON [C].[Candidate_ID] = [EMP].[Candidate_ID]
				LEFT JOIN [Person].[dbo].[Person] P ON [P].[Person_ID] = [C].[Person_ID]
				LEFT JOIN [Title].[dbo].[Title] T ON [T].[Title_ID] = [P].[Title_ID]
			) PS ON [PS].[Employee_ID] = [ConEMP].[Refer_By]
			LEFT JOIN (
				SELECT [PP].[Project_Position_ID] 
						,[Site_ID] = CASE WHEN [MPP].[Site_ID] IS NOT NULL THEN [MPP].[Site_ID] 
										ELSE
											CASE WHEN [MSP].[Site_ID] IS NOT NULL THEN [MSP].[Site_ID] ELSE 0 END
										END
						,[Branch_ID] = CASE WHEN [MPP].[Branch_ID] IS NOT NULL THEN [MPP].[Branch_ID] 
										ELSE
											CASE WHEN [MSP].[Branch_ID] IS NOT NULL THEN [MSP].[Branch_ID] 
											ELSE 
													CASE WHEN [MBP].[Branch_ID] IS NOT NULL THEN [MBP].[Branch_ID] ELSE 0 END
											END
										END
						,[Project_Client_ID] = CASE WHEN [MPP].[Project_Client_ID] IS NOT NULL THEN [MPP].[Project_Client_ID] ELSE 0 END
						,[COM].[Company_ID]
				FROM [Company].[dbo].[Project_Position] PP
				LEFT JOIN [Company].[dbo].[Map_Comp_Position] MCPP ON [MCPP].[Project_Position_ID] = [PP].[Project_Position_ID] AND [MCPP].[Is_Active] = 1 AND [MCPP].[Is_Delete] = 0
				LEFT JOIN (
					SELECT [MPP].[Project_Position_ID]
							,[PC].[Project_Client_ID]
							,[PC].[Project_Name]
							,[PC].[Branch_ID]
							,[PC].[Branch_Name]
							,[PC].[Site_ID]
							,[PC].[Site_Name]
							,[PC].[Comp_Branch_Project]
							,[PC].[Comp_Branch_Site_Project]
							,[PC].[Comp_Project]
							,[PC].[Comp_Site_Project]
					FROM [Company].[dbo].[Map_Project_Position] MPP
					LEFT JOIN (
						SELECT [PC].[Project_Client_ID]
								,[PC].[Project_Name]
								,[Comp_Project] = [MCP].[Company_ID]
								,[MBP].[Comp_Branch_Project]
								,[MSP].[Comp_Branch_Site_Project]
								,[MSP].[Comp_Site_Project]
								,[MSP].[Site_ID]
								,[MSP].[Site_Name]
								,[Branch_ID] = CASE WHEN [MBP].[Branch_ID_Of_Project] IS NOT NULL THEN [MBP].[Branch_ID_Of_Project] 
															ELSE [MSP].[Branch_ID_Of_Site_Project] END
								,[Branch_Name] = CASE WHEN [MBP].[Branch_Name_Of_Project] IS NOT NULL THEN [MBP].[Branch_Name_Of_Project] 
															ELSE [MSP].[Branch_Name_Of_Site_Project] END
						FROM [Company].[dbo].[Project_Client] PC
						LEFT JOIN [Company].[dbo].[Map_Comp_Project] MCP ON [MCP].[Project_Client_ID] = [PC].[Project_Client_ID] AND [MCP].[Is_Active] = 1 AND [MCP].[Is_Delete] = 0
						LEFT JOIN (
										SELECT [Branch_ID_Of_Project] = [B].[Branch_ID]
												,[Branch_Name_Of_Project] = [B].[Branch_Name]
												,[Comp_Branch_Project] = [MCB].[Company_ID]
												,[MBP].[Project_Client_ID]
										FROM [Company].[dbo].[Map_Branch_Project] MBP
										LEFT JOIN [Company].[dbo].[Map_Comp_Branch] MCB ON [MCB].[Branch_ID] = [MBP].[Branch_ID] AND [MCB].[Is_Active] = 1 AND [MCB].[Is_Delete] = 0
										LEFT JOIN [Company].[dbo].[Branch_By_Comp] B ON [B].[Branch_ID] = [MBP].[Branch_ID] AND [B].[Is_Active] = 1 AND [B].[Is_Delete] = 0
										WHERE [MBP].[Is_Active] = 1
										AND [MBP].[Is_Delete] = 0
									) MBP ON [MBP].[Project_Client_ID] = [PC].[Project_Client_ID]
						LEFT JOIN (
										SELECT [MSP].[Project_Client_ID]
												,[S].[Site_ID]
												,[S].[Site_Name]
												,[Branch_ID_Of_Site_Project] = [BS].[Branch_ID]
												,[Branch_Name_Of_Site_Project] = [BS].[Branch_Name]
												,[Comp_Site_Project] = [MCS].[Company_ID]
												,[Comp_Branch_Site_Project] = [MCB].[Company_ID]
										FROM [Company].[dbo].[Map_Site_Project] MSP
										LEFT JOIN [Company].[dbo].[Map_Comp_Site] MCS ON [MCS].[Site_ID] = [MSP].[Site_ID] AND [MSP].[Is_Active] = 1 AND [MSP].[Is_Delete] = 0
										LEFT JOIN [Company].[dbo].[Site] S ON [S].[Site_ID] = [MSP].[Site_ID] AND [S].[Is_Active] = 1
										LEFT JOIN [Company].[dbo].[Map_Branch_Site] MBS ON [MBS].[Site_ID] = [MSP].[Site_ID] AND [MBS].[Is_Active] = 1 AND [MBS].[Is_Delete] = 0
										LEFT JOIN [Company].[dbo].[Map_Comp_Branch] MCB ON [MCB].[Branch_ID] = [MBS].[Branch_ID] AND [MCB].[Is_Active] = 1 AND [MCB].[Is_Delete] = 0
										LEFT JOIN [Company].[dbo].[Branch_By_Comp] BS ON [BS].[Branch_ID] = [MBS].[Branch_ID] AND [BS].[Is_Active] = 1 AND [BS].[Is_Delete] = 0
										WHERE [MSP].[Is_Active] = 1
										AND [MSP].[Is_Delete] = 0
								) MSP ON [MSP].[Project_Client_ID] = [PC].[Project_Client_ID]
						WHERE [PC].[Is_Active] = 1
						AND [PC].[Is_Delete] = 0
					) PC ON [PC].[Project_Client_ID] = [MPP].[Project_Client_ID]
					WHERE [MPP].[Is_Active] = 1
					AND [MPP].[Is_Delete] = 0
				) MPP ON [MPP].[Project_Position_ID] = [PP].[Project_Position_ID]
				LEFT JOIN (
					SELECT [MSP].[Project_Position_ID]
							,[S].[Site_ID]
							,[S].[Site_Name]
							,[BS].[Branch_ID]
							,[BS].[Branch_Name]
							,[Comp_Site] = [MCS].[Company_ID]
							,[Comp_Branch_Site] = [MCB].[Company_ID]
					FROM [Company].[dbo].[Map_Site_Position] MSP
					LEFT JOIN [Company].[dbo].[Map_Comp_Site] MCS ON [MCS].[Site_ID] = [MSP].[Site_ID] AND [MSP].[Is_Active] = 1 AND [MSP].[Is_Delete] = 0
					LEFT JOIN [Company].[dbo].[Site] S ON [S].[Site_ID] = [MSP].[Site_ID] AND [S].[Is_Active] = 1
					LEFT JOIN [Company].[dbo].[Map_Branch_Site] MBS ON [MBS].[Site_ID] = [MSP].[Site_ID] AND [MBS].[Is_Active] = 1 AND [MBS].[Is_Delete] = 0
					LEFT JOIN [Company].[dbo].[Map_Comp_Branch] MCB ON [MCB].[Branch_ID] = [MBS].[Branch_ID] AND [MCB].[Is_Active] = 1 AND [MCB].[Is_Delete] = 0
					LEFT JOIN [Company].[dbo].[Branch_By_Comp] BS ON [BS].[Branch_ID] = [MBS].[Branch_ID] AND [BS].[Is_Active] = 1 AND [BS].[Is_Delete] = 0
					WHERE [MSP].[Is_Active] = 1
					AND [MSP].[Is_Delete] = 0
				) MSP ON [MSP].[Project_Position_ID] = [PP].[Project_Position_ID] 
				LEFT JOIN (
					SELECT [MBP].[Project_Position_ID]
							,[BS].[Branch_ID]
							,[BS].[Branch_Name]
							,[Comp_Branch] = [MCB].[Company_ID]
					FROM [Company].[dbo].[Map_Branch_Position] MBP
					LEFT JOIN [Company].[dbo].[Map_Comp_Branch] MCB ON [MCB].[Branch_ID] = [MBP].[Branch_ID] AND [MCB].[Is_Active] = 1 AND [MCB].[Is_Delete] = 0
					LEFT JOIN [Company].[dbo].[Branch_By_Comp] BS ON [BS].[Branch_ID] = [MBP].[Branch_ID] AND [BS].[Is_Active] = 1 AND [BS].[Is_Delete] = 0
					WHERE [MBP].[Is_Active] = 1
					AND [MBP].[Is_Delete] = 0
				) MBP ON [MBP].[Project_Position_ID] = [PP].[Project_Position_ID]
				LEFT JOIN [Company].[dbo].[Company] COM ON (
																[COM].[Company_ID] = [MCPP].[Company_ID]
																OR [COM].[Company_ID] = [MPP].[Comp_Branch_Project]
																OR [COM].[Company_ID] = [MPP].[Comp_Branch_Site_Project]
																OR [COM].[Company_ID] = [MPP].[Comp_Project]
																OR [COM].[Company_ID] = [MPP].[Comp_Site_Project]
																OR [COM].[Company_ID] = [MSP].[Comp_Branch_Site]
																OR [COM].[Company_ID] = [MSP].[Comp_Site]
																OR [COM].[Company_ID] = [MBP].[Comp_Branch]
															)
			) PP ON [PP].[Project_Position_ID] = [ConEMP].[Project_Position_ID]
			WHERE [ConEMP].[Contract_EMP_ID] = @Contract_EMP_ID;

		--	SELECT [ConEMP].[Position_ID_OF_Com]
		--		  ,[ConEMP].[Position_By_Com_ID]
		--		  ,[ConEMP].[Contract_Type_ID_OF_Com]
		--		  ,[ConEMP].[Salary]
		--		  ,[ConEMP].[DOJ]
		--		 ,[Date_Of_Join_STR] = case when [ConEMP].[DOJ] is null 
		--							then '-'
		--							else
		--							FORMAT([ConEMP].[DOJ],'dd MMM yyyy')
		--							end
		--		  ,[ConEMP].[Start_Date]
		--		  ,[Start_Date_STR] = case when [ConEMP].[Start_Date] is null 
		--							then '-'
		--							else
		--							FORMAT([ConEMP].[Start_Date],'dd MMM yyyy')
		--							end
		--		  ,[ConEMP].[End_Date]
		--		  ,[End_Date_STR] = case when [ConEMP].[End_Date] is null 
		--							then '-'
		--							else
		--							FORMAT([ConEMP].[End_Date],'dd MMM yyyy')
		--							end
		--		  ,[ConEMP].[File_Name_Original]
		--		  ,[ConEMP].[File_Name_Convert]
		--		  ,[ConEMP].[Payment_Seq_ID]
		--		  ,[ConEMP].[Currency_ID]
		--		  ,[ConEMP].[Refer_By]
		--		  ,[PS].[Refer_By_Name]
		--		  ,[ConEMP].[Project_Position_ID]
		--		  ,[PP].[Project_Client_ID]
		--		  ,[PC].[Site_ID]
		--		  ,[PC].[Branch_ID]
		--		  ,[PC].[Company_ID]
		--		  ,[BL].[Billing_Rate]
		--		  ,[ConEMP].[Benefit]
		--		  ,@Other_Income_Amount AS [Other_Income_Amount]
		--FROM [dbo].[Contract_EMP] ConEMP 
		--LEFT JOIN [Company].[dbo].[Project_Position] PP ON [PP].[Project_Position_ID] = [ConEMP].[Project_Position_ID]
		--LEFT JOIN [Company].[dbo].[Project_Client] PC ON [PC].[Project_Client_ID] = [PP].[Project_Client_ID]
		--LEFT JOIN [Accounting].[dbo].[Billing] BL ON [BL].[Billing_ID] = [ConEMP].[Billing_ID]
		--LEFT JOIN (
		--			SELECT 
		--				[EMP].[Employee_ID]
		--				,[Refer_By_Name] = CASE WHEN [T].[Title_Name] IS NOT NULL THEN TRIM([T].[Title_Name]) + ' ' + [P].[Full_Name]
		--											ELSE [P].[Full_Name] END
		--			FROM [dbo].[Employee] EMP
		--			LEFT JOIN [Candidate].[dbo].[Candidate] C ON [C].[Candidate_ID] = [EMP].[Candidate_ID]
		--			LEFT JOIN [Person].[dbo].[Person] P ON [P].[Person_ID] = [C].[Person_ID]
		--			LEFT JOIN [Title].[dbo].[Title] T ON [T].[Title_ID] = [P].[Title_ID]
		--		  ) PS ON [PS].[Employee_ID] = [ConEMP].[Refer_By]
		--WHERE [ConEMP].[Contract_EMP_ID]= @Contract_EMP_ID;
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
				,'DB Employee - sp_Get_Contract_For_Update'
				,ERROR_MESSAGE()
				,999
				,GETDATE());
   SET @Status_Code = '999';
END CATCH
