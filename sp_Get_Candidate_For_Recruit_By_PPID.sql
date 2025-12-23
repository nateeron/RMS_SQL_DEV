USE [Candidate]
GO
/****** Object:  StoredProcedure [dbo].[sp_Get_Candidate_For_Recruit_By_PPID]    Script Date: 12/23/2025 12:30:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[sp_Get_Candidate_For_Recruit_By_PPID] 
@Project_Position_ID INT = 0, 
@Company_ID INT = 0,
@Gender_ID INT = 0,
@Skill_By_Company_ID NVARCHAR(512) = NULL, 
@Current_Position_ID INT = 0,
@Current_Position_By_Comp_ID INT = 0,
@Candidate_Name NVARCHAR(512) = NULL,
@Map_Skill_ID NVARCHAR(512) = NULL,
@Tel_Country_ID INT = 0,
@Tel_Number NVARCHAR(512) = NULL,
@Candidate_Tag_Query NVARCHAR(max) = NULL,
@Software_ID INT = 0,
@Status_Code NVARCHAR(100) = null OUTPUT

AS
BEGIN TRY
	DECLARE @Step_Sign_Contract INT = 0,
			@Pipeline_Type_System INT = 0,
			@Company_Type INT = 0,
			@Company_Parent_ID INT = 0,
			@Map_Skill_Type_System INT = 0,
			@Map_Skill_Type_Temp INT = 0;

	SET @Company_Type = (SELECT TOP 1 [CT].[Company_Type_ID] 
							FROM [Company].[dbo].[Company_Type] CT
							WHERE [CT].[Company_Type_Name] = 'System'
							AND [CT].[Is_Active] = 1);

	SET @Company_Parent_ID = (SELECT TOP 1 [C].[Company_Parent_ID] 
								FROM [Company].[dbo].[Company] C
								WHERE [C].[Company_ID] = @Company_ID);

	IF @Company_Parent_ID IS NULL
		BEGIN
			SET @Company_Parent_ID = 0;
		END

	SET @Pipeline_Type_System = (SELECT TOP 1
										[PLT].[Pipeline_Type_ID]
									FROM [Pipeline].[dbo].[Pipeline_Type] PLT
									WHERE [PLT].[Pipeline_Type_Name] = 'System'
									AND [PLT].[Is_Active] = 1
									AND [PLT].[Is_Delete] = 0);
  
	SET @Step_Sign_Contract = (SELECT TOP 1 
									[PL].[Number_Step]
								FROM [Pipeline].[dbo].[Pipeline] PL
								WHERE [PL].[Pipeline_Name] = 'Sign Contract'
								AND [PL].[Company_ID] = 0
								AND [PL].[Pipeline_Type_ID] = @Pipeline_Type_System
								AND [PL].[Is_Active] = 1
								AND [PL].[Is_Delete] = 0);

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
		SELECT [tt].[Update_By],
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
	CTE_PipelineCount AS (
		SELECT [M].[Candidate_ID],
				COUNT([M].[Candidate_ID]) AS Sum_Candidate
		FROM [Pipeline].[dbo].[Map_Can_Pile_Com] M
		LEFT JOIN [Company].[dbo].[Project_Position] PP ON [M].[Project_Position_ID] = [PP].[Project_Position_ID]
		WHERE [M].[Is_Active] = 1
			AND [M].[Is_Delete] = 0
			AND [PP].[Project_Position_ID] = @Project_Position_ID
			AND [M].[Company_ID] = @Company_ID
		GROUP BY [M].[Candidate_ID]
	),
	CTE_CompanyHierarchy AS (
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
	CTE_CompanyHierarchyForTags AS (
		SELECT [COM].[Company_ID]
		FROM [Company].[dbo].[Company] COM
		WHERE (@Company_Parent_ID = 0 AND ([COM].[Company_ID] = @Company_ID OR [COM].[Company_Parent_ID] = @Company_ID))
			OR (@Company_Parent_ID <> 0 AND ([COM].[Company_ID] = @Company_Parent_ID OR [COM].[Company_Parent_ID] = @Company_Parent_ID))
	),
	CTE_SkillGroup AS (
		SELECT [SG].[Skill_Group_ID],
				[Skill_Group_Name] = CASE 
					WHEN [SG].[Parent_Skill_Group_ID] = 0 OR [SG].[Parent_Skill_Group_ID] IS NULL  
					THEN [SG].[Skill_Group_Name]
					ELSE (
						SELECT TOP 1 [Skill].[dbo].[Skill_Group].[Skill_Group_Name] 
						FROM [Skill].[dbo].[Skill_Group] 
						WHERE [Skill].[dbo].[Skill_Group].[Skill_Group_ID] = [SG].[Parent_Skill_Group_ID]
					)
				END,
				[Sub_Skill_Group_Name] = CASE
					WHEN [SG].[Parent_Skill_Group_ID] = 0 OR [SG].[Parent_Skill_Group_ID] IS NULL 
					THEN NULL
					ELSE [SG].[Skill_Group_Name]
				END
		FROM [Skill].[dbo].[Skill_Group] SG
	),
	CTE_SkillUnion AS (
		SELECT [MSKILL].[Map_Skill_ID],
				[MSKILL].[Skill_Group_ID],
				[MSKILL].[Skill_ID],
				[Skill].[dbo].[Skill].[Skill_Name],
				[SGS].[Skill_Group_Name],
				[SGS].[Sub_Skill_Group_Name],
				@Map_Skill_Type_System AS [SKILL_TYPE]
		FROM [Skill].[dbo].[Map_Skill] MSKILL
		LEFT JOIN CTE_SkillGroup SGS ON [MSKILL].[Skill_Group_ID] = [SGS].[Skill_Group_ID]
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
		LEFT JOIN CTE_SkillGroup SGT ON [MSKILLT].[Skill_Group_ID] = [SGT].[Skill_Group_ID]
		LEFT JOIN [Skill].[dbo].[Skill_Temp] ON [MSKILLT].[Skill_Temp_ID] = [Skill].[dbo].[Skill_Temp].[Skill_Temp_ID]
	),
	CTE_SkillByCompany AS (
		SELECT [sbc].[Company_ID],
				[sbc].[Skill_By_Com_ID],
				[sbc].[Map_Skill_ID],
				[SKU].[Skill_Group_Name],
				[SKU].[Skill_Name],
				[SKU].[Sub_Skill_Group_Name],
				[SKU].[Skill_ID],
				[SKU].[Skill_Group_ID]
		FROM [SKILL].[DBO].[Skill_By_Company] SBC
		LEFT JOIN CTE_SkillUnion SKU ON [SKU].[Map_Skill_ID] = [SBC].[Map_Skill_ID] 
			AND [SKU].[SKILL_TYPE] = [SBC].[Map_Skill_Type_ID] 
		WHERE [sbc].[Company_ID] IN (SELECT [Company_ID] FROM CTE_CompanyHierarchy)
	),
	CTE_Skill AS (
		SELECT [SKC].[Candidate_ID],
				[SK].[Map_Skill_ID],
				[SKC].[Skill_By_Comp_ID],
				[SK].[Skill_Group_ID],
				[SK].[Skill_ID],
				[SK].[Skill_Name],
				[SK].[Skill_Group_Name],
				[SK].[Sub_Skill_Group_Name]
		FROM [Skill].[dbo].[Skill_Candidate] SKC
		LEFT JOIN CTE_SkillByCompany SK ON [SK].[Skill_By_Com_ID] = [SKC].[Skill_By_Comp_ID]
		WHERE [skc].[Map_Skill_ID] = 0
			AND [skc].[Is_Deleted] = 0
	),
	CTE_CandidateTag AS (
		SELECT  
			[CT].[Candidate_Tag_ID], 
			[CT].[Candidate_Tag_Name], 
			1 AS [CanTagType_Com_ID],
			[CT].[Color],
			[CT].[Detail]
		FROM [RMS_Candidate_Tag].[dbo].[Candidate_Tag] CT	
		WHERE [CT].[Is_Active] = 1
			AND [CT].[Software_ID] = @Software_ID
			AND [CT].[Is_Deleted] = 0
		UNION
		SELECT  
			[CTT].[Candidate_Tag_ID], 
			[CTT].[Candidate_Tag_Name], 
			2 AS [CanTagType_Com_ID],
			[CTT].[Color],
			[CTT].[Detail]
		FROM [RMS_Candidate_Tag].[dbo].[Candidate_Tag_Temp] CTT
		WHERE [CTT].[Company_ID] IN (SELECT [Company_ID] FROM CTE_CompanyHierarchyForTags)
			AND [CTT].[Software_ID] = @Software_ID
			AND [CTT].[Is_Active] = 1
			AND [CTT].[Is_Deleted] = 0
	),
	CTE_CandidateTagByCompany AS (
		SELECT 
			[CTBC].[Candidate_Tag_ID],
			[CTBC].[CanTagType_Com_ID],
			[CT].[Candidate_Tag_Name],
			[CT].[Color],
			[CT].[Detail]
		FROM [RMS_Candidate_Tag].[dbo].[Candidate_Tag_By_Company] CTBC
		LEFT JOIN CTE_CandidateTag CT ON [CT].[Candidate_Tag_ID] = [CTBC].[Candidate_Tag_ID] 
			AND [CT].[CanTagType_Com_ID] = [CTBC].[CanTagType_Com_ID]
		WHERE [CTBC].[Company_ID] IN (SELECT [Company_ID] FROM CTE_CompanyHierarchyForTags)
			AND [CTBC].[Is_Active] = 1
	),
	CTE_BaseCandidates AS (
		SELECT [C].[Candidate_ID]
				,[P].[Person_ID]
				,[P].[Full_Name] AS [Candidate_Name]
				,[Tel_Country_ID] = CASE WHEN [PHONE].[Tel_Country_ID] IS NULL THEN 0 ELSE [PHONE].[Tel_Country_ID] END
				,[Tel_Country_Code] = CASE WHEN [PHONE].[Tel_Country_Code] IS NULL THEN '-' ELSE [PHONE].[Tel_Country_Code] END
				,[Tel] = CASE WHEN [PHONE].[Tel_Number] IS NULL THEN '-' ELSE [PHONE].[Tel_Number] END
				,[C].[Current_Position]
				,[C].[Current_Position_By_Com]
				,[POS].[Position_Name]
				,[PU].[Full_Name] AS [Created_Name]
				,[Updated_Date] = CASE WHEN [LUC].[Update_Date] IS NULL THEN '-' ELSE FORMAT([LUC].[Update_Date],'dd MMM yyyy') END
				,[Select_Status] = CASE WHEN [PL].[Sum_Candidate] IS NULL OR [PL].[Sum_Candidate] = 0 THEN 0 ELSE [PL].[Sum_Candidate] END
				,[P].[Gender_ID]
				,[SKILL].[Skill_By_Comp_ID]
				,[C].[Company_ID]
		FROM [Candidate].[dbo].[Candidate] C
		LEFT JOIN [Person].[dbo].[Person] P ON [P].[Person_ID] = [C].[Person_ID] 
		LEFT JOIN CTE_Phone PHONE ON [PHONE].[Reference_ID] = [P].[Person_ID]
		LEFT JOIN CTE_LogUpdate LUC ON [LUC].[Candidate_ID] = [C].[Candidate_ID] AND [C].[Is_Deleted] = 0
		LEFT JOIN [PERSON].[DBO].[Person] PU ON [PU].[Person_ID] = [LUC].[Update_By]
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
		LEFT JOIN CTE_PipelineCount PL ON [PL].[Candidate_ID] = [C].[Candidate_ID]
		LEFT JOIN CTE_Skill SKILL ON [SKILL].[Candidate_ID] = [C].[Candidate_ID] 
		WHERE [C].[Is_Deleted] = 0
			AND [C].[Company_ID] = @Company_ID
			AND (
				[C].[Show_Data_ID] IN (
					SELECT [Candidate].[dbo].[Show_Data].[Show_Data_ID] 
					FROM [Candidate].[dbo].[Show_Data] 
					WHERE ([Candidate].[dbo].[Show_Data].[Show_Data_Name] = 'Only Me'
						OR [Candidate].[dbo].[Show_Data].[Show_Data_Name] = 'Everyone'
						OR [Candidate].[dbo].[Show_Data].[Show_Data_Name] = 'Expired')
						AND [Candidate].[dbo].[Show_Data].[Is_Active] = 1
				) 
			)
			AND [P].[Full_Name] <> ''
			AND [P].[Full_Name] IS NOT NULL
			AND [C].[Is_Employee] = 0
			AND (@Candidate_Tag_Query IS NULL OR @Candidate_Tag_Query = '' OR 
				EXISTS (
					SELECT 1 
					FROM [dbo].[Map_Candidate_Tag_Com] MCT
					WHERE [MCT].[Candidate_ID] = [C].[Candidate_ID]
						AND [MCT].[Is_Active] = 1
						AND (CAST(@Candidate_Tag_Query AS NVARCHAR(MAX)) LIKE '%' + CAST([MCT].[Candidate_Tag_ID] AS NVARCHAR(MAX)) + '%'
							OR CAST(@Candidate_Tag_Query AS NVARCHAR(MAX)) LIKE '%' + CAST([MCT].[CanTagType_Com_ID] AS NVARCHAR(MAX)) + '%')
				)
			)
		UNION 
		SELECT [C].[Candidate_ID]
				,[P].[Person_ID]
				,[P].[Full_Name] AS [Candidate_Name]
				,[Tel_Country_ID] = CASE WHEN [PHONE].[Tel_Country_ID] IS NULL THEN 0 ELSE [PHONE].[Tel_Country_ID] END
				,[Tel_Country_Code] = CASE WHEN [PHONE].[Tel_Country_Code] IS NULL THEN '-' ELSE [PHONE].[Tel_Country_Code] END
				,[Tel] = CASE WHEN [PHONE].[Tel_Number] IS NULL THEN '-' ELSE [PHONE].[Tel_Number] END
				,[C].[Current_Position]
				,[C].[Current_Position_By_Com]
				,[POS].[Position_Name]
				,[PU].[Full_Name] AS [Created_Name]
				,[Updated_Date] = CASE WHEN [LUC].[Update_Date] IS NULL THEN '-' ELSE FORMAT([LUC].[Update_Date],'dd MMM yyyy') END
				,[Select_Status] = CASE WHEN [PL].[Sum_Candidate] IS NULL OR [PL].[Sum_Candidate] = 0 THEN 0 ELSE [PL].[Sum_Candidate] END
				,[P].[Gender_ID]
				,[SKILL].[Skill_By_Comp_ID]
				,[C].[Company_ID]
		FROM [Candidate].[dbo].[Candidate] C
		LEFT JOIN [Person].[dbo].[Person] P ON [P].[Person_ID] = [C].[Person_ID] 
		LEFT JOIN CTE_Phone PHONE ON [PHONE].[Reference_ID] = [P].[Person_ID]
		LEFT JOIN CTE_LogUpdate LUC ON [LUC].[Candidate_ID] = [C].[Candidate_ID] AND [C].[Is_Deleted] = 0
		LEFT JOIN [PERSON].[DBO].[Person] PU ON [PU].[Person_ID] = [LUC].[Update_By]
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
		LEFT JOIN CTE_PipelineCount PL ON [PL].[Candidate_ID] = [C].[Candidate_ID]
		LEFT JOIN [Company].[dbo].[Company] COM ON [COM].[Company_ID] = [C].[Company_ID]
		LEFT JOIN CTE_Skill SKILL ON [SKILL].[Candidate_ID] = [C].[Candidate_ID] 
		WHERE [C].[Is_Deleted] = 0
			AND (
				(@Company_Parent_ID <> 0 AND [COM].[Company_ID] IN (
					SELECT [C].[Company_ID] 
					FROM [Company].[dbo].[Company] C
					WHERE [C].[Company_Parent_ID] = @Company_Parent_ID
					OR [C].[Company_ID] = @Company_Parent_ID
				))
				OR (@Company_Parent_ID = 0 AND [COM].[Company_ID] IN (
					SELECT [C].[Company_ID] 
					FROM [Company].[dbo].[Company] C
					WHERE [C].[Company_Parent_ID] = @Company_ID
					OR [C].[Company_ID] = @Company_ID
				))
			)
			AND (
				[C].[Show_Data_ID] IN (
					SELECT [Candidate].[dbo].[Show_Data].[Show_Data_ID] 
					FROM [Candidate].[dbo].[Show_Data] 
					WHERE ([Candidate].[dbo].[Show_Data].[Show_Data_Name] = 'Everyone'
					OR [Candidate].[dbo].[Show_Data].[Show_Data_Name] = 'Expired')
					AND [Candidate].[dbo].[Show_Data].[Is_Active] = 1
				) 
			)
			AND [P].[Full_Name] <> ''
			AND [P].[Full_Name] IS NOT NULL
			AND [C].[Is_Employee] = 0
			AND (@Candidate_Tag_Query IS NULL OR @Candidate_Tag_Query = '' OR 
				EXISTS (
					SELECT 1 
					FROM [dbo].[Map_Candidate_Tag_Com] MCT
					WHERE [MCT].[Candidate_ID] = [C].[Candidate_ID]
						AND [MCT].[Is_Active] = 1
						AND (CAST(@Candidate_Tag_Query AS NVARCHAR(MAX)) LIKE '%' + CAST([MCT].[Candidate_Tag_ID] AS NVARCHAR(MAX)) + '%'
							OR CAST(@Candidate_Tag_Query AS NVARCHAR(MAX)) LIKE '%' + CAST([MCT].[CanTagType_Com_ID] AS NVARCHAR(MAX)) + '%')
				)
			)
	)
	SELECT [A].[Candidate_ID]
			,[A].[Person_ID]
			,[A].[Candidate_Name]
			,[A].[Tel_Country_ID]
			,[A].[Tel_Country_Code]
			,[A].[Tel]
			,[A].[Current_Position]
			,[A].[Current_Position_By_Com]
			,[A].[Position_Name]
			,[A].[Created_Name]
			,[A].[Updated_Date]
			,[A].[Select_Status]
			,[Looking_Position] = (
				SELECT 
					STUFF((
						SELECT ', ' + CAST([POS].[Position_Name] AS NVARCHAR(MAX))
						FROM [Candidate].[dbo].[Map_Looking_For_Position] MLP 
						LEFT JOIN CTE_Position POS 
						ON [POS].[Position_ID] = (
							CASE 
								WHEN [MLP].[Position_By_Com_ID] = 0 OR [MLP].[Position_By_Com_ID] IS NULL THEN [MLP].[Position_ID]
								ELSE (
									SELECT [Position_ID_OF_Com]
									FROM CTE_PositionByComp PB 
									WHERE [PB].[Position_By_Com_ID] = [MLP].[Position_By_Com_ID]
								)
							END
						)
						AND [POS].[Position_By_Com_Type_ID] = (
							CASE 
								WHEN [MLP].[Position_By_Com_ID] = 0 OR [MLP].[Position_By_Com_ID] IS NULL THEN 2
								ELSE (
									SELECT [PB].[Position_By_Com_Type_ID] 
									FROM CTE_PositionByComp PB 
									WHERE [PB].[Position_By_Com_ID] = [MLP].[Position_By_Com_ID]
								)
							END
						)
						WHERE [MLP].[Is_Active] = 1 AND [MLP].[Candidate_ID] = [A].[Candidate_ID]
						FOR XML PATH(''), TYPE
					).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS [Position_Name]
			)
			,[Candidate_Tag] = (
				SELECT STUFF((
					SELECT ' ' + CAST(
						'<a class="mx-1" data-bs-toggle="tooltip" data-bs-placement="top" title="' 
						+ ISNULL([CT].[Candidate_Tag_Name], '') 
						+ '" style="cursor: pointer;color:'
						+ ISNULL([CT].[Color], '') 
						+ ' "> <i class="fas fa-tag"></i></a> '
					AS NVARCHAR(MAX))
					FROM [dbo].[Map_Candidate_Tag_Com] MCT
					LEFT JOIN CTE_CandidateTagByCompany CT ON [CT].[Candidate_Tag_ID] = [MCT].[Candidate_Tag_ID] 
						AND [CT].[CanTagType_Com_ID] = [MCT].[CanTagType_Com_ID]
					WHERE [MCT].[Candidate_ID] = [A].[Candidate_ID]
						AND [MCT].[Is_Active] = 1
					FOR XML PATH(''), TYPE
				).value('.', 'NVARCHAR(MAX)'), 1, 1, '') AS Candidate_Tag_Name
			)
	FROM CTE_BaseCandidates A
	WHERE [A].[Select_Status] = 0
		AND (@Candidate_Name IS NULL OR @Candidate_Name = '' OR [A].[Candidate_Name] LIKE '%' + RTRIM(LTRIM(@Candidate_Name)) + '%')
		AND (@Current_Position_By_Comp_ID = 0 OR [A].[Current_Position_By_Com] = @Current_Position_By_Comp_ID)
		AND (@Current_Position_ID = 0 OR [A].[Current_Position] = @Current_Position_ID)
		AND (@Tel_Country_ID = 0 OR [A].[Tel_Country_ID] = @Tel_Country_ID)
		AND (@Tel_Number IS NULL OR @Tel_Number = '' OR [A].[Tel] = @Tel_Number)
		AND (@Gender_ID = 0 OR [A].[Gender_ID] = @Gender_ID)
		AND (@Skill_By_Company_ID IS NULL OR @Skill_By_Company_ID = '' OR 
			CHARINDEX(CAST([A].[Skill_By_Comp_ID] AS NVARCHAR(MAX)), @Skill_By_Company_ID) > 0)
	GROUP BY [A].[Candidate_ID]
			,[A].[Person_ID]
			,[A].[Candidate_Name]
			,[A].[Tel_Country_ID]
			,[A].[Tel_Country_Code]
			,[A].[Tel]
			,[A].[Current_Position]
			,[A].[Current_Position_By_Com]
			,[A].[Position_Name]
			,[A].[Created_Name]
			,[A].[Updated_Date]
			,[A].[Select_Status]
	ORDER BY [A].[Candidate_Name];

	SET	@Status_Code = '200';
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
			,'DB Candidate - sp_Get_Candidate_For_Recruit_By_PPID'
			,ERROR_MESSAGE()
			,999
			,GETDATE());
SET @Status_Code = '999';
END CATCH
