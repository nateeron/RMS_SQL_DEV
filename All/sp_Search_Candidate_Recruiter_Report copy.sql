USE [Candidate]
GO

	DECLARE @Full_Name NVARCHAR(512) = NULL,
	@Current_Position NVARCHAR(512) = NULL,
	@Current_Position_By_Com_ID NVARCHAR(512) = NULL,
	@Looking_Position NVARCHAR(512) = NULL,
	@Looking_Position_By_Com_ID NVARCHAR(512) = NULL,
	@Gender_ID INT = 0,
	@Min_Expected_Salary NVARCHAR(512) = NULL,
	@Max_Expected_Salary NVARCHAR(512) = NULL,
	@Skill_By_Company_ID NVARCHAR(512) = NULL, 
	@Map_Skill_ID NVARCHAR(512) = NULL,
	@Country_ID INT = 0,
	@City_ID INT = 0,
	@Company_ID INT = 3357,
	@User_ID INT = 0

	-- Declare variables for lookup values
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

	-- Parse Current_Position
	IF @Current_Position IS NOT NULL AND @Current_Position <> ''
	BEGIN
		INSERT INTO @CurrentPositionTable (ID)
		SELECT TRY_CAST(LTRIM(RTRIM(value)) AS INT)
		FROM STRING_SPLIT(@Current_Position, ',')
		WHERE LTRIM(RTRIM(value)) <> '' AND TRY_CAST(LTRIM(RTRIM(value)) AS INT) IS NOT NULL;
	END;

	-- Parse Current_Position_By_Com_ID
	IF @Current_Position_By_Com_ID IS NOT NULL AND @Current_Position_By_Com_ID <> ''
	BEGIN
		INSERT INTO @CurrentPositionByComTable (ID)
		SELECT TRY_CAST(LTRIM(RTRIM(value)) AS INT)
		FROM STRING_SPLIT(@Current_Position_By_Com_ID, ',')
		WHERE LTRIM(RTRIM(value)) <> '' AND TRY_CAST(LTRIM(RTRIM(value)) AS INT) IS NOT NULL;
	END;

	-- Parse Looking_Position
	IF @Looking_Position IS NOT NULL AND @Looking_Position <> ''
	BEGIN
		INSERT INTO @LookingPositionTable (ID)
		SELECT TRY_CAST(LTRIM(RTRIM(value)) AS INT)
		FROM STRING_SPLIT(@Looking_Position, ',')
		WHERE LTRIM(RTRIM(value)) <> '' AND TRY_CAST(LTRIM(RTRIM(value)) AS INT) IS NOT NULL;
	END;

	-- Parse Looking_Position_By_Com_ID
	IF @Looking_Position_By_Com_ID IS NOT NULL AND @Looking_Position_By_Com_ID <> ''
	BEGIN
		INSERT INTO @LookingPositionByComTable (ID)
		SELECT TRY_CAST(LTRIM(RTRIM(value)) AS INT)
		FROM STRING_SPLIT(@Looking_Position_By_Com_ID, ',')
		WHERE LTRIM(RTRIM(value)) <> '' AND TRY_CAST(LTRIM(RTRIM(value)) AS INT) IS NOT NULL;
	END;

	-- Parse Skill_By_Company_ID
	IF @Skill_By_Company_ID IS NOT NULL AND @Skill_By_Company_ID <> ''
	BEGIN
		INSERT INTO @SkillByCompanyTable (ID)
		SELECT TRY_CAST(LTRIM(RTRIM(value)) AS INT)
		FROM STRING_SPLIT(@Skill_By_Company_ID, ',')
		WHERE LTRIM(RTRIM(value)) <> '' AND TRY_CAST(LTRIM(RTRIM(value)) AS INT) IS NOT NULL;
	END;

	-- Parse Map_Skill_ID
	IF @Map_Skill_ID IS NOT NULL AND @Map_Skill_ID <> ''
	BEGIN
		INSERT INTO @MapSkillTable (ID)
		SELECT TRY_CAST(LTRIM(RTRIM(value)) AS INT)
		FROM STRING_SPLIT(@Map_Skill_ID, ',')
		WHERE LTRIM(RTRIM(value)) <> '' AND TRY_CAST(LTRIM(RTRIM(value)) AS INT) IS NOT NULL;
	END;

	-- CTEs for common data
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
	-- Main candidate data with UNION for Show_Data_ID filtering (matching sp_Search_Candidate exactly)
	CTE_CandidateBase AS (
		SELECT  [CAN].[Candidate_ID]
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
		WHERE [C].[Show_Data_ID] = @Only_me
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
		WHERE [C].[Show_Data_ID] = @Only_me
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
		WHERE [C].[Show_Data_ID] = @Show_data_expired
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
		WHERE [C].[Show_Data_ID] = @Everyone
		AND [C].[Is_Employee] = 0
		AND [CAN].[Is_Deleted] = 0
		AND [SD].[Is_Active] = 1
		AND [C].[Company_ID] IN (
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
		)
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
		[Phone_Number] = CASE 
			WHEN [PHONE].[Tel_Country_Code] IS NOT NULL AND [PHONE].[Tel_Number] IS NOT NULL
			THEN [PHONE].[Tel_Country_Code] + ' ' + [PHONE].[Tel_Number]
			WHEN [PHONE].[Tel_Number] IS NOT NULL
			THEN [PHONE].[Tel_Number]
			ELSE '-'
		END,
		[Email] = ISNULL([PA].[Email], '-'),
		[Last_Position_Name] = [POS].[Position_Name],
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
	FROM CTE_CandidateBase CAN
	LEFT JOIN (
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
			AND [AD].[Address_Type_ID] = @Address_Type_ID 
			AND [AD].[Category_Type_ID] = @Address_Category_Type_ID
	) PA ON [PA].[Person_ID] = [CAN].[Person_ID]
	LEFT JOIN CTE_Phone PHONE ON [PHONE].[Reference_ID] = [PA].[Person_ID]
	LEFT JOIN (
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
	) LUC ON [LUC].[Candidate_ID] = [CAN].[Candidate_ID] AND [CAN].[Is_Deleted] = 0
	LEFT JOIN (
		SELECT  [PER].[Person_ID]
				,[PER].[First_Name]
				,[PER].[Middle_Name]
				,[PER].[Last_Name]
				,[PER].[Full_Name] 
		FROM [PERSON].[DBO].[Person] PER  
	) PU ON [PU].[Person_ID] = [LUC].[Recruiter_ID]
	LEFT JOIN ( 
		SELECT [P].[Position_ID] 
				,[P].[Position_Name] 
				,2 AS [Position_By_Com_Type_ID]  
		FROM  [RMS_Position].[dbo].[Position] P  
		UNION
		SELECT [PT].[Position_Temp_ID] AS [Position_ID] 
				,[PT].[Position_Name] 
				,1 AS [Position_By_Com_Type_ID]
		FROM [RMS_Position].[DBO].[Position_Temp] PT
	) POS ON [POS].[Position_ID] = (
		CASE WHEN [CAN].[Current_Position_By_Com] = 0 OR [CAN].[Current_Position_By_Com] IS NULL  
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
	)
	AND [POS].[Position_By_Com_Type_ID] = (
		CASE WHEN [CAN].[Current_Position_By_Com] = 0 OR [CAN].[Current_Position_By_Com] IS NULL  
		THEN 2
		ELSE (
			SELECT [PB].[Position_By_Com_Type_ID]
			FROM [RMS_Position].[dbo].[Position_By_Comp] PB 
			WHERE [PB].[Position_By_Com_ID] = [CAN].[Current_Position_By_Com]
		)
		END
	)
	LEFT JOIN CTE_LastSalary LS ON [LS].[Candidate_ID] = [CAN].[Candidate_ID] AND [LS].[RowNum] = 1
	LEFT JOIN CTE_CandidateStatus CS ON [CS].[Candidate_ID] = [CAN].[Candidate_ID]
	LEFT JOIN ( 
		SELECT [MPO].[Candidate_ID], [MPO].[Position_ID], [MPO].[Position_By_Com_ID], [POS].[Position_Name] 
		FROM [Candidate].[DBO].[Map_Looking_For_Position] MPO 
		LEFT JOIN ( 
			SELECT [P].[Position_ID], [P].[Position_Name], 2 AS [Position_By_Com_Type_ID]  
			FROM  [RMS_Position].[dbo].[Position] P  
			UNION
			SELECT [PT].[Position_Temp_ID] AS [Position_ID], [PT].[Position_Name], 1 AS [Position_By_Com_Type_ID]
			FROM [RMS_Position].[DBO].[Position_Temp] PT
		) POS ON [POS].[Position_ID] = (
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
		GROUP BY [MPO].[Candidate_ID], [MPO].[Position_ID], [MPO].[Position_By_Com_ID], [POS].[Position_Name] 
	) MPOP ON [MPOP].[Candidate_ID] = [CAN].[Candidate_ID]
	LEFT JOIN (
		SELECT [SKC].[Candidate_ID]
				,[SK].[Map_Skill_ID] AS [Map_Skill_ID] 
				,[SKC].[Skill_By_Comp_ID]
				,[SK].[Skill_Group_ID]
				,[SK].[Skill_ID]
				,[SK].[Skill_Name]
				,[SK].[Skill_Group_Name] 
				,[SK].[Sub_Skill_Group_Name] 
		FROM [Skill].[dbo].[Skill_Candidate] SKC
		LEFT JOIN (
			SELECT [sbc].[Company_ID]
					,[sbc].[Skill_By_Com_ID]
					,[sbc].[Map_Skill_ID] 
					,[SKU].[Skill_Group_Name]
					,[SKU].[Skill_Name]
					,[SKU].[Sub_Skill_Group_Name]
					,[SKU].[Skill_ID]
					,[SKU].[Skill_Group_ID]
			FROM [SKILL].[DBO].[Skill_By_Company] SBC
			LEFT JOIN (			
				SELECT [MSKILL].[Map_Skill_ID],
						[MSKILL].[Skill_Group_ID],
						[MSKILL].[Skill_ID],
						[Skill].[dbo].[Skill].[Skill_Name],
						[SGS].[Skill_Group_Name],
						[SGS].[Sub_Skill_Group_Name],
						@Map_Skill_Type_System AS [SKILL_TYPE]
				FROM [Skill].[dbo].[Map_Skill] MSKILL
				LEFT JOIN (
					SELECT [SG].[Skill_Group_ID], 
							[Skill_Group_Name] = CASE WHEN [SG].[Parent_Skill_Group_ID] = 0 OR [SG].[Parent_Skill_Group_ID] IS NULL  
								THEN [SG].[Skill_Group_Name]
								ELSE (
									SELECT TOP 1 [Skill].[dbo].[Skill_Group].[Skill_Group_Name] 
									FROM [Skill].[dbo].[Skill_Group] 
									WHERE [Skill].[dbo].[Skill_Group].[Skill_Group_ID] = [SG].[Parent_Skill_Group_ID]
								)
							END, 
							[Sub_Skill_Group_Name] = CASE WHEN [SG].[Parent_Skill_Group_ID] = 0 OR [SG].[Parent_Skill_Group_ID] IS NULL 
								THEN NULL
								ELSE [SG].[Skill_Group_Name] END 
					FROM [Skill].[dbo].[Skill_Group] SG
				) SGS ON [MSKILL].[Skill_Group_ID] = [SGS].[Skill_Group_ID]
				LEFT JOIN [Skill].[dbo].[Skill] ON [MSKILL].[Skill_ID] = [Skill].[dbo].[Skill].[Skill_ID]
				WHERE [MSKILL].[Skill_Group_ID] IS NOT NULL

				UNION  

				SELECT [MSKILLT].[Map_Skill_Temp_ID] AS [Map_Skill_ID],
						[MSKILLT].[Skill_Group_ID],
						[MSKILLT].[Skill_Temp_ID] AS [Skill_ID], 
						[Skill].[dbo].[Skill_Temp].[Skill_Name],
						[SGT].[Skill_Group_Name],
						[SGT].[Sub_Skill_Group_Name],
						@Map_Skill_Type_Temp AS [SKILL_TYPE] 
				FROM [Skill].[dbo].[Map_Skill_Temp] MSKILLT
				LEFT JOIN (
					SELECT [SG].[Skill_Group_ID], 
							[Skill_Group_Name] = CASE WHEN [SG].[Parent_Skill_Group_ID] = 0 OR [SG].[Parent_Skill_Group_ID] IS NULL  
								THEN [SG].[Skill_Group_Name]
								ELSE (
									SELECT TOP 1 [Skill].[dbo].[Skill_Group].[Skill_Group_Name] 
									FROM [Skill].[dbo].[Skill_Group] 
									WHERE [Skill].[dbo].[Skill_Group].[Skill_Group_ID] = [SG].[Parent_Skill_Group_ID]
								)
							END, 
							[Sub_Skill_Group_Name] = CASE WHEN [SG].[Parent_Skill_Group_ID] = 0 OR [SG].[Parent_Skill_Group_ID] IS NULL 
								THEN NULL
								ELSE [SG].[Skill_Group_Name] END 
					FROM [Skill].[dbo].[Skill_Group] SG
				) SGT ON [MSKILLT].[Skill_Group_ID] = [SGT].[Skill_Group_ID]
				LEFT JOIN [Skill].[dbo].[Skill_Temp] ON [MSKILLT].[Skill_Temp_ID] = [Skill].[dbo].[Skill_Temp].[Skill_Temp_ID]
			) SKU ON [SKU].[Map_Skill_ID] = [SBC].[Map_Skill_ID] AND [SKU].[SKILL_TYPE] = [SBC].[Map_Skill_Type_ID] 
			WHERE [sbc].[Company_ID] IN (
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
			) 
		) SK ON [SK].[Skill_By_Com_ID] = [SKC].[Skill_By_Comp_ID]
		WHERE [SKC].[Map_Skill_ID] = 0
		AND [SKC].[Is_Deleted] = 0	 
	) SKILL ON [SKILL].[Candidate_ID] = [CAN].[Candidate_ID]
	WHERE [CAN].[Is_Employee] = 0 
	AND [CAN].[Is_Deleted] = 0
	AND (@Full_Name IS NULL OR @Full_Name = '' OR [PA].[Full_Name] LIKE '%' + @Full_Name + '%')
	AND (
		(SELECT COUNT(*) FROM @CurrentPositionTable) = 0 
		OR [CAN].[Current_Position] IN (SELECT ID FROM @CurrentPositionTable)
	)
	AND (
		(SELECT COUNT(*) FROM @CurrentPositionByComTable) = 0 
		OR [CAN].[Current_Position_By_Com] IN (SELECT ID FROM @CurrentPositionByComTable)
	)
	AND (
		(SELECT COUNT(*) FROM @LookingPositionTable) = 0 
		OR [MPOP].[Position_ID] IN (SELECT ID FROM @LookingPositionTable)
	)
	AND (
		(SELECT COUNT(*) FROM @LookingPositionByComTable) = 0 
		OR [MPOP].[Position_By_Com_ID] IN (SELECT ID FROM @LookingPositionByComTable)
	)
	AND (@Gender_ID = 0 OR [PA].[Gender_ID] = @Gender_ID)
	AND (
		(@Min_Expected_Salary IS NULL OR @Min_Expected_Salary = '') 
		AND (@Max_Expected_Salary IS NULL OR @Max_Expected_Salary = '')
		OR (
			(@Min_Expected_Salary IS NOT NULL AND @Min_Expected_Salary <> '')
			AND (@Max_Expected_Salary IS NULL OR @Max_Expected_Salary = '')
			AND [CAN].[Min_Exp_Salary] <= CAST(@Min_Expected_Salary AS INT) 
			AND [CAN].[Max_Exp_Salary] >= CAST(@Min_Expected_Salary AS INT)
		)
		OR (
			(@Min_Expected_Salary IS NULL OR @Min_Expected_Salary = '')
			AND (@Max_Expected_Salary IS NOT NULL AND @Max_Expected_Salary <> '')
			AND [CAN].[Min_Exp_Salary] <= CAST(@Max_Expected_Salary AS INT) 
			AND [CAN].[Max_Exp_Salary] >= CAST(@Max_Expected_Salary AS INT)
		)
		OR (
			(@Min_Expected_Salary IS NOT NULL AND @Min_Expected_Salary <> '')
			AND (@Max_Expected_Salary IS NOT NULL AND @Max_Expected_Salary <> '')
			AND [CAN].[Min_Exp_Salary] <= CAST(@Max_Expected_Salary AS INT) 
			AND [CAN].[Max_Exp_Salary] >= CAST(@Min_Expected_Salary AS INT)
		)
	)
	AND (
		@Company_ID = 0
		OR (
			(SELECT COUNT(*) FROM @SkillByCompanyTable) = 0 
			OR [SKILL].[Skill_By_Comp_ID] IN (SELECT ID FROM @SkillByCompanyTable)
		)
	)
	AND (
		@Company_ID <> 0
		OR (
			(SELECT COUNT(*) FROM @MapSkillTable) = 0 
			OR [SKILL].[Map_Skill_ID] IN (SELECT ID FROM @MapSkillTable)
		)
	)
	AND (@Country_ID = 0 OR [PA].[Country_ID] = @Country_ID)
	AND (@City_ID = 0 OR [PA].[City_ID] = @City_ID)
	GROUP BY 
		[PU].[Full_Name],
		[LUC].[Recruiter_ID],
		[PA].[Full_Name],
		[CAN].[Person_ID],
		[PA].[Birth_Date],
		[PHONE].[Tel_Country_Code],
		[PHONE].[Tel_Number],
		[PA].[Email],
		[POS].[Position_Name],
		[CAN].[Current_Position],
		[CAN].[Current_Position_By_Com],
		[LS].[Salary],
		[CS].[Candidate_Status]
	ORDER BY [PA].[Full_Name];

