USE [Candidate]
GO
/****** Object:  StoredProcedure [dbo].[sp_Get_Candidate_Recruiter_Report]    Script Date: 12/23/2025 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	Get Candidate and Recruiter Report with filters
-- Parameters:
--	@Company_ID - Single Company ID
--	@Project_Position_ID - Comma-separated list of Project Position IDs (e.g., '1,2,3')
--	@Current_Position_ID - Comma-separated list of Current Position IDs (e.g., '1,2,3')
--	@Candidate_ID - Comma-separated list of Candidate IDs (e.g., '1,2,3')
--	@Recruiter_ID - Comma-separated list of Recruiter/Person IDs (e.g., '1,2,3')
-- =============================================
ALTER PROCEDURE [dbo].[sp_Get_Candidate_Recruiter_Report]
	@Company_ID INT = 0,
	@Project_Position_ID NVARCHAR(MAX) = NULL,
	@Current_Position_ID NVARCHAR(MAX) = NULL,
	@Candidate_ID NVARCHAR(MAX) = NULL,
	@Recruiter_ID NVARCHAR(MAX) = NULL,
	@Status_Code NVARCHAR(100) = NULL OUTPUT
AS
BEGIN TRY
	-- Parse comma-separated values into table variables
	DECLARE @ProjectPositionTable TABLE (ID INT);
	DECLARE @CurrentPositionTable TABLE (ID INT);
	DECLARE @CandidateTable TABLE (ID INT);
	DECLARE @RecruiterTable TABLE (ID INT);

	-- Parse Project_Position_ID
	IF @Project_Position_ID IS NOT NULL AND @Project_Position_ID <> ''
	BEGIN
		INSERT INTO @ProjectPositionTable (ID)
		SELECT TRY_CAST(LTRIM(RTRIM(value)) AS INT)
		FROM STRING_SPLIT(@Project_Position_ID, ',')
		WHERE LTRIM(RTRIM(value)) <> '' AND TRY_CAST(LTRIM(RTRIM(value)) AS INT) IS NOT NULL;
	END;

	-- Parse Current_Position_ID
	IF @Current_Position_ID IS NOT NULL AND @Current_Position_ID <> ''
	BEGIN
		INSERT INTO @CurrentPositionTable (ID)
		SELECT TRY_CAST(LTRIM(RTRIM(value)) AS INT)
		FROM STRING_SPLIT(@Current_Position_ID, ',')
		WHERE LTRIM(RTRIM(value)) <> '' AND TRY_CAST(LTRIM(RTRIM(value)) AS INT) IS NOT NULL;
	END;

	-- Parse Candidate_ID
	IF @Candidate_ID IS NOT NULL AND @Candidate_ID <> ''
	BEGIN
		INSERT INTO @CandidateTable (ID)
		SELECT TRY_CAST(LTRIM(RTRIM(value)) AS INT)
		FROM STRING_SPLIT(@Candidate_ID, ',')
		WHERE LTRIM(RTRIM(value)) <> '' AND TRY_CAST(LTRIM(RTRIM(value)) AS INT) IS NOT NULL;
	END;

	-- Parse Recruiter_ID
	IF @Recruiter_ID IS NOT NULL AND @Recruiter_ID <> ''
	BEGIN
		INSERT INTO @RecruiterTable (ID)
		SELECT TRY_CAST(LTRIM(RTRIM(value)) AS INT)
		FROM STRING_SPLIT(@Recruiter_ID, ',')
		WHERE LTRIM(RTRIM(value)) <> '' AND TRY_CAST(LTRIM(RTRIM(value)) AS INT) IS NOT NULL;
	END;

	WITH CTE_Position AS (
		SELECT [P].[Position_ID], [P].[Position_Name], 2 AS [Position_By_Com_Type_ID]  
		FROM [RMS_Position].[dbo].[Position] P
		UNION
		SELECT [PT].[Position_Temp_ID] AS [Position_ID], [PT].[Position_Name], 1 AS [Position_By_Com_Type_ID] 
		FROM [RMS_Position].[DBO].[Position_Temp] PT
	),
	CTE_PositionByComp AS (
		SELECT [PB].[Position_By_Com_ID],
				[PB].[Position_ID],
				[PB].[Position_By_Com_Type_ID],
				[Position_ID_OF_Com] = [PB].[Position_ID]
		FROM [RMS_Position].[dbo].[Position_By_Comp] PB
	),
	CTE_Phone AS (
		SELECT [T].[Tel_ID], 
				[TC].[Tel_Country_ID],
				[TC].[Tel_Country_Code],
				[T].[Tel_Number],
				[T].[Reference_ID]
		FROM [Mobile].[dbo].[Tel] T
		LEFT JOIN [Mobile].[dbo].[Mobile_Category_Type] MCT ON [MCT].[Category_Type_ID] = [T].[Category_Type_ID]
		LEFT JOIN [Mobile].[dbo].[Tel_Type] TT ON [TT].[Tel_Type_ID] = [T].[Tel_Type_ID]
		LEFT JOIN [Tel_Country].[dbo].[Tel_Country] TC ON [TC].[Tel_Country_ID] = [T].[Tel_Country_ID]
														AND [TC].[Is_Active] = 1
														AND [TC].[Is_Deleted] = 0
		WHERE [T].[Is_Active] = 1
			AND [MCT].[Category_Type_Name] = 'Person'
			AND [TT].[Tel_Type_Name] = 'Mobile'
	),
	CTE_LogUpdate AS (
		SELECT [tt].[Update_By] AS [Recruiter_ID],
				[tt].[Update_Date],
				[tt].[Candidate_ID]
		FROM [Candidate].[dbo].[Log_Update_Candidate] tt
		INNER JOIN (
			SELECT [ss].[Candidate_ID], MAX([ss].[Update_Date]) AS MaxDateTime
			FROM [Candidate].[dbo].[Log_Update_Candidate] ss
			GROUP BY [ss].[Candidate_ID]
		) groupedtt ON tt.[Candidate_ID] = groupedtt.[Candidate_ID] 
			AND tt.[Update_Date] = groupedtt.MaxDateTime
		GROUP BY [tt].[Update_By], [tt].[Update_Date], [tt].[Candidate_ID]
	),
	CTE_LastSalary AS (
		SELECT 
			[EC].[Candidate_ID],
			[EC].[Last_Salary] AS [Salary],
			ROW_NUMBER() OVER (PARTITION BY [EC].[Candidate_ID] ORDER BY [EC].[Start_Date] DESC) AS RowNum
		FROM [Candidate].[dbo].[Experiences_Candidate] EC
		WHERE [EC].[Is_Deleted] = 0
			AND [EC].[Is_Active] = 1
			AND [EC].[Last_Salary] IS NOT NULL
	),
	CTE_CandidateStatus AS (
		SELECT 
			[C].[Candidate_ID],
			[Candidate_Status] = CASE 
				WHEN [C].[Is_Employee] = 1 THEN 'Employee'
				WHEN EXISTS (
					SELECT 1 
					FROM [Pipeline].[dbo].[Map_Can_Pile_Com] MCP
					WHERE [MCP].[Candidate_ID] = [C].[Candidate_ID]
						AND [MCP].[Is_Active] = 1
						AND [MCP].[Is_Delete] = 0
				) THEN 'In Pipeline'
				ELSE 'Candidate'
			END
		FROM [Candidate].[dbo].[Candidate] C
	)
	SELECT 
		[Recruiter_Name] = [PU].[Full_Name],
		[Recruiter_ID] = [LUC].[Recruiter_ID],
		[Candidate_Name] = [P].[Full_Name],
		[Candidate_ID] = [P].[Person_ID],
		[Candidate_Age] = CASE 
			WHEN [P].[Birth_Date] IS NOT NULL 
			THEN DATEDIFF(YEAR, [P].[Birth_Date], GETDATE()) - 
				 CASE 
					 WHEN DATEADD(YEAR, DATEDIFF(YEAR, [P].[Birth_Date], GETDATE()), [P].[Birth_Date]) > GETDATE() 
					 THEN 1 
					 ELSE 0 
				 END
			ELSE NULL
		END,
		[Phone_Number] = CASE 
			WHEN [PHONE].[Tel_Country_Code] IS NOT NULL AND [PHONE].[Tel_Number] IS NOT NULL
			THEN [PHONE].[Tel_Country_Code] + ' ' + [PHONE].[Tel_Number]
			WHEN [PHONE].[Tel_Number] IS NOT NULL
			THEN [PHONE].[Tel_Number]
			ELSE '-'
		END,
		[Email] = ISNULL([P].[Email], '-'),
		[Last_Position_Name] = [POS].[Position_Name],
		[ID_Position] = CASE 
			WHEN [C].[Current_Position_By_Com] = 0 OR [C].[Current_Position_By_Com] IS NULL  
			THEN [C].[Current_Position]
			ELSE [C].[Current_Position_By_Com]
		END,
		[Last_Salary] = CASE 
			WHEN [LS].[Salary] IS NOT NULL 
			THEN CAST([LS].[Salary] AS NVARCHAR(50))
			ELSE '-'
		END,
		[Candidate_Status] = ISNULL([CS].[Candidate_Status], 'Candidate')
	FROM [Candidate].[dbo].[Candidate] C
	LEFT JOIN [Person].[dbo].[Person] P ON [P].[Person_ID] = [C].[Person_ID]
	LEFT JOIN CTE_Phone PHONE ON [PHONE].[Reference_ID] = [P].[Person_ID]
	LEFT JOIN CTE_LogUpdate LUC ON [LUC].[Candidate_ID] = [C].[Candidate_ID] AND [C].[Is_Deleted] = 0
	LEFT JOIN [PERSON].[DBO].[Person] PU ON [PU].[Person_ID] = [LUC].[Recruiter_ID]
	LEFT JOIN CTE_Position POS ON [POS].[Position_ID] = (
		CASE 
			WHEN [C].[Current_Position_By_Com] = 0 OR [C].[Current_Position_By_Com] IS NULL  
			THEN [C].[Current_Position]
			ELSE (
				SELECT [Position_ID_OF_Com]
				FROM CTE_PositionByComp PB 
				WHERE [PB].[Position_By_Com_ID] = [C].[Current_Position_By_Com]
			)
		END
	)
	AND [POS].[Position_By_Com_Type_ID] = (
		CASE 
			WHEN [C].[Current_Position_By_Com] = 0 OR [C].[Current_Position_By_Com] IS NULL THEN 2
			ELSE (
				SELECT [PB].[Position_By_Com_Type_ID]
				FROM CTE_PositionByComp PB 
				WHERE [PB].[Position_By_Com_ID] = [C].[Current_Position_By_Com]
			)
		END
	)
	LEFT JOIN CTE_LastSalary LS ON [LS].[Candidate_ID] = [C].[Candidate_ID] AND [LS].[RowNum] = 1
	LEFT JOIN CTE_CandidateStatus CS ON [CS].[Candidate_ID] = [C].[Candidate_ID]
	LEFT JOIN [Pipeline].[dbo].[Map_Can_Pile_Com] MCP ON [MCP].[Candidate_ID] = [C].[Candidate_ID]
		AND [MCP].[Is_Active] = 1
		AND [MCP].[Is_Delete] = 0
	WHERE [C].[Is_Deleted] = 0
		AND (@Company_ID = 0 OR [C].[Company_ID] = @Company_ID)
		AND (
			(SELECT COUNT(*) FROM @ProjectPositionTable) = 0 
			OR [MCP].[Project_Position_ID] IN (SELECT ID FROM @ProjectPositionTable)
		)
		AND (
			(SELECT COUNT(*) FROM @CurrentPositionTable) = 0 
			OR [C].[Current_Position] IN (SELECT ID FROM @CurrentPositionTable)
			OR [C].[Current_Position_By_Com] IN (SELECT ID FROM @CurrentPositionTable)
		)
		AND (
			(SELECT COUNT(*) FROM @CandidateTable) = 0 
			OR [C].[Candidate_ID] IN (SELECT ID FROM @CandidateTable)
		)
		AND (
			(SELECT COUNT(*) FROM @RecruiterTable) = 0 
			OR [LUC].[Recruiter_ID] IN (SELECT ID FROM @RecruiterTable)
		)
		AND [P].[Full_Name] IS NOT NULL
		AND [P].[Full_Name] <> ''
	GROUP BY 
		[PU].[Full_Name],
		[LUC].[Recruiter_ID],
		[P].[Full_Name],
		[P].[Person_ID],
		[P].[Birth_Date],
		[PHONE].[Tel_Country_Code],
		[PHONE].[Tel_Number],
		[P].[Email],
		[POS].[Position_Name],
		[C].[Current_Position],
		[C].[Current_Position_By_Com],
		[LS].[Salary],
		[CS].[Candidate_Status]
	ORDER BY [P].[Full_Name];

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
			,'DB Candidate - sp_Get_Candidate_Recruiter_Report'
			,ERROR_MESSAGE()
			,999
			,GETDATE());
	SET @Status_Code = '999';
END CATCH

