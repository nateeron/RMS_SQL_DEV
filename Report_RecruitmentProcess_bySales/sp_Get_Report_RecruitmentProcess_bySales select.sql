USE [Pipeline]
GO
/****** Object:  StoredProcedure [dbo].[sp_Get_Report_RecruitmentProcess_bySales]    Script Date: 2/9/2026 11:29:53 AM ******/

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- sp_Get_Report_RecruitmentProcess_bySales @Company_ID = 3357 ,@Position_ID_str ='43,75,36,79' , @Client_ID_str ='3392,3441'
-- sp_Get_Report_RecruitmentProcess_bySales  @Company_ID = 3357 , @Client_ID_str ='3392,3441'
-- sp_Get_Report_RecruitmentProcess_bySales  @Company_ID = 3357 , @DateFromStr ='07 jun 2025'
-- sp_Get_Report_RecruitmentProcess_bySales 1
-- =============================================
	-- Add the parameters for the stored procedure here
	DECLARE @Company_ID INT = 2,
    @Owner_ID_str  NVARCHAR(500) = NULL,
    @Client_ID_str  NVARCHAR(500) = NULL,
    @Position_ID_str NVARCHAR(500) = NULL,
    @DateFromStr VARCHAR(30) =NULL,
    @DateToStr   VARCHAR(30) = NULL
	

	-------------------------------------------------------
    -- Date convert
    -------------------------------------------------------
    DECLARE @DateFrom DATETIME = TRY_CONVERT(DATETIME, NULLIF(@DateFromStr, ''));
    DECLARE @DateTo   DATETIME = TRY_CONVERT(DATETIME, NULLIF(@DateToStr, ''));


    -------------------------------------------------------
    -- Pipeline Type
    -------------------------------------------------------
    DECLARE @Pipeline_Type_ID INT = 0;
    SELECT TOP 1 @Pipeline_Type_ID = PT.Pipeline_Type_ID
    FROM dbo.Pipeline_Type PT
    WHERE PT.Pipeline_Type_Name = 'System';

    -------------------------------------------------------
    -- Pipelines list (แทน #PipelineTemp)
    -------------------------------------------------------
    DECLARE @Pipelines TABLE (
        Pipeline_ID INT,
        Pipeline_Name NVARCHAR(100),
        Priority INT
    );

    INSERT INTO @Pipelines (Pipeline_ID, Pipeline_Name, Priority)
    SELECT
        P.Pipeline_ID,
        P.Pipeline_Name,
        P.Number_Step
    FROM dbo.Pipeline P
    WHERE
    (
        P.Pipeline_Type_ID = @Pipeline_Type_ID
        OR (P.Pipeline_Type_ID <> @Pipeline_Type_ID AND P.Company_ID = @Company_ID)
    )
    AND P.Is_Active = 1
    AND P.Is_Delete = 0;

    -------------------------------------------------------
    -- Dynamic SQL variables
    -------------------------------------------------------
    DECLARE @SQL NVARCHAR(MAX) = N'';
    DECLARE @SelectColumns NVARCHAR(MAX) = N'';
    DECLARE @TotalAllExpression NVARCHAR(MAX) = N'';

    DECLARE @Pipeline_ID INT;
    DECLARE @Pipeline_Name NVARCHAR(100);
    DECLARE @EscapedPipelineName NVARCHAR(200);
    DECLARE @ColNum INT = 1;

    -------------------------------------------------------
    -- Build dynamic columns (cursor)
    -------------------------------------------------------
    DECLARE pipeline_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT Pipeline_ID, Pipeline_Name
    FROM @Pipelines
    ORDER BY Priority;

    OPEN pipeline_cursor;
    FETCH NEXT FROM pipeline_cursor INTO @Pipeline_ID, @Pipeline_Name;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @SelectColumns <> N'' SET @SelectColumns += N', ';

        SET @EscapedPipelineName = REPLACE(@Pipeline_Name, N'''', N''''''); -- escape '

        SET @SelectColumns +=
              CAST(@Pipeline_ID AS NVARCHAR(10)) + N' AS collumID' + CAST(@ColNum AS NVARCHAR(10))
            + N', ''' + @EscapedPipelineName + N''' AS collumName' + CAST(@ColNum AS NVARCHAR(10))
            + N', SUM(CASE WHEN Pipeline_ID = ' + CAST(@Pipeline_ID AS NVARCHAR(10)) +
              N' THEN 1 ELSE 0 END) AS collumCount' + CAST(@ColNum AS NVARCHAR(10));
			  
        SET @ColNum += 1;
        FETCH NEXT FROM pipeline_cursor INTO @Pipeline_ID, @Pipeline_Name;
    END;

    CLOSE pipeline_cursor;
    DEALLOCATE pipeline_cursor;

    -------------------------------------------------------
    -- Total_All
    -------------------------------------------------------
    DECLARE @PipelineIdList NVARCHAR(MAX);

	SELECT @PipelineIdList =
	    STUFF((
	        SELECT N',' + CAST(p.Pipeline_ID AS NVARCHAR(10))
	        FROM @Pipelines p
	        ORDER BY p.Priority
	        FOR XML PATH(''), TYPE
	    ).value('.', 'NVARCHAR(MAX)'), 1, 1, N'');
	
	-- กันกรณีไม่มี pipeline
	IF @PipelineIdList IS NULL OR @PipelineIdList = N''
	    SET @PipelineIdList = N'-1';
	
	SET @TotalAllExpression =
	    N'SUM(CASE WHEN Pipeline_ID IN (' + @PipelineIdList + N') THEN 1 ELSE 0 END) AS Total_All';
    -------------------------------------------------------
    -- Final Dynamic SQL (Owner join "เหมือนเดิม" ผ่าน Candidate C)
    -------------------------------------------------------
    
    ;WITH AllData AS (
        -- MAP
        SELECT
            m.Map_Can_Pile_Com_ID,
            m.Candidate_ID,
            m.Project_Position_ID,
            m.Pipeline_ID,
            m.Company_ID,
            m.Updated_Date AS Created_Date,
            'MAP' AS SourceType
        FROM Pipeline.dbo.Map_Can_Pile_Com m
        WHERE m.Is_Active = 1
          AND m.Is_Delete = 0
          AND m.Company_ID = @Company_ID
          AND (
                ( @DateFrom IS NULL AND @DateTo IS NULL )
             OR ( @DateFrom IS NOT NULL AND @DateTo IS NULL AND m.Updated_Date >= @DateFrom )
             OR ( @DateFrom IS NULL AND @DateTo IS NOT NULL AND m.Updated_Date < DATEADD(DAY,1,@DateTo) )
             OR ( @DateFrom IS NOT NULL AND @DateTo IS NOT NULL
                  AND m.Updated_Date >= @DateFrom
                  AND m.Updated_Date < DATEADD(DAY,1,@DateTo) )
          )

        UNION ALL

        -- HISTORY
        SELECT
            h.Map_Can_Pile_Com_ID,
            h.Candidate_ID,
            h.Project_Position_ID,
            h.Pipeline_ID,
            h.Company_ID,
            h.Updated_Date AS Created_Date,
            'HISTORY' AS SourceType
        FROM Pipeline.dbo.His_Can_Pile_Com h
        WHERE h.Is_Active = 1
          AND h.Is_Delete = 0
          AND h.Company_ID = @Company_ID
          AND (
                ( @DateFrom IS NULL AND @DateTo IS NULL )
             OR ( @DateFrom IS NOT NULL AND @DateTo IS NULL AND h.Updated_Date >= @DateFrom )
             OR ( @DateFrom IS NULL AND @DateTo IS NOT NULL AND h.Updated_Date < DATEADD(DAY,1,@DateTo) )
             OR ( @DateFrom IS NOT NULL AND @DateTo IS NOT NULL
                  AND h.Updated_Date >= @DateFrom
                  AND h.Updated_Date < DATEADD(DAY,1,@DateTo) )
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
       -- WHERE rn = 1
       
		
		  
    ),
    -- Get Company Type ID for Client
    CompanyTypeClient AS (
        SELECT TOP 1 Company_Type_ID
        FROM Company.dbo.Company_Type
        WHERE Company_Type_Name = 'Client'
    ),
    -- Get Position details
    P_Position AS (
        SELECT Position_ID, Position_Name, 2 AS Position_By_Com_Type_ID
        FROM RMS_Position.dbo.Position
        UNION
        SELECT Position_Temp_ID AS Position_ID, Position_Name, 1 AS Position_By_Com_Type_ID
        FROM RMS_Position.dbo.Position_Temp
    ),
    -- Get Project Position with Client and Position info
     ProjectPositionInfo AS (
        SELECT 
            PP.Project_Position_ID,
            COM.Company_ID AS Client_ID,
            COM.Company_Name AS Client_Name,
            P.Position_ID,
            CASE WHEN P.Position_Name IS NOT NULL THEN P.Position_Name ELSE '-' END AS Position_Name,
			CASE WHEN [MUP].[Owner_Name] IS NOT NULL THEN [MUP].[Owner_Name] ELSE '-' END AS Sale_Name,
			[MUP].[Person_ID] AS Sale_ID,
            PP.Job_Req_Date
        FROM Company.dbo.Project_Position PP
        LEFT JOIN Company.dbo.Map_Comp_Position MCPP ON MCPP.Project_Position_ID = PP.Project_Position_ID 
            AND MCPP.Is_Active = 1 AND MCPP.Is_Delete = 0
        LEFT JOIN Company.dbo.Company COM ON COM.Company_ID = MCPP.Company_ID
            AND COM.Company_Type_ID = (SELECT Company_Type_ID FROM CompanyTypeClient)
            AND COM.Is_Active = 1 AND COM.Is_Delete = 0
		LEFT JOIN (
				SELECT [MUP].[Project_Position_ID],
					[Owner_Name] = [P].[Full_Name],
					[MUP].[Person_ID],
					[MUP].[Is_Active]
				FROM [Company].[dbo].[Map_User_PrjPosi] MUP
					LEFT JOIN [Person].[dbo].[Person] P ON [P].[Person_ID] = [MUP].[Person_ID]
			) MUP ON [MUP].[Project_Position_ID] = [PP].[Project_Position_ID] AND [MUP].[Is_Active] = 1
        LEFT JOIN P_Position P ON P.Position_ID = (
            CASE 
                WHEN PP.Position_By_Comp_ID = 0 OR PP.Position_By_Comp_ID IS NULL THEN PP.Position_ID
                ELSE (
                    SELECT CASE WHEN PB.Position_By_Com_Type_ID = 1 THEN 
                        (SELECT Position_Temp_ID FROM RMS_Position.dbo.Position_Temp WHERE Position_Temp_ID = PB.Position_ID)
                    ELSE PB.Position_ID END
                    FROM RMS_Position.dbo.Position_By_Comp PB 
                    WHERE PB.Position_By_Com_ID = PP.Position_By_Comp_ID
                )
            END
        )
        AND P.Position_By_Com_Type_ID = (
            CASE WHEN PP.Position_By_Comp_ID = 0 OR PP.Position_By_Comp_ID IS NULL THEN 2
            ELSE (SELECT Position_By_Com_Type_ID FROM RMS_Position.dbo.Position_By_Comp WHERE Position_By_Com_ID = PP.Position_By_Comp_ID)
            END
        )
        WHERE PP.Is_Delete = 0
    ),
    OwnerData AS (
        SELECT
            MC.Map_Can_Pile_Com_ID,
            MC.Candidate_ID,
            MC.Pipeline_ID,
            PL.Pipeline_Name,
            MC.Project_Position_ID,
            LUC.Owner_ID,

            -- ✅ ใช้ CONCAT แบบเดิม: ถ้าไม่มี owner จะได้ '' '' (space)
            CONCAT(
                LTRIM(RTRIM(T_Own.Title_Name)), ' ', Own.Full_Name
            ) AS Owner_Name,
            
            -- Client and Position info
			PPI.Sale_Name,
			PPI.Sale_ID,
            PPI.Client_ID,
            PPI.Client_Name,
            PPI.Position_ID,
            PPI.Position_Name,
            PPI.Job_Req_Date

        FROM LatestPipelineData MC

        -- ✅ สำคัญ: ต้องผ่าน Candidate ที่ Is_Deleted = 0 ก่อน (เหมือนเดิม)
        LEFT JOIN Candidate.dbo.Candidate C
               ON C.Candidate_ID = MC.Candidate_ID
              AND C.Is_Deleted = 0

        -- ✅ สำคัญ: join LUC ผ่าน C.Candidate_ID (ไม่ใช่ MC.Candidate_ID)
        LEFT JOIN (
            SELECT
                tt.Update_By AS Owner_ID,
                tt.Candidate_ID
            FROM Candidate.dbo.Log_Update_Candidate tt
            INNER JOIN (
                SELECT
                    ss.Candidate_ID,
                    MAX(ss.Update_Date) AS MaxDateTime
                FROM Candidate.dbo.Log_Update_Candidate ss
                WHERE ss.Is_Employee = 0
                  AND ss.Is_Terminate = 0
                GROUP BY ss.Candidate_ID
            ) groupedtt
                ON tt.Candidate_ID = groupedtt.Candidate_ID
               AND tt.Update_Date = groupedtt.MaxDateTime
               AND tt.Is_Employee = 0
               AND tt.Is_Terminate = 0
        ) LUC ON LUC.Candidate_ID = C.Candidate_ID

        LEFT JOIN Person.dbo.Person Own
               ON Own.Person_ID = LUC.Owner_ID
        LEFT JOIN Title.dbo.Title T_Own
               ON T_Own.Title_ID = Own.Title_ID
        LEFT JOIN Pipeline.dbo.Pipeline PL
               ON PL.Pipeline_ID = MC.Pipeline_ID
        LEFT JOIN ProjectPositionInfo PPI
               ON PPI.Project_Position_ID = MC.Project_Position_ID

        WHERE
           ( @Owner_ID_str IS NULL
            OR @Owner_ID_str = ''
            OR LTRIM(RTRIM(@Owner_ID_str)) = ''
            OR PPI.Sale_ID IN (
                SELECT CAST(LTRIM(RTRIM(value)) AS INT)
                FROM STRING_SPLIT(@Owner_ID_str, ',')
                WHERE LTRIM(RTRIM(value)) <> ''
                  AND ISNUMERIC(LTRIM(RTRIM(value))) = 1
            )
			)
			AND ( @Client_ID_str IS NULL
            OR @Client_ID_str = ''
            OR LTRIM(RTRIM(@Client_ID_str)) = ''
            OR PPI.Client_ID IN (
                SELECT CAST(LTRIM(RTRIM(value)) AS INT)
                FROM STRING_SPLIT(@Client_ID_str, ',')
                WHERE LTRIM(RTRIM(value)) <> ''
                  AND ISNUMERIC(LTRIM(RTRIM(value))) = 1
				) 
			)
    )
    SELECT
        MAX(Sale_Name) AS Sale_Name,
        MAX(Sale_ID) AS Sale_ID,
        MAX(Client_ID) AS Client_ID,
        MAX(Client_Name) AS Client_Name,
        Position_ID,
        MAX(Project_Position_ID) AS Project_Position_ID,
        MAX(Position_Name) AS Position_Name,
        MAX(Job_Req_Date) AS Job_Req_Date,  
		
		1 AS collumID1, 
		'Candidates' AS collumName1, 
		SUM(CASE WHEN Pipeline_ID = 1 THEN 1 ELSE 0 END) AS collumCount1, 
		6 AS collumID2, 'RSO Sent to Client' AS collumName2, 
		SUM(CASE WHEN Pipeline_ID = 6 THEN 1 ELSE 0 END) AS collumCount2, 
		7 AS collumID3, 'Appointment' AS collumName3, 
		SUM(CASE WHEN Pipeline_ID = 7 THEN 1 ELSE 0 END) AS collumCount3, 
		8 AS collumID4, 'Pass' AS collumName4, 
		SUM(CASE WHEN Pipeline_ID = 8 THEN 1 ELSE 0 END) AS collumCount4, 
		2 AS collumID5, 'Sign Contract' AS collumName5, 
		SUM(CASE WHEN Pipeline_ID = 2 THEN 1 ELSE 0 END) AS collumCount5, 
		3 AS collumID6, 'Terminate' AS collumName6, 
		SUM(CASE WHEN Pipeline_ID = 3 THEN 1 ELSE 0 END) AS collumCount6, 
		4 AS collumID7, 'Drop' AS collumName7, 
		SUM(CASE WHEN Pipeline_ID = 4 THEN 1 ELSE 0 END) AS collumCount7, 
		SUM(CASE WHEN Pipeline_ID IN (1,6,7,8,2,3,4) THEN 1 ELSE 0 END) AS Total_All
    FROM OwnerData
	WHERE Position_ID IS NOT NULL and Client_ID IS NOT NULL
	AND (@Position_ID_str IS NULL
		 OR @Position_ID_str = ''
		 OR LTRIM(RTRIM(@Position_ID_str)) = ''
		 OR Position_ID IN (
									 SELECT CAST(LTRIM(RTRIM(value)) AS INT)
									 FROM STRING_SPLIT(@Position_ID_str, ',')
									 WHERE LTRIM(RTRIM(value)) <> ''
									 AND ISNUMERIC(LTRIM(RTRIM(value))) = 1
								)
		 )
	GROUP BY Position_ID,Client_ID
    ORDER BY Position_ID;
   


  