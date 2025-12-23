USE Pipeline;
GO

DECLARE @DateFrom DATETIME = NULL;
DECLARE @DateTo   DATETIME = NULL;
DECLARE @Project_Position_ID INT = 3111;
DECLARE @Company_ID INT = 3357;
DECLARE @DateFromStr VARCHAR(30) = '';
DECLARE @DateToStr   VARCHAR(30) = '';
DECLARE @Owner_Name NVARCHAR(100) = '';

-- แปลง '' → NULL
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
       -- AND m.Project_Position_ID = @Project_Position_ID
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
       -- AND h.Project_Position_ID = @Project_Position_ID
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
),
LatestPipelineData AS (
    SELECT
        Map_Can_Pile_Com_ID,
        Candidate_ID,
        Project_Position_ID,
        Pipeline_ID,
        Company_ID,
        Created_Date,
        SourceType
    FROM Ranked
    WHERE rn = 1
	and Project_Position_ID = @Project_Position_ID
	
),
OwnerData AS (
    SELECT
        [MC].[Map_Can_Pile_Com_ID],
        [MC].[Candidate_ID],
        [MC].[Pipeline_ID],
        [MC].[Project_Position_ID],
        [LUC].[Owner_ID],
        CONCAT(LTRIM(RTRIM([T_Own].[Title_Name])) + ' ', [Own].[Full_Name]) AS [Owner_Name]
    FROM LatestPipelineData MC
    LEFT JOIN [Candidate].[dbo].[Candidate] C ON [C].[Candidate_ID] = [MC].[Candidate_ID] AND [C].[Is_Deleted] = 0
    LEFT JOIN (
        SELECT [CAN].*
        FROM (
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
        ) CAN
    ) LUC ON [LUC].[Candidate_ID] = [C].[Candidate_ID]
    LEFT JOIN [Person].[dbo].[Person] Own ON [Own].[Person_ID] = [LUC].[Owner_ID]
    LEFT JOIN [Title].[dbo].[Title] T_Own ON [T_Own].[Title_ID] = [Own].[Title_ID]
    WHERE CONCAT(LTRIM(RTRIM([T_Own].[Title_Name])) + ' ', [Own].[Full_Name]) LIKE '%' + @Owner_Name + '%'
        OR @Owner_Name = ''
)select * from LatestPipelineData
ORDER BY Created_Date DESC;
--SELECT
--    [Owner_Name],
--    SUM(CASE WHEN [Pipeline_ID] = 1 THEN 1 ELSE 0 END) AS [Total_Candidate],
--    SUM(CASE WHEN [Pipeline_ID] = 18 THEN 1 ELSE 0 END) AS [Total_RSO_SentToClient],
--    SUM(CASE WHEN [Pipeline_ID] = 19 THEN 1 ELSE 0 END) AS [Total_Appointment],
--    SUM(CASE WHEN [Pipeline_ID] = 20 THEN 1 ELSE 0 END) AS [Total_Pass],
--    SUM(CASE WHEN [Pipeline_ID] = 2 THEN 1 ELSE 0 END) AS [Total_SignContract],
--    SUM(CASE WHEN [Pipeline_ID] = 3 THEN 1 ELSE 0 END) AS [Total_Terminate],
--    SUM(CASE WHEN [Pipeline_ID] = 4 THEN 1 ELSE 0 END) AS [Total_Drop],
--    SUM(CASE WHEN [Pipeline_ID] IN (1, 18, 19, 20, 2, 3, 4) THEN 1 ELSE 0 END) AS [Total_All]
--FROM OwnerData
--WHERE [Owner_Name] IS NOT NULL
--GROUP BY [Owner_Name]
--ORDER BY [Owner_Name];

