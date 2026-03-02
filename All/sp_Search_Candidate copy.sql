USE [Candidate]
GO

	-- Add the parameters for the stored procedure here
DECLARE	@Full_Name NVARCHAR(512) = NULL,
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
	@User_ID INT = 0;

	DECLARE @sqlCommand VARCHAR(MAX),
			@columnList NVARCHAR(500);

	-- Main query using CTEs
	SET @sqlCommand = 'WITH Config_CTE AS (
		SELECT 
			ISNULL((SELECT TOP(1) [P].[Pipeline_ID]
					FROM [Pipeline].[dbo].[Pipeline] P
					WHERE [P].[Pipeline_Name] = ''Candidates''
					AND [P].[Is_Active] = 1
					AND [P].[Is_Delete] = 0), 0) AS [Pipeline],
			ISNULL((SELECT TOP 1 [Map_Skill_Type_ID]
					FROM [Skill].[dbo].[Map_Skill_Type]
					WHERE [Map_Skill_Type_Name] = ''System''), 0) AS [Map_Skill_Type_System],
			ISNULL((SELECT TOP 1 [Map_Skill_Type_ID]
					FROM [Skill].[dbo].[Map_Skill_Type]
					WHERE [Map_Skill_Type_Name] = ''Company''), 0) AS [Map_Skill_Type_Temp],
			ISNULL((SELECT TOP 1 [Address_Type_ID]
					FROM [Address].[dbo].[Address_Type]
					WHERE [Address_Type_Name] = ''Register''), 0) AS [Address_Type_ID],
			ISNULL((SELECT TOP 1 [Category_Type_ID]
					FROM [Address].[dbo].[Address_Category_Type]
					WHERE [Category_Type_Name] = ''Person''), 0) AS [Address_Category_Type_ID],
			ISNULL((SELECT TOP 1 [Show_Data_ID]
					FROM [dbo].[Show_Data] SD
					WHERE [Show_Data_Name] = ''Everyone''
					AND [Is_Active] = 1), 0) AS [Everyone],
			ISNULL((SELECT TOP 1 [Show_Data_ID]
					FROM [dbo].[Show_Data] SD
					WHERE [Show_Data_Name] = ''Only me''
					AND [Is_Active] = 1), 0) AS [Only_me],
			ISNULL((SELECT TOP 1 [Show_Data_ID]
					FROM [dbo].[Show_Data] SD
					WHERE [Show_Data_Name] = ''Expired''
					AND [Is_Active] = 1), 0) AS [Show_data_expired]
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
	Candidate_Base_CTE AS (
		SELECT  [CAN].[Candidate_ID]
				,[C].[Company_ID]
				,[CAN].[Person_ID]
				,[CAN].[Current_Position]  
				,[Current_Position_By_Com] = CASE WHEN [CAN].[Current_Position_By_Com] IS NULL THEN 0 ELSE [CAN].[Current_Position_By_Com] END
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
				,[Current_Position_By_Com] = CASE WHEN [CAN].[Current_Position_By_Com] IS NULL THEN 0 ELSE [CAN].[Current_Position_By_Com] END
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
				,[Current_Position_By_Com] = CASE WHEN [CAN].[Current_Position_By_Com] IS NULL THEN 0 ELSE [CAN].[Current_Position_By_Com] END
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
				,[Current_Position_By_Com] = CASE WHEN [CAN].[Current_Position_By_Com] IS NULL THEN 0 ELSE [CAN].[Current_Position_By_Com] END
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
	),
	Position_Union_CTE AS (
		SELECT [P].[Position_ID] 
				,[P].[Position_Name] 
				,2 AS [Position_By_Com_Type_ID]  
		FROM  [RMS_Position].[dbo].[Position] P  

		UNION

		SELECT [PT].[Position_Temp_ID] AS [Position_ID] 
				,[PT].[Position_Name] 
				,1 AS [Position_By_Com_Type_ID]
		FROM [RMS_Position].[DBO].[Position_Temp] PT
	),
	LookingPosition_CTE AS (
		SELECT [MPO].[Candidate_ID] 
				,[MPO].[Position_ID]
				,[MPO].[Position_By_Com_ID]
				,[POS].[Position_Name] 
		FROM [Candidate].[DBO].[Map_Looking_For_Position] MPO 
		LEFT JOIN Position_Union_CTE POS ON [POS].[Position_ID] = (
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
	Person_Address_CTE AS (
		SELECT  [PER].[Person_ID]
				,[PER].[First_Name]
				,[PER].[Middle_Name]
				,[PER].[Last_Name]
				,[PER].[Full_Name]
				,[PER].[Gender_ID]
				,(SELECT [G].[Gender_Name] FROM [Gender].[DBO].[Gender] G WHERE [G].[Gender_ID] = [PER].[Gender_ID]) AS [Gender_Name]
				,[AD].[Country_ID]
				,(SELECT [C].[Country_Name] FROM [Country].[DBO].[Country] C WHERE [C].[Country_ID] = [AD].[Country_ID]) AS [Country_Name]
				,[AD].[City_ID]
				,(SELECT [CI].[City_Name] FROM [Country].[DBO].[City] CI WHERE [CI].[City_ID] = [AD].[City_ID]) AS [City_Name]
		FROM [PERSON].[DBO].[Person] PER  
		LEFT JOIN [Address].[DBO].[Address] AD ON [AD].[Reference_ID] = [PER].[Person_ID] 
			AND [AD].[Address_Type_ID] = (SELECT [Address_Type_ID] FROM Config_CTE)
			AND [AD].[Category_Type_ID] = (SELECT [Address_Category_Type_ID] FROM Config_CTE)
	),
	LogUpdateCandidate_CTE AS (
		SELECT [tt].[Update_By] AS [Owner_ID]
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
	Owner_Person_CTE AS (
		SELECT  [PER].[Person_ID]
				,[PER].[First_Name]
				,[PER].[Middle_Name]
				,[PER].[Last_Name]
				,[PER].[Full_Name] 
		FROM [PERSON].[DBO].[Person] PER  
	),
	CurrentPosition_CTE AS (
		SELECT [POS].[Position_ID]
				,[POS].[Position_Name]
				,[PB].[Position_By_Com_ID]
				,[POS].[Position_By_Com_Type_ID]
		FROM Position_Union_CTE POS
		LEFT JOIN [RMS_Position].[dbo].[Position_By_Comp] PB ON [POS].[Position_ID] = (
			CASE WHEN [PB].[Position_By_Com_Type_ID] = 1 
			THEN (
				SELECT [PT].[Position_Temp_ID]
				FROM [RMS_Position].[dbo].[Position_Temp] PT
				WHERE [PT].[Position_Temp_ID] = [PB].[Position_ID]
			)
			ELSE [PB].[Position_ID] END
		)
	),
	Skill_Group_CTE AS (
		SELECT  [SG].[Skill_Group_ID]
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
		SELECT   [SKC].[Candidate_ID]
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
	Main_Query_CTE AS (
		SELECT  [CAN].[Candidate_ID]
				,[CAN].[Person_ID]
				,[CAN].[Show_Data_ID]
				,[CAN].[Show_Data_Name]
				,[CAN].[Current_Position]  
				,[CAN].[Current_Position_By_Com]  
				,[POS].[Position_Name] AS [Current_Position_Name]
				,[MPOP].[Position_ID] AS [Looking_Position_ID]
				,[MPOP].[Position_By_Com_ID] AS [Looking_Position_By_Com_ID]
				,[MPOP].[Position_Name] AS [Looking_Position_Name] 
				,[PA].[Gender_ID]
				,[PA].[Gender_Name]
				,[CAN].[Min_Exp_Salary]
				,[CAN].[Max_Exp_Salary]
				,[PA].[City_ID]
				,[PA].[City_Name]
				,[PA].[Country_ID]
				,[PA].[Country_Name]
				,[PA].[Full_Name]
				,[SKILL].[Map_Skill_ID]
				,[SKILL].[Skill_By_Comp_ID]
				,[SKILL].[Skill_ID]
				,[SKILL].[Skill_Name]
				,[SKILL].[Skill_Group_ID]
				,[SKILL].[Skill_Group_Name]
				,[SKILL].[Sub_Skill_Group_Name]
				,[Updated_Date] = CASE WHEN [LUC].[Update_Date] IS NULL 
										THEN ''-''
									ELSE 
										FORMAT([LUC].[Update_Date], ''dd MMM yyyy'') 
									END
				,[LUC].[Owner_ID]
				,[CREATED].[Full_Name] AS [Updated_By]
				,[COMP].[Company_Name]
				,[COMP].[Company_ID]
				,[MCP].[Exprie_Date]
		FROM Candidate_Base_CTE CAN
		LEFT JOIN [Company].[DBO].[Company] COMP ON [COMP].[Company_ID] = [CAN].[Company_ID]
		LEFT JOIN ExpireDate_CTE MCP ON [MCP].[Candidate_ID] = [CAN].[Candidate_ID] AND [MCP].[Company_ID] = [CAN].[Company_ID]
		LEFT JOIN LookingPosition_CTE MPOP ON [MPOP].[Candidate_ID] = [CAN].[Candidate_ID]
		LEFT JOIN Person_Address_CTE PA ON [PA].[Person_ID] = [CAN].[Person_ID]  
		LEFT JOIN LogUpdateCandidate_CTE LUC ON [LUC].[Candidate_ID] = [CAN].[Candidate_ID]
		LEFT JOIN Owner_Person_CTE CREATED ON [CREATED].[Person_ID] = [LUC].[Owner_ID]
		LEFT JOIN Position_Union_CTE POS ON [POS].[Position_ID] = (
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
		LEFT JOIN Skill_Candidate_CTE SKILL ON [SKILL].[Candidate_ID] = [CAN].[Candidate_ID] 
		WHERE [CAN].[Is_Employee] = 0 
		AND [CAN].[Is_Deleted] = 0
	)
	SELECT [SEARCH].[Company_ID],
			[SEARCH].[Person_ID],
			[SEARCH].[Candidate_ID],
			[SEARCH].[Owner_ID],
			[SEARCH].[Show_Data_ID],
			[SEARCH].[Show_Data_Name],
			[SEARCH].[Full_Name],
			[Current_Position_Name] = CASE WHEN [SEARCH].[Current_Position_Name] IS NULL THEN ''-'' ELSE [SEARCH].[Current_Position_Name] END, 
			[SEARCH].[Updated_Date],
			[Gender_Name] = CASE WHEN [SEARCH].[Gender_Name] IS NULL THEN ''-'' ELSE [SEARCH].[Gender_Name] END, 
			[SEARCH].[Min_Exp_Salary],
			[SEARCH].[Max_Exp_Salary],
			[Country_Name] = CASE WHEN [SEARCH].[Country_Name] IS NULL THEN ''-'' ELSE [SEARCH].[Country_Name] END, 
			[City_Name] = CASE WHEN [SEARCH].[City_Name] IS NULL THEN ''-'' ELSE [SEARCH].[City_Name] END,
			[SEARCH].[Updated_By] AS [Owner], 
			[SEARCH].[Company_Name],
			[Exprie_Date_STR] = CASE WHEN [SEARCH].[Exprie_Date] IS NULL 
									THEN ''-''
								ELSE 
									FORMAT([SEARCH].[Exprie_Date], ''dd MMM yyyy'') 
								END,
			[SEARCH].[Exprie_Date]
	FROM Main_Query_CTE SEARCH
	WHERE 1=1 ';

	-- Build WHERE clause conditions
	IF RTRIM(LTRIM(@Full_Name)) <> ''
		BEGIN
			SET @sqlCommand = CONCAT(@sqlCommand, ' AND [SEARCH].[Full_Name] LIKE ''%@Full_Name%'' ');
			SET @sqlCommand = REPLACE(@sqlCommand, '@Full_Name', RTRIM(LTRIM(@Full_Name)));
		END
		
	IF RTRIM(LTRIM(@Current_Position_By_Com_ID)) <> ''
		BEGIN
			SET @sqlCommand = CONCAT(@sqlCommand, ' AND [SEARCH].[Current_Position_By_Com] IN (@Current_Position_By_Com_ID)'); 
			SET @sqlCommand = REPLACE(@sqlCommand, '@Current_Position_By_Com_ID', @Current_Position_By_Com_ID); 
		END		
		
	IF RTRIM(LTRIM(@Current_Position)) <> ''
		BEGIN
			SET @sqlCommand = CONCAT(@sqlCommand, ' AND [SEARCH].[Current_Position] IN (@Current_Position)'); 
			SET @sqlCommand = REPLACE(@sqlCommand, '@Current_Position', @Current_Position); 
		END		
		
	IF RTRIM(LTRIM(@Looking_Position_By_Com_ID)) <> ''
		BEGIN
			SET @sqlCommand = CONCAT(@sqlCommand, ' AND [SEARCH].[Looking_Position_By_Com_ID] IN (@Looking_Position_By_Com_ID)'); 
			SET @sqlCommand = REPLACE(@sqlCommand, '@Looking_Position_By_Com_ID', @Looking_Position_By_Com_ID); 
		END		
		
	IF RTRIM(LTRIM(@Looking_Position)) <> ''
		BEGIN
			SET @sqlCommand = CONCAT(@sqlCommand, ' AND [SEARCH].[Looking_Position_ID] IN (@Looking_Position)'); 
			SET @sqlCommand = REPLACE(@sqlCommand, '@Looking_Position', @Looking_Position); 
		END		
		
	IF @Gender_ID <> 0
		BEGIN
			SET @sqlCommand = CONCAT(@sqlCommand, ' AND [SEARCH].[Gender_ID] = @Gender_ID'); 
			SET @sqlCommand = REPLACE(@sqlCommand, '@Gender_ID', @Gender_ID); 
		END		
			
	IF RTRIM(LTRIM(@Min_Expected_Salary)) <> '' AND @Max_Expected_Salary IS NULL
		BEGIN
			SET @sqlCommand = CONCAT(@sqlCommand, ' AND [SEARCH].[Min_Exp_Salary] <= @Min_Expected_Salary AND [SEARCH].[Max_Exp_Salary] >= @Min_Expected_Salary');
			SET @sqlCommand = REPLACE(@sqlCommand, '@Min_Expected_Salary', @Min_Expected_Salary);  
		END
		
	IF @Min_Expected_Salary IS NULL AND RTRIM(LTRIM(@Max_Expected_Salary)) <> ''
		BEGIN
			SET @sqlCommand = CONCAT(@sqlCommand, ' AND [SEARCH].[Min_Exp_Salary] <= @Max_Expected_Salary AND [SEARCH].[Max_Exp_Salary] <= @Max_Expected_Salary');
			SET @sqlCommand = REPLACE(@sqlCommand, '@Max_Expected_Salary', @Max_Expected_Salary);  
		END

	IF RTRIM(LTRIM(@Min_Expected_Salary)) <> '' AND RTRIM(LTRIM(@Max_Expected_Salary)) <> ''
		BEGIN
			SET @sqlCommand = CONCAT(@sqlCommand, ' AND [SEARCH].[Min_Exp_Salary] >= @Min_Expected_Salary AND [SEARCH].[Max_Exp_Salary] <= @Max_Expected_Salary');
			SET @sqlCommand = REPLACE(@sqlCommand, '@Min_Expected_Salary', @Min_Expected_Salary); 
			SET @sqlCommand = REPLACE(@sqlCommand, '@Max_Expected_Salary', @Max_Expected_Salary); 
		END		

	IF @Company_ID <> 0
		BEGIN
			IF RTRIM(LTRIM(@Skill_By_Company_ID)) <> ''
				BEGIN
					SET @sqlCommand = CONCAT(@sqlCommand, ' AND [SEARCH].[Skill_By_Comp_ID] IN (@Skill_By_Company_ID)'); 
					SET @sqlCommand = REPLACE(@sqlCommand, '@Skill_By_Company_ID', @Skill_By_Company_ID); 
				END
		END
	ELSE
		BEGIN
			IF RTRIM(LTRIM(@Map_Skill_ID)) <> ''
				BEGIN
					SET @sqlCommand = CONCAT(@sqlCommand, ' AND [SEARCH].[Map_Skill_ID] IN (@Map_Skill_ID)'); 
					SET @sqlCommand = REPLACE(@sqlCommand, '@Map_Skill_ID', @Map_Skill_ID); 
				END	
		END
			 
	IF @Country_ID <> 0
		BEGIN
			SET @sqlCommand = CONCAT(@sqlCommand, ' AND [SEARCH].[Country_ID] = @Country_ID'); 
			SET @sqlCommand = REPLACE(@sqlCommand, '@Country_ID', @Country_ID); 
		END	
		
	IF @City_ID <> 0
		BEGIN
			SET @sqlCommand = CONCAT(@sqlCommand, ' AND [SEARCH].[City_ID] = @City_ID'); 
			SET @sqlCommand = REPLACE(@sqlCommand, '@City_ID', @City_ID); 
		END	

	-- Add GROUP BY and ORDER BY
	SET @sqlCommand = CONCAT(@sqlCommand, ' 
	GROUP BY  [SEARCH].[Candidate_ID],
			[SEARCH].[Full_Name],
			[SEARCH].[Current_Position_Name], 
			[SEARCH].[Updated_Date],
			[SEARCH].[Gender_Name],
			[SEARCH].[Min_Exp_Salary],
			[SEARCH].[Max_Exp_Salary],
			[SEARCH].[Country_Name],
			[SEARCH].[City_Name],
			[SEARCH].[Person_ID],
			[SEARCH].[Owner_ID],
			[SEARCH].[Updated_By],
			[SEARCH].[Company_Name],
			[SEARCH].[Company_ID],
			[SEARCH].[Exprie_Date],
			[SEARCH].[Show_Data_ID],
			[SEARCH].[Show_Data_Name]
	ORDER BY [SEARCH].[Updated_Date] DESC');

	-- Replace parameter placeholders
	SET @sqlCommand = REPLACE(@sqlCommand, '@User_ID', @User_ID); 
	SET @sqlCommand = REPLACE(@sqlCommand, '@Company_ID', @Company_ID); 

	EXEC (@sqlCommand);
 

