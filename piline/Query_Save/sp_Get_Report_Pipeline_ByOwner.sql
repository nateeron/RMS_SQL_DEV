USE [Pipeline]
GO

  Declare  @Company_ID INT = 3357,
    @Project_Position_ID INT = 3111,
    @DateFromStr VARCHAR(30) = NULL,
    @DateToStr   VARCHAR(30) = NULL,
    @Owner_Name  NVARCHAR(100) = NULL



    DECLARE @DateFrom DATETIME = NULL;
    DECLARE @DateTo   DATETIME = NULL;

    -- แปลง string → DATETIME
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
       AND (Project_Position_ID = @Project_Position_ID OR @Project_Position_ID = 0)

    ),
    OwnerData AS (
        SELECT
            MC.Map_Can_Pile_Com_ID,
            MC.Candidate_ID,
            MC.Pipeline_ID,
			PL.Pipeline_Name,
            MC.Project_Position_ID,
            LUC.Owner_ID,
            CONCAT(
                LTRIM(RTRIM(T_Own.Title_Name)), ' ', Own.Full_Name
            ) AS Owner_Name
        FROM LatestPipelineData MC
        LEFT JOIN [Candidate].[dbo].[Candidate] C 
               ON C.Candidate_ID = MC.Candidate_ID
              AND C.Is_Deleted = 0
        LEFT JOIN (
            SELECT
                tt.Update_By AS Owner_ID,
                tt.Candidate_ID
            FROM [Candidate].[dbo].[Log_Update_Candidate] tt
            INNER JOIN (
                SELECT
                    ss.Candidate_ID,
                    MAX(ss.Update_Date) AS MaxDateTime
                FROM [Candidate].[dbo].[Log_Update_Candidate] ss
                WHERE ss.Is_Employee = 0
                  AND ss.Is_Terminate = 0
                GROUP BY ss.Candidate_ID
            ) groupedtt
                ON tt.Candidate_ID = groupedtt.Candidate_ID
               AND tt.Update_Date = groupedtt.MaxDateTime
               AND tt.Is_Employee = 0
               AND tt.Is_Terminate = 0
        ) LUC ON LUC.Candidate_ID = C.Candidate_ID
        LEFT JOIN [Person].[dbo].[Person] Own 
               ON Own.Person_ID = LUC.Owner_ID
        LEFT JOIN [Title].[dbo].[Title] T_Own 
               ON T_Own.Title_ID = Own.Title_ID
		Left Join [dbo].[Pipeline] PL 
			ON PL.Pipeline_ID = MC.Pipeline_ID
        WHERE
            @Owner_Name IS NULL
            OR @Owner_Name = ''
            OR CONCAT(
                    LTRIM(RTRIM(T_Own.Title_Name)), ' ', Own.Full_Name
               ) LIKE '%' + @Owner_Name + '%'
    )
    SELECT
		Project_Position_ID,
        Owner_Name,
		Pipeline_ID,
		Pipeline_Name
        --SUM(CASE WHEN Pipeline_ID = 1  THEN 1 ELSE 0 END) AS Total_Candidate,
        --SUM(CASE WHEN Pipeline_ID = 18 THEN 1 ELSE 0 END) AS Total_RSO_SentToClient,
        --SUM(CASE WHEN Pipeline_ID = 19 THEN 1 ELSE 0 END) AS Total_Appointment,
        --SUM(CASE WHEN Pipeline_ID = 20 THEN 1 ELSE 0 END) AS Total_Pass,
        --SUM(CASE WHEN Pipeline_ID = 2  THEN 1 ELSE 0 END) AS Total_SignContract,
        --SUM(CASE WHEN Pipeline_ID = 3  THEN 1 ELSE 0 END) AS Total_Terminate,
        --SUM(CASE WHEN Pipeline_ID = 4  THEN 1 ELSE 0 END) AS Total_Drop,
        --SUM(CASE WHEN Pipeline_ID IN (1,18,19,20,2,3,4) THEN 1 ELSE 0 END) AS Total_All
    FROM OwnerData
    WHERE Owner_Name IS NOT NULL
    --GROUP BY Project_Position_ID,Owner_Name
    ORDER BY Project_Position_ID,Owner_Name;


--SELECT [PL].[Pipeline_ID]
--		  ,[PL].[Pipeline_Name]
--		  ,[PL].[Number_Step]
--		  ,[PL].[Detail]
--		  ,[PL].[Is_Active]
--	FROM [dbo].[Pipeline] PL
--	WHERE  [PL].[Is_Delete] = 0 AND [PL].[Is_Active] = 1

--exec [sp_Get_Report_Pipeline_ByOwner] 3357,3111