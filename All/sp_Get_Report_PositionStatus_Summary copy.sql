USE [Pipeline]
GO
/****** Object:  StoredProcedure [dbo].[sp_Get_Report_PositionStatus_Summary]    Script Date: 12/22/2025 11:54:34 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Procedure name: [dbo].[sp_Get_Report_PositionStatus_Summary]
-- Function: Get Position Status Summary grouped by Sales Name and Client Name
-- Create date: 12/19/2025
-- Description: Counts Open and Closed Positions by Sales Name and Client Name
-- Open Position = Is_Active = 1 (from Project_Position table)
-- Closed Position = Is_Active = 0 (from Project_Position table)
 -- [dbo].[sp_Get_Report_PositionStatus_Summary] 3357,'3,42,1063'
-- =============================================
ALTER PROCEDURE [dbo].[sp_Get_Report_PositionStatus_Summary]
	@Company_ID INT = 0,
	@Role_ID NVARCHAR(100) = NULL,
	@DateFromStr	VARCHAR(30) = NULL,
    @DateToStr		VARCHAR(30) = NULL,
	@Client_ID_str NVARCHAR(500) = '',
	@Owner_ID_str NVARCHAR(500) = ''
AS

DECLARE @COMPANY_TYPE_ID INT = 0,
	@Address_Type_ID INT = 0,
	@Category_Type_ID INT = 0,
	@Count_View_Branch INT = 0,
	@Count_View_Location INT = 0,
	@Count_View_Project INT = 0;

BEGIN TRY
	DECLARE @DateFrom DATETIME = NULL;
    DECLARE @DateTo   DATETIME = NULL;

    -- แปลง string → DATETIME
    SET @DateFrom = TRY_CONVERT(DATETIME, NULLIF(@DateFromStr, ''));
    SET @DateTo   = TRY_CONVERT(DATETIME, NULLIF(@DateToStr, ''));

SET @COMPANY_TYPE_ID = (
		SELECT TOP (1) [Company_Type_ID]
		FROM [Company].[dbo].[Company_Type]
		WHERE [Company_Type_Name] = 'Client'
	);

-- Check Role Permissions
IF @Role_ID IS NOT NULL AND @Role_ID <> ''
BEGIN
	SET @Count_View_Branch = (SELECT COUNT([MRF].[Map_Role_Func_Module_ID])
							FROM [Role].[dbo].[Map_Role_Func_Module] MRF
							LEFT JOIN [Role].[dbo].[Role] R ON [R].[Role_ID] = [MRF].[Role_ID]
							LEFT JOIN [Menu].[dbo].[Module] M ON [M].[Module_ID] = [MRF].[Module_ID]
							LEFT JOIN [Function].[dbo].[Function] F ON [F].[Function_ID] = [MRF].[Function_ID]
							WHERE [MRF].[Role_ID] IN (SELECT * FROM STRING_SPLIT(REPLACE(@Role_ID, '"', ''), ','))
							AND [F].[Function_Name] = 'View'
							AND [M].[Module_Name] IN ('View Branch Name')
							AND [MRF].[Is_Active] = 1);

	SET @Count_View_Location = (SELECT COUNT([MRF].[Map_Role_Func_Module_ID])
							FROM [Role].[dbo].[Map_Role_Func_Module] MRF
							LEFT JOIN [Role].[dbo].[Role] R ON [R].[Role_ID] = [MRF].[Role_ID]
							LEFT JOIN [Menu].[dbo].[Module] M ON [M].[Module_ID] = [MRF].[Module_ID]
							LEFT JOIN [Function].[dbo].[Function] F ON [F].[Function_ID] = [MRF].[Function_ID]
							WHERE [MRF].[Role_ID] IN (SELECT * FROM STRING_SPLIT(REPLACE(@Role_ID, '"', ''), ','))
							AND [F].[Function_Name] = 'View'
							AND [M].[Module_Name] IN ('View Location')
							AND [MRF].[Is_Active] = 1);

	SET @Count_View_Project = (SELECT COUNT([MRF].[Map_Role_Func_Module_ID])
							FROM [Role].[dbo].[Map_Role_Func_Module] MRF
							LEFT JOIN [Role].[dbo].[Role] R ON [R].[Role_ID] = [MRF].[Role_ID]
							LEFT JOIN [Menu].[dbo].[Module] M ON [M].[Module_ID] = [MRF].[Module_ID]
							LEFT JOIN [Function].[dbo].[Function] F ON [F].[Function_ID] = [MRF].[Function_ID]
							WHERE [MRF].[Role_ID] IN (SELECT * FROM STRING_SPLIT(REPLACE(@Role_ID, '"', ''), ','))
							AND [F].[Function_Name] = 'View'
							AND [M].[Module_Name] IN ('View Project Name')
							AND [MRF].[Is_Active] = 1);
END

BEGIN
	WITH AllData AS (
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
	ID_Position AS (
			SELECT  Project_Position_ID
			FROM Ranked
			WHERE rn = 1
			Group by Project_Position_ID
	),
	MBP_MapBranchProject AS (
		SELECT [Branch_ID_Of_Project] = [B].[Branch_ID],
			[Branch_Name_Of_Project] = [B].[Branch_Name],
			[Comp_Branch_Project] = [MCB].[Company_ID],
			[MBP].[Project_Client_ID]
		FROM [Company].[dbo].[Map_Branch_Project] MBP
			LEFT JOIN [Company].[dbo].[Map_Comp_Branch] MCB ON [MCB].[Branch_ID] = [MBP].[Branch_ID]
			AND [MCB].[Is_Active] = 1
			AND [MCB].[Is_Delete] = 0
			LEFT JOIN [Company].[dbo].[Branch_By_Comp] B ON [B].[Branch_ID] = [MBP].[Branch_ID]
			AND [B].[Is_Active] = 1
			AND [B].[Is_Delete] = 0
		WHERE [MBP].[Is_Active] = 1
			AND [MBP].[Is_Delete] = 0
	),
	MSP_Map_Site_Project AS (
		SELECT [MSP].[Project_Client_ID],
			[S].[Site_ID],
			[S].[Site_Name],
			[Branch_ID_Of_Site_Project] = [BS].[Branch_ID],
			[Branch_Name_Of_Site_Project] = [BS].[Branch_Name],
			[Comp_Site_Project] = [MCS].[Company_ID],
			[Comp_Branch_Site_Project] = [MCB].[Company_ID]
		FROM [Company].[dbo].[Map_Site_Project] MSP
			LEFT JOIN [Company].[dbo].[Map_Comp_Site] MCS ON [MCS].[Site_ID] = [MSP].[Site_ID]
			AND [MSP].[Is_Active] = 1
			AND [MSP].[Is_Delete] = 0
			LEFT JOIN [Company].[dbo].[Site] S ON [S].[Site_ID] = [MSP].[Site_ID]
			AND [S].[Is_Active] = 1
			LEFT JOIN [Company].[dbo].[Map_Branch_Site] MBS ON [MBS].[Site_ID] = [MSP].[Site_ID]
			AND [MBS].[Is_Active] = 1
			AND [MBS].[Is_Delete] = 0
			LEFT JOIN [Company].[dbo].[Map_Comp_Branch] MCB ON [MCB].[Branch_ID] = [MBS].[Branch_ID]
			AND [MCB].[Is_Active] = 1
			AND [MCB].[Is_Delete] = 0
			LEFT JOIN [Company].[dbo].[Branch_By_Comp] BS ON [BS].[Branch_ID] = [MBS].[Branch_ID]
			AND [BS].[Is_Active] = 1
			AND [BS].[Is_Delete] = 0
		WHERE [MSP].[Is_Active] = 1
			AND [MSP].[Is_Delete] = 0
	),
	MSP_Map_Site_Position AS (
		SELECT [MSP].[Project_Position_ID],
			[S].[Site_ID],
			[S].[Site_Name],
			[BS].[Branch_ID],
			[BS].[Branch_Name],
			[Comp_Site] = [MCS].[Company_ID],
			[Comp_Branch_Site] = [MCB].[Company_ID]
		FROM [Company].[dbo].[Map_Site_Position] MSP
			LEFT JOIN [Company].[dbo].[Map_Comp_Site] MCS ON [MCS].[Site_ID] = [MSP].[Site_ID]
			AND [MSP].[Is_Active] = 1
			AND [MSP].[Is_Delete] = 0
			LEFT JOIN [Company].[dbo].[Site] S ON [S].[Site_ID] = [MSP].[Site_ID]
			AND [S].[Is_Active] = 1
			LEFT JOIN [Company].[dbo].[Map_Branch_Site] MBS ON [MBS].[Site_ID] = [MSP].[Site_ID]
			AND [MBS].[Is_Active] = 1
			AND [MBS].[Is_Delete] = 0
			LEFT JOIN [Company].[dbo].[Map_Comp_Branch] MCB ON [MCB].[Branch_ID] = [MBS].[Branch_ID]
			AND [MCB].[Is_Active] = 1
			AND [MCB].[Is_Delete] = 0
			LEFT JOIN [Company].[dbo].[Branch_By_Comp] BS ON [BS].[Branch_ID] = [MBS].[Branch_ID]
			AND [BS].[Is_Active] = 1
			AND [BS].[Is_Delete] = 0
		WHERE [MSP].[Is_Active] = 1
			AND [MSP].[Is_Delete] = 0
	),
	MBP_Map_Branch_Position AS (
		SELECT [MBP].[Project_Position_ID],
			[BS].[Branch_ID],
			[BS].[Branch_Name],
			[Comp_Branch] = [MCB].[Company_ID]
		FROM [Company].[dbo].[Map_Branch_Position] MBP
			LEFT JOIN [Company].[dbo].[Map_Comp_Branch] MCB ON [MCB].[Branch_ID] = [MBP].[Branch_ID]
			AND [MCB].[Is_Active] = 1
			AND [MCB].[Is_Delete] = 0
			LEFT JOIN [Company].[dbo].[Branch_By_Comp] BS ON [BS].[Branch_ID] = [MBP].[Branch_ID]
			AND [BS].[Is_Active] = 1
			AND [BS].[Is_Delete] = 0
		WHERE [MBP].[Is_Active] = 1
			AND [MBP].[Is_Delete] = 0
	),
	P_Position AS (
		SELECT [P].[Position_ID],
			[P].[Position_Name],
			2 AS [Position_By_Com_Type_ID]
		FROM [RMS_Position].[dbo].[Position] P
		UNION
		SELECT [PT].[Position_Temp_ID] AS [Position_ID],
			[PT].[Position_Name],
			1 AS [Position_By_Com_Type_ID]
		FROM [RMS_Position].[DBO].[Position_Temp] PT
	),
	MPP_Map_Project_Position AS (
		SELECT [MPP].[Project_Position_ID],
			[PC].[Project_Client_ID],
			[PC].[Project_Name],
			[PC].[Branch_ID],
			[PC].[Branch_Name],
			[PC].[Site_ID],
			[PC].[Site_Name],
			[PC].[Comp_Branch_Project],
			[PC].[Comp_Branch_Site_Project],
			[PC].[Comp_Project],
			[PC].[Comp_Site_Project]
		FROM [Company].[dbo].[Map_Project_Position] MPP
			LEFT JOIN (
				SELECT [PC].[Project_Client_ID],
					[PC].[Project_Name],
					[Comp_Project] = [MCP].[Company_ID],
					[MBP].[Comp_Branch_Project],
					[MSP].[Comp_Branch_Site_Project],
					[MSP].[Comp_Site_Project],
					[MSP].[Site_ID],
					[MSP].[Site_Name],
					[Branch_ID] = CASE
						WHEN [MBP].[Branch_ID_Of_Project] IS NOT NULL THEN [MBP].[Branch_ID_Of_Project]
						ELSE [MSP].[Branch_ID_Of_Site_Project]
					END,
					[Branch_Name] = CASE
						WHEN [MBP].[Branch_Name_Of_Project] IS NOT NULL THEN [MBP].[Branch_Name_Of_Project]
						ELSE [MSP].[Branch_Name_Of_Site_Project]
					END
				FROM [Company].[dbo].[Project_Client] PC
					LEFT JOIN [Company].[dbo].[Map_Comp_Project] MCP ON [MCP].[Project_Client_ID] = [PC].[Project_Client_ID]
					AND [MCP].[Is_Active] = 1
					AND [MCP].[Is_Delete] = 0
					LEFT JOIN (
						SELECT [Branch_ID_Of_Project],
							[Branch_Name_Of_Project],
							[Comp_Branch_Project],
							[Project_Client_ID]
						FROM MBP_MapBranchProject
					) MBP ON [MBP].[Project_Client_ID] = [PC].[Project_Client_ID]
					LEFT JOIN (
						SELECT [Project_Client_ID],
							[Site_ID],
							[Site_Name],
							[Branch_ID_Of_Site_Project],
							[Branch_Name_Of_Site_Project],
							[Comp_Site_Project],
							[Comp_Branch_Site_Project]
						FROM MSP_Map_Site_Project
					) MSP ON [MSP].[Project_Client_ID] = [PC].[Project_Client_ID]
				WHERE [PC].[Is_Active] = 1
					AND [PC].[Is_Delete] = 0
			) PC ON [PC].[Project_Client_ID] = [MPP].[Project_Client_ID]
		WHERE [MPP].[Is_Active] = 1
			AND [MPP].[Is_Delete] = 0
	),
	-- Get Client List
	Client_List AS (
		SELECT [COMP].[Company_ID] AS [Client_ID],
			[COMP].[Company_Name] AS [Client_Name]
		FROM [Company].[dbo].[Company] COMP
		WHERE [COMP].[Com_ID_Of_Com_Type] = @Company_ID
			AND [COMP].[Company_Type_ID] = @COMPANY_TYPE_ID
			AND [COMP].[Is_Active] = 1
			AND [COMP].[Is_Delete] = 0
	),
	-- Get Project Position details with Owner info
	PP_ProjectPosition AS (
		SELECT 
			COM.Company_ID AS Client_ID,
			PP.Project_Position_ID,
			PP.Position_ID AS Position_ID_OF_Com,
			PP.Position_By_Comp_ID,
			PP.Is_Active,
			PP.Created_Date,
			[P].[Position_ID],
			CASE WHEN [P].[Position_Name] IS NOT NULL THEN [P].[Position_Name] ELSE '-' END AS Position_Name,
			CASE WHEN [MUP].[Owner_Name] IS NOT NULL THEN [MUP].[Owner_Name] ELSE '-' END AS Owner_Name,
			[MUP].[Person_ID] AS Owner_Person_ID
		FROM Company.dbo.Project_Position PP
			LEFT JOIN (
				SELECT [MUP].[Project_Position_ID],
					[Owner_Name] = [P].[Full_Name],
					[MUP].[Person_ID],
					[MUP].[Is_Active]
				FROM [Company].[dbo].[Map_User_PrjPosi] MUP
					LEFT JOIN [Person].[dbo].[Person] P ON [P].[Person_ID] = [MUP].[Person_ID]
			) MUP ON [MUP].[Project_Position_ID] = [PP].[Project_Position_ID] AND [MUP].[Is_Active] = 1
			LEFT JOIN P_Position P ON [P].[Position_ID] = (
				CASE 
					WHEN [PP].[Position_By_Comp_ID] = 0 OR [PP].[Position_By_Comp_ID] IS NULL THEN
						[PP].[Position_ID]
					ELSE
						(SELECT [Position_ID] = (
							CASE WHEN [PB].[Position_By_Com_Type_ID] = 1 THEN 
								(SELECT [PT].[Position_Temp_ID] FROM [RMS_Position].[dbo].[Position_Temp] PT WHERE [PT].[Position_Temp_ID] = [PB].[Position_ID])
							ELSE
								[PB].[Position_ID]
							END
						)
						FROM [RMS_Position].[dbo].[Position_By_Comp] PB 
						WHERE [PB].[Position_By_Com_ID] = [PP].[Position_By_Comp_ID]
						)
				END
			)
			AND [P].[Position_By_Com_Type_ID] = (
				CASE WHEN [PP].[Position_By_Comp_ID] = 0 OR [PP].[Position_By_Comp_ID] IS NULL THEN 2
				ELSE
					(SELECT [PB].[Position_By_Com_Type_ID]
					FROM [RMS_Position].[dbo].[Position_By_Comp] PB WHERE [PB].[Position_By_Com_ID] = [PP].[Position_By_Comp_ID])
				END
			)
			LEFT JOIN [Company].[dbo].[Map_Comp_Position] MCPP ON [MCPP].[Project_Position_ID] = [PP].[Project_Position_ID] 
				AND [MCPP].[Is_Active] = 1 
				AND [MCPP].[Is_Delete] = 0
			LEFT JOIN MPP_Map_Project_Position MPP ON [MPP].[Project_Position_ID] = [PP].[Project_Position_ID]
			LEFT JOIN MSP_Map_Site_Position MSP ON [MSP].[Project_Position_ID] = [PP].[Project_Position_ID]
			LEFT JOIN MBP_Map_Branch_Position MBP ON [MBP].[Project_Position_ID] = [PP].[Project_Position_ID]
			LEFT JOIN Company.dbo.Company COM ON COM.Company_ID IN (
				MCPP.Company_ID,
				MPP.Comp_Branch_Project,
				MPP.Comp_Branch_Site_Project,
				MPP.Comp_Project,
				MPP.Comp_Site_Project,
				MSP.Comp_Branch_Site,
				MSP.Comp_Site,
				MBP.Comp_Branch
			)
		WHERE PP.Is_Delete = 0
			AND COM.Company_Type_ID = 2
			AND COM.Company_ID IN (SELECT Client_ID FROM Client_List)
			AND (
				[MPP].[Comp_Branch_Project] = COM.Company_ID 
				OR [MPP].[Comp_Branch_Site_Project] = COM.Company_ID 
				OR [MPP].[Comp_Project] = COM.Company_ID 
				OR [MPP].[Comp_Site_Project] = COM.Company_ID
				OR [MCPP].[Company_ID] = COM.Company_ID
				OR [MSP].[Comp_Branch_Site] = COM.Company_ID
				OR [MSP].[Comp_Site] = COM.Company_ID
				OR [MBP].[Comp_Branch] = COM.Company_ID
			)
			-- Apply Role-based filtering
			AND (
				@Role_ID IS NULL 
				OR @Role_ID = ''
				OR (
					(@Count_View_Branch = 0 AND @Count_View_Location <> 0 AND @Count_View_Project <> 0 AND [MPP].[Branch_ID] IS NULL AND [MSP].[Branch_ID] IS NULL AND [MBP].[Branch_ID] IS NULL)
					OR (@Count_View_Branch <> 0 AND @Count_View_Location = 0 AND @Count_View_Project <> 0 AND [MPP].[Site_ID] IS NULL AND [MSP].[Site_ID] IS NULL)
					OR (@Count_View_Branch <> 0 AND @Count_View_Location <> 0 AND @Count_View_Project = 0 AND [MPP].[Project_Client_ID] IS NULL)
					OR (@Count_View_Branch = 0 AND @Count_View_Location = 0 AND @Count_View_Project <> 0 AND [MPP].[Branch_ID] IS NULL AND [MSP].[Branch_ID] IS NULL AND [MBP].[Branch_ID] IS NULL AND [MPP].[Site_ID] IS NULL AND [MSP].[Site_ID] IS NULL)
					OR (@Count_View_Branch = 0 AND @Count_View_Location <> 0 AND @Count_View_Project = 0 AND [MPP].[Branch_ID] IS NULL AND [MSP].[Branch_ID] IS NULL AND [MBP].[Branch_ID] IS NULL AND [MPP].[Project_Client_ID] IS NULL)
					OR (@Count_View_Branch <> 0 AND @Count_View_Location = 0 AND @Count_View_Project = 0 AND [MPP].[Site_ID] IS NULL AND [MSP].[Site_ID] IS NULL AND [MPP].[Project_Client_ID] IS NULL)
					OR (@Count_View_Branch = 0 AND @Count_View_Location = 0 AND @Count_View_Project = 0 AND [MPP].[Branch_ID] IS NULL AND [MSP].[Branch_ID] IS NULL AND [MBP].[Branch_ID] IS NULL AND [MPP].[Site_ID] IS NULL AND [MSP].[Site_ID] IS NULL AND [MPP].[Project_Client_ID] IS NULL)
					OR (@Count_View_Branch <> 0 AND @Count_View_Location <> 0 AND @Count_View_Project <> 0)
				)
			)
	),
	-- CTE: Split Client ID values
	ClientIDFilter AS (
		SELECT TRY_CAST(LTRIM(RTRIM([value])) AS INT) AS [Client_ID_Value]
		FROM STRING_SPLIT(@Client_ID_str, ',')
		WHERE @Client_ID_str <> '' AND @Client_ID_str IS NOT NULL
			AND TRY_CAST(LTRIM(RTRIM([value])) AS INT) IS NOT NULL
	),
	-- CTE: Split Owner ID values
	OwnerIDFilter AS (
		SELECT TRY_CAST(LTRIM(RTRIM([value])) AS INT) AS [Owner_ID_Value]
		FROM STRING_SPLIT(@Owner_ID_str, ',')
		WHERE @Owner_ID_str <> '' AND @Owner_ID_str IS NOT NULL
			AND TRY_CAST(LTRIM(RTRIM([value])) AS INT) IS NOT NULL
	),
	-- Get Position Status using Is_Active from Project_Position
	PositionWithStatus AS (
		SELECT 
			PP.Client_ID,
			PP.Owner_Name AS Sales_Name,
			PP.Owner_Person_ID,
			CL.Client_Name,
			PP.Position_ID,
			PP.Project_Position_ID,
			PP.Created_Date,
			-- Use Is_Active from Project_Position: 1 = Open Position, 0 = Closed Position
			CASE 
				WHEN PP.Is_Active = 1 THEN 'Open'
				ELSE 'Closed'
			END AS Position_Status
		FROM PP_ProjectPosition PP
			LEFT JOIN ID_Position IP ON IP.Project_Position_ID = PP.Project_Position_ID
			INNER JOIN Client_List CL ON CL.Client_ID = PP.Client_ID
	)
	-- Final Summary grouped by Sales Name and Client Name
	SELECT 
		Client_ID,
		Owner_Person_ID,
		Sales_Name,
		Client_Name,
		[Open_Positions] = SUM(CASE WHEN Position_Status = 'Open' THEN 1 ELSE 0 END),
		[Closed_Positions] = SUM(CASE WHEN Position_Status = 'Closed' THEN 1 ELSE 0 END),
		[Total_Positions] = COUNT(DISTINCT Project_Position_ID),
		Created_Date
	FROM PositionWithStatus
	WHERE 
		-- Filter by Client ID (if provided) - supports multiple IDs
		(@Client_ID_str = '' OR @Client_ID_str IS NULL OR 
			Client_ID IN (SELECT [Client_ID_Value] FROM ClientIDFilter)
		)
		-- Filter by Owner ID (if provided) - supports multiple IDs
		AND (@Owner_ID_str = '' OR @Owner_ID_str IS NULL OR 
			Owner_Person_ID IN (SELECT [Owner_ID_Value] FROM OwnerIDFilter)
		)
	GROUP BY Client_ID, Owner_Person_ID, Sales_Name, Client_Name,Created_Date
	ORDER BY Client_Name ,Sales_Name;

END
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
		'DB Pipeline - sp_Get_Report_PositionStatus_Summary',
		ERROR_MESSAGE(),
		999,
		GETDATE()
	);
END CATCH

