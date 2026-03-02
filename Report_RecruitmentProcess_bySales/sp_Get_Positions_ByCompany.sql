USE [Pipeline]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Get Project_Position_ID, Position_Name (all) and Sale_Name, Sale_ID (same as report) by Company_ID
-- Usage: EXEC sp_Get_Positions_ByCompany @Company_ID = 3357
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[sp_Get_Positions_ByCompany]
    @Company_ID INT
AS
BEGIN
    SET NOCOUNT ON;

;WITH
T_PP AS (
    SELECT
        PP.Project_Position_ID,
        P.Position_ID,
        Position_Name = CASE WHEN P.Position_Name IS NOT NULL THEN P.Position_Name ELSE N'-' END,
        PP.Job_Req_Date
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
    WHERE PP.Is_Delete = 0
),
T_MapCompPosition AS (
    SELECT Project_Position_ID, Company_ID
    FROM [Company].[dbo].[Map_Comp_Position] MCPP
    WHERE MCPP.Is_Active = 1 AND MCPP.Is_Delete = 0
),
T_MapProject AS (
    SELECT
        MPP.Project_Position_ID,
        PC.Comp_Branch_Project, PC.Comp_Branch_Site_Project, PC.Comp_Project, PC.Comp_Site_Project
    FROM [Company].[dbo].[Map_Project_Position] MPP
    LEFT JOIN (
        SELECT
            PC.Project_Client_ID,
            Comp_Project = MCP.Company_ID,
            MBP.Comp_Branch_Project, MSP.Comp_Branch_Site_Project, MSP.Comp_Site_Project
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
            SELECT MSP.Project_Client_ID, MCS.Company_ID AS Comp_Site_Project, MCB.Company_ID AS Comp_Branch_Site_Project
            FROM [Company].[dbo].[Map_Site_Project] MSP
            LEFT JOIN [Company].[dbo].[Map_Comp_Site] MCS ON MCS.Site_ID = MSP.Site_ID AND MSP.Is_Active = 1 AND MSP.Is_Delete = 0
            LEFT JOIN [Company].[dbo].[Map_Branch_Site] MBS ON MBS.Site_ID = MSP.Site_ID AND MBS.Is_Active = 1 AND MBS.Is_Delete = 0
            LEFT JOIN [Company].[dbo].[Map_Comp_Branch] MCB ON MCB.Branch_ID = MBS.Branch_ID AND MCB.Is_Active = 1 AND MCB.Is_Delete = 0
            WHERE MSP.Is_Active = 1 AND MSP.Is_Delete = 0
        ) MSP ON MSP.Project_Client_ID = PC.Project_Client_ID
        WHERE PC.Is_Active = 1 AND PC.Is_Delete = 0
    ) PC ON PC.Project_Client_ID = MPP.Project_Client_ID
    WHERE MPP.Is_Active = 1 AND MPP.Is_Delete = 0
),
T_MapSite AS (
    SELECT Project_Position_ID, MCS.Company_ID AS Comp_Site, MCB.Company_ID AS Comp_Branch_Site
    FROM [Company].[dbo].[Map_Site_Position] MSP
    LEFT JOIN [Company].[dbo].[Map_Comp_Site] MCS ON MCS.Site_ID = MSP.Site_ID AND MSP.Is_Active = 1 AND MSP.Is_Delete = 0
    LEFT JOIN [Company].[dbo].[Map_Branch_Site] MBS ON MBS.Site_ID = MSP.Site_ID AND MBS.Is_Active = 1 AND MBS.Is_Delete = 0
    LEFT JOIN [Company].[dbo].[Map_Comp_Branch] MCB ON MCB.Branch_ID = MBS.Branch_ID AND MCB.Is_Active = 1 AND MCB.Is_Delete = 0
    WHERE MSP.Is_Active = 1 AND MSP.Is_Delete = 0
),
T_MapBranch AS (
    SELECT Project_Position_ID, MCB.Company_ID AS Comp_Branch
    FROM [Company].[dbo].[Map_Branch_Position] MBP
    LEFT JOIN [Company].[dbo].[Map_Comp_Branch] MCB ON MCB.Branch_ID = MBP.Branch_ID AND MCB.Is_Active = 1 AND MCB.Is_Delete = 0
    WHERE MBP.Is_Active = 1 AND MBP.Is_Delete = 0
),
T_Owner AS (
    SELECT MUP.Project_Position_ID, Sale_Name = P.Full_Name, Sale_ID = MUP.Person_ID
    FROM [Company].[dbo].[Map_User_PrjPosi] MUP
    LEFT JOIN [Person].[dbo].[Person] P ON P.Person_ID = MUP.Person_ID
    WHERE MUP.Is_Active = 1
),
CompanyTypeClient AS (
    SELECT TOP 1 Company_Type_ID FROM [Company].[dbo].[Company_Type] WHERE Company_Type_Name = N'Client'
),
T_ProjectPositionInfo AS (
    SELECT
        pp.Project_Position_ID,
        pp.Position_Name,
        Sale_Name   = CASE WHEN PS.Sale_Name IS NULL THEN N'-' ELSE PS.Sale_Name END,
        Sale_ID     = PS.Sale_ID
    FROM T_PP pp
    LEFT JOIN T_MapCompPosition MCPP ON MCPP.Project_Position_ID = pp.Project_Position_ID
    LEFT JOIN T_MapProject MPP ON MPP.Project_Position_ID = pp.Project_Position_ID
    LEFT JOIN T_MapSite MSP ON MSP.Project_Position_ID = pp.Project_Position_ID
    LEFT JOIN T_MapBranch MBP ON MBP.Project_Position_ID = pp.Project_Position_ID
    INNER JOIN [Company].[dbo].[Company] COM
        ON COM.Company_ID = COALESCE(MCPP.Company_ID, MPP.Comp_Branch_Project, MPP.Comp_Branch_Site_Project, MPP.Comp_Project, MPP.Comp_Site_Project, MSP.Comp_Branch_Site, MSP.Comp_Site, MBP.Comp_Branch)
        AND COM.Company_Type_ID = (SELECT Company_Type_ID FROM CompanyTypeClient)
        AND COM.Is_Active = 1 AND COM.Is_Delete = 0
    LEFT JOIN T_Owner PS ON PS.Project_Position_ID = pp.Project_Position_ID
    WHERE COM.Com_ID_Of_Com_Type = @Company_ID
      AND pp.Position_ID IS NOT NULL
)
SELECT DISTINCT
    Project_Position_ID,
    Position_Name,
    Sale_Name,
    Sale_ID
FROM T_ProjectPositionInfo
ORDER BY Position_Name, Project_Position_ID, Sale_Name;

END
GO
