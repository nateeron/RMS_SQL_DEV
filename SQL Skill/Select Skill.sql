Declare @Company_ID int = 3357;
DECLARE @Map_Skill_Type_System int = 0,
	@Map_Skill_Type_Temp int = 0;
SET @Map_Skill_Type_System = 1 -- System
SET @Map_Skill_Type_Temp = 2 -- Company
;
with Skill_group as (
	SELECT [SSG].[Skill_Group_ID],
		[SSG].[Parent_Skill_Group_ID],
		Skill_Group_Name = CASE
			WHEN SG_CHILD.Parent_Skill_Group_ID = 0
			OR SG_CHILD.Parent_Skill_Group_ID IS NULL THEN SG_CHILD.Skill_Group_Name
			ELSE SG_PARENT.Skill_Group_Name
		END,
		Sub_Skill_Group_Name = CASE
			WHEN SG_CHILD.Parent_Skill_Group_ID <> 0 THEN SG_CHILD.Skill_Group_Name
			ELSE ''
		END
	FROM [dbo].[Skill_Group] SSG
		LEFT JOIN dbo.Skill_Group SG_CHILD ON SG_CHILD.Skill_Group_ID = SSG.Skill_Group_ID
		AND SG_CHILD.Is_Active = 1
		AND SG_CHILD.Is_Delete = 0
		LEFT JOIN dbo.Skill_Group SG_PARENT ON SG_PARENT.Skill_Group_ID = SG_CHILD.Parent_Skill_Group_ID
		AND SG_PARENT.Is_Active = 1
		AND SG_PARENT.Is_Delete = 0
),
TBCompanyID AS (
	SELECT [COM].[Company_ID]
	FROM [Company].[dbo].[Company] COM
	WHERE [COM].[Company_ID] = @Company_ID
		OR [COM].[Company_Parent_ID] = @Company_ID
),
TB1 as (
	select 
		[MT].[Map_Skill_Temp_ID] as [Map_Skill_ID],
		@Map_Skill_Type_Temp as [Map_Skill_Type_ID],
		'Company' as [Map_Skill_Type_Name],
		[Skill_Group_ID] =  CASE
								WHEN [SG].[Parent_Skill_Group_ID] = 0 
								THEN [MT].[Skill_Group_ID]
								ELSE [SG].[Parent_Skill_Group_ID]
							END,
		[SG].[Skill_Group_Name],
		[Sub_Skill_Group_ID] = CASE
									WHEN [SG].[Parent_Skill_Group_ID] <> 0 
									THEN [MT].[Skill_Group_ID]
									ELSE 0
								END,
		[SG].[Sub_Skill_Group_Name],
		[MT].[Skill_Temp_ID] as [Skill_ID],
		[SKT].[Skill_Name],
		[Is_Active] = CASE
						WHEN (
								SELECT [SBC].[Is_Active]
								FROM [Skill].[dbo].[Skill_By_Company] SBC
								WHERE [SBC].[Map_Skill_ID] = [MT].[Map_Skill_Temp_ID]
									AND [SBC].[Map_Skill_Type_ID] = @Map_Skill_Type_Temp
							) IS NULL 
						THEN 0
						ELSE (
							SELECT [SBC].[Is_Active]
							FROM [Skill].[dbo].[Skill_By_Company] SBC
							WHERE [SBC].[Map_Skill_ID] = [MT].[Map_Skill_Temp_ID]
								AND [SBC].[Map_Skill_Type_ID] = @Map_Skill_Type_Temp
						)
					END
	FROM [dbo].[Map_Skill_Temp] MT
		LEFT JOIN [dbo].[Skill_Temp] SKT ON [SKT].[Skill_Temp_ID] = [MT].[Skill_Temp_ID]
		LEFT JOIN Skill_group SG ON [SG].[Skill_Group_ID] = [MT].[Skill_Group_ID]
	WHERE [MT].[Is_Active] = 1
		AND [MT].[Is_Delete] = 0
		AND [SKT].[Company_ID] IN (
			SELECT Company_ID
			from TBCompanyID
		)
),
Skill_By_Company_Sys as (
	SELECT [SBC].[Map_Skill_ID]
	FROM [Skill].[dbo].[Skill_By_Company] SBC
	WHERE [SBC].[Map_Skill_Type_ID] = @Map_Skill_Type_System
		AND [SBC].[Is_Active] = 1
		AND [SBC].[Company_ID] in (
			SELECT Company_ID
			from TBCompanyID
		)
),
TB2 AS (
	select [MS].[Map_Skill_ID],
		@Map_Skill_Type_System as [Map_Skill_Type_ID],
		'System' as [Map_Skill_Type_Name],
		[Skill_Group_ID] = CASE
			WHEN [SG].[Parent_Skill_Group_ID] = 0 THEN [MS].[Skill_Group_ID]
			ELSE [SG].[Parent_Skill_Group_ID]
		END,
		[SG].[Skill_Group_Name],
		[Sub_Skill_Group_ID] = CASE
			WHEN [SG].[Parent_Skill_Group_ID] <> 0 THEN [MS].[Skill_Group_ID]
			ELSE 0
		END,
		[SG].[Sub_Skill_Group_Name],
		[MS].[Skill_ID],
		[SK].[Skill_Name],
		[Is_Active] = 0
	FROM [dbo].[Map_Skill] MS
		LEFT JOIN [dbo].[Skill] SK ON [SK].[Skill_ID] = [MS].[Skill_ID]
		LEFT JOIN Skill_group SG ON [SG].[Skill_Group_ID] = MS.[Skill_Group_ID]
	WHERE [MS].[Is_Delete] = 0
		AND [MS].[Is_Active] = 1
		AND [MS].[Map_Skill_ID] NOT IN (
			select Map_Skill_ID
			from Skill_By_Company_Sys
		)
),
Skill_By_Company_com as (
	SELECT [SBC].[Map_Skill_ID]
	FROM [Skill].[dbo].[Skill_By_Company] SBC
	WHERE [SBC].[Map_Skill_Type_ID] = @Map_Skill_Type_System
		AND [SBC].[Is_Active] = 1
		AND [SBC].[Company_ID] in (
			SELECT Company_ID
			from TBCompanyID
		)
),
Skill_Groups as (
	SELECT [SSG].[Skill_Group_ID],
		[SSG].[Parent_Skill_Group_ID],
		[Skill_Group_Name] = CASE
			WHEN [SSG].[Parent_Skill_Group_ID] = 0 THEN [SSG].[Skill_Group_Name]
			ELSE (
				SELECT TOP (1) [dbo].[Skill_Group].[Skill_Group_Name]
				FROM [dbo].[Skill_Group]
				WHERE [dbo].[Skill_Group].[Skill_Group_ID] = [SSG].[Parent_Skill_Group_ID]
			)
		END,
		[Sub_Skill_Group_Name] = CASE
			WHEN [SSG].[Parent_Skill_Group_ID] <> 0 THEN [SSG].[Skill_Group_Name]
			ELSE ''
		END
	FROM [dbo].[Skill_Group] SSG
),
TB3 AS (
	select [MS].[Map_Skill_ID],
		@Map_Skill_Type_System as [Map_Skill_Type_ID],
		'System' as [Map_Skill_Type_Name],
		[Skill_Group_ID] = CASE
			WHEN [SG].[Parent_Skill_Group_ID] = 0 THEN [MS].[Skill_Group_ID]
			ELSE [SG].[Parent_Skill_Group_ID]
		END,
		[SG].[Skill_Group_Name],
		[Sub_Skill_Group_ID] = CASE
			WHEN [SG].[Parent_Skill_Group_ID] <> 0 THEN [MS].[Skill_Group_ID]
			ELSE 0
		END,
		[SG].[Sub_Skill_Group_Name],
		[MS].[Skill_ID],
		[SK].[Skill_Name],
		[Is_Active] = 1

	FROM [dbo].[Map_Skill] MS
		LEFT JOIN [dbo].[Skill] SK ON [SK].[Skill_ID] = [MS].[Skill_ID]
		LEFT JOIN Skill_group SG ON [SG].[Skill_Group_ID] = MS.[Skill_Group_ID]
	WHERE [MS].[Is_Delete] = 0
		AND [MS].[Is_Active] = 1
		AND [MS].[Map_Skill_ID] IN (
			select Map_Skill_ID
			from Skill_By_Company_Sys
		)
),
final as (
	select Map_Skill_ID,
		Map_Skill_Type_ID,
		Map_Skill_Type_Name,
		Skill_Group_ID,
		Skill_Group_Name,
		Sub_Skill_Group_ID,
		Sub_Skill_Group_Name,
		Skill_ID,
		Skill_Name,
		Is_Active
	From TB1
	UNION
	select Map_Skill_ID,
		Map_Skill_Type_ID,
		Map_Skill_Type_Name,
		Skill_Group_ID,
		Skill_Group_Name,
		Sub_Skill_Group_ID,
		Sub_Skill_Group_Name,
		Skill_ID,
		Skill_Name,
		Is_Active
	From TB2
	UNION
	select Map_Skill_ID,
		Map_Skill_Type_ID,
		Map_Skill_Type_Name,
		Skill_Group_ID,
		Skill_Group_Name,
		Sub_Skill_Group_ID,
		Sub_Skill_Group_Name,
		Skill_ID,
		Skill_Name,
		Is_Active
	From TB3
)
select *
from final
--where Is_Active = 1 
  
--where Map_Skill_Type_ID = 2