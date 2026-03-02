USE [Employee]
GO
/****** Object:  StoredProcedure [dbo].[sp_GetAll_Employee_Combined]    Script Date: 12/16/2025 2:51:46 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Procedure name: [dbo].[sp_GetAll_Employee_Combined]
-- Function: Get All Employee with combined data from sp_GetAll_Employee, sp_GetById_Employee, and sp_Get_Contract_For_Update
-- Create date: 12/12/2025
-- Description: Select function that combines data from three stored procedures
-- sp_GetAll_Employee_Combined 3357
----------------------------------------
-- From
-- sp_GetAll_Employee 3357
-- sp_GetById_Employee 1355
-- sp_Get_Contract_For_Update 1780

-- =============================================
ALTER PROCEDURE [dbo].[sp_GetAll_Employee_Combined]
@Company_ID INT = 1
AS
DECLARE @Status_ID INT = 0,
        @Status_New_ID INT = 0;

BEGIN TRY
	-- Get Status_ID for 'New' status
	SET @Status_ID = (SELECT TOP 1 [SCE].[Status_Contract_EMP_ID]
					FROM [Employee].[dbo].[Status_Contract_EMP] SCE
					WHERE [SCE].[Status_Contract_EMP_Name] = 'New');

	SET @Status_New_ID = (SELECT TOP 1 [SC].[Status_Contract_EMP_ID] 
							FROM [DBO].[Status_Contract_EMP] SC
							WHERE [SC].[Status_Contract_EMP_Name] = 'New' );

	SELECT 
		-- From sp_GetAll_Employee
		[EMP].[Employee_ID],
		[CANDIDATE].[Full_Name] AS [Employee_Name],
		
		-- From sp_GetById_Employee
		[EMP].[Candidate_ID],
		[EMP].[Company_ID],
		[C].[Company_Name],
		[Start_Date_str] = CASE WHEN [CONTR].[Start_Date] IS NULL THEN '-'
								ELSE FORMAT([CONTR].[Start_Date], 'dd MMM yyyy') END,
		[Date_Of_Join_str] = CASE WHEN [CONTR].[DOJ] IS NULL THEN '-'
									ELSE FORMAT([CONTR].[DOJ], 'dd MMM yyyy') END,
		[End_Date_str] = CASE WHEN [CONTR].[End_Date] IS NULL THEN '-'
								ELSE FORMAT([CONTR].[End_Date], 'dd MMM yyyy') END,
		[CONTR].[Start_Date],
		[CONTR].[DOJ],
		[CONTR].[End_Date],
		[CONTR].[Contract_EMP_ID],
		[POS].[Position_Name],
		[CONTR].[Contract_Type_Name],
		[EMP].[Status_Employee],
		[CONTR].[Project_Position_ID],
		
		-- From sp_Get_Contract_For_Update
		[ConEMP].[Position_ID_OF_Com],
		[ConEMP].[Position_By_Com_ID],
		[ConEMP].[Contract_Type_ID_OF_Com],
		[ConEMP].[Contract_Type_By_Comp_ID],
		[PP].[Branch_ID],
		[PP].[Company_ID] AS [client_CompanyID]
		,[pp].ComCliantName
	FROM [Employee].[dbo].[Employee] EMP
	-- Get Employee Name (from sp_GetAll_Employee logic)
	LEFT JOIN (
		SELECT
			[CAN].[Candidate_ID],
			[T].[Title_ID],
			[T].[Title_Name],
			[CAN].[Person_ID],
			[P].[Full_Name]
		FROM [Candidate].[dbo].[Candidate] CAN
		LEFT JOIN [Person].[dbo].[Person] P ON [P].[Person_ID] = [CAN].[Person_ID]
		LEFT JOIN [Title].[dbo].[Title] T ON [T].[Title_ID] = [P].[Title_ID]
	) CANDIDATE ON [CANDIDATE].[Candidate_ID] = [EMP].[Candidate_ID]
	
	-- Get Company Name
	LEFT JOIN [Company].[dbo].[Company] C ON [C].[Company_ID] = [EMP].[Company_ID]
	
	-- Get Contract details (from sp_GetById_Employee logic - latest active contract)
	LEFT JOIN (
		SELECT [CTEMP].*
				,[ER].[Refer_By_Name]
				,[CONTYP].[Contract_Type_Name]
			FROM [DBO].[Contract_EMP] CTEMP
			LEFT JOIN (
				SELECT [P].[Contract_Type_ID] , [P].[Contract_Type_Name] , 2 AS [Contract_Type_By_Comp_Type_ID]  
				FROM  [RMS_Contract_Type].[dbo].[Contract_Type] P  
			UNION
				SELECT [PT].[Contract_Type_Temp_ID] AS [Contract_Type_ID] , [PT].[Contract_Type_Temp_Name] , 1 AS [Contract_Type_By_Comp_Type_ID]
				FROM [RMS_Contract_Type].[dbo].[Contract_Type_Temp] PT
			)CONTYP ON [CONTYP].[Contract_Type_ID] = (
													CASE WHEN [CTEMP].[Contract_Type_By_Comp_ID] = 0 OR [CTEMP].[Contract_Type_By_Comp_ID] IS NULL
														 THEN [CTEMP].[Contract_Type_ID_OF_Com]
													ELSE
														 (
															SELECT [Contract_Type_ID_OF_Com] = (
																									CASE WHEN [PB].[Contract_Type_By_Comp_Type_ID] = 1
																										 THEN (
																												SELECT [PT].[Contract_Type_Temp_ID]
																												FROM [RMS_Contract_Type].[dbo].[Contract_Type_Temp] PT
																												WHERE [PT].[Contract_Type_Temp_ID] = [PB].[Contract_Type_ID]
																										      )
																									 ELSE
																										 [PB].[Contract_Type_ID]
																									 END
																							   )
															FROM [RMS_Contract_Type].[dbo].[Contract_Type_By_Comp] PB
															WHERE [PB].[Contract_Type_By_Comp_ID] = [CTEMP].[Contract_Type_By_Comp_ID]
														 )
													END
												 )
				AND [CONTYP].[Contract_Type_By_Comp_Type_ID] = (
																CASE WHEN [CTEMP].[Contract_Type_By_Comp_ID] = 0 OR [CTEMP].[Contract_Type_By_Comp_ID] IS NULL 
																		THEN 2
																ELSE
																	(
																		SELECT [PB].[Contract_Type_By_Comp_Type_ID]
																		FROM [RMS_Contract_Type].[dbo].[Contract_Type_By_Comp] PB
																		WHERE [PB].[Contract_Type_By_Comp_ID] = [CTEMP].[Contract_Type_By_Comp_ID]
																	)
																END
															)
			LEFT JOIN (SELECT [Refer_By_Name] = (CASE WHEN [T].[Title_Name] IS NOT NULL THEN TRIM([T].[Title_Name]) + ' ' + [P].[Full_Name]
												 ELSE [P].[Full_Name] END),
						  [EMP].[Employee_ID]
				   FROM [Employee].[dbo].[Employee] EMP
				   LEFT JOIN [Candidate].[dbo].[Candidate] C ON [C].[Candidate_ID] = [EMP].[Candidate_ID]
				   LEFT JOIN [Person].[dbo].[Person] P ON [P].[Person_ID] = [C].[Person_ID]
				   LEFT JOIN [Title].[dbo].[Title] T ON [T].[Title_ID] = [P].[Title_ID]) ER ON [ER].[Employee_ID] = [CTEMP].[Refer_By]
			WHERE [CTEMP].[Is_Active] = 1
			AND [CTEMP].[Contract_EMP_ID] = (
				SELECT MAX([CT].[Contract_EMP_ID])
				FROM [DBO].[Contract_EMP] CT
				WHERE [CT].[Employee_ID] = [CTEMP].[Employee_ID]
				AND [CT].[Is_Active] = 1
			)
	) CONTR ON [CONTR].[Employee_ID] = [EMP].[Employee_ID]
	
	-- Get Position Name (from sp_GetById_Employee logic)
	LEFT JOIN (
		SELECT [P].[Position_ID] , [P].[Position_Name] , 2 AS [Position_By_Com_Type_ID]  
		FROM  [RMS_Position].[dbo].[Position] P  
		UNION
		SELECT [PT].[Position_Temp_ID] AS [Position_ID] , [PT].[Position_Name] , 1 AS [Position_By_Com_Type_ID]
		FROM [RMS_Position].[DBO].[Position_Temp] PT
	) POS ON [POS].[Position_ID] = (
									CASE 
									WHEN [CONTR].[Position_By_Com_ID] = 0 OR [CONTR].[Position_By_Com_ID] IS NULL  THEN
											[CONTR].[Position_ID_OF_Com]
									ELSE
											(SELECT  [Position_ID_OF_Com] = (CASE  WHEN [PB].[Position_By_Com_Type_ID] = 1 THEN 
																						(SELECT TOP 1 [PT].[Position_Temp_ID]
																						FROM [RMS_Position].[dbo].[Position_Temp] PT
																						WHERE [PT].[Position_Temp_ID] = [PB].[Position_ID])
																				ELSE
																						[PB].[Position_ID]
																				END)
											FROM [RMS_Position].[dbo].[Position_By_Comp] PB 
											WHERE [PB].[Position_By_Com_ID] = [CONTR].[Position_By_Com_ID]
											)
									END
									)
			AND [POS].[Position_By_Com_Type_ID] = (
													CASE 
													WHEN [CONTR].[Position_By_Com_ID] = 0 OR [CONTR].[Position_By_Com_ID] IS NULL  THEN
															2
													ELSE
														(SELECT TOP 1 [PB].[Position_By_Com_Type_ID]
														FROM [RMS_Position].[dbo].[Position_By_Comp] PB WHERE [PB].[Position_By_Com_ID] = [CONTR].[Position_By_Com_ID])
													END
													)
	
	-- Get Contract details for update (from sp_Get_Contract_For_Update logic)
	LEFT JOIN [dbo].[Contract_EMP] ConEMP ON [ConEMP].[Contract_EMP_ID] = [CONTR].[Contract_EMP_ID]
	
	-- Get Project Position details with Branch_ID and Company_ID (from sp_Get_Contract_For_Update logic)
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
				,[COM].Company_Name as ComCliantName
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
			LEFT JOIN [Company].[dbo].[Company] C ON C.Company_ID = [MCB].[Company_ID]
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
	
	WHERE [EMP].[Company_ID] = @Company_ID
	AND [EMP].[Is_Deleted] = 0
	AND [CONTR].[Is_Active] = 1
	-- Filter to only include employees that have a contract with Status = 'New' (from sp_GetAll_Employee logic)
	AND EXISTS (
		SELECT 1
		FROM [Employee].[dbo].[Contract_EMP] CE_CHECK
		WHERE [CE_CHECK].[Employee_ID] = [EMP].[Employee_ID]
		AND [CE_CHECK].[Status_Contract_EMP_ID] = @Status_ID
		AND [CE_CHECK].[Is_Active] = 1
	);
--	client_CompanyID
--3396
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
				,'DB Employee - sp_GetAll_Employee_Combined'
				,ERROR_MESSAGE()
				,999
				,GETDATE());
END CATCH

