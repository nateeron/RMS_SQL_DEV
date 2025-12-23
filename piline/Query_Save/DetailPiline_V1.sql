DECLARE @DateFrom DATETIME = NULL;
DECLARE @DateTo   DATETIME = NULL;
DECLARE @Project_Position_ID INT = 3111;
DECLARE @Company_ID INT = 3357;

-- แปลง '' → NULL
DECLARE @DateFromStr VARCHAR(30) = '';
DECLARE @DateToStr   VARCHAR(30) = '';

SET @DateFrom = TRY_CONVERT(DATETIME, NULLIF(@DateFromStr, ''));
SET @DateTo   = TRY_CONVERT(DATETIME, NULLIF(@DateToStr, ''));
;WITH AllData AS (
    -- MAP
    SELECT
        m.Map_Can_Pile_Com_ID,
        m.Candidate_ID,
        m.Project_Position_ID,
        m.Pipeline_ID,
        m.Company_ID,
        m.Created_Date AS Created_Date,
        'MAP' AS SourceType
    FROM [Pipeline].[dbo].[Map_Can_Pile_Com] m
    WHERE 
        m.Is_Active = 1
        AND m.Is_Delete = 0
        AND m.Company_ID = @Company_ID
        AND (
               ( @DateFrom IS NULL AND @DateTo IS NULL )
            OR ( @DateFrom IS NOT NULL AND @DateTo IS NULL
                 AND m.Created_Date >= @DateFrom )
            OR ( @DateFrom IS NULL AND @DateTo IS NOT NULL
                 AND m.Created_Date < DATEADD(DAY, 1, @DateTo) )
            OR ( @DateFrom IS NOT NULL AND @DateTo IS NOT NULL
                 AND m.Created_Date >= @DateFrom
                 AND m.Created_Date < DATEADD(DAY, 1, @DateTo) )
        )

    UNION ALL

    -- HISTORY
    SELECT
        h.Map_Can_Pile_Com_ID,
        h.Candidate_ID,
        h.Project_Position_ID,
        h.Pipeline_ID,
        h.Company_ID,
        h.Created_Date_His AS Created_Date,
        'HISTORY' AS SourceType
    FROM [Pipeline].[dbo].[His_Can_Pile_Com] h
    WHERE 
        h.Is_Active = 1
        AND h.Is_Delete = 0
        AND h.Company_ID = @Company_ID
        AND (
               ( @DateFrom IS NULL AND @DateTo IS NULL )
            OR ( @DateFrom IS NOT NULL AND @DateTo IS NULL
                 AND h.Created_Date_His >= @DateFrom )
            OR ( @DateFrom IS NULL AND @DateTo IS NOT NULL
                 AND h.Created_Date_His < DATEADD(DAY, 1, @DateTo) )
            OR ( @DateFrom IS NOT NULL AND @DateTo IS NOT NULL
                 AND h.Created_Date_His >= @DateFrom
                 AND h.Created_Date_His < DATEADD(DAY, 1, @DateTo) )
        )
),
Ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY Candidate_ID, Project_Position_ID
            ORDER BY Created_Date DESC
        ) AS rn
    FROM AllData
)

SELECT
    Map_Can_Pile_Com_ID,
    Candidate_ID,
    Project_Position_ID,
    r.Pipeline_ID,
    r.Company_ID,
    r.Created_Date,
    SourceType,
	p.Pipeline_Name
FROM Ranked r
LEFT JOIN  [Pipeline].[dbo].[Pipeline] p ON P.Pipeline_ID = r.Pipeline_ID
WHERE rn = 1 
and Project_Position_ID = @Project_Position_ID
--ORDER BY Created_Date DESC;


--use Pipeline
--GO
--exec [sp_Get_Pipeline_By_ComID] 3357;
--exec [sp_Get_Candidate_By_Map_Can_Pile] 4,3111,3357;

--use Candidate
--GO
--[sp_Get_Candidate_For_Pipe_By_ID] 5021;