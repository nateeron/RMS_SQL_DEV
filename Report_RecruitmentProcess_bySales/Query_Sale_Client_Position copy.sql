USE [Company]
GO
-- =============================================
-- Query หา Sale_Name, Sale_ID, Client_ID, Client_Name, Position_ID, Project_Position_ID, Position_Name
-- + Job_Req_Date + การคำนวณ Pipeline (collumID/collumName/collumCount, Total_All)
-- ใช้การหาเดียวกันกับ asdasd.sql: แยก #TempTable แล้ว JOIN ชั้นเดียว
-- =============================================
-- ตัวอย่าง: nui asdasd, 3862, 3396, กกกก, 16, 3099, HR Officer, Job_Req_Date, collumID1, collumName1, collumCount1, ... Total_All
-- =============================================

DECLARE @Company_ID   INT = 3357;
DECLARE @DateFromStr  VARCHAR(30) = NULL;
DECLARE @DateToStr    VARCHAR(30) = NULL;

DECLARE @DateFrom DATETIME = TRY_CONVERT(DATETIME, NULLIF(@DateFromStr, ''));
DECLARE @DateTo   DATETIME = TRY_CONVERT(DATETIME, NULLIF(@DateToStr, ''));

-- ----- Pipeline list + dynamic columns (เหมือน aaasss) -----
DECLARE @Pipeline_Type_ID INT = 0;
SELECT TOP 1 @Pipeline_Type_ID = PT.Pipeline_Type_ID
FROM [Pipeline].[dbo].[Pipeline_Type] PT
WHERE PT.Pipeline_Type_Name = 'System';

DECLARE @Pipelines TABLE (Pipeline_ID INT, Pipeline_Name NVARCHAR(100), Priority INT);
INSERT INTO @Pipelines (Pipeline_ID, Pipeline_Name, Priority)
SELECT P.Pipeline_ID, P.Pipeline_Name, P.Number_Step
FROM [Pipeline].[dbo].[Pipeline] P
WHERE (P.Pipeline_Type_ID = @Pipeline_Type_ID OR (P.Pipeline_Type_ID <> @Pipeline_Type_ID AND P.Company_ID = @Company_ID))
  AND P.Is_Active = 1 AND P.Is_Delete = 0;

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

-- ----- 1) ลบ #TempTable ถ้ามีเหลือจากรันก่อน -----
IF OBJECT_ID('tempdb..#T_PP') IS NOT NULL DROP TABLE #T_PP;
IF OBJECT_ID('tempdb..#T_MapCompPosition') IS NOT NULL DROP TABLE #T_MapCompPosition;
IF OBJECT_ID('tempdb..#T_MapProject') IS NOT NULL DROP TABLE #T_MapProject;
IF OBJECT_ID('tempdb..#T_MapSite') IS NOT NULL DROP TABLE #T_MapSite;
IF OBJECT_ID('tempdb..#T_MapBranch') IS NOT NULL DROP TABLE #T_MapBranch;
IF OBJECT_ID('tempdb..#T_Owner') IS NOT NULL DROP TABLE #T_Owner;
IF OBJECT_ID('tempdb..#T_ProjectPositionInfo') IS NOT NULL DROP TABLE #T_ProjectPositionInfo;
IF OBJECT_ID('tempdb..#T_AllPipelineData') IS NOT NULL DROP TABLE #T_AllPipelineData;

-- ----- 2) สร้าง Temp Tables (หลักการเดียวกับ asdasd.sql) -----

-- 2.1) #T_PP = Project_Position + Position (มี Position_ID, Position_Name, Job_Req_Date)
SELECT
    PP.Project_Position_ID,
    P.Position_ID,
    Position_Name = CASE WHEN P.Position_Name IS NOT NULL THEN P.Position_Name ELSE '-' END,
    PP.Job_Req_Date
INTO #T_PP
FROM [Company].[dbo].[Project_Position] PP
LEFT JOIN (
    SELECT P.Position_ID, P.Position_Name, 2 AS Position_By_Com_Type_ID FROM [RMS_Position].[dbo].[Position] P
    UNION
    SELECT PT.Position_Temp_ID, PT.Position_Name, 1 AS Position_By_Com_Type_ID FROM [RMS_Position].[dbo].[Position_Temp] PT
) P ON P.Position_ID = (CASE WHEN PP.Position_By_Comp_ID = 0 OR PP.Position_By_Comp_ID IS NULL THEN PP.Position_ID
    ELSE (SELECT TOP 1 CASE WHEN PB.Position_By_Com_Type_ID = 1 THEN (SELECT TOP 1 PT.Position_Temp_ID FROM [RMS_Position].[dbo].[Position_Temp] PT WHERE PT.Position_Temp_ID = PB.Position_ID) ELSE PB.Position_ID END
        FROM [RMS_Position].[dbo].[Position_By_Comp] PB WHERE PB.Position_By_Com_ID = PP.Position_By_Comp_ID) END)
  AND P.Position_By_Com_Type_ID = (CASE WHEN PP.Position_By_Comp_ID = 0 OR PP.Position_By_Comp_ID IS NULL THEN 2
    ELSE (SELECT TOP 1 PB.Position_By_Com_Type_ID FROM [RMS_Position].[dbo].[Position_By_Comp] PB WHERE PB.Position_By_Com_ID = PP.Position_By_Comp_ID) END)
WHERE PP.Is_Delete = 0;

-- 2.2) #T_MapCompPosition
SELECT MCPP.Project_Position_ID, MCPP.Company_ID
INTO #T_MapCompPosition
FROM [Company].[dbo].[Map_Comp_Position] MCPP
WHERE MCPP.Is_Active = 1 AND MCPP.Is_Delete = 0;

-- 2.3) #T_MapProject
SELECT
    MPP.Project_Position_ID,
    PC.Project_Client_ID, PC.Project_Name, PC.Branch_ID, PC.Branch_Name, PC.Site_ID, PC.Site_Name,
    PC.Comp_Branch_Project, PC.Comp_Branch_Site_Project, PC.Comp_Project, PC.Comp_Site_Project
INTO #T_MapProject
FROM [Company].[dbo].[Map_Project_Position] MPP
LEFT JOIN (
    SELECT
        PC.Project_Client_ID, PC.Project_Name,
        Comp_Project = MCP.Company_ID,
        MBP.Comp_Branch_Project, MSP.Comp_Branch_Site_Project, MSP.Comp_Site_Project,
        MSP.Site_ID, MSP.Site_Name,
        Branch_ID   = CASE WHEN MBP.Branch_ID_Of_Project IS NOT NULL THEN MBP.Branch_ID_Of_Project ELSE MSP.Branch_ID_Of_Site_Project END,
        Branch_Name = CASE WHEN MBP.Branch_Name_Of_Project IS NOT NULL THEN MBP.Branch_Name_Of_Project ELSE MSP.Branch_Name_Of_Site_Project END
    FROM [Company].[dbo].[Project_Client] PC
    LEFT JOIN [Company].[dbo].[Map_Comp_Project] MCP ON MCP.Project_Client_ID = PC.Project_Client_ID AND MCP.Is_Active = 1 AND MCP.Is_Delete = 0
    LEFT JOIN (
        SELECT B.Branch_ID AS Branch_ID_Of_Project, B.Branch_Name AS Branch_Name_Of_Project, MCB.Company_ID AS Comp_Branch_Project, MBP.Project_Client_ID
        FROM [Company].[dbo].[Map_Branch_Project] MBP
        LEFT JOIN [Company].[dbo].[Map_Comp_Branch] MCB ON MCB.Branch_ID = MBP.Branch_ID AND MCB.Is_Active = 1 AND MCB.Is_Delete = 0
        LEFT JOIN [Company].[dbo].[Branch_By_Comp] B ON B.Branch_ID = MBP.Branch_ID AND B.Is_Active = 1 AND B.Is_Delete = 0
        WHERE MBP.Is_Active = 1 AND MBP.Is_Delete = 0
    ) MBP ON MBP.Project_Client_ID = PC.Project_Client_ID
    LEFT JOIN (
        SELECT MSP.Project_Client_ID, S.Site_ID, S.Site_Name, BS.Branch_ID AS Branch_ID_Of_Site_Project, BS.Branch_Name AS Branch_Name_Of_Site_Project, MCS.Company_ID AS Comp_Site_Project, MCB.Company_ID AS Comp_Branch_Site_Project
        FROM [Company].[dbo].[Map_Site_Project] MSP
        LEFT JOIN [Company].[dbo].[Map_Comp_Site] MCS ON MCS.Site_ID = MSP.Site_ID AND MSP.Is_Active = 1 AND MSP.Is_Delete = 0
        LEFT JOIN [Company].[dbo].[Site] S ON S.Site_ID = MSP.Site_ID AND S.Is_Active = 1
        LEFT JOIN [Company].[dbo].[Map_Branch_Site] MBS ON MBS.Site_ID = MSP.Site_ID AND MBS.Is_Active = 1 AND MBS.Is_Delete = 0
        LEFT JOIN [Company].[dbo].[Map_Comp_Branch] MCB ON MCB.Branch_ID = MBS.Branch_ID AND MCB.Is_Active = 1 AND MCB.Is_Delete = 0
        LEFT JOIN [Company].[dbo].[Branch_By_Comp] BS ON BS.Branch_ID = MBS.Branch_ID AND BS.Is_Active = 1
        WHERE MSP.Is_Active = 1 AND MSP.Is_Delete = 0
    ) MSP ON MSP.Project_Client_ID = PC.Project_Client_ID
    WHERE PC.Is_Active = 1 AND PC.Is_Delete = 0
) PC ON PC.Project_Client_ID = MPP.Project_Client_ID
WHERE MPP.Is_Active = 1 AND MPP.Is_Delete = 0;

-- 2.4) #T_MapSite
SELECT MSP.Project_Position_ID, S.Site_ID, S.Site_Name, BS.Branch_ID, BS.Branch_Name, MCS.Company_ID AS Comp_Site, MCB.Company_ID AS Comp_Branch_Site
INTO #T_MapSite
FROM [Company].[dbo].[Map_Site_Position] MSP
LEFT JOIN [Company].[dbo].[Map_Comp_Site] MCS ON MCS.Site_ID = MSP.Site_ID AND MSP.Is_Active = 1 AND MSP.Is_Delete = 0
LEFT JOIN [Company].[dbo].[Site] S ON S.Site_ID = MSP.Site_ID AND S.Is_Active = 1
LEFT JOIN [Company].[dbo].[Map_Branch_Site] MBS ON MBS.Site_ID = MSP.Site_ID AND MBS.Is_Active = 1 AND MBS.Is_Delete = 0
LEFT JOIN [Company].[dbo].[Map_Comp_Branch] MCB ON MCB.Branch_ID = MBS.Branch_ID AND MCB.Is_Active = 1 AND MCB.Is_Delete = 0
LEFT JOIN [Company].[dbo].[Branch_By_Comp] BS ON BS.Branch_ID = MBS.Branch_ID AND BS.Is_Active = 1
WHERE MSP.Is_Active = 1 AND MSP.Is_Delete = 0;

-- 2.5) #T_MapBranch
SELECT MBP.Project_Position_ID, BS.Branch_ID, BS.Branch_Name, MCB.Company_ID AS Comp_Branch
INTO #T_MapBranch
FROM [Company].[dbo].[Map_Branch_Position] MBP
LEFT JOIN [Company].[dbo].[Map_Comp_Branch] MCB ON MCB.Branch_ID = MBP.Branch_ID AND MCB.Is_Active = 1 AND MCB.Is_Delete = 0
LEFT JOIN [Company].[dbo].[Branch_By_Comp] BS ON BS.Branch_ID = MBP.Branch_ID AND BS.Is_Active = 1 AND BS.Is_Delete = 0
WHERE MBP.Is_Active = 1 AND MBP.Is_Delete = 0;

-- 2.6) #T_Owner = Sale
SELECT MUP.Project_Position_ID, Sale_Name = P.Full_Name, Sale_ID = MUP.Person_ID
INTO #T_Owner
FROM [Company].[dbo].[Map_User_PrjPosi] MUP
LEFT JOIN [Person].[dbo].[Person] P ON P.Person_ID = MUP.Person_ID
WHERE MUP.Is_Active = 1;

-- 2.7) #T_ProjectPositionInfo = รวม Sale, Client, Position, Job_Req_Date ต่อ Project_Position (สำหรับ join กับ Pipeline)
SELECT
    pp.Project_Position_ID,
    pp.Position_ID,
    pp.Position_Name,
    pp.Job_Req_Date,
    Client_ID   = COM.Company_ID,
    Client_Name = COM.Company_Name,
    Sale_Name   = CASE WHEN PS.Sale_Name IS NULL THEN '-' ELSE PS.Sale_Name END,
    Sale_ID     = PS.Sale_ID
INTO #T_ProjectPositionInfo
FROM #T_PP pp
LEFT JOIN #T_MapCompPosition MCPP ON MCPP.Project_Position_ID = pp.Project_Position_ID
LEFT JOIN #T_MapProject MPP ON MPP.Project_Position_ID = pp.Project_Position_ID
LEFT JOIN #T_MapSite MSP ON MSP.Project_Position_ID = pp.Project_Position_ID
LEFT JOIN #T_MapBranch MBP ON MBP.Project_Position_ID = pp.Project_Position_ID
INNER JOIN [Company].[dbo].[Company] COM
    ON COM.Company_ID = COALESCE(MCPP.Company_ID, MPP.Comp_Branch_Project, MPP.Comp_Branch_Site_Project, MPP.Comp_Project, MPP.Comp_Site_Project, MSP.Comp_Branch_Site, MSP.Comp_Site, MBP.Comp_Branch)
    AND COM.Company_Type_ID = (SELECT TOP 1 Company_Type_ID FROM [Company].[dbo].[Company_Type] WHERE Company_Type_Name = 'Client')
    AND COM.Is_Active = 1 AND COM.Is_Delete = 0
LEFT JOIN #T_Owner PS ON PS.Project_Position_ID = pp.Project_Position_ID
WHERE (@Company_ID IS NULL OR COM.Com_ID_Of_Com_Type = @Company_ID);

-- 2.8) #T_AllPipelineData = MAP + HISTORY (กรอง Company + วันที่)
SELECT Map_Can_Pile_Com_ID, Candidate_ID, Project_Position_ID, Pipeline_ID, Company_ID, Updated_Date AS Created_Date
INTO #T_AllPipelineData
FROM [Pipeline].[dbo].[Map_Can_Pile_Com] m
WHERE m.Is_Active = 1 AND m.Is_Delete = 0
  AND (@Company_ID IS NULL OR m.Company_ID = @Company_ID)
  AND (
        (@DateFrom IS NULL AND @DateTo IS NULL)
     OR (@DateFrom IS NOT NULL AND @DateTo IS NULL AND m.Updated_Date >= @DateFrom)
     OR (@DateFrom IS NULL AND @DateTo IS NOT NULL AND m.Updated_Date < DATEADD(DAY, 1, @DateTo))
     OR (@DateFrom IS NOT NULL AND @DateTo IS NOT NULL AND m.Updated_Date >= @DateFrom AND m.Updated_Date < DATEADD(DAY, 1, @DateTo))
  )
UNION ALL
SELECT Map_Can_Pile_Com_ID, Candidate_ID, Project_Position_ID, Pipeline_ID, Company_ID, Updated_Date AS Created_Date
FROM [Pipeline].[dbo].[His_Can_Pile_Com] h
WHERE h.Is_Active = 1 AND h.Is_Delete = 0
  AND (@Company_ID IS NULL OR h.Company_ID = @Company_ID)
  AND (
        (@DateFrom IS NULL AND @DateTo IS NULL)
     OR (@DateFrom IS NOT NULL AND @DateTo IS NULL AND h.Updated_Date >= @DateFrom)
     OR (@DateFrom IS NULL AND @DateTo IS NOT NULL AND h.Updated_Date < DATEADD(DAY, 1, @DateTo))
     OR (@DateFrom IS NOT NULL AND @DateTo IS NOT NULL AND h.Updated_Date >= @DateFrom AND h.Updated_Date < DATEADD(DAY, 1, @DateTo))
  );

-- ----- 3) Query สุดท้าย: JOIN Pipeline + ProjectPositionInfo, GROUP BY + dynamic columns -----
SET @SQL = N'
SELECT
    MAX(PPI.Sale_Name)     AS Sale_Name,
    MAX(PPI.Sale_ID)      AS Sale_ID,
    MAX(PPI.Client_ID)    AS Client_ID,
    MAX(PPI.Client_Name)  AS Client_Name,
    PPI.Position_ID       AS Position_ID,
    MAX(PPI.Project_Position_ID) AS Project_Position_ID,
    MAX(PPI.Position_Name) AS Position_Name,
    MAX(PPI.Job_Req_Date) AS Job_Req_Date, ' + @SelectColumns + N', ' + @TotalAllExpression + N'
FROM #T_AllPipelineData MC
LEFT JOIN #T_ProjectPositionInfo PPI ON PPI.Project_Position_ID = MC.Project_Position_ID
WHERE PPI.Position_ID IS NOT NULL
  AND PPI.Client_ID IS NOT NULL
GROUP BY PPI.Position_ID, PPI.Client_ID
ORDER BY PPI.Position_ID, PPI.Client_ID;
';

EXEC sp_executesql @SQL;

-- ----- 4) เช็คและลบ #TempTable -----
IF OBJECT_ID('tempdb..#T_PP') IS NOT NULL DROP TABLE #T_PP;
IF OBJECT_ID('tempdb..#T_MapCompPosition') IS NOT NULL DROP TABLE #T_MapCompPosition;
IF OBJECT_ID('tempdb..#T_MapProject') IS NOT NULL DROP TABLE #T_MapProject;
IF OBJECT_ID('tempdb..#T_MapSite') IS NOT NULL DROP TABLE #T_MapSite;
IF OBJECT_ID('tempdb..#T_MapBranch') IS NOT NULL DROP TABLE #T_MapBranch;
IF OBJECT_ID('tempdb..#T_Owner') IS NOT NULL DROP TABLE #T_Owner;
IF OBJECT_ID('tempdb..#T_ProjectPositionInfo') IS NOT NULL DROP TABLE #T_ProjectPositionInfo;
IF OBJECT_ID('tempdb..#T_AllPipelineData') IS NOT NULL DROP TABLE #T_AllPipelineData;
