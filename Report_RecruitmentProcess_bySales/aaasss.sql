USE [Pipeline]
GO
-- =============================================
-- Query ธรรมดา (ไม่ใช่ Stored Procedure)
-- Recruitment Process Report by Sales
-- แยก Query ใส่ #TempTable แล้ว JOIN ชั้นเดียว สุดท้ายเช็คลบ Temp
-- Output: Sale_Name, Sale_ID, Client_ID, Client_Name, Position_ID, Project_Position_ID, Position_Name + dynamic pipeline columns
-- =============================================
-- เปลี่ยนค่า @Company_ID, @Owner_ID_str, @Client_ID_str, @Position_ID_str, @DateFromStr, @DateToStr ตามต้องการ แล้วรันทั้งก้อน
-- =============================================

DECLARE @Company_ID      INT = 3357,
        @Owner_ID_str    NVARCHAR(500) = NULL,
        @Client_ID_str   NVARCHAR(500) = NULL,
        @Position_ID_str NVARCHAR(500) = NULL,
        @DateFromStr     VARCHAR(30)   = NULL,
        @DateToStr       VARCHAR(30)   = NULL;

DECLARE @DateFrom DATETIME = TRY_CONVERT(DATETIME, NULLIF(@DateFromStr, ''));
DECLARE @DateTo   DATETIME = TRY_CONVERT(DATETIME, NULLIF(@DateToStr, ''));

    -------------------------------------------------------
    -- Pipeline Type (System)
    -------------------------------------------------------
    DECLARE @Pipeline_Type_ID INT = 0;
    SELECT TOP 1 @Pipeline_Type_ID = PT.Pipeline_Type_ID
    FROM dbo.Pipeline_Type PT
    WHERE PT.Pipeline_Type_Name = 'System';

    -------------------------------------------------------
    -- Pipelines list
    -------------------------------------------------------
    DECLARE @Pipelines TABLE (Pipeline_ID INT, Pipeline_Name NVARCHAR(100), Priority INT);
    INSERT INTO @Pipelines (Pipeline_ID, Pipeline_Name, Priority)
    SELECT P.Pipeline_ID, P.Pipeline_Name, P.Number_Step
    FROM dbo.Pipeline P
    WHERE (P.Pipeline_Type_ID = @Pipeline_Type_ID OR (P.Pipeline_Type_ID <> @Pipeline_Type_ID AND P.Company_ID = @Company_ID))
      AND P.Is_Active = 1 AND P.Is_Delete = 0;

    -------------------------------------------------------
    -- Dynamic column building (cursor)
    -------------------------------------------------------
    DECLARE @SQL NVARCHAR(MAX) = N'';
    DECLARE @SelectColumns NVARCHAR(MAX) = N'';
    DECLARE @TotalAllExpression NVARCHAR(MAX) = N'';
    DECLARE @Pipeline_ID INT, @Pipeline_Name NVARCHAR(100), @EscapedPipelineName NVARCHAR(200), @ColNum INT = 1;

    DECLARE pipeline_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT Pipeline_ID, Pipeline_Name FROM @Pipelines ORDER BY Priority;

    OPEN pipeline_cursor;
    FETCH NEXT FROM pipeline_cursor INTO @Pipeline_ID, @Pipeline_Name;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @SelectColumns <> N'' SET @SelectColumns += N', ';
        SET @EscapedPipelineName = REPLACE(@Pipeline_Name, N'''', N'''''');
        SET @SelectColumns +=
            CAST(@Pipeline_ID AS NVARCHAR(10)) + N' AS collumID' + CAST(@ColNum AS NVARCHAR(10))
            + N', ''' + @EscapedPipelineName + N''' AS collumName' + CAST(@ColNum AS NVARCHAR(10))
            + N', SUM(CASE WHEN MC.Pipeline_ID = ' + CAST(@Pipeline_ID AS NVARCHAR(10)) + N' THEN 1 ELSE 0 END) AS collumCount' + CAST(@ColNum AS NVARCHAR(10));
        SET @ColNum += 1;
        FETCH NEXT FROM pipeline_cursor INTO @Pipeline_ID, @Pipeline_Name;
    END;
    CLOSE pipeline_cursor;
    DEALLOCATE pipeline_cursor;

    DECLARE @PipelineIdList NVARCHAR(MAX);
    SELECT @PipelineIdList = STUFF((
        SELECT N',' + CAST(p.Pipeline_ID AS NVARCHAR(10)) FROM @Pipelines p ORDER BY p.Priority
        FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)'), 1, 1, N'');
    IF @PipelineIdList IS NULL OR @PipelineIdList = N'' SET @PipelineIdList = N'-1';
    SET @TotalAllExpression = N'SUM(CASE WHEN MC.Pipeline_ID IN (' + @PipelineIdList + N') THEN 1 ELSE 0 END) AS Total_All';

    -------------------------------------------------------
    -- ลบ #TempTable ถ้ามีเหลือจากรันก่อน
    -------------------------------------------------------
    IF OBJECT_ID('tempdb..#T_ProjectPositionInfo') IS NOT NULL DROP TABLE #T_ProjectPositionInfo;
    IF OBJECT_ID('tempdb..#T_AllPipelineData') IS NOT NULL DROP TABLE #T_AllPipelineData;
    IF OBJECT_ID('tempdb..#T_OwnerLookup') IS NOT NULL DROP TABLE #T_OwnerLookup;

    -------------------------------------------------------
    -- #T_ProjectPositionInfo = Sale, Client, Position ต่อ Project_Position (หลักการเดียวกับ asdasd)
    -------------------------------------------------------
    ;WITH CompanyTypeClient AS (
        SELECT TOP 1 Company_Type_ID
        FROM Company.dbo.Company_Type
        WHERE Company_Type_Name = 'Client'
    ),
    P_Position AS (
        SELECT Position_ID, Position_Name, 2 AS Position_By_Com_Type_ID FROM RMS_Position.dbo.Position
        UNION
        SELECT Position_Temp_ID AS Position_ID, Position_Name, 1 AS Position_By_Com_Type_ID FROM RMS_Position.dbo.Position_Temp
    )
    SELECT
        PP.Project_Position_ID,
        Client_ID   = COM.Company_ID,
        Client_Name = COM.Company_Name,
        P.Position_ID,
        Position_Name = CASE WHEN P.Position_Name IS NOT NULL THEN P.Position_Name ELSE '-' END,
        Sale_Name    = CASE WHEN MUP.Owner_Name IS NOT NULL THEN MUP.Owner_Name ELSE '-' END,
        Sale_ID      = MUP.Person_ID,
        PP.Job_Req_Date
    INTO #T_ProjectPositionInfo
    FROM Company.dbo.Project_Position PP
    LEFT JOIN Company.dbo.Map_Comp_Position MCPP
        ON MCPP.Project_Position_ID = PP.Project_Position_ID AND MCPP.Is_Active = 1 AND MCPP.Is_Delete = 0
    LEFT JOIN Company.dbo.Company COM
        ON COM.Company_ID = MCPP.Company_ID
        AND COM.Company_Type_ID = (SELECT Company_Type_ID FROM CompanyTypeClient)
        AND COM.Is_Active = 1 AND COM.Is_Delete = 0
    LEFT JOIN (
        SELECT MUP.Project_Position_ID, Owner_Name = P.Full_Name, MUP.Person_ID, MUP.Is_Active
        FROM Company.dbo.Map_User_PrjPosi MUP
        LEFT JOIN Person.dbo.Person P ON P.Person_ID = MUP.Person_ID
    ) MUP ON MUP.Project_Position_ID = PP.Project_Position_ID AND MUP.Is_Active = 1
    LEFT JOIN P_Position P
        ON P.Position_ID = (CASE
                WHEN PP.Position_By_Comp_ID = 0 OR PP.Position_By_Comp_ID IS NULL THEN PP.Position_ID
                ELSE (SELECT TOP 1 CASE WHEN PB.Position_By_Com_Type_ID = 1 THEN (SELECT TOP 1 Position_Temp_ID FROM RMS_Position.dbo.Position_Temp WHERE Position_Temp_ID = PB.Position_ID) ELSE PB.Position_ID END
                    FROM RMS_Position.dbo.Position_By_Comp PB WHERE PB.Position_By_Com_ID = PP.Position_By_Comp_ID)
            END)
        AND P.Position_By_Com_Type_ID = (CASE WHEN PP.Position_By_Comp_ID = 0 OR PP.Position_By_Comp_ID IS NULL THEN 2
            ELSE (SELECT TOP 1 Position_By_Com_Type_ID FROM RMS_Position.dbo.Position_By_Comp WHERE Position_By_Comp_ID = PP.Position_By_Comp_ID) END)
    WHERE PP.Is_Delete = 0;

    -------------------------------------------------------
    -- #T_AllPipelineData = MAP + HISTORY (date + Company filter)
    -------------------------------------------------------
    SELECT Map_Can_Pile_Com_ID, Candidate_ID, Project_Position_ID, Pipeline_ID, Company_ID, Updated_Date AS Created_Date, 'MAP' AS SourceType
    INTO #T_AllPipelineData
    FROM Pipeline.dbo.Map_Can_Pile_Com m
    WHERE m.Is_Active = 1 AND m.Is_Delete = 0 AND m.Company_ID = @Company_ID
      AND (
            (@DateFrom IS NULL AND @DateTo IS NULL)
         OR (@DateFrom IS NOT NULL AND @DateTo IS NULL AND m.Updated_Date >= @DateFrom)
         OR (@DateFrom IS NULL AND @DateTo IS NOT NULL AND m.Updated_Date < DATEADD(DAY, 1, @DateTo))
         OR (@DateFrom IS NOT NULL AND @DateTo IS NOT NULL AND m.Updated_Date >= @DateFrom AND m.Updated_Date < DATEADD(DAY, 1, @DateTo))
      )
    UNION ALL
    SELECT Map_Can_Pile_Com_ID, Candidate_ID, Project_Position_ID, Pipeline_ID, Company_ID, Updated_Date AS Created_Date, 'HISTORY' AS SourceType
    FROM Pipeline.dbo.His_Can_Pile_Com h
    WHERE h.Is_Active = 1 AND h.Is_Delete = 0 AND h.Company_ID = @Company_ID
      AND (
            (@DateFrom IS NULL AND @DateTo IS NULL)
         OR (@DateFrom IS NOT NULL AND @DateTo IS NULL AND h.Updated_Date >= @DateFrom)
         OR (@DateFrom IS NULL AND @DateTo IS NOT NULL AND h.Updated_Date < DATEADD(DAY, 1, @DateTo))
         OR (@DateFrom IS NOT NULL AND @DateTo IS NOT NULL AND h.Updated_Date >= @DateFrom AND h.Updated_Date < DATEADD(DAY, 1, @DateTo))
      );

    -------------------------------------------------------
    -- #T_OwnerLookup = Candidate -> Owner (latest from Log_Update_Candidate) + Owner_Name
    -------------------------------------------------------
    ;WITH LatestOwner AS (
        SELECT tt.Candidate_ID, tt.Update_By AS Owner_ID,
               ROW_NUMBER() OVER (PARTITION BY tt.Candidate_ID ORDER BY tt.Update_Date DESC) AS rn
        FROM Candidate.dbo.Log_Update_Candidate tt
        WHERE tt.Is_Employee = 0 AND tt.Is_Terminate = 0
    )
    SELECT
        L.Candidate_ID,
        L.Owner_ID,
        Owner_Name = CONCAT(LTRIM(RTRIM(T_Own.Title_Name)), ' ', Own.Full_Name)
    INTO #T_OwnerLookup
    FROM LatestOwner L
    INNER JOIN Person.dbo.Person Own ON Own.Person_ID = L.Owner_ID
    LEFT JOIN Title.dbo.Title T_Own ON T_Own.Title_ID = Own.Title_ID
    WHERE L.rn = 1;

    -------------------------------------------------------
    -- Final Dynamic SQL: JOIN Temp Tables ชั้นเดียว
    -------------------------------------------------------
    SET @SQL = N'
    SELECT
        MAX(PPI.Sale_Name)     AS Sale_Name,
        MAX(PPI.Sale_ID)       AS Sale_ID,
        MAX(PPI.Client_ID)     AS Client_ID,
        MAX(PPI.Client_Name)   AS Client_Name,
        PPI.Position_ID        AS Position_ID,
        MAX(MC.Project_Position_ID) AS Project_Position_ID,
        MAX(PPI.Position_Name) AS Position_Name,
        MAX(PPI.Job_Req_Date)  AS Job_Req_Date, ' + @SelectColumns + N', ' + @TotalAllExpression + N'
    FROM #T_AllPipelineData MC
    LEFT JOIN Candidate.dbo.Candidate C
        ON C.Candidate_ID = MC.Candidate_ID AND C.Is_Deleted = 0
    LEFT JOIN #T_OwnerLookup LUC ON LUC.Candidate_ID = C.Candidate_ID
    LEFT JOIN Pipeline.dbo.Pipeline PL ON PL.Pipeline_ID = MC.Pipeline_ID
    LEFT JOIN #T_ProjectPositionInfo PPI ON PPI.Project_Position_ID = MC.Project_Position_ID
    WHERE PPI.Position_ID IS NOT NULL
      AND PPI.Client_ID IS NOT NULL
      AND (
            @Owner_ID_str IS NULL OR @Owner_ID_str = '''' OR LTRIM(RTRIM(@Owner_ID_str)) = ''''
            OR PPI.Sale_ID IN (
                SELECT CAST(LTRIM(RTRIM(value)) AS INT)
                FROM STRING_SPLIT(@Owner_ID_str, '','')
                WHERE LTRIM(RTRIM(value)) <> '''' AND ISNUMERIC(LTRIM(RTRIM(value))) = 1
            )
      )
      AND (
            @Client_ID_str IS NULL OR @Client_ID_str = '''' OR LTRIM(RTRIM(@Client_ID_str)) = ''''
            OR PPI.Client_ID IN (
                SELECT CAST(LTRIM(RTRIM(value)) AS INT)
                FROM STRING_SPLIT(@Client_ID_str, '','')
                WHERE LTRIM(RTRIM(value)) <> '''' AND ISNUMERIC(LTRIM(RTRIM(value))) = 1
            )
      )
      AND (
            @Position_ID_str IS NULL OR @Position_ID_str = '''' OR LTRIM(RTRIM(@Position_ID_str)) = ''''
            OR PPI.Position_ID IN (
                SELECT CAST(LTRIM(RTRIM(value)) AS INT)
                FROM STRING_SPLIT(@Position_ID_str, '','')
                WHERE LTRIM(RTRIM(value)) <> '''' AND ISNUMERIC(LTRIM(RTRIM(value))) = 1
            )
      )
    GROUP BY PPI.Position_ID, PPI.Client_ID
    ORDER BY PPI.Position_ID;
    ';

    EXEC sp_executesql @SQL,
        N'@Company_ID INT, @Owner_ID_str NVARCHAR(500), @Client_ID_str NVARCHAR(500), @Position_ID_str NVARCHAR(500)',
        @Company_ID, @Owner_ID_str, @Client_ID_str, @Position_ID_str;

    -------------------------------------------------------
    -- เช็คและลบ #TempTable
    -------------------------------------------------------
    IF OBJECT_ID('tempdb..#T_ProjectPositionInfo') IS NOT NULL DROP TABLE #T_ProjectPositionInfo;
    IF OBJECT_ID('tempdb..#T_AllPipelineData') IS NOT NULL DROP TABLE #T_AllPipelineData;
    IF OBJECT_ID('tempdb..#T_OwnerLookup') IS NOT NULL DROP TABLE #T_OwnerLookup;

