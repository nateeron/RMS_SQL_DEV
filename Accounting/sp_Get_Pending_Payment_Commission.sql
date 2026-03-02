USE [Accounting]
GO
/****** Object:  StoredProcedure [dbo].[sp_Get_Pending_Payment_Commission]    Script Date: 2/17/2026 1:41:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[sp_Get_Pending_Payment_Commission] 
	@Company_ID INT = 0,
	@User_ID INT = 0,
	@Recruiter_ID_str NVARCHAR(512) = NULL,
	@Candidate_ID_str NVARCHAR(512) = NULL,
	@Client_ID_str NVARCHAR(512) = NULL,
	@Position_ID_str NVARCHAR(512) = NULL,
	@Status_Code NVARCHAR(100) = NULL OUTPUT
AS
BEGIN TRY
	DECLARE @Role_Type_ID INT = 0,
			@Role_Freelance_ID INT = 0;

	SET @Role_Type_ID = (SELECT TOP 1 [RT].[Role_Type_ID] 
						 FROM [Role].[dbo].[Role_Type] RT 
						 WHERE [RT].[Role_Type_Name] = 'System' 
						 AND [RT].[Is_Active] = 1);

	SET @Role_Freelance_ID = (SELECT TOP 1 [R].[Role_ID]
							  FROM [Role].[dbo].[Role] R
							  WHERE [R].[Role_Name] = 'Freelance Recruiter'
							  AND [R].[Role_Type_ID] = @Role_Type_ID
							  AND [R].[Is_Active] = 1
							  AND [R].[Is_Delete] = 0);

	IF @Role_Freelance_ID IS NULL
		BEGIN
			SET @Role_Freelance_ID = 0;
		END


	SELECT [A].*
			,[Payment_Condition] = CASE WHEN [A].[Payment_Condition_Name] = 'Payment after Guarantee Period'
								   THEN CONCAT('Payment after Guarantee ', [A].[Payment_After_Guarantee_Period], ' Days')
								   ELSE [A].[Payment_Condition_Name] END
			,[Payment_Date_Str] = CASE WHEN [A].[Payment_Date] IS NOT NULL THEN FORMAT([A].[Payment_Date],'dd MMM yyyy')
								  ELSE '-' END
	FROM (
			SELECT [CON].[Contract_EMP_ID]
					,[Status_Contract_EMP_ID] = [CON].[Status_Contract_EMP_ID]
					,[SCE].[Status_Contract_EMP_Name]
					,[CON].[Terminate_Status_ID]
					,[TS].[Terminate_Name]
					,[Recruiter_ID] = [CREATED].[Person_ID]
					,[Recruiter_Name] = [CREATED].[Full_Name]
					,[CAN].[Candidate_ID]
					,[Candidate_Name] = [P].[Full_Name]
					,[CON].[Position_By_Com_ID]
					,[POS].[Position_Name]
					,[Client_ID] = [PP].[Company_ID]
					,[Client_Name] = [PP].[Company_Name]
					,[Payment_Condition_ID] = [MPC].[Payment_Condition_ID]
					,[Payment_Condition_Name] = [PMC].[Payment_Condition_Name]
					,[Payment_After_Guarantee_Period] = [MPC].[Payment_After_Guarantee_Period]
					,[Payment_Date] = CASE WHEN [PMC].[Payment_Condition_Name] = 'Payment after Guarantee Period'
									  THEN DATEADD(day, [MPC].[Payment_After_Guarantee_Period], [CON].[DOJ])
									  ELSE
											CASE WHEN [PMC].[Payment_Condition_Name] = 'Pay on Candidate Join Date'
											THEN [CON].[DOJ]
											ELSE [MPC].[Pay_on_Customize_Date] END
									  END
					,[Date_of_Join] = [CON].[DOJ]
					,[Date_of_Join_Str] = CASE WHEN [CON].[DOJ] IS NOT NULL THEN FORMAT([CON].[DOJ],'dd MMM yyyy')
										  ELSE '-' END
					,[Commission_Type_ID] = [MCT].[Commission_Type_ID]
					,[Commission_Type_Name] = [CT].[Commission_Type_Name]
					,[Commission_Value] = [MCT].[Commission_Value]
					,[Currency_ID] = [MCT].[Currency_ID]
					,[CON].[Salary]
			FROM (
				SELECT * FROM (
					SELECT [b].*
							,ROW_NUMBER() OVER (PARTITION BY [c].[Employee_ID] ORDER BY [b].[Contract_EMP_ID]) AS rn
					FROM [Employee].[dbo].[Contract_EMP] b
					INNER JOIN [Employee].[dbo].[Employee] c ON [c].[Employee_ID] = [b].[Employee_ID]
				) c
				where [c].[rn] = 1
			) CON
			LEFT JOIN [Employee].[dbo].[Status_Contract_EMP] SCE ON [SCE].[Status_Contract_EMP_ID] = [CON].[Status_Contract_EMP_ID]
			LEFT JOIN [Terminate_Status].[dbo].[Terminate_Status] TS ON [TS].[Terminate_ID] = [CON].[Terminate_Status_ID]
			LEFT JOIN [Company].[dbo].[Company] C ON [CON].[Company_ID] = [C].[Company_ID]
			LEFT JOIN [Accounting].[dbo].[Invoice_of_Commission] INC ON [INC].[Contract_EMP_ID] = [CON].[Contract_EMP_ID]
			LEFT JOIN [Employee].[dbo].[Employee] EMP ON [EMP].[Employee_ID] = [CON].[Employee_ID]
			LEFT JOIN [Candidate].[dbo].[Candidate] CAN ON [CAN].[Candidate_ID] = [EMP].[Candidate_ID]
			LEFT JOIN [Person].[dbo].[Person] P ON [P].[Person_ID] = [CAN].[Person_ID]
			LEFT JOIN (
				SELECT [P].[Position_ID] , [P].[Position_Name] , 2 AS [Position_By_Com_Type_ID] FROM [RMS_Position].[dbo].[Position] P  
				UNION
				SELECT [PT].[Position_Temp_ID] AS [Position_ID] , [PT].[Position_Name] , 1 AS [Position_By_Com_Type_ID] FROM [RMS_Position].[dbo].[Position_Temp] PT
			) POS ON [POS].[Position_ID] = (
												CASE WHEN [CON].[Position_By_Com_ID] = 0 OR [CON].[Position_By_Com_ID] IS NULL THEN [CON].[Position_ID_OF_Com]
												ELSE
													(
															SELECT  [Position_ID_OF_Com] = (
																								CASE WHEN [PB].[Position_By_Com_Type_ID] = 1 
																								THEN 
																									(
																										SELECT [PT].[Position_Temp_ID]
																										FROM [RMS_Position].[dbo].[Position_Temp] PT
																										WHERE [PT].[Position_Temp_ID] = [PB].[Position_ID]
																									)
																								ELSE [PB].[Position_ID] END
																							)
															FROM [RMS_Position].[dbo].[Position_By_Comp] PB 
															WHERE [PB].[Position_By_Com_ID] = [CON].[Position_By_Com_ID]
													)
												END
										   )
				AND [POS].[Position_By_Com_Type_ID] = (
															CASE WHEN [CON].[Position_By_Com_ID] = 0 OR [CON].[Position_By_Com_ID] IS NULL  THEN 2
															ELSE
																(
																		SELECT [PB].[Position_By_Com_Type_ID]
																		FROM [RMS_Position].[dbo].[Position_By_Comp] PB 
																		WHERE [PB].[Position_By_Com_ID] = [CON].[Position_By_Com_ID]
																)
															END
														) 
			LEFT JOIN (
				SELECT [PP].[Project_Position_ID] 
						,[COM].[Company_ID]
						,[COM].[Company_Name]
				FROM [Company].[dbo].[Project_Position] PP
				LEFT JOIN [Company].[dbo].[Map_Comp_Position] MCPP ON [MCPP].[Project_Position_ID] = [PP].[Project_Position_ID] AND [MCPP].[Is_Active] = 1 AND [MCPP].[Is_Delete] = 0
				LEFT JOIN (
					SELECT [MPP].[Project_Position_ID]
							,[PC].[Comp_Branch_Project]
							,[PC].[Comp_Branch_Site_Project]
							,[PC].[Comp_Project]
							,[PC].[Comp_Site_Project]
					FROM [Company].[dbo].[Map_Project_Position] MPP
					LEFT JOIN (
						SELECT [PC].[Project_Client_ID]
								,[Comp_Project] = [MCP].[Company_ID]
								,[MBP].[Comp_Branch_Project]
								,[MSP].[Comp_Branch_Site_Project]
								,[MSP].[Comp_Site_Project]
						FROM [Company].[dbo].[Project_Client] PC
						LEFT JOIN [Company].[dbo].[Map_Comp_Project] MCP ON [MCP].[Project_Client_ID] = [PC].[Project_Client_ID] AND [MCP].[Is_Active] = 1 AND [MCP].[Is_Delete] = 0
						LEFT JOIN (
										SELECT [Comp_Branch_Project] = [MCB].[Company_ID]
												,[MBP].[Project_Client_ID]
										FROM [Company].[dbo].[Map_Branch_Project] MBP
										LEFT JOIN [Company].[dbo].[Map_Comp_Branch] MCB ON [MCB].[Branch_ID] = [MBP].[Branch_ID] AND [MCB].[Is_Active] = 1 AND [MCB].[Is_Delete] = 0
										WHERE [MBP].[Is_Active] = 1
										AND [MBP].[Is_Delete] = 0
									) MBP ON [MBP].[Project_Client_ID] = [PC].[Project_Client_ID]
						LEFT JOIN (
										SELECT [MSP].[Project_Client_ID]
												,[Comp_Site_Project] = [MCS].[Company_ID]
												,[Comp_Branch_Site_Project] = [MCB].[Company_ID]
										FROM [Company].[dbo].[Map_Site_Project] MSP
										LEFT JOIN [Company].[dbo].[Map_Comp_Site] MCS ON [MCS].[Site_ID] = [MSP].[Site_ID] AND [MSP].[Is_Active] = 1 AND [MSP].[Is_Delete] = 0
										LEFT JOIN [Company].[dbo].[Map_Branch_Site] MBS ON [MBS].[Site_ID] = [MSP].[Site_ID] AND [MBS].[Is_Active] = 1 AND [MBS].[Is_Delete] = 0
										LEFT JOIN [Company].[dbo].[Map_Comp_Branch] MCB ON [MCB].[Branch_ID] = [MBS].[Branch_ID] AND [MCB].[Is_Active] = 1 AND [MCB].[Is_Delete] = 0
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
							,[Comp_Site] = [MCS].[Company_ID]
							,[Comp_Branch_Site] = [MCB].[Company_ID]
					FROM [Company].[dbo].[Map_Site_Position] MSP
					LEFT JOIN [Company].[dbo].[Map_Comp_Site] MCS ON [MCS].[Site_ID] = [MSP].[Site_ID] AND [MSP].[Is_Active] = 1 AND [MSP].[Is_Delete] = 0
					LEFT JOIN [Company].[dbo].[Map_Branch_Site] MBS ON [MBS].[Site_ID] = [MSP].[Site_ID] AND [MBS].[Is_Active] = 1 AND [MBS].[Is_Delete] = 0
					LEFT JOIN [Company].[dbo].[Map_Comp_Branch] MCB ON [MCB].[Branch_ID] = [MBS].[Branch_ID] AND [MCB].[Is_Active] = 1 AND [MCB].[Is_Delete] = 0
					WHERE [MSP].[Is_Active] = 1
					AND [MSP].[Is_Delete] = 0
				) MSP ON [MSP].[Project_Position_ID] = [PP].[Project_Position_ID] 
				LEFT JOIN (
					SELECT [MBP].[Project_Position_ID]
							,[Comp_Branch] = [MCB].[Company_ID]
					FROM [Company].[dbo].[Map_Branch_Position] MBP
					LEFT JOIN [Company].[dbo].[Map_Comp_Branch] MCB ON [MCB].[Branch_ID] = [MBP].[Branch_ID] AND [MCB].[Is_Active] = 1 AND [MCB].[Is_Delete] = 0
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
			) PP ON [PP].[Project_Position_ID] = [CON].[Project_Position_ID]
			LEFT JOIN [Company].[dbo].[Map_Payment_Condition] MPC ON [MPC].[Project_Position_ID] = [PP].[Project_Position_ID] AND [MPC].[Is_Active] = 1
			LEFT JOIN [Company].[dbo].[Payment_Condition] PMC ON [PMC].[Payment_Condition_ID] = [MPC].[Payment_Condition_ID]
			LEFT JOIN [Company].[dbo].[Map_Commission_Type_Position] MCT ON [MCT].[Project_Position_ID] = [PP].[Project_Position_ID] AND [MCT].[Is_Active] = 1
			LEFT JOIN [Company].[dbo].[Commission_Type] CT ON [CT].[Commission_Type_ID] = [MCT].[Commission_Type_ID]
			LEFT JOIN (
				SELECT [CAN].*
				FROM (
							SELECT [tt].[Update_By] AS [Owner_ID]
									,[tt].[Update_Date]
									,[tt].[Candidate_ID]
							FROM [Candidate].[dbo].[Log_Update_Candidate] tt
							INNER JOIN (
											SELECT [ss].[Candidate_ID]
													,MAX([ss].[Update_Date]) AS MaxDateTime
											FROM [Candidate].[dbo].[Log_Update_Candidate] ss
											INNER JOIN (
												SELECT [E].[Candidate_ID]
														,[CE].[Created_Date]
												FROM [Employee].[dbo].[Contract_EMP] CE
												LEFT JOIN [Employee].[dbo].[Employee] E ON [E].[Employee_ID] = [CE].[Employee_ID]
											) CE ON [CE].[Candidate_ID] = [ss].[Candidate_ID]
											WHERE [ss].[Is_Employee] = 0
											AND [ss].[Is_Terminate] = 0
											AND [ss].[Update_Date] <= [CE].[Created_Date]
											GROUP BY [ss].[Candidate_ID]
							) groupedtt ON tt.[Candidate_ID] = groupedtt.[Candidate_ID] AND tt.[Update_Date] = groupedtt.MaxDateTime AND [tt].[Is_Employee] = 0 AND [tt].[Is_Terminate] = 0
							GROUP BY [tt].[Update_By], [tt].[Update_Date], [tt].[Candidate_ID]
				) CAN
			) LUC ON [LUC].[Candidate_ID] = [CAN].[Candidate_ID] AND [CAN].[Is_Deleted] = 0
			LEFT JOIN (
				SELECT  [PER].[Person_ID]
						,[PER].[First_Name]
						,[PER].[Middle_Name]
						,[PER].[Last_Name]
						,[PER].[Full_Name] 
				FROM [PERSON].[DBO].[Person] PER  
			) CREATED ON [CREATED].[Person_ID] = [LUC].[Owner_ID]
			LEFT JOIN [Person].[dbo].[Map_Person] MP ON [MP].[Person_ID] = [CREATED].[Person_ID] AND [MP].[Is_Active] = 1
			LEFT JOIN [Role].[dbo].[Map_Role_User] MRU ON [MRU].[User_Login_ID] = [MP].[User_Login_ID] AND [MRU].[Is_Active] = 1
			WHERE [CON].[Company_ID] = @Company_ID
			AND [INC].[Invoice_of_Commission_ID] IS NULL
			AND [MRU].[Role_ID] = @Role_Freelance_ID
	) A
	WHERE (@Position_ID_str = '' OR @Position_ID_str IS NULL OR 
				(
					([A].[Position_By_Com_ID] != 0 AND [A].[Position_By_Com_ID] IS NOT NULL 
					 AND [A].[Position_By_Com_ID] IN (SELECT TRY_CAST([value] AS INT) AS [Position_ID_Value]
														FROM STRING_SPLIT(@Position_ID_str, ',')
														WHERE @Position_ID_str <> '' AND @Position_ID_str IS NOT NULL
														AND TRY_CAST(LTRIM(RTRIM([value])) AS INT) IS NOT NULL)
					)
				)
			)
	AND (@Client_ID_Str = '' OR @Client_ID_Str IS NULL OR 
				(
					([A].[Client_ID] != 0 AND [A].[Client_ID] IS NOT NULL 
					 AND [A].[Client_ID] IN (SELECT TRY_CAST([value] AS INT) AS [Client_ID_Value]
												FROM STRING_SPLIT(@Client_ID_Str, ',')
												WHERE @Client_ID_Str <> '' AND @Client_ID_Str IS NOT NULL
												AND TRY_CAST(LTRIM(RTRIM([value])) AS INT) IS NOT NULL)
					)
				)
			)
	AND (@Candidate_ID_Str = '' OR @Candidate_ID_Str IS NULL OR 
				(
					([A].[Candidate_ID] != 0 AND [A].[Candidate_ID] IS NOT NULL 
					 AND [A].[Candidate_ID] IN (SELECT TRY_CAST([value] AS INT) AS [Candidate_ID_Value]
												FROM STRING_SPLIT(@Candidate_ID_Str, ',')
												WHERE @Candidate_ID_Str <> '' AND @Candidate_ID_Str IS NOT NULL
												AND TRY_CAST(LTRIM(RTRIM([value])) AS INT) IS NOT NULL)
					)
				)
			)
	AND (@Recruiter_ID_Str = '' OR @Recruiter_ID_Str IS NULL OR 
				(
					([A].[Recruiter_ID] != 0 AND [A].[Recruiter_ID] IS NOT NULL 
					 AND [A].[Recruiter_ID] IN (SELECT TRY_CAST([value] AS INT) AS [Recruiter_ID_Value]
												FROM STRING_SPLIT(@Recruiter_ID_Str, ',')
												WHERE @Recruiter_ID_Str <> '' AND @Recruiter_ID_Str IS NOT NULL
												AND TRY_CAST(LTRIM(RTRIM([value])) AS INT) IS NOT NULL)
					)
				)
			)
	group by [A].[Contract_EMP_ID]
			,[A].[Status_Contract_EMP_ID]
			,[A].[Status_Contract_EMP_Name]
			,[A].[Terminate_Status_ID]
			,[A].[Terminate_Name]
			,[A].[Candidate_ID]
			,[A].[Recruiter_ID]
			,[A].[Recruiter_Name]
			,[A].[Candidate_Name]
			,[A].[Position_Name]
			,[A].[Client_Name]
			,[A].[Payment_Condition_ID]
			,[A].[Payment_Condition_Name]
			,[A].[Payment_After_Guarantee_Period]
			,[A].[Payment_Date]
			,[A].[Date_of_Join]
			,[A].[Date_of_Join_Str]
			,[A].[Commission_Type_ID]
			,[A].[Commission_Type_Name]
			,[A].[Commission_Value]
			,[A].[Currency_ID]
			,[A].[Salary]
			,[A].[Position_By_Com_ID]
			,[A].[Client_ID]
	ORDER BY [A].[Contract_EMP_ID] ASC

	SET @Status_Code = '200';
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
			,'DB Accounting - sp_Get_Pending_Payment_Commission'
			,ERROR_MESSAGE()
			,@User_ID
			,GETDATE());
	SET @Status_Code = '999';
END CATCH
