USE [Employee]
GO
/****** Object:  StoredProcedure [dbo].[sp_GetAll_Employee_Combined]    Script Date: 12/18/2025 4:01:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Procedure name: [dbo].[sp_GetAll_Employee_Combined]
-- Function: Get All Employee with combined data from sp_GetAll_Employee, sp_GetById_Employee, and sp_Get_Contract_For_Update
-- Create date: 12/12/2025
-- Description: Select function that combines data from three stored procedures
-- sp_GetAll_Employee_Combined 3357,'','',''

--EXEC [dbo].[sp_GetAll_Employee_Combined]
--	@Company_ID = 3357,
--	@From_Date_str = '2025-01-01',
--	@To_Date_str = '2025-12-31',
--	@Sales_Name_str = '3869,3864',
--	@Client_Name_str = '3396,3399',
--	@Employee_Name_str = 'M09 (K.) M09,htrfuh qqqqq',
--	@Employee_Status_id = 'Active,Released',
--	@Contract_Type_id = '6,1'

--EXEC [dbo].[sp_GetAll_Employee_Combined]
--	@Company_ID = 3357,
--	@From_Date_str = '',
--	@To_Date_str = '',
--	@Sales_Name_str = '',
--	@Client_Name_str = '',
--	@Employee_Name_str = 'M09 (K.) M09,htrfuh qqqqq',
--	@Employee_Status_id = 'Active,Released',
--	@Contract_Type_id = '6,1'
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
@Employee_Status_id NVARCHAR(500) = '',
@Contract_Type_id NVARCHAR(500) = ''
AS
DECLARE @Status_Terminate_ID INT = 0;

BEGIN TRY
	-- Get Status_ID for 'Terminate' status
	SET @Status_Terminate_ID = (SELECT TOP 1 [Status_Contract_EMP_ID]
					FROM [Employee].[dbo].[Status_Contract_EMP]
					WHERE [Status_Contract_EMP_Name] = 'Terminate');

	-- CTE: Split Sales Name/ID values
	WITH SalesFilter AS (
		SELECT LTRIM(RTRIM([value])) AS [Sales_Value]
		FROM STRING_SPLIT(@Sales_Name_str, ',')
		WHERE @Sales_Name_str <> '' AND @Sales_Name_str IS NOT NULL
	),
	-- CTE: Split Client Name/ID values
	ClientFilter AS (
		SELECT LTRIM(RTRIM([value])) AS [Client_Value]
		FROM STRING_SPLIT(@Client_Name_str, ',')
		WHERE @Client_Name_str <> '' AND @Client_Name_str IS NOT NULL
	),
	-- CTE: Split Employee Name values
	EmployeeNameFilter AS (
		SELECT LTRIM(RTRIM([value])) AS [Employee_Name_Value]
		FROM STRING_SPLIT(@Employee_Name_str, ',')
		WHERE @Employee_Name_str <> '' AND @Employee_Name_str IS NOT NULL
	),
	-- CTE: Get Employee Status values (names) from comma-separated string
	EmployeeStatusFilter AS (
		SELECT LTRIM(RTRIM([value])) AS [Status_Employee_Value]
		FROM STRING_SPLIT(@Employee_Status_id, ',')
		WHERE @Employee_Status_id <> '' AND @Employee_Status_id IS NOT NULL
	),
	-- CTE: Split Contract Type ID values
	ContractTypeFilter AS (
		SELECT TRY_CAST(LTRIM(RTRIM([value])) AS INT) AS [Contract_Type_ID_Value]
		FROM STRING_SPLIT(@Contract_Type_id, ',')
		WHERE @Contract_Type_id <> '' AND @Contract_Type_id IS NOT NULL
			AND TRY_CAST(LTRIM(RTRIM([value])) AS INT) IS NOT NULL
	),
	-- CTE: All Contract Types (pre-computed union)
	 ContractTypes AS (
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
		WHERE ([CTEMP].[Is_Active] = 1 OR [CTEMP].[Status_Contract_EMP_ID] = @Status_Terminate_ID)
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
			[CT].[Contract_Type_ID],
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
		[CONTR].[Contract_Type_ID],
		[CONTR].[Contract_Type_Name],
		[EMP].[Status_Employee],
		[CONTR].[Project_Position_ID],
		-- From sp_Get_Contract_For_Update
		[ConEMP].[Position_ID_OF_Com],
		[ConEMP].[Position_By_Com_ID],
		[ConEMP].[Contract_Type_ID_OF_Com],
		[ConEMP].[Contract_Type_By_Comp_ID],
		[ConEMP].[Terminate_Status_ID],
		[ConEMP].[Terminate_Remark],
		[ConEMP].[Terminate_Date],
		[PP].[Branch_ID],
		[PP].[Company_ID] AS [client_CompanyID],
		[PP].[ComCliantName],
		[sell_CliantName] = CASE WHEN [MUP].[Owner_Name] IS NOT NULL THEN [MUP].[Owner_Name] ELSE '-' END
	FROM [Employee].[dbo].[Employee] EMP
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
			[MUP].[Person_ID],
			[MUP].[Is_Active]
		FROM [Company].[dbo].[Map_User_PrjPosi] MUP
		LEFT JOIN [Person].[dbo].[Person] P ON [P].[Person_ID] = [MUP].[Person_ID]
	) MUP ON [MUP].[Project_Position_ID] = [PP].[Project_Position_ID] AND [MUP].[Is_Active] = 1
	
	WHERE [EMP].[Company_ID] = @Company_ID
		AND ([EMP].[Is_Deleted] = 0 OR [CONTR].[Terminate_Date] IS NOT NULL)
		AND (([CONTR].[Is_Active] = 1) OR ([CONTR].[Status_Contract_EMP_ID] = @Status_Terminate_ID))
		-- Filter by From/To Date using Start_Date only (ignore End_Date)
		AND (@From_Date_str = '' OR TRY_CAST(@From_Date_str AS DATE) IS NULL OR [CONTR].[Start_Date] >= TRY_CAST(@From_Date_str AS DATE))
		AND (@To_Date_str = '' OR TRY_CAST(@To_Date_str AS DATE) IS NULL OR [CONTR].[Start_Date] <= TRY_CAST(@To_Date_str AS DATE))
		-- Filter by Sales Name/ID (if provided) - supports multiple values, handles both IDs and names
		AND (@Sales_Name_str = '' OR @Sales_Name_str IS NULL OR 
			EXISTS (
				SELECT 1 FROM SalesFilter SF
				WHERE (TRY_CAST(SF.[Sales_Value] AS INT) IS NOT NULL AND [MUP].[Person_ID] = TRY_CAST(SF.[Sales_Value] AS INT))
					OR (TRY_CAST(SF.[Sales_Value] AS INT) IS NULL AND [MUP].[Owner_Name] LIKE '%' + SF.[Sales_Value] + '%')
			)
		)
		-- Filter by Client Name/ID (if provided) - supports multiple values, handles both IDs and names
		AND (@Client_Name_str = '' OR @Client_Name_str IS NULL OR 
			EXISTS (
				SELECT 1 FROM ClientFilter CF
				WHERE (TRY_CAST(CF.[Client_Value] AS INT) IS NOT NULL AND [PP].[Company_ID] = TRY_CAST(CF.[Client_Value] AS INT))
					OR (TRY_CAST(CF.[Client_Value] AS INT) IS NULL AND [PP].[ComCliantName] LIKE '%' + CF.[Client_Value] + '%')
			)
		)
		-- Filter by Employee Name (if provided) - supports multiple values
		AND (@Employee_Name_str = '' OR @Employee_Name_str IS NULL OR 
			EXISTS (
				SELECT 1 FROM EmployeeNameFilter ENF
				WHERE [CN].[Full_Name] LIKE '%' + ENF.[Employee_Name_Value] + '%'
			)
		)
		-- Filter by Employee Status (if provided) - supports multiple status names
		AND (@Employee_Status_id = '' OR @Employee_Status_id IS NULL OR 
			[EMP].[Status_Employee] IN (SELECT [Status_Employee_Value] FROM EmployeeStatusFilter)
		)
		-- Filter by Contract Type ID (if provided) - supports multiple IDs
		AND (@Contract_Type_id = '' OR @Contract_Type_id IS NULL OR 
			[ConEMP].[Contract_Type_ID_OF_Com] IN (SELECT [Contract_Type_ID_Value] FROM ContractTypeFilter)
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

