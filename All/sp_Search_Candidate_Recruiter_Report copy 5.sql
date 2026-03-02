USE [Candidate]
GO
/****** Object:  StoredProcedure [dbo].[[sp_Get_Candidate_Contact_Report]]    Script Date: 12/29/2025 12:51:35 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- ProcedureName: [dbo].[[sp_Get_Candidate_Contact_Report]]
-- Function: Search candidates with recruiter information for reporting
-- Create date: 12/23/2025
-- Update date: 12/29/2025
-- Description: Optimized stored procedure using CTEs to search candidates
--              with recruiter assignment information and additional search fields
 -- [dbo].[sp_Get_Candidate_Contact_Report] @Company_ID= 3357
-- =============================================
ALTER PROCEDURE [dbo].[sp_Get_Candidate_Contact_Report]
	@Company_ID INT = 0,
	@DateFrom NVARCHAR(100) = NULL,
	@DateTo NVARCHAR(512) = NULL,
	@Country_ID_str NVARCHAR(512) = '',
	@City_ID_str NVARCHAR(512) = '',
	@Recruiter_ID_str NVARCHAR(512) = '',
	@Candidate_ID_str NVARCHAR(512) = '',
	@Position_DI_str NVARCHAR(512) = ''
	

AS
BEGIN
	SET NOCOUNT ON;
	
	BEGIN TRY
		DECLARE @Map_Skill_Type_System INT = 0,
			@Map_Skill_Type_Temp INT = 0,
			@Address_Type_ID INT = 0,
			@Address_Category_Type_ID INT = 0,
			@Everyone INT = 0,
			@Only_me INT = 0,
			@Show_data_expired INT = 0,
			@Pipeline INT = 0;

	-- Get Pipeline ID for 'Candidates'
	SET @Pipeline = (SELECT TOP(1) [P].[Pipeline_ID]
						FROM [Pipeline].[dbo].[Pipeline] P
						WHERE [P].[Pipeline_Name] = 'Candidates'
						AND [P].[Is_Active] = 1
						AND [P].[Is_Delete] = 0);

	IF @Pipeline IS NULL
		SET @Pipeline = 0;

	-- Get Map Skill Type IDs
	SET @Map_Skill_Type_System = (SELECT TOP 1 [Map_Skill_Type_ID]
									FROM [Skill].[dbo].[Map_Skill_Type]
									WHERE [Map_Skill_Type_Name] = 'System');
	IF @Map_Skill_Type_System IS NULL SET @Map_Skill_Type_System = 0;

	SET @Map_Skill_Type_Temp = (SELECT TOP 1 [Map_Skill_Type_ID]
								FROM [Skill].[dbo].[Map_Skill_Type]
								WHERE [Map_Skill_Type_Name] = 'Company');
	IF @Map_Skill_Type_Temp IS NULL SET @Map_Skill_Type_Temp = 0;

	-- Get Address Type IDs
	SET @Address_Type_ID = (SELECT TOP 1 [Address_Type_ID]
							FROM [Address].[dbo].[Address_Type]
							WHERE [Address_Type_Name] = 'Register');
	IF @Address_Type_ID IS NULL SET @Address_Type_ID = 0;

	SET @Address_Category_Type_ID = (SELECT TOP 1 [Category_Type_ID]
										FROM [Address].[dbo].[Address_Category_Type]
										WHERE [Category_Type_Name] = 'Person');
	IF @Address_Category_Type_ID IS NULL SET @Address_Category_Type_ID = 0;

	-- Get Show Data IDs
	SET @Everyone = (SELECT TOP 1 [Show_Data_ID]
					FROM [dbo].[Show_Data] SD
					WHERE [Show_Data_Name] = 'Everyone'
					AND [Is_Active] = 1);
	IF @Everyone IS NULL SET @Everyone = 0;

	SET @Only_me = (SELECT TOP 1 [Show_Data_ID]
					FROM [dbo].[Show_Data] SD
					WHERE [Show_Data_Name] = 'Only me'
					AND [Is_Active] = 1);
	IF @Only_me IS NULL SET @Only_me = 0;

	SET @Show_data_expired = (SELECT TOP 1 [Show_Data_ID]
							  FROM [dbo].[Show_Data] SD
							  WHERE [Show_Data_Name] = 'Expired'
							  AND [Is_Active] = 1);
	IF @Show_data_expired IS NULL SET @Show_data_expired = 0;

	-- Parse comma-separated values into table variables
	DECLARE @CurrentPositionTable TABLE (ID INT);
	DECLARE @CurrentPositionByComTable TABLE (ID INT);
	DECLARE @LookingPositionTable TABLE (ID INT);
	DECLARE @LookingPositionByComTable TABLE (ID INT);
	DECLARE @SkillByCompanyTable TABLE (ID INT);
	DECLARE @MapSkillTable TABLE (ID INT);
	DECLARE @CountryTable TABLE (ID INT);
	DECLARE @CityTable TABLE (ID INT);
	DECLARE @RecruiterTable TABLE (ID INT);
	DECLARE @CandidateTable TABLE (ID INT);
	DECLARE @PositionTable TABLE (ID INT);

	-- Parse comma-separated Country IDs
	IF @Country_ID_str IS NOT NULL AND LEN(LTRIM(RTRIM(@Country_ID_str))) > 0
	BEGIN
		INSERT INTO @CountryTable (ID)
		SELECT TRY_CAST(value AS INT)
		FROM STRING_SPLIT(@Country_ID_str, ',')
		WHERE LEN(LTRIM(RTRIM(value))) > 0
			AND TRY_CAST(value AS INT) IS NOT NULL;
	END

	-- Parse comma-separated City IDs
	IF @City_ID_str IS NOT NULL AND LEN(LTRIM(RTRIM(@City_ID_str))) > 0
	BEGIN
		INSERT INTO @CityTable (ID)
		SELECT TRY_CAST(value AS INT)
		FROM STRING_SPLIT(@City_ID_str, ',')
		WHERE LEN(LTRIM(RTRIM(value))) > 0
			AND TRY_CAST(value AS INT) IS NOT NULL;
	END

	-- Parse comma-separated Recruiter IDs
	IF @Recruiter_ID_str IS NOT NULL AND LEN(LTRIM(RTRIM(@Recruiter_ID_str))) > 0
	BEGIN
		INSERT INTO @RecruiterTable (ID)
		SELECT TRY_CAST(value AS INT)
		FROM STRING_SPLIT(@Recruiter_ID_str, ',')
		WHERE LEN(LTRIM(RTRIM(value))) > 0
			AND TRY_CAST(value AS INT) IS NOT NULL;
	END

	-- Parse comma-separated Candidate IDs
	IF @Candidate_ID_str IS NOT NULL AND LEN(LTRIM(RTRIM(@Candidate_ID_str))) > 0
	BEGIN
		INSERT INTO @CandidateTable (ID)
		SELECT TRY_CAST(value AS INT)
		FROM STRING_SPLIT(@Candidate_ID_str, ',')
		WHERE LEN(LTRIM(RTRIM(value))) > 0
			AND TRY_CAST(value AS INT) IS NOT NULL;
	END

	-- Parse comma-separated Position IDs
	IF @Position_DI_str IS NOT NULL AND LEN(LTRIM(RTRIM(@Position_DI_str))) > 0
	BEGIN
		INSERT INTO @PositionTable (ID)
		SELECT TRY_CAST(value AS INT)
		FROM STRING_SPLIT(@Position_DI_str, ',')
		WHERE LEN(LTRIM(RTRIM(value))) > 0
			AND TRY_CAST(value AS INT) IS NOT NULL;
	END

	-- CTEs for common data
	WITH CTE_Position AS (
		SELECT [P].[Position_ID], [P].[Position_Name], 2 AS [Position_By_Com_Type_ID]  
		FROM [RMS_Position].[dbo].[Position] P
		UNION
		SELECT [PT].[Position_Temp_ID] AS [Position_ID], [PT].[Position_Name], 1 AS [Position_By_Com_Type_ID] 
		FROM [RMS_Position].[DBO].[Position_Temp] PT
	),Config_CTE AS (
		SELECT 
			ISNULL((SELECT TOP(1) [P].[Pipeline_ID]
					FROM [Pipeline].[dbo].[Pipeline] P
					WHERE [P].[Pipeline_Name] = 'Candidates'
					AND [P].[Is_Active] = 1
					AND [P].[Is_Delete] = 0), 0) AS [Pipeline],
			ISNULL((SELECT TOP 1 [Map_Skill_Type_ID]
					FROM [Skill].[dbo].[Map_Skill_Type]
					WHERE [Map_Skill_Type_Name] = 'System'), 0) AS [Map_Skill_Type_System],
			ISNULL((SELECT TOP 1 [Map_Skill_Type_ID]
					FROM [Skill].[dbo].[Map_Skill_Type]
					WHERE [Map_Skill_Type_Name] = 'Company'), 0) AS [Map_Skill_Type_Temp],
			ISNULL((SELECT TOP 1 [Address_Type_ID]
					FROM [Address].[dbo].[Address_Type]
					WHERE [Address_Type_Name] = 'Register'), 0) AS [Address_Type_ID],
			ISNULL((SELECT TOP 1 [Category_Type_ID]
					FROM [Address].[dbo].[Address_Category_Type]
					WHERE [Category_Type_Name] = 'Person'), 0) AS [Address_Category_Type_ID],
			ISNULL((SELECT TOP 1 [Show_Data_ID]
					FROM [dbo].[Show_Data] SD
					WHERE [Show_Data_Name] = 'Everyone'
					AND [Is_Active] = 1), 0) AS [Everyone],
			ISNULL((SELECT TOP 1 [Show_Data_ID]
					FROM [dbo].[Show_Data] SD
					WHERE [Show_Data_Name] = 'Only me'
					AND [Is_Active] = 1), 0) AS [Only_me],
			ISNULL((SELECT TOP 1 [Show_Data_ID]
					FROM [dbo].[Show_Data] SD
					WHERE [Show_Data_Name] = 'Expired'
					AND [Is_Active] = 1), 0) AS [Show_data_expired]
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
			WHERE [ss].[Is_Employee] = 0
			AND [ss].[Is_Terminate] = 0
			GROUP BY [ss].[Candidate_ID]
		) groupedtt ON tt.[Candidate_ID] = groupedtt.[Candidate_ID] 
			AND tt.[Update_Date] = groupedtt.MaxDateTime
			AND [tt].[Is_Employee] = 0
			AND [tt].[Is_Terminate] = 0
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
	),
	Company_Hierarchy_CTE AS (
		SELECT [COM].[Company_ID]
		FROM [Company].[DBO].[Company] COM
		WHERE [COM].[Company_Parent_ID] = @Company_ID

		UNION

		SELECT [COM].[Company_ID]
		FROM [Company].[DBO].[Company] COM
		WHERE [COM].[Company_ID] IN (
			SELECT [COM].[Company_Parent_ID]
			FROM [Company].[DBO].[Company] COM
			WHERE [COM].[Company_ID] = @Company_ID
		)

		UNION
		
		SELECT [COM].[Company_ID]
		FROM [Company].[DBO].[Company] COM
		WHERE [COM].[Company_Parent_ID] IN (
			SELECT [COM].[Company_ID]
			FROM [Company].[DBO].[Company] COM
			WHERE [COM].[Company_ID] IN (
				SELECT [COM].[Company_Parent_ID]
				FROM [Company].[DBO].[Company] COM
				WHERE [COM].[Company_ID] = @Company_ID
			)
		)

		UNION
		
		SELECT [COM].[Company_ID]
		FROM [Company].[DBO].[Company] COM
		WHERE [COM].[Company_ID] = @Company_ID
	),
	-- Main candidate data with UNION for Show_Data_ID filtering (matching sp_Search_Candidate exactly)
	CTE_CandidateBase AS (
		SELECT  [CAN].[Candidate_ID]
				,[C].[Company_ID]
				,[CAN].[Person_ID]
				,[CAN].[Current_Position]  
				,[Current_Position_By_Com] = CASE WHEN [CAN].[Current_Position_By_Com] IS NULL THEN 0 ELSE  [CAN].[Current_Position_By_Com] END
				,[CAN].[Min_Exp_Salary]
				,[CAN].[Max_Exp_Salary] 
				,[CAN].[Is_Employee]
				,[CAN].[Is_Deleted]
				,[CAN].[Updated_Date]
				,[CAN].[Created_Date]
				,[CAN].[Show_Data_ID]
				,[SD].[Show_Data_Name]
				,[CAN].[Created_By]
				,[CAN].[Updated_By]
		FROM [Candidate].[dbo].[Map_Candidadte_Company] C
		LEFT JOIN [Candidate].[dbo].[Candidate] CAN ON [CAN].[Candidate_ID] = [C].[Candidate_ID]
		LEFT JOIN [Candidate].[dbo].[Show_Data] SD ON [SD].[Show_Data_ID] = [C].[Show_Data_ID]
		CROSS JOIN Config_CTE CFG
		WHERE [C].[Show_Data_ID] = CFG.[Only_me]
		AND [SD].[Is_Active] = 1
		AND [C].[Is_Employee] = 0
		AND [CAN].[Is_Deleted] = 0
		AND [C].[Company_ID] = @Company_ID

		UNION

		SELECT	 [CAN].[Candidate_ID]
													,[C].[Company_ID]
													,[CAN].[Person_ID]
													,[CAN].[Current_Position]  
													,[Current_Position_By_Com] = CASE WHEN [CAN].[Current_Position_By_Com] IS NULL
																						THEN 0
																					ELSE 
																							[CAN].[Current_Position_By_Com]
																					END
													,[CAN].[Min_Exp_Salary]
													,[CAN].[Max_Exp_Salary] 
													,[C].[Is_Employee]
													,[CAN].[Is_Deleted]
													,[CAN].[Updated_Date]
													,[CAN].[Created_Date]
													,[C].[Show_Data_ID]
													,[SD].[Show_Data_Name]
													,[CAN].[Created_By]
													,[CAN].[Updated_By]
		FROM [Candidate].[dbo].[Map_Candidadte_Company] C
		LEFT JOIN [Candidate].[dbo].[Candidate] CAN ON [CAN].[Candidate_ID] = [C].[Candidate_ID]
		LEFT JOIN [Candidate].[dbo].[Show_Data] SD ON [SD].[Show_Data_ID] = [C].[Show_Data_ID]
		CROSS JOIN Config_CTE CFG
		WHERE [C].[Show_Data_ID] = CFG.[Only_me]
		AND [SD].[Is_Active] = 1
		AND [C].[Is_Employee] = 0
		AND [CAN].[Is_Deleted] = 0
		AND [C].[Company_ID] = @Company_ID

		UNION

		SELECT	 [CAN].[Candidate_ID]
													,[C].[Company_ID]
													,[CAN].[Person_ID]
													,[CAN].[Current_Position]  
													,[Current_Position_By_Com] = CASE WHEN [CAN].[Current_Position_By_Com] IS NULL
																						THEN 0
																					ELSE 
																						[CAN].[Current_Position_By_Com]
																					END
													,[CAN].[Min_Exp_Salary]
													,[CAN].[Max_Exp_Salary] 
													,[C].[Is_Employee]
													,[CAN].[Is_Deleted]
													,[CAN].[Updated_Date]
													,[CAN].[Created_Date]
													,[C].[Show_Data_ID]
													,[SD].[Show_Data_Name]
													,[CAN].[Created_By]
													,[CAN].[Updated_By]
		FROM [Candidate].[dbo].[Map_Candidadte_Company] C
		LEFT JOIN [Candidate].[dbo].[Candidate] CAN ON [CAN].[Candidate_ID] = [C].[Candidate_ID]
		LEFT JOIN [Candidate].[dbo].[Show_Data] SD ON [SD].[Show_Data_ID] = [C].[Show_Data_ID]
		CROSS JOIN Config_CTE CFG
		WHERE [C].[Show_Data_ID] = CFG.[Show_data_expired]
		AND [C].[Is_Employee] = 0
		AND [CAN].[Is_Deleted] = 0
		AND [C].[Company_ID] = @Company_ID

		UNION

		SELECT	 [CAN].[Candidate_ID]
													,[C].[Company_ID]
													,[CAN].[Person_ID]
													,[CAN].[Current_Position]  
													,[Current_Position_By_Com] = CASE WHEN [CAN].[Current_Position_By_Com] IS NULL
																						THEN 0
																					ELSE 
																							[CAN].[Current_Position_By_Com]
																					END
													,[CAN].[Min_Exp_Salary]
													,[CAN].[Max_Exp_Salary] 
													,[C].[Is_Employee]
													,[CAN].[Is_Deleted]
													,[CAN].[Updated_Date]
													,[CAN].[Created_Date]
													,[C].[Show_Data_ID]
													,[SD].[Show_Data_Name]
													,[CAN].[Created_By]
													,[CAN].[Updated_By]
		FROM [Candidate].[dbo].[Map_Candidadte_Company] C
		LEFT JOIN [Candidate].[dbo].[Candidate] CAN ON [CAN].[Candidate_ID] = [C].[Candidate_ID]
		LEFT JOIN [Candidate].[dbo].[Show_Data] SD ON [SD].[Show_Data_ID] = [C].[Show_Data_ID]
		CROSS JOIN Config_CTE CFG
		WHERE [C].[Show_Data_ID] = CFG.[Everyone]
		AND [C].[Is_Employee] = 0
		AND [CAN].[Is_Deleted] = 0
		AND [SD].[Is_Active] = 1
		AND [C].[Company_ID] IN (SELECT [Company_ID] FROM Company_Hierarchy_CTE)
	),
	Person_CTE AS (
		SELECT  [PER].[Person_ID]
				,[PER].[First_Name]
				,[PER].[Middle_Name]
				,[PER].[Last_Name]
				,[PER].[Full_Name]
				,[PER].[Gender_ID]
				,[PER].[Email]
				,[PER].[Birth_Date]
				,[Gender_Name] = (SELECT [G].[Gender_Name] FROM [Gender].[DBO].[Gender] G WHERE [G].[Gender_ID] = [PER].[Gender_ID])
				,[AD].[Country_ID]
				,[Country_Name] = (SELECT [C].[Country_Name] FROM [Country].[DBO].[Country] C WHERE [C].[Country_ID] = [AD].[Country_ID])
				,[AD].[City_ID]
				,[City_Name] = (SELECT [CI].[City_Name] FROM [Country].[DBO].[City] CI WHERE [CI].[City_ID] = [AD].[City_ID])
		FROM [PERSON].[DBO].[Person] PER  
		LEFT JOIN [Address].[DBO].[Address] AD ON [AD].[Reference_ID] = [PER].[Person_ID] 
			AND [AD].[Address_Type_ID] = (SELECT [Address_Type_ID] FROM Config_CTE)
			AND [AD].[Category_Type_ID] = (SELECT [Address_Category_Type_ID] FROM Config_CTE)
	),
	Log_Update_Candidate_CTE AS (
		SELECT [tt].[Update_By] AS [Recruiter_ID]
				,[tt].[Update_Date]
				,[tt].[Candidate_ID]
		FROM [Candidate].[dbo].[Log_Update_Candidate] tt
		INNER JOIN (
			SELECT [ss].[Candidate_ID]
					,MAX([ss].[Update_Date]) AS MaxDateTime
			FROM [Candidate].[dbo].[Log_Update_Candidate] ss
			WHERE [ss].[Is_Employee] = 0
			AND [ss].[Is_Terminate] = 0
			GROUP BY [ss].[Candidate_ID]
		) groupedtt ON tt.[Candidate_ID] = groupedtt.[Candidate_ID] 
			AND tt.[Update_Date] = groupedtt.MaxDateTime 
			AND [tt].[Is_Employee] = 0 
			AND [tt].[Is_Terminate] = 0
		GROUP BY [tt].[Update_By], [tt].[Update_Date], [tt].[Candidate_ID]
	),
	Recruiter_Person_CTE AS (
		SELECT  [PER].[Person_ID]
				,[PER].[First_Name]
				,[PER].[Middle_Name]
				,[PER].[Last_Name]
				,[PER].[Full_Name] 
		FROM [PERSON].[DBO].[Person] PER  
	),
	CurrentPosition_Resolved_CTE AS (
		SELECT [CAN].[Candidate_ID]
				,[CAN].[Current_Position]
				,[CAN].[Current_Position_By_Com]
				,[Resolved_Position_ID] = CASE WHEN [CAN].[Current_Position_By_Com] = 0 OR [CAN].[Current_Position_By_Com] IS NULL  
					THEN [CAN].[Current_Position]
					ELSE (
						SELECT [Position_ID_OF_Com] = (
							CASE WHEN [PB].[Position_By_Com_Type_ID] = 1 
							THEN (
								SELECT [PT].[Position_Temp_ID]
								FROM [RMS_Position].[dbo].[Position_Temp] PT
								WHERE [PT].[Position_Temp_ID] = [PB].[Position_ID]
							)
							ELSE [PB].[Position_ID] END
						)
						FROM [RMS_Position].[dbo].[Position_By_Comp] PB 
						WHERE [PB].[Position_By_Com_ID] = [CAN].[Current_Position_By_Com]
					)
				END
				,[Resolved_Position_Type_ID] = CASE WHEN [CAN].[Current_Position_By_Com] = 0 OR [CAN].[Current_Position_By_Com] IS NULL  
					THEN 2
					ELSE (
						SELECT [PB].[Position_By_Com_Type_ID]
						FROM [RMS_Position].[dbo].[Position_By_Comp] PB 
						WHERE [PB].[Position_By_Com_ID] = [CAN].[Current_Position_By_Com]
					)
				END
		FROM CTE_CandidateBase CAN
	),
	CurrentPosition_CTE AS (
		SELECT [CPR].[Candidate_ID]
				,[CPR].[Current_Position]
				,[CPR].[Current_Position_By_Com]
				,[POS].[Position_ID]
				,[POS].[Position_Name]
				,[POS].[Position_By_Com_Type_ID]
		FROM CurrentPosition_Resolved_CTE CPR
		LEFT JOIN CTE_Position POS ON [POS].[Position_ID] = [CPR].[Resolved_Position_ID]
			AND [POS].[Position_By_Com_Type_ID] = [CPR].[Resolved_Position_Type_ID]
	),
	LookingPosition_CTE AS (
		SELECT [MPO].[Candidate_ID] 
				,[MPO].[Position_ID]
				,[MPO].[Position_By_Com_ID]
				,[POS].[Position_Name] 
		FROM [Candidate].[DBO].[Map_Looking_For_Position] MPO 
		LEFT JOIN CTE_Position POS ON [POS].[Position_ID] = (
			CASE WHEN [MPO].[Position_By_Com_ID] = 0 OR [MPO].[Position_By_Com_ID] IS NULL  
			THEN [MPO].[Position_ID]
			ELSE (
				SELECT [Position_ID_OF_Com] = (
					CASE WHEN [PB].[Position_By_Com_Type_ID] = 1 
					THEN (
						SELECT [PT].[Position_Temp_ID]
						FROM [RMS_Position].[dbo].[Position_Temp] PT
						WHERE [PT].[Position_Temp_ID] = [PB].[Position_ID]
					)
					ELSE [PB].[Position_ID] END
				)
				FROM [RMS_Position].[dbo].[Position_By_Comp] PB 
				WHERE [PB].[Position_By_Com_ID] = [MPO].[Position_By_Com_ID]
			)
			END
		)
		AND [POS].[Position_By_Com_Type_ID] = (
			CASE WHEN [MPO].[Position_By_Com_ID] = 0 OR [MPO].[Position_By_Com_ID] IS NULL  
			THEN 2
			ELSE (
				SELECT [PB].[Position_By_Com_Type_ID]
				FROM [RMS_Position].[dbo].[Position_By_Comp] PB 
				WHERE [PB].[Position_By_Com_ID] = [MPO].[Position_By_Com_ID]
			)
			END
		)	 
		GROUP BY [MPO].[Candidate_ID] 
				,[MPO].[Position_ID]
				,[MPO].[Position_By_Com_ID]
				,[POS].[Position_Name] 
	),
	Skill_Group_CTE AS (
		SELECT [SG].[Skill_Group_ID]
				,[Skill_Group_Name] = CASE WHEN [SG].[Parent_Skill_Group_ID] = 0 OR [SG].[Parent_Skill_Group_ID] IS NULL  
					THEN [SG].[Skill_Group_Name]
					ELSE (
						SELECT TOP 1 [Skill].[dbo].[Skill_Group].[Skill_Group_Name] 
						FROM [Skill].[dbo].[Skill_Group] 
						WHERE [Skill].[dbo].[Skill_Group].[Skill_Group_ID] = [SG].[Parent_Skill_Group_ID]
					)
				END
				,[Sub_Skill_Group_Name] = CASE WHEN [SG].[Parent_Skill_Group_ID] = 0 OR [SG].[Parent_Skill_Group_ID] IS NULL 
					THEN NULL
					ELSE [SG].[Skill_Group_Name] 
				END 
		FROM [Skill].[dbo].[Skill_Group] SG
	),
	MapSkill_System_CTE AS (
		SELECT [MSKILL].[Map_Skill_ID]
				,[MSKILL].[Skill_Group_ID]
				,[MSKILL].[Skill_ID]
				,[Skill].[dbo].[Skill].[Skill_Name]
				,[SGS].[Skill_Group_Name]
				,[SGS].[Sub_Skill_Group_Name]
				,(SELECT [Map_Skill_Type_System] FROM Config_CTE) AS [SKILL_TYPE]
		FROM [Skill].[dbo].[Map_Skill] MSKILL
		LEFT JOIN Skill_Group_CTE SGS ON [MSKILL].[Skill_Group_ID] = [SGS].[Skill_Group_ID]
		LEFT JOIN [Skill].[dbo].[Skill] ON [MSKILL].[Skill_ID] = [Skill].[dbo].[Skill].[Skill_ID]
		WHERE [MSKILL].[Skill_Group_ID] IS NOT NULL
	),
	MapSkill_Temp_CTE AS (
		SELECT [MSKILLT].[Map_Skill_Temp_ID] AS [Map_Skill_ID]
				,[MSKILLT].[Skill_Group_ID]
				,[MSKILLT].[Skill_Temp_ID] AS [Skill_ID]
				,[Skill].[dbo].[Skill_Temp].[Skill_Name]
				,[SGT].[Skill_Group_Name]
				,[SGT].[Sub_Skill_Group_Name]
				,(SELECT [Map_Skill_Type_Temp] FROM Config_CTE) AS [SKILL_TYPE] 
		FROM [Skill].[dbo].[Map_Skill_Temp] MSKILLT
		LEFT JOIN Skill_Group_CTE SGT ON [MSKILLT].[Skill_Group_ID] = [SGT].[Skill_Group_ID]
		LEFT JOIN [Skill].[dbo].[Skill_Temp] ON [MSKILLT].[Skill_Temp_ID] = [Skill].[dbo].[Skill_Temp].[Skill_Temp_ID]
	),
	MapSkill_Union_CTE AS (
		SELECT * FROM MapSkill_System_CTE
		UNION
		SELECT * FROM MapSkill_Temp_CTE
	),
	Skill_ByCompany_CTE AS (
		SELECT [sbc].[Company_ID]
				,[sbc].[Skill_By_Com_ID]
				,[sbc].[Map_Skill_ID] 
				,[SKU].[Skill_Group_Name]
				,[SKU].[Skill_Name]
				,[SKU].[Sub_Skill_Group_Name]
				,[SKU].[Skill_ID]
				,[SKU].[Skill_Group_ID]
		FROM [SKILL].[DBO].[Skill_By_Company] SBC
		LEFT JOIN MapSkill_Union_CTE SKU ON [SKU].[Map_Skill_ID] = [SBC].[Map_Skill_ID] 
			AND [SKU].[SKILL_TYPE] = [SBC].[Map_Skill_Type_ID] 
		WHERE [sbc].[Company_ID] IN (SELECT [Company_ID] FROM Company_Hierarchy_CTE)
	),
	Skill_Candidate_CTE AS (
		SELECT [SKC].[Candidate_ID]
				,[SK].[Map_Skill_ID] AS [Map_Skill_ID] 
				,[SKC].[Skill_By_Comp_ID]
				,[SK].[Skill_Group_ID]
				,[SK].[Skill_ID]
				,[SK].[Skill_Name]
				,[SK].[Skill_Group_Name] 
				,[SK].[Sub_Skill_Group_Name] 
		FROM [Skill].[dbo].[Skill_Candidate] SKC
		LEFT JOIN Skill_ByCompany_CTE SK ON [SK].[Skill_By_Com_ID] = [SKC].[Skill_By_Comp_ID]
		WHERE [SKC].[Map_Skill_ID] = 0
		AND [SKC].[Is_Deleted] = 0
	),
	Pipeline_LastCreate_CTE AS (
		SELECT [M].[Candidate_ID]
				,[M].[Company_ID]
				,MAX([M].[Created_Date]) AS [Last_Create]
		FROM [Pipeline].[dbo].[Map_Can_Pile_Com] M
		CROSS JOIN Config_CTE CFG
		WHERE [M].[Pipeline_ID] = CFG.[Pipeline]
		GROUP BY [M].[Candidate_ID], [M].[Company_ID]

		UNION

		SELECT [LUC].[Candidate_ID]
				,[CAN2].[Company_ID]
				,[LUC].[Last_Create]
		FROM (
			SELECT [tt].[Candidate_ID]
					,[tt].[Update_Date] AS [Last_Create]
			FROM [Candidate].[dbo].[Log_Update_Candidate] tt
			INNER JOIN (
				SELECT [ss].[Candidate_ID], MAX([ss].[Update_Date]) AS MaxDateTime
				FROM [Candidate].[dbo].[Log_Update_Candidate] ss
				GROUP BY [ss].[Candidate_ID]
			) groupedtt 
			ON tt.[Candidate_ID] = groupedtt.[Candidate_ID] 
			AND tt.[Update_Date] = groupedtt.MaxDateTime
			AND [tt].[Is_Employee] = 0
			AND [tt].[Is_Terminate] = 0
			GROUP BY [tt].[Update_By], [tt].[Update_Date], [tt].[Candidate_ID]
		) LUC
		LEFT JOIN [Candidate].[dbo].[Candidate] CAN2 ON [CAN2].[Candidate_ID] = [LUC].[Candidate_ID]
		WHERE [CAN2].[Candidate_ID] IS NOT NULL
	),
	Pipeline_MaxCreate_CTE AS (
		SELECT [Candidate_ID]
				,MAX([Last_Create]) AS [Last_Create]
		FROM Pipeline_LastCreate_CTE
		GROUP BY [Candidate_ID]
	),
	ExpireDate_CTE AS (
		SELECT [CAN].[Candidate_ID]
				,[PIPE].[Company_ID]
				,DATEADD(DAY, [CONFIG].[Number_of_Days], [PIPE].[Last_Create]) AS [Exprie_Date]
		FROM [Candidate].[dbo].[Candidate] CAN
		LEFT JOIN Pipeline_MaxCreate_CTE PMAX ON [PMAX].[Candidate_ID] = [CAN].[Candidate_ID]
		LEFT JOIN [Candidate].[dbo].[Candidate] C ON [C].[Candidate_ID] = [PMAX].[Candidate_ID]
		LEFT JOIN Pipeline_LastCreate_CTE PIPE ON [PIPE].[Candidate_ID] = [CAN].[Candidate_ID] 
			AND [PIPE].[Last_Create] = [PMAX].[Last_Create]
		LEFT JOIN [Candidate].[dbo].[Expire_Candidate] CONFIG ON [CONFIG].[Company_ID] = [C].[Company_ID]
		WHERE [CAN].[Is_Deleted] = 0
		AND [CAN].[Is_Employee] = 0
	)
	
	SELECT 
		[Recruiter_Name] = [PU].[Full_Name],
		[Recruiter_ID] = [LUC].[Recruiter_ID],
		[Candidate_Name] = [PA].[Full_Name],
		[Candidate_ID] = [CAN].[Person_ID],
		[Candidate_Age] = CASE 
			WHEN [PA].[Birth_Date] IS NOT NULL 
			THEN DATEDIFF(YEAR, [PA].[Birth_Date], GETDATE()) - 
				 CASE 
					 WHEN DATEADD(YEAR, DATEDIFF(YEAR, [PA].[Birth_Date], GETDATE()), [PA].[Birth_Date]) > GETDATE() 
					 THEN 1 
					 ELSE 0 
				 END
			ELSE NULL
		END,

		[PHONE].[Tel_Country_Code],
		[PHONE].[Tel_Number],
		
		[Email] = ISNULL([PA].[Email], '-'),
		[Last_Position_Name] = [CPOS].[Position_Name],
		[ID_Position] = CASE 
			WHEN [CAN].[Current_Position_By_Com] = 0 OR [CAN].[Current_Position_By_Com] IS NULL  
			THEN [CAN].[Current_Position]
			ELSE [CAN].[Current_Position_By_Com]
		END,
		[Last_Salary] = CASE 
			WHEN [LS].[Salary] IS NOT NULL 
			THEN CAST([LS].[Salary] AS NVARCHAR(50))
			ELSE '-'
		END,
		[Candidate_Status] = ISNULL([CS].[Candidate_Status], 'Candidate')
		-- Additional fields from sp_Search_Candidate
		--,[SEARCH_Candidate_ID] = [CAN].[Candidate_ID],
		--[SEARCH_Full_Name] = [PA].[Full_Name],
		--[SEARCH_Current_Position_Name] = [CPOS].[Position_Name],
		--[SEARCH_Updated_Date] = CASE WHEN [LUC].[Update_Date] IS NULL 
		--							THEN '-'
		--						ELSE 
		--							FORMAT([LUC].[Update_Date], 'dd MMM yyyy') 
		--						END,
		--[SEARCH_Gender_Name] = CASE WHEN [PA].[Gender_Name] IS NULL THEN '-' ELSE [PA].[Gender_Name] END,
		--[SEARCH_Min_Exp_Salary] = [CAN].[Min_Exp_Salary],
		--[SEARCH_Max_Exp_Salary] = [CAN].[Max_Exp_Salary],
		--[SEARCH_Country_Name] = CASE WHEN [PA].[Country_Name] IS NULL THEN '-' ELSE [PA].[Country_Name] END,
		--[SEARCH_City_Name] = CASE WHEN [PA].[City_Name] IS NULL THEN '-' ELSE [PA].[City_Name] END
		--,[SEARCH_Person_ID] = [CAN].[Person_ID],xx
		--[SEARCH_Owner_ID] = [LUC].[Recruiter_ID],xx
		--[SEARCH_Updated_By] = [PU].[Full_Name],xx
		--,[SEARCH_Company_Name] = [COMP].[Company_Name]
		--,[SEARCH_Company_ID] = [CAN].[Company_ID]
		--,[SEARCH_Exprie_Date] = [MCP].[Exprie_Date]
		--,[SEARCH_Exprie_Date_STR] = CASE WHEN [MCP].[Exprie_Date] IS NULL 
		--								THEN '-'
		--							ELSE 
		--								FORMAT([MCP].[Exprie_Date], 'dd MMM yyyy') 
		--							END
		,[CAN].[Show_Data_ID]
		,[CAN].[Show_Data_Name]
	FROM CTE_CandidateBase CAN
	LEFT JOIN [Company].[DBO].[Company] COMP ON [COMP].[Company_ID] = [CAN].[Company_ID]
	--LEFT JOIN ExpireDate_CTE MCP ON [MCP].[Candidate_ID] = [CAN].[Candidate_ID] AND [MCP].[Company_ID] = [CAN].[Company_ID]
	LEFT JOIN Person_CTE PA ON [PA].[Person_ID] = [CAN].[Person_ID]
	LEFT JOIN CTE_Phone PHONE ON [PHONE].[Reference_ID] = [PA].[Person_ID]
	LEFT JOIN Log_Update_Candidate_CTE LUC ON [LUC].[Candidate_ID] = [CAN].[Candidate_ID] AND [CAN].[Is_Deleted] = 0
	LEFT JOIN Recruiter_Person_CTE PU ON [PU].[Person_ID] = [LUC].[Recruiter_ID]
	LEFT JOIN CurrentPosition_CTE CPOS ON [CPOS].[Candidate_ID] = [CAN].[Candidate_ID]
	LEFT JOIN CTE_LastSalary LS ON [LS].[Candidate_ID] = [CAN].[Candidate_ID] AND [LS].[RowNum] = 1
	LEFT JOIN CTE_CandidateStatus CS ON [CS].[Candidate_ID] = [CAN].[Candidate_ID]
	LEFT JOIN LookingPosition_CTE MPOP ON [MPOP].[Candidate_ID] = [CAN].[Candidate_ID]
	WHERE [CAN].[Is_Employee] = 0 
	AND [CAN].[Is_Deleted] = 0
	-- Filter by Position (Current Position)
	AND (
		NOT EXISTS (SELECT 1 FROM @PositionTable)
		OR [CAN].[Current_Position] IN (SELECT ID FROM @PositionTable)
		OR [CAN].[Current_Position_By_Com] IN (SELECT ID FROM @PositionTable)
	)
	-- Filter by Candidate IDs
	AND (
		NOT EXISTS (SELECT 1 FROM @CandidateTable)
		OR [CAN].[Candidate_ID] IN (SELECT ID FROM @CandidateTable)
		OR [CAN].[Person_ID] IN (SELECT ID FROM @CandidateTable)
	)
	-- Filter by Country IDs
	AND (
		NOT EXISTS (SELECT 1 FROM @CountryTable)
		OR [PA].[Country_ID] IN (SELECT ID FROM @CountryTable)
	)
	-- Filter by City IDs
	AND (
		NOT EXISTS (SELECT 1 FROM @CityTable)
		OR [PA].[City_ID] IN (SELECT ID FROM @CityTable)
	)
	-- Filter by Recruiter IDs
	AND (
		NOT EXISTS (SELECT 1 FROM @RecruiterTable)
		OR [LUC].[Recruiter_ID] IN (SELECT ID FROM @RecruiterTable)
	)
	-- Filter by Date Range (Update Date or Created Date as fallback)
	AND (
		@DateFrom IS NULL OR @DateFrom = '' 
		OR CAST(COALESCE([LUC].[Update_Date], [CAN].[Created_Date]) AS DATE) >= TRY_CAST(@DateFrom AS DATE)
	)
	AND (
		@DateTo IS NULL OR @DateTo = ''
		OR CAST(COALESCE([LUC].[Update_Date], [CAN].[Created_Date]) AS DATE) <= TRY_CAST(@DateTo AS DATE)
	)
	
	GROUP BY 
		[PU].[Full_Name],
		[LUC].[Recruiter_ID],
		[PA].[Full_Name]
		,[CAN].[Person_ID]
		,[PA].[Birth_Date]
		,[PHONE].[Tel_Country_Code]
		,[PHONE].[Tel_Number],
		[PA].[Email],
		[CPOS].[Position_Name],
		[CAN].[Current_Position],
		[CAN].[Current_Position_By_Com],
		[LS].[Salary],
		[CS].[Candidate_Status]
		-- Additional fields from sp_Search_Candidate for GROUP BY
		--,[CAN].[Candidate_ID],
		--[LUC].[Update_Date],
		--[PA].[Gender_Name],
		--[CAN].[Min_Exp_Salary],
		--[CAN].[Max_Exp_Salary],
		--[PA].[Country_Name],
		--[PA].[City_Name]
		--,[COMP].[Company_Name],
		--[CAN].[Company_ID],
		--[MCP].[Exprie_Date]
		,[CAN].[Show_Data_ID]
		,[CAN].[Show_Data_Name]
	ORDER BY [PA].[Full_Name];
	-- [dbo].[sp_Search_Candidate_Recruiter_Report] @Company_ID= 3357

	END TRY
	BEGIN CATCH
		INSERT INTO [Log].[dbo].[Log]
			([Software_ID]
			,[Function_Name]
			,[Detail]
			,[Created By]
			,[Created Date])
		VALUES
			('1'
			,'DB Candidate - sp_Search_Candidate_Recruiter_Report'
			,ERROR_MESSAGE()
			,0
			,GETDATE());
		
		-- Re-throw the error
		THROW;
	END CATCH
END
