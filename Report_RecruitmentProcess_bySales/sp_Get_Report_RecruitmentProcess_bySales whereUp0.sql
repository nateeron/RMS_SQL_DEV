USE [Pipeline]
GO
/****** Object:  StoredProcedure [dbo].[sp_Get_Report_RecruitmentProcess_bySales]    Script Date: 2/24/2026 11:39:20 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- sp_Get_Report_RecruitmentProcess_bySales @Company_ID = 3357 ,@Position_ID_str ='43,75,36,79' , @Client_ID_str ='3392,3441'
-- sp_Get_Report_RecruitmentProcess_bySales  @Company_ID = 3357 , @Client_ID_str ='3392,3441'
-- sp_Get_Report_RecruitmentProcess_bySales  @Company_ID = 3357 , @DateFromStr ='07 jun 2025'
-- sp_Get_Report_RecruitmentProcess_bySales 1
-- =============================================
ALTER PROCEDURE [dbo].[sp_Get_Report_RecruitmentProcess_bySales] 
	-- Add the parameters for the stored procedure here
	 @Company_ID INT ,
    @Owner_ID_str  NVARCHAR(500) = NULL,
    @Client_ID_str  NVARCHAR(500) = NULL,
    @Position_ID_str NVARCHAR(500) = NULL,
    @DateFromStr VARCHAR(30) =NULL,
    @DateToStr   VARCHAR(30) = NULL
	
AS
	-------------------------------------------------------
    -- Date convert
    -------------------------------------------------------
    DECLARE @DateFrom DATETIME = TRY_CONVERT(DATETIME, NULLIF(@DateFromStr, ''));
    DECLARE @DateTo   DATETIME = TRY_CONVERT(DATETIME, NULLIF(@DateToStr, ''));

BEGIN TRY
    

-- ----- Pipeline list + dynamic columns -----
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

-- ----- Build full query with CTEs (แทน Temp Table) -----
DECLARE @SQL NVARCHAR(MAX) = N'
;WITH
T_PP AS (
    SELECT
        PP.Project_Position_ID,
        P.Position_ID,
        Position_Name = CASE WHEN P.Position_Name IS NOT NULL THEN P.Position_Name ELSE ''-'' END,
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
    SELECT TOP 1 Company_Type_ID FROM [Company].[dbo].[Company_Type] WHERE Company_Type_Name = ''Client''
),
T_ProjectPositionInfo AS (
    SELECT
        pp.Project_Position_ID,
        pp.Position_ID,
        pp.Position_Name,
        pp.Job_Req_Date,
        Client_ID   = COM.Company_ID,
        Client_Name = COM.Company_Name,
        Sale_Name   = CASE WHEN PS.Sale_Name IS NULL THEN ''-'' ELSE PS.Sale_Name END,
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
    WHERE (@Company_ID IS NULL OR COM.Com_ID_Of_Com_Type = @Company_ID)
),
T_AllPipelineData AS (
    SELECT Project_Position_ID, Pipeline_ID
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
    SELECT Project_Position_ID, Pipeline_ID
    FROM [Pipeline].[dbo].[His_Can_Pile_Com] h
    WHERE h.Is_Active = 1 AND h.Is_Delete = 0
      AND (@Company_ID IS NULL OR h.Company_ID = @Company_ID)
      AND (
            (@DateFrom IS NULL AND @DateTo IS NULL)
         OR (@DateFrom IS NOT NULL AND @DateTo IS NULL AND h.Updated_Date >= @DateFrom)
         OR (@DateFrom IS NULL AND @DateTo IS NOT NULL AND h.Updated_Date < DATEADD(DAY, 1, @DateTo))
         OR (@DateFrom IS NOT NULL AND @DateTo IS NOT NULL AND h.Updated_Date >= @DateFrom AND h.Updated_Date < DATEADD(DAY, 1, @DateTo))
      )
)
SELECT
    MAX(PPI.Sale_Name)     AS Sale_Name,
    MAX(PPI.Sale_ID)      AS Sale_ID,
    MAX(PPI.Client_ID)    AS Client_ID,
    MAX(PPI.Client_Name)  AS Client_Name,
    PPI.Position_ID       AS Position_ID,
    MAX(PPI.Project_Position_ID) AS Project_Position_ID,
    MAX(PPI.Position_Name) AS Position_Name,
    MAX(PPI.Job_Req_Date) AS Job_Req_Date, ' + @SelectColumns + N', ' + @TotalAllExpression + N'
FROM T_ProjectPositionInfo PPI
LEFT JOIN T_AllPipelineData MC ON MC.Project_Position_ID = PPI.Project_Position_ID
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
HAVING SUM(CASE WHEN MC.Pipeline_ID IN (' + @PipelineIdList + N') THEN 1 ELSE 0 END) > 0
ORDER BY PPI.Position_ID, PPI.Client_ID;
';

EXEC sp_executesql @SQL,
    N'@Company_ID INT, @DateFrom DATETIME, @DateTo DATETIME, @Owner_ID_str NVARCHAR(500), @Client_ID_str NVARCHAR(500), @Position_ID_str NVARCHAR(500)',
    @Company_ID, @DateFrom, @DateTo, @Owner_ID_str, @Client_ID_str, @Position_ID_str;


END TRY 
BEGIN CATCH 
	INSERT INTO [LOG].[dbo].[Log] (
		[Software_ID],
		[Function_Name],
		[Detail],
		[Created By],
		[Created Date]
	)
	VALUES (
		'1',
		'DB Company - sp_Get_Report_RecruitmentProcess_bySales',
		ERROR_MESSAGE(),
		0,
		GETDATE()
	);
END CATCH



