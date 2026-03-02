


DECLARE @Company_ID INT = 3357;

DECLARE 
    @Map_Skill_Type_System INT = 1, -- System
    @Map_Skill_Type_Temp   INT = 2; -- Company

WITH SkillGroup AS (
    SELECT 
        C.Skill_Group_ID,
        C.Parent_Skill_Group_ID,
        Skill_Group_Name = CASE 
            WHEN C.Parent_Skill_Group_ID = 0 OR C.Parent_Skill_Group_ID IS NULL
            THEN C.Skill_Group_Name
            ELSE P.Skill_Group_Name
        END,
        Sub_Skill_Group_Name = CASE 
            WHEN C.Parent_Skill_Group_ID <> 0
            THEN C.Skill_Group_Name
            ELSE NULL
        END
    FROM Skill.dbo.Skill_Group C
    LEFT JOIN Skill.dbo.Skill_Group P
        ON P.Skill_Group_ID = C.Parent_Skill_Group_ID
       AND P.Is_Active = 1
       AND P.Is_Delete = 0
    WHERE C.Is_Active = 1
      AND C.Is_Delete = 0
),
CompanyScope AS (
    SELECT Company_ID
    FROM Company.dbo.Company
    WHERE Company_ID = @Company_ID
       OR Company_Parent_ID = @Company_ID
)
SELECT *
FROM (

    /* ===============================
       1) Company Skill (Temp)
       =============================== */
    SELECT
        MT.Map_Skill_Temp_ID         AS Map_Skill_ID,
        @Map_Skill_Type_Temp         AS Map_Skill_Type_ID,
        'Company'                    AS Map_Skill_Type_Name,

        CASE 
            WHEN SG.Parent_Skill_Group_ID = 0 
            THEN MT.Skill_Group_ID
            ELSE SG.Parent_Skill_Group_ID
        END                          AS Skill_Group_ID,

        SG.Skill_Group_Name,

        CASE 
            WHEN SG.Parent_Skill_Group_ID <> 0 
            THEN MT.Skill_Group_ID
            ELSE 0
        END                          AS Sub_Skill_Group_ID,

        SG.Sub_Skill_Group_Name,

        MT.Skill_Temp_ID             AS Skill_ID,
        SKT.Skill_Name,

        ISNULL(SBC.Is_Active, 0)     AS Is_Active

    FROM Skill.dbo.Map_Skill_Temp MT
    JOIN Skill.dbo.Skill_Temp SKT
        ON SKT.Skill_Temp_ID = MT.Skill_Temp_ID
    LEFT JOIN SkillGroup SG
        ON SG.Skill_Group_ID = MT.Skill_Group_ID
    LEFT JOIN Skill.dbo.Skill_By_Company SBC
        ON SBC.Map_Skill_ID = MT.Map_Skill_Temp_ID
       AND SBC.Map_Skill_Type_ID = @Map_Skill_Type_Temp
       AND SBC.Company_ID IN (SELECT Company_ID FROM CompanyScope)

    WHERE MT.Is_Active = 1
      AND MT.Is_Delete = 0
      AND SKT.Company_ID IN (SELECT Company_ID FROM CompanyScope)
	      UNION ALL

    /* ===============================
       2) System Skill (Inactive)
       =============================== */
    SELECT
        MS.Map_Skill_ID,
        @Map_Skill_Type_System       AS Map_Skill_Type_ID,
        'System'                     AS Map_Skill_Type_Name,

        CASE 
            WHEN SG.Parent_Skill_Group_ID = 0 
            THEN MS.Skill_Group_ID
            ELSE SG.Parent_Skill_Group_ID
        END                          AS Skill_Group_ID,

        SG.Skill_Group_Name,

        CASE 
            WHEN SG.Parent_Skill_Group_ID <> 0 
            THEN MS.Skill_Group_ID
            ELSE 0
        END                          AS Sub_Skill_Group_ID,

        SG.Sub_Skill_Group_Name,

        MS.Skill_ID,
        SK.Skill_Name,

        0                            AS Is_Active

    FROM Skill.dbo.Map_Skill MS
    JOIN Skill.dbo.Skill SK
        ON SK.Skill_ID = MS.Skill_ID
    LEFT JOIN SkillGroup SG
        ON SG.Skill_Group_ID = MS.Skill_Group_ID

    WHERE MS.Is_Active = 1
      AND MS.Is_Delete = 0
      AND NOT EXISTS (
            SELECT 1
            FROM Skill.dbo.Skill_By_Company SBC
            WHERE SBC.Map_Skill_ID = MS.Map_Skill_ID
              AND SBC.Map_Skill_Type_ID = @Map_Skill_Type_System
              AND SBC.Is_Active = 1
              AND SBC.Company_ID IN (SELECT Company_ID FROM CompanyScope)
      )

	      UNION ALL

    /* ===============================
       3) System Skill (Active)
       =============================== */
    SELECT
        MS.Map_Skill_ID,
        @Map_Skill_Type_System       AS Map_Skill_Type_ID,
        'System'                     AS Map_Skill_Type_Name,

        CASE 
            WHEN SG.Parent_Skill_Group_ID = 0 
            THEN MS.Skill_Group_ID
            ELSE SG.Parent_Skill_Group_ID
        END                          AS Skill_Group_ID,

        SG.Skill_Group_Name,

        CASE 
            WHEN SG.Parent_Skill_Group_ID <> 0 
            THEN MS.Skill_Group_ID
            ELSE 0
        END                          AS Sub_Skill_Group_ID,

        SG.Sub_Skill_Group_Name,
        MS.Skill_ID,
        SK.Skill_Name,
        1 AS Is_Active

    FROM Skill.dbo.Map_Skill MS
    JOIN Skill.dbo.Skill SK
        ON SK.Skill_ID = MS.Skill_ID
    LEFT JOIN SkillGroup SG
        ON SG.Skill_Group_ID = MS.Skill_Group_ID

    WHERE MS.Is_Active = 1
      AND MS.Is_Delete = 0
      AND EXISTS (
            SELECT 1
            FROM Skill.dbo.Skill_By_Company SBC
            WHERE SBC.Map_Skill_ID = MS.Map_Skill_ID
              AND SBC.Map_Skill_Type_ID = @Map_Skill_Type_System
              AND SBC.Is_Active = 1
              AND SBC.Company_ID IN (SELECT Company_ID FROM CompanyScope)
      )

) A
ORDER BY 
    A.Skill_Group_Name,
    A.Sub_Skill_Group_Name,
    A.Skill_Name;
