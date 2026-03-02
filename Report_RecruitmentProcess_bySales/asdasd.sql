USE [Company]
GO

-- =============================================
-- Description:  Recruitment Process Report by Company ID
-- แยก query ใส่ #TempTable แล้ว JOIN ชั้นเดียว สุดท้ายเช็คลบ Temp
-- =============================================
-- EXEC [dbo].[sp_Get_RecruitProcess_By_ComID] 3357, '2,3'

-- ----- 1) Parameters -----
DECLARE @Company_ID           INT = 3357,
        @Role_ID              NVARCHAR(100) = '2,3',
        @Pipeline_Type_System  INT = 0,
        @Step_Sign_Contract    INT = 0;

-- ----- 2) Lookup: Pipeline Type "System" & Step "Sign Contract" -----
SET @Pipeline_Type_System = (
    SELECT TOP 1 PLT.Pipeline_Type_ID
    FROM [Pipeline].[dbo].[Pipeline_Type] PLT
    WHERE PLT.Pipeline_Type_Name = 'System'
      AND PLT.Is_Active = 1 AND PLT.Is_Delete = 0
);
SET @Step_Sign_Contract = (
    SELECT TOP 1 PL.Number_Step
    FROM [Pipeline].[dbo].[Pipeline] PL
    WHERE PL.Pipeline_Name = 'Sign Contract'
      AND PL.Company_ID = 0
      AND PL.Pipeline_Type_ID = @Pipeline_Type_System
      AND PL.Is_Active = 1 AND PL.Is_Delete = 0
);

-- ----- 3) ลบ #TempTable ถ้ามีเหลือจากรันก่อน (เช็คก่อนสร้าง) -----
IF OBJECT_ID('tempdb..#T_PP') IS NOT NULL DROP TABLE #T_PP;
IF OBJECT_ID('tempdb..#T_MapCompPosition') IS NOT NULL DROP TABLE #T_MapCompPosition;
IF OBJECT_ID('tempdb..#T_MapProject') IS NOT NULL DROP TABLE #T_MapProject;
IF OBJECT_ID('tempdb..#T_MapSite') IS NOT NULL DROP TABLE #T_MapSite;
IF OBJECT_ID('tempdb..#T_MapBranch') IS NOT NULL DROP TABLE #T_MapBranch;
IF OBJECT_ID('tempdb..#T_PositionLog') IS NOT NULL DROP TABLE #T_PositionLog;
IF OBJECT_ID('tempdb..#T_Owner') IS NOT NULL DROP TABLE #T_Owner;
IF OBJECT_ID('tempdb..#T_Hiring') IS NOT NULL DROP TABLE #T_Hiring;
IF OBJECT_ID('tempdb..#T_OnProcess') IS NOT NULL DROP TABLE #T_OnProcess;
IF OBJECT_ID('tempdb..#T_Candidate') IS NOT NULL DROP TABLE #T_Candidate;

-- ----- 4) สร้าง Temp Tables แยกตามส่วนของ Query -----

-- 4.1) #T_PP = Project_Position + Contract_Type + Position (ข้อมูลหลักตำแหน่ง)
SELECT
    PP.Project_Position_ID,
    Contract_Type_Name   = CT.Contract_Type_Name,
    Position_Name       = P.Position_Name,
    PP.QTY,
    Budget_Min          = REPLACE((SELECT FORMAT(PP.Budget_Min, 'C2')), '$', ''),
    Budget_Max          = REPLACE((SELECT FORMAT(PP.Budget_Max, 'C2')), '$', ''),
    PP.Budget_Negotiate,
    Duration_Of_Contract = CASE WHEN PP.Duration_Of_Contract IS NULL THEN '-' ELSE PP.Duration_Of_Contract END,
    PP.Job_Req_Date,
    PP.Is_Active
INTO #T_PP
FROM [Company].[dbo].[Project_Position] PP
LEFT JOIN (
    SELECT P.Contract_Type_ID, P.Contract_Type_Name, 2 AS Contract_Type_By_Comp_Type_ID
    FROM [RMS_Contract_Type].[dbo].[Contract_Type] P
    UNION
    SELECT PT.Contract_Type_Temp_ID, PT.Contract_Type_Temp_Name, 1 AS Contract_Type_By_Comp_Type_ID
    FROM [RMS_Contract_Type].[dbo].[Contract_Type_Temp] PT
) CT ON CT.Contract_Type_ID = (CASE WHEN PP.Contract_Type_By_Comp_ID = 0 OR PP.Contract_Type_By_Comp_ID IS NULL THEN PP.Contact_Type_ID
    ELSE (SELECT CASE WHEN PB.Contract_Type_By_Comp_Type_ID = 1 THEN (SELECT PT.Contract_Type_Temp_ID FROM [RMS_Contract_Type].[dbo].[Contract_Type_Temp] PT WHERE PT.Contract_Type_Temp_ID = PB.Contract_Type_ID) ELSE PB.Contract_Type_ID END
        FROM [RMS_Contract_Type].[dbo].[Contract_Type_By_Comp] PB WHERE PB.Contract_Type_By_Comp_ID = PP.Contract_Type_By_Comp_ID) END)
  AND CT.Contract_Type_By_Comp_Type_ID = (CASE WHEN PP.Contract_Type_By_Comp_ID = 0 OR PP.Contract_Type_By_Comp_ID IS NULL THEN 2
    ELSE (SELECT PB.Contract_Type_By_Comp_Type_ID FROM [RMS_Contract_Type].[dbo].[Contract_Type_By_Comp] PB WHERE PB.Contract_Type_By_Comp_ID = PP.Contract_Type_By_Comp_ID) END)
LEFT JOIN (
    SELECT P.Position_ID, P.Position_Name, 2 AS Position_By_Com_Type_ID FROM [RMS_Position].[dbo].[Position] P
    UNION
    SELECT PT.Position_Temp_ID, PT.Position_Name, 1 AS Position_By_Com_Type_ID FROM [RMS_Position].[dbo].[Position_Temp] PT
) P ON P.Position_ID = (CASE WHEN PP.Position_By_Comp_ID = 0 OR PP.Position_By_Comp_ID IS NULL THEN PP.Position_ID
    ELSE (SELECT CASE WHEN PB.Position_By_Com_Type_ID = 1 THEN (SELECT PT.Position_Temp_ID FROM [RMS_Position].[dbo].[Position_Temp] PT WHERE PT.Position_Temp_ID = PB.Position_ID) ELSE PB.Position_ID END
        FROM [RMS_Position].[dbo].[Position_By_Comp] PB WHERE PB.Position_By_Com_ID = PP.Position_By_Comp_ID) END)
  AND P.Position_By_Com_Type_ID = (CASE WHEN PP.Position_By_Comp_ID = 0 OR PP.Position_By_Comp_ID IS NULL THEN 2
    ELSE (SELECT PB.Position_By_Com_Type_ID FROM [RMS_Position].[dbo].[Position_By_Comp] PB WHERE PB.Position_By_Com_ID = PP.Position_By_Comp_ID) END)
WHERE PP.Is_Delete = 0;

-- 4.2) #T_MapCompPosition = Map Comp-Position (Company จาก Position)
SELECT MCPP.Project_Position_ID, MCPP.Company_ID
INTO #T_MapCompPosition
FROM [Company].[dbo].[Map_Comp_Position] MCPP
WHERE MCPP.Is_Active = 1 AND MCPP.Is_Delete = 0;

-- 4.3) #T_MapProject = Map Project-Position + Project_Client (Branch/Site/Project)
SELECT
    MPP.Project_Position_ID,
    PC.Project_Client_ID,
    PC.Project_Name,
    PC.Branch_ID,
    PC.Branch_Name,
    PC.Site_ID,
    PC.Site_Name,
    PC.Comp_Branch_Project,
    PC.Comp_Branch_Site_Project,
    PC.Comp_Project,
    PC.Comp_Site_Project
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

-- 4.4) #T_MapSite = Map Site-Position
SELECT MSP.Project_Position_ID, S.Site_ID, S.Site_Name, BS.Branch_ID, BS.Branch_Name, MCS.Company_ID AS Comp_Site, MCB.Company_ID AS Comp_Branch_Site
INTO #T_MapSite
FROM [Company].[dbo].[Map_Site_Position] MSP
LEFT JOIN [Company].[dbo].[Map_Comp_Site] MCS ON MCS.Site_ID = MSP.Site_ID AND MSP.Is_Active = 1 AND MSP.Is_Delete = 0
LEFT JOIN [Company].[dbo].[Site] S ON S.Site_ID = MSP.Site_ID AND S.Is_Active = 1
LEFT JOIN [Company].[dbo].[Map_Branch_Site] MBS ON MBS.Site_ID = MSP.Site_ID AND MBS.Is_Active = 1 AND MBS.Is_Delete = 0
LEFT JOIN [Company].[dbo].[Map_Comp_Branch] MCB ON MCB.Branch_ID = MBS.Branch_ID AND MCB.Is_Active = 1 AND MCB.Is_Delete = 0
LEFT JOIN [Company].[dbo].[Branch_By_Comp] BS ON BS.Branch_ID = MBS.Branch_ID AND BS.Is_Active = 1
WHERE MSP.Is_Active = 1 AND MSP.Is_Delete = 0;

-- 4.5) #T_MapBranch = Map Branch-Position
SELECT MBP.Project_Position_ID, BS.Branch_ID, BS.Branch_Name, MCB.Company_ID AS Comp_Branch
INTO #T_MapBranch
FROM [Company].[dbo].[Map_Branch_Position] MBP
LEFT JOIN [Company].[dbo].[Map_Comp_Branch] MCB ON MCB.Branch_ID = MBP.Branch_ID AND MCB.Is_Active = 1 AND MCB.Is_Delete = 0
LEFT JOIN [Company].[dbo].[Branch_By_Comp] BS ON BS.Branch_ID = MBP.Branch_ID AND BS.Is_Active = 1 AND BS.Is_Delete = 0
WHERE MBP.Is_Active = 1 AND MBP.Is_Delete = 0;

-- 4.6) #T_PositionLog = ล่าสุดต่อ Project_Position
;WITH CTE AS (
    SELECT PL.Project_Position_ID, PL.Created_Date,
           ROW_NUMBER() OVER (PARTITION BY PL.Project_Position_ID ORDER BY PL.Created_Date DESC) AS rn
    FROM [Company].[dbo].[Position_Log] PL
)
SELECT Project_Position_ID, Created_Date
INTO #T_PositionLog
FROM CTE WHERE rn = 1;

-- 4.7) #T_Owner = Owner ต่อ Position
SELECT MUP.Project_Position_ID, Owner = P.Full_Name
INTO #T_Owner
FROM [Company].[dbo].[Map_User_PrjPosi] MUP
LEFT JOIN [Person].[dbo].[Person] P ON P.Person_ID = MUP.Person_ID
WHERE MUP.Is_Active = 1;

-- 4.8) #T_Hiring = จำนวน Sign Contract ต่อ Position (ของ Company ที่สนใจ)
SELECT MCP.Project_Position_ID, COUNT(MCP.Project_Position_ID) AS Hiring
INTO #T_Hiring
FROM [Pipeline].[dbo].[Map_Can_Pile_Com] MCP
WHERE MCP.Is_Active = 1
  AND MCP.Company_ID = @Company_ID
  AND MCP.Pipeline_ID IN (SELECT P.Pipeline_ID FROM [Pipeline].[dbo].[Pipeline] P WHERE P.Pipeline_Name IN ('Sign Contract') AND P.Pipeline_Type_ID = @Pipeline_Type_System)
GROUP BY MCP.Project_Position_ID;

-- 4.9) #T_OnProcess = จำนวน On Process (ก่อน Sign Contract, ไม่ใช่ System type)
SELECT MCP.Project_Position_ID, COUNT(PL.Pipeline_ID) AS On_Process
INTO #T_OnProcess
FROM [Pipeline].[dbo].[Map_Can_Pile_Com] MCP
LEFT JOIN [Pipeline].[dbo].[Pipeline] PL ON PL.Pipeline_ID = MCP.Pipeline_ID
WHERE MCP.Is_Active = 1 AND MCP.Is_Delete = 0
  AND MCP.Company_ID = @Company_ID
  AND PL.Number_Step < @Step_Sign_Contract
  AND PL.Pipeline_Type_ID <> @Pipeline_Type_System
  AND PL.Is_Delete = 0
GROUP BY MCP.Project_Position_ID;

-- 4.10) #T_Candidate = จำนวน Candidates ต่อ Position
SELECT MCP.Project_Position_ID, COUNT(PL.Pipeline_ID) AS Candidate
INTO #T_Candidate
FROM [Pipeline].[dbo].[Map_Can_Pile_Com] MCP
LEFT JOIN [Pipeline].[dbo].[Pipeline] PL ON PL.Pipeline_ID = MCP.Pipeline_ID
WHERE MCP.Is_Active = 1 AND MCP.Is_Delete = 0
  AND MCP.Company_ID = @Company_ID
  AND PL.Pipeline_Type_ID = @Pipeline_Type_System
  AND PL.Is_Delete = 0 AND PL.Pipeline_Name = 'Candidates'
GROUP BY MCP.Project_Position_ID;

-- ----- 5) Query สุดท้าย: JOIN Temp Tables ชั้นเดียว -----
SELECT
    pp.Project_Position_ID,
    COM.Company_ID,
    COM.Company_Name,
    Profile_Image_Gen = CASE WHEN COM.Profile_Image_Gen IS NULL THEN '' ELSE COM.Profile_Image_Gen END,
    Branch_Name = CASE
        WHEN MPP.Branch_Name IS NOT NULL THEN MPP.Branch_Name
        WHEN MSP.Branch_Name IS NOT NULL THEN MSP.Branch_Name
        WHEN MBP.Branch_Name IS NOT NULL THEN MBP.Branch_Name
        ELSE '-'
    END,
    Site_Name = CASE WHEN MPP.Site_Name IS NOT NULL THEN MPP.Site_Name WHEN MSP.Site_Name IS NOT NULL THEN MSP.Site_Name ELSE '-' END,
    Project_Name = CASE WHEN MPP.Project_Name IS NOT NULL THEN MPP.Project_Name ELSE '-' END,
    pp.Position_Name,
    pp.QTY,
    Hiring   = CASE WHEN H.Hiring IS NULL OR H.Hiring = 0 THEN 0 ELSE H.Hiring END,
    Owner    = CASE WHEN PS.Owner IS NULL THEN '-' ELSE PS.Owner END,
    On_Process = CASE WHEN OP.On_Process IS NULL THEN 0 ELSE OP.On_Process END,
    pp.Is_Active,
    Candidate = CASE WHEN C.Candidate IS NULL THEN 0 ELSE C.Candidate END,
    Budget   = CASE WHEN pp.Budget_Negotiate = 0 THEN CONCAT(pp.Budget_Min, ' - ', pp.Budget_Max) ELSE 'Negotiate' END,
    pp.Duration_Of_Contract,
    Reactive_Date   = CASE WHEN POL.Created_Date IS NULL THEN '-' ELSE FORMAT(POL.Created_Date, 'dd MMM yyyy') END,
    Job_Request_Date = CASE WHEN pp.Job_Req_Date IS NULL THEN '-' ELSE FORMAT(pp.Job_Req_Date, 'dd MMM yyyy') END,
    pp.Contract_Type_Name,
    Job_Request_Date_D = pp.Job_Req_Date,
    Reactive_Date_D   = POL.Created_Date
FROM #T_PP pp
LEFT JOIN #T_MapCompPosition MCPP ON MCPP.Project_Position_ID = pp.Project_Position_ID
LEFT JOIN #T_MapProject MPP ON MPP.Project_Position_ID = pp.Project_Position_ID
LEFT JOIN #T_MapSite MSP ON MSP.Project_Position_ID = pp.Project_Position_ID
LEFT JOIN #T_MapBranch MBP ON MBP.Project_Position_ID = pp.Project_Position_ID
INNER JOIN [Company].[dbo].[Company] COM
    ON COM.Company_ID = COALESCE(MCPP.Company_ID, MPP.Comp_Branch_Project, MPP.Comp_Branch_Site_Project, MPP.Comp_Project, MPP.Comp_Site_Project, MSP.Comp_Branch_Site, MSP.Comp_Site, MBP.Comp_Branch)
LEFT JOIN #T_PositionLog POL ON POL.Project_Position_ID = pp.Project_Position_ID
LEFT JOIN #T_Owner PS ON PS.Project_Position_ID = pp.Project_Position_ID
LEFT JOIN #T_Hiring H ON H.Project_Position_ID = pp.Project_Position_ID
LEFT JOIN #T_OnProcess OP ON OP.Project_Position_ID = pp.Project_Position_ID
LEFT JOIN #T_Candidate C ON C.Project_Position_ID = pp.Project_Position_ID
WHERE COM.Company_Type_ID = 2
  AND COM.Com_ID_Of_Com_Type = @Company_ID
ORDER BY COM.Company_Name ASC;

-- ----- 6) เช็คและลบ #TempTable -----
IF OBJECT_ID('tempdb..#T_PP') IS NOT NULL DROP TABLE #T_PP;
IF OBJECT_ID('tempdb..#T_MapCompPosition') IS NOT NULL DROP TABLE #T_MapCompPosition;
IF OBJECT_ID('tempdb..#T_MapProject') IS NOT NULL DROP TABLE #T_MapProject;
IF OBJECT_ID('tempdb..#T_MapSite') IS NOT NULL DROP TABLE #T_MapSite;
IF OBJECT_ID('tempdb..#T_MapBranch') IS NOT NULL DROP TABLE #T_MapBranch;
IF OBJECT_ID('tempdb..#T_PositionLog') IS NOT NULL DROP TABLE #T_PositionLog;
IF OBJECT_ID('tempdb..#T_Owner') IS NOT NULL DROP TABLE #T_Owner;
IF OBJECT_ID('tempdb..#T_Hiring') IS NOT NULL DROP TABLE #T_Hiring;
IF OBJECT_ID('tempdb..#T_OnProcess') IS NOT NULL DROP TABLE #T_OnProcess;
IF OBJECT_ID('tempdb..#T_Candidate') IS NOT NULL DROP TABLE #T_Candidate;
