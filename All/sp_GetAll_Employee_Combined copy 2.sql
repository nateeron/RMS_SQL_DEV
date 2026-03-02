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
@Company_ID INT = 1,
@From_Date_str NVARCHAR(50) = '',
@To_Date_str NVARCHAR(50) = '',
@Sales_Name_str NVARCHAR(500) = '',
@Client_Name_str NVARCHAR(500) = '',
@Employee_Name_str NVARCHAR(500) = '',
@Employee_Status_id INT = 0,
@Contract_Type_id INT = 0
AS
DECLARE @Status_ID INT = 0;

BEGIN TRY
	-- Get Status_ID for 'New' status (removed duplicate query)
	SET @Status_ID = (SELECT TOP 1 [Status_Contract_EMP_ID]
					FROM [Employee].[dbo].[Status_Contract_EMP]
					WHERE [Status_Contract_EMP_Name] = 'New');

	-- CTE: All Contract Types (pre-computed union)
	WITH ContractTypes AS (
		SELECT [Contract_Type_ID], [Contract_Type_Name], 2 AS [Contract_Type_By_Comp_Type_ID]  
		FROM [RMS_Contract_Type].[dbo].[Contract_Type]
		UNION ALL
		SELECT [Contract_Type_Temp_ID] AS [Contract_Type_ID], [Contract_Type_Temp_Name] AS [Contract_Type_Name], 1 AS [Contract_Type_By_Comp_Type_ID]
		FROM [RMS_Contract_Type].[dbo].[Contract_Type_Temp]
	),
	-- CTE: Contract Type By Comp lookup (pre-computed to avoid subqueries)
	ContractTypeByComp AS (
		SELECT 
			[PB].[Contract_Type_By_Comp_ID],
			[PB].[Contract_Type_By_Comp_Type_ID],
			[Contract_Type_ID_OF_Com] = [PB].[Contract_Type_ID]
		FROM [RMS_Contract_Type].[dbo].[Contract_Type_By_Comp] PB
	),
	-- CTE: All Positions (pre-computed union)
	AllPositions AS (
		SELECT [Position_ID], [Position_Name], 2 AS [Position_By_Com_Type_ID]  
		FROM [RMS_Position].[dbo].[Position]
		UNION ALL
		SELECT [Position_Temp_ID] AS [Position_ID], [Position_Name], 1 AS [Position_By_Com_Type_ID]
		FROM [RMS_Position].[DBO].[Position_Temp]
	),
	-- CTE: Position By Comp lookup (pre-computed)
	PositionByComp AS (
		SELECT 
			[PB].[Position_By_Com_ID],
			[PB].[Position_By_Com_Type_ID],
			[Position_ID_OF_Com] = [PB].[Position_ID]
		FROM [RMS_Position].[dbo].[Position_By_Comp] PB
	),
	-- CTE: Latest Active Contracts per Employee (optimized with ROW_NUMBER)
	LatestContracts AS (
		SELECT 
			[CTEMP].*,
			ROW_NUMBER() OVER (PARTITION BY [CTEMP].[Employee_ID] ORDER BY [CTEMP].[Contract_EMP_ID] DESC) AS [RowNum]
		FROM [DBO].[Contract_EMP] CTEMP
		WHERE [CTEMP].[Is_Active] = 1
	),
	-- CTE: Contract with Contract Type resolved
	ContractsWithType AS (
		SELECT 
			[LC].*,
			[Contract_Type_ID_Resolved] = CASE 
				WHEN [LC].[Contract_Type_By_Comp_ID] = 0 OR [LC].[Contract_Type_By_Comp_ID] IS NULL 
					THEN [LC].[Contract_Type_ID_OF_Com]
				ELSE [CTBC].[Contract_Type_ID_OF_Com]
			END,
			[Contract_Type_By_Comp_Type_ID_Resolved] = CASE 
				WHEN [LC].[Contract_Type_By_Comp_ID] = 0 OR [LC].[Contract_Type_By_Comp_ID] IS NULL 
					THEN 2
				ELSE [CTBC].[Contract_Type_By_Comp_Type_ID]
			END
		FROM LatestContracts LC
		LEFT JOIN ContractTypeByComp CTBC ON [CTBC].[Contract_Type_By_Comp_ID] = [LC].[Contract_Type_By_Comp_ID]
		WHERE [LC].[RowNum] = 1
	),
	-- CTE: Contract with Contract Type Name
	ContractsFinal AS (
		SELECT 
			[CWT].*,
			[CT].[Contract_Type_Name]
		FROM ContractsWithType CWT
		LEFT JOIN ContractTypes CT ON [CT].[Contract_Type_ID] = [CWT].[Contract_Type_ID_Resolved]
			AND [CT].[Contract_Type_By_Comp_Type_ID] = [CWT].[Contract_Type_By_Comp_Type_ID_Resolved]
	),
	-- CTE: Refer By Names (pre-computed)
	ReferByNames AS (
		SELECT 
			[EMP].[Employee_ID],
			[Refer_By_Name] = CASE 
				WHEN [T].[Title_Name] IS NOT NULL THEN TRIM([T].[Title_Name]) + ' ' + [P].[Full_Name]
				ELSE [P].[Full_Name] 
			END
		FROM [Employee].[dbo].[Employee] EMP
		LEFT JOIN [Candidate].[dbo].[Candidate] C ON [C].[Candidate_ID] = [EMP].[Candidate_ID]
		LEFT JOIN [Person].[dbo].[Person] P ON [P].[Person_ID] = [C].[Person_ID]
		LEFT JOIN [Title].[dbo].[Title] T ON [T].[Title_ID] = [P].[Title_ID]
	),
	-- CTE: Contracts with Refer By Name
	ContractsWithRefer AS (
		SELECT 
			[CF].*,
			[RBN].[Refer_By_Name]
		FROM ContractsFinal CF
		LEFT JOIN ReferByNames RBN ON [RBN].[Employee_ID] = [CF].[Refer_By]
	),
	-- CTE: Position resolved for contracts
	ContractPositions AS (
		SELECT 
			[CR].[Contract_EMP_ID],
			[CR].[Employee_ID],
			[Position_ID_Resolved] = CASE 
				WHEN [CR].[Position_By_Com_ID] = 0 OR [CR].[Position_By_Com_ID] IS NULL 
					THEN [CR].[Position_ID_OF_Com]
				ELSE [PBC].[Position_ID_OF_Com]
			END,
			[Position_By_Com_Type_ID_Resolved] = CASE 
				WHEN [CR].[Position_By_Com_ID] = 0 OR [CR].[Position_By_Com_ID] IS NULL 
					THEN 2
				ELSE [PBC].[Position_By_Com_Type_ID]
			END
		FROM ContractsWithRefer CR
		LEFT JOIN PositionByComp PBC ON [PBC].[Position_By_Com_ID] = [CR].[Position_By_Com_ID]
	),
	-- CTE: Contracts with Position Name
	ContractsWithPosition AS (
		SELECT 
			[CR].*,
			[AP].[Position_Name]
		FROM ContractsWithRefer CR
		INNER JOIN ContractPositions CP ON [CP].[Contract_EMP_ID] = [CR].[Contract_EMP_ID]
		LEFT JOIN AllPositions AP ON [AP].[Position_ID] = [CP].[Position_ID_Resolved]
			AND [AP].[Position_By_Com_Type_ID] = [CP].[Position_By_Com_Type_ID_Resolved]
	),
	-- CTE: Employees with New Status Contract (optimized EXISTS to INNER JOIN)
	EmployeesWithNewContract AS (
		SELECT DISTINCT [CE].[Employee_ID]
		FROM [Employee].[dbo].[Contract_EMP] CE
		WHERE [CE].[Status_Contract_EMP_ID] = @Status_ID
			AND [CE].[Is_Active] = 1
	),
	-- CTE: Candidate Names (pre-computed)
	CandidateNames AS (
		SELECT
			[CAN].[Candidate_ID],
			[P].[Full_Name]
		FROM [Candidate].[dbo].[Candidate] CAN
		LEFT JOIN [Person].[dbo].[Person] P ON [P].[Person_ID] = [CAN].[Person_ID]
	),
	-- CTE: Project Position details (simplified with COALESCE)
	ProjectPositions AS (
		SELECT 
			[PP].[Project_Position_ID],
			[Site_ID] = COALESCE([MPP].[Site_ID], [MSP].[Site_ID], 0),
			[Branch_ID] = COALESCE([MPP].[Branch_ID], [MSP].[Branch_ID], [MBP].[Branch_ID], 0),
			[Project_Client_ID] = COALESCE([MPP].[Project_Client_ID], 0),
			[Company_ID] = [COM].[Company_ID],
			[ComCliantName] = [COM].[Company_Name]
		FROM [Company].[dbo].[Project_Position] PP
		LEFT JOIN [Company].[dbo].[Map_Comp_Position] MCPP ON [MCPP].[Project_Position_ID] = [PP].[Project_Position_ID] 
			AND [MCPP].[Is_Active] = 1 AND [MCPP].[Is_Delete] = 0
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
						,[Branch_ID] = COALESCE([MBP].[Branch_ID_Of_Project], [MSP].[Branch_ID_Of_Site_Project])
						,[Branch_Name] = COALESCE([MBP].[Branch_Name_Of_Project], [MSP].[Branch_Name_Of_Site_Project])
				FROM [Company].[dbo].[Project_Client] PC
				LEFT JOIN [Company].[dbo].[Map_Comp_Project] MCP ON [MCP].[Project_Client_ID] = [PC].[Project_Client_ID] 
					AND [MCP].[Is_Active] = 1 AND [MCP].[Is_Delete] = 0
				LEFT JOIN (
					SELECT [Branch_ID_Of_Project] = [B].[Branch_ID]
							,[Branch_Name_Of_Project] = [B].[Branch_Name]
							,[Comp_Branch_Project] = [MCB].[Company_ID]
							,[MBP].[Project_Client_ID]
					FROM [Company].[dbo].[Map_Branch_Project] MBP
					LEFT JOIN [Company].[dbo].[Map_Comp_Branch] MCB ON [MCB].[Branch_ID] = [MBP].[Branch_ID] 
						AND [MCB].[Is_Active] = 1 AND [MCB].[Is_Delete] = 0
					LEFT JOIN [Company].[dbo].[Branch_By_Comp] B ON [B].[Branch_ID] = [MBP].[Branch_ID] 
						AND [B].[Is_Active] = 1 AND [B].[Is_Delete] = 0
					WHERE [MBP].[Is_Active] = 1 AND [MBP].[Is_Delete] = 0
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
					LEFT JOIN [Company].[dbo].[Map_Comp_Site] MCS ON [MCS].[Site_ID] = [MSP].[Site_ID] 
						AND [MSP].[Is_Active] = 1 AND [MSP].[Is_Delete] = 0
					LEFT JOIN [Company].[dbo].[Site] S ON [S].[Site_ID] = [MSP].[Site_ID] AND [S].[Is_Active] = 1
					LEFT JOIN [Company].[dbo].[Map_Branch_Site] MBS ON [MBS].[Site_ID] = [MSP].[Site_ID] 
						AND [MBS].[Is_Active] = 1 AND [MBS].[Is_Delete] = 0
					LEFT JOIN [Company].[dbo].[Map_Comp_Branch] MCB ON [MCB].[Branch_ID] = [MBS].[Branch_ID] 
						AND [MCB].[Is_Active] = 1 AND [MCB].[Is_Delete] = 0
					LEFT JOIN [Company].[dbo].[Branch_By_Comp] BS ON [BS].[Branch_ID] = [MBS].[Branch_ID] 
						AND [BS].[Is_Active] = 1 AND [BS].[Is_Delete] = 0
					WHERE [MSP].[Is_Active] = 1 AND [MSP].[Is_Delete] = 0
				) MSP ON [MSP].[Project_Client_ID] = [PC].[Project_Client_ID]
				WHERE [PC].[Is_Active] = 1 AND [PC].[Is_Delete] = 0
			) PC ON [PC].[Project_Client_ID] = [MPP].[Project_Client_ID]
			WHERE [MPP].[Is_Active] = 1 AND [MPP].[Is_Delete] = 0
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
			LEFT JOIN [Company].[dbo].[Map_Comp_Site] MCS ON [MCS].[Site_ID] = [MSP].[Site_ID] 
				AND [MSP].[Is_Active] = 1 AND [MSP].[Is_Delete] = 0
			LEFT JOIN [Company].[dbo].[Site] S ON [S].[Site_ID] = [MSP].[Site_ID] AND [S].[Is_Active] = 1
			LEFT JOIN [Company].[dbo].[Map_Branch_Site] MBS ON [MBS].[Site_ID] = [MSP].[Site_ID] 
				AND [MBS].[Is_Active] = 1 AND [MBS].[Is_Delete] = 0
			LEFT JOIN [Company].[dbo].[Map_Comp_Branch] MCB ON [MCB].[Branch_ID] = [MBS].[Branch_ID] 
				AND [MCB].[Is_Active] = 1 AND [MCB].[Is_Delete] = 0
			LEFT JOIN [Company].[dbo].[Branch_By_Comp] BS ON [BS].[Branch_ID] = [MBS].[Branch_ID] 
				AND [BS].[Is_Active] = 1 AND [BS].[Is_Delete] = 0
			WHERE [MSP].[Is_Active] = 1 AND [MSP].[Is_Delete] = 0
		) MSP ON [MSP].[Project_Position_ID] = [PP].[Project_Position_ID] 
		LEFT JOIN (
			SELECT [MBP].[Project_Position_ID]
					,[BS].[Branch_ID]
					,[BS].[Branch_Name]
					,[Comp_Branch] = [MCB].[Company_ID]
			FROM [Company].[dbo].[Map_Branch_Position] MBP
			LEFT JOIN [Company].[dbo].[Map_Comp_Branch] MCB ON [MCB].[Branch_ID] = [MBP].[Branch_ID] 
				AND [MCB].[Is_Active] = 1 AND [MCB].[Is_Delete] = 0
			LEFT JOIN [Company].[dbo].[Branch_By_Comp] BS ON [BS].[Branch_ID] = [MBP].[Branch_ID] 
				AND [BS].[Is_Active] = 1 AND [BS].[Is_Delete] = 0
			WHERE [MBP].[Is_Active] = 1 AND [MBP].[Is_Delete] = 0
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
	)

	SELECT 
		-- From sp_GetAll_Employee
		[EMP].[Employee_ID],
		[CN].[Full_Name] AS [Employee_Name],
		
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
		[Contract_Length] = CASE 
			WHEN [CONTR].[Start_Date] IS NULL OR [CONTR].[End_Date] IS NULL THEN '-'
			WHEN DATEDIFF(YEAR, [CONTR].[Start_Date], [CONTR].[End_Date]) > 0 THEN
				CAST(DATEDIFF(YEAR, [CONTR].[Start_Date], [CONTR].[End_Date]) AS VARCHAR) + 
				CASE WHEN DATEDIFF(YEAR, [CONTR].[Start_Date], [CONTR].[End_Date]) = 1 THEN ' Year' ELSE ' Years' END
			WHEN DATEDIFF(MONTH, [CONTR].[Start_Date], [CONTR].[End_Date]) > 0 THEN
				CAST(DATEDIFF(MONTH, [CONTR].[Start_Date], [CONTR].[End_Date]) AS VARCHAR) + 
				CASE WHEN DATEDIFF(MONTH, [CONTR].[Start_Date], [CONTR].[End_Date]) = 1 THEN ' month' ELSE ' month' END
			WHEN DATEDIFF(DAY, [CONTR].[Start_Date], [CONTR].[End_Date]) > 0 THEN
				CAST(DATEDIFF(DAY, [CONTR].[Start_Date], [CONTR].[End_Date]) AS VARCHAR) + 
				CASE WHEN DATEDIFF(DAY, [CONTR].[Start_Date], [CONTR].[End_Date]) = 1 THEN ' Day' ELSE ' Days' END
			ELSE '0 Days'
		END,
		[CONTR].[Start_Date],
		[CONTR].[DOJ],
		[CONTR].[End_Date],
		[CONTR].[Contract_EMP_ID],
		[CONTR].[Position_Name],
		[CONTR].[Contract_Type_Name],
		[EMP].[Status_Employee],
		[CONTR].[Project_Position_ID],
		
		-- From sp_Get_Contract_For_Update
		[ConEMP].[Position_ID_OF_Com],
		[ConEMP].[Position_By_Com_ID],
		[ConEMP].[Contract_Type_ID_OF_Com],
		[ConEMP].[Contract_Type_By_Comp_ID],
		[PP].[Branch_ID],
		[PP].[Company_ID] AS [client_CompanyID],
		[PP].[ComCliantName],
		[sell_CliantName] = CASE WHEN [MUP].[Owner_Name] IS NOT NULL THEN [MUP].[Owner_Name] ELSE '-' END
	FROM [Employee].[dbo].[Employee] EMP
	-- Filter employees with New status contract early (INNER JOIN instead of EXISTS)
	INNER JOIN EmployeesWithNewContract EWC ON [EWC].[Employee_ID] = [EMP].[Employee_ID]
	-- Get Employee Name
	LEFT JOIN CandidateNames CN ON [CN].[Candidate_ID] = [EMP].[Candidate_ID]
	-- Get Company Name
	LEFT JOIN [Company].[dbo].[Company] C ON [C].[Company_ID] = [EMP].[Company_ID]
	-- Get Contract details (latest active contract)
	LEFT JOIN ContractsWithPosition CONTR ON [CONTR].[Employee_ID] = [EMP].[Employee_ID]
	-- Get Contract details for update
	LEFT JOIN [dbo].[Contract_EMP] ConEMP ON [ConEMP].[Contract_EMP_ID] = [CONTR].[Contract_EMP_ID]
	-- Get Project Position details
	LEFT JOIN ProjectPositions PP ON [PP].[Project_Position_ID] = [ConEMP].[Project_Position_ID]
	-- Get Owner Name from Map_User_PrjPosi
	LEFT JOIN (
		SELECT [MUP].[Project_Position_ID],
			[Owner_Name] = [P].[Full_Name],
			[MUP].[Is_Active]
		FROM [Company].[dbo].[Map_User_PrjPosi] MUP
		LEFT JOIN [Person].[dbo].[Person] P ON [P].[Person_ID] = [MUP].[Person_ID]
	) MUP ON [MUP].[Project_Position_ID] = [PP].[Project_Position_ID] AND [MUP].[Is_Active] = 1
	
	WHERE [EMP].[Company_ID] = @Company_ID
		AND [EMP].[Is_Deleted] = 0
		AND [CONTR].[Is_Active] = 1
		-- Filter by From Date (if provided)
		AND (@From_Date_str = '' OR TRY_CAST(@From_Date_str AS DATE) IS NULL OR [CONTR].[Start_Date] >= TRY_CAST(@From_Date_str AS DATE))
		-- Filter by To Date (if provided)
		AND (@To_Date_str = '' OR TRY_CAST(@To_Date_str AS DATE) IS NULL OR [CONTR].[End_Date] <= TRY_CAST(@To_Date_str AS DATE))
		-- Filter by Sales Name (if provided)
		AND (@Sales_Name_str = '' OR @Sales_Name_str IS NULL OR [MUP].[Owner_Name] LIKE '%' + @Sales_Name_str + '%')
		-- Filter by Client Name (if provided)
		AND (@Client_Name_str = '' OR @Client_Name_str IS NULL OR [PP].[ComCliantName] LIKE '%' + @Client_Name_str + '%')
		-- Filter by Employee Name (if provided)
		AND (@Employee_Name_str = '' OR @Employee_Name_str IS NULL OR [CN].[Full_Name] LIKE '%' + @Employee_Name_str + '%')
		-- Filter by Employee Status ID (if provided)
		AND (@Employee_Status_id = 0 OR [EMP].[Status_Employee] = @Employee_Status_id)
		-- Filter by Contract Type ID (if provided)
		AND (@Contract_Type_id = 0 OR [ConEMP].[Contract_Type_ID_OF_Com] = @Contract_Type_id);
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

