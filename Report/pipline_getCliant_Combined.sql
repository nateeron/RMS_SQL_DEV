USE [Pipeline]
GO

DECLARE @Company_ID INT = 3357,
	@Role_ID NVARCHAR(100) = NULL,
	@DateFromStr	VARCHAR(30) = NULL,
    @DateToStr		VARCHAR(30) = NULL,
	@Owner_ID_str		NVARCHAR(500) = '', 
	@Client_ID_str	NVARCHAR(500) = '', 	
	@Position_ID_str  NVARCHAR(500) = '';


DECLARE @COMPANY_TYPE_ID INT = 0,
	@Address_Type_ID INT = 0,
	@Category_Type_ID INT = 0,
	@Count_View_Branch INT = 0,
	@Count_View_Location INT = 0,
	@Count_View_Project INT = 0;


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
SET @Address_Type_ID = (
		SELECT TOP (1) [Address_Type_ID]
		FROM [Address].[dbo].[Address_Type]
		WHERE [Address_Type_Name] = 'Register'
	);
SET @Category_Type_ID = (
		SELECT TOP (1) [Category_Type_ID]
		FROM [Address].[dbo].[Address_Category_Type]
		WHERE [Category_Type_Name] = 'Company'
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

-- Pipeline IDs for counting
DECLARE @Candidate_Pipeline_ID INT = 0,
		@RSO_Sent_Pipeline_ID INT = 0,
		@Appointment_Pipeline_ID INT = 0,
		@Pass_Pipeline_ID INT = 0,
		@SignContract_Pipeline_ID INT = 0,
		@Terminate_Pipeline_ID INT = 0,
		@Drop_Pipeline_ID INT = 0;

SET @Candidate_Pipeline_ID = (SELECT TOP 1 [P].[Pipeline_ID]
							  FROM [Pipeline].[dbo].[Pipeline] P
							  WHERE [P].[Pipeline_Name] = 'Candidates'
							  AND [P].[Is_Active] = 1
							  AND [P].[Is_Delete] = 0);

SET @RSO_Sent_Pipeline_ID = (SELECT TOP 1 [P].[Pipeline_ID]
							  FROM [Pipeline].[dbo].[Pipeline] P
							  WHERE [P].[Pipeline_Name] = 'RSO Sent to Client'
							  AND [P].[Is_Active] = 1
							  AND [P].[Is_Delete] = 0);

SET @Appointment_Pipeline_ID = (SELECT TOP 1 [P].[Pipeline_ID]
								  FROM [Pipeline].[dbo].[Pipeline] P
								  WHERE [P].[Pipeline_Name] = 'Appointment'
								  AND [P].[Is_Active] = 1
								  AND [P].[Is_Delete] = 0);

SET @Pass_Pipeline_ID = (SELECT TOP 1 [P].[Pipeline_ID]
						FROM [Pipeline].[dbo].[Pipeline] P
						WHERE [P].[Pipeline_Name] = 'Pass'
						AND [P].[Is_Active] = 1
						AND [P].[Is_Delete] = 0);

SET @SignContract_Pipeline_ID = (SELECT TOP 1 [P].[Pipeline_ID]
								FROM [Pipeline].[dbo].[Pipeline] P
								WHERE [P].[Pipeline_Name] = 'Sign Contract'
								AND [P].[Is_Active] = 1
								AND [P].[Is_Delete] = 0);

SET @Terminate_Pipeline_ID = (SELECT TOP 1 [P].[Pipeline_ID]
								FROM [Pipeline].[dbo].[Pipeline] P
								WHERE [P].[Pipeline_Name] = 'Terminate'
								AND [P].[Is_Active] = 1
								AND [P].[Is_Delete] = 0);

SET @Drop_Pipeline_ID = (SELECT TOP 1 [P].[Pipeline_ID]
						FROM [Pipeline].[dbo].[Pipeline] P
						WHERE [P].[Pipeline_Name] = 'Drop'
						AND [P].[Is_Active] = 1
						AND [P].[Is_Delete] = 0);

IF @Candidate_Pipeline_ID IS NULL SET @Candidate_Pipeline_ID = 0;
IF @RSO_Sent_Pipeline_ID IS NULL SET @RSO_Sent_Pipeline_ID = 0;
IF @Appointment_Pipeline_ID IS NULL SET @Appointment_Pipeline_ID = 0;
IF @Pass_Pipeline_ID IS NULL SET @Pass_Pipeline_ID = 0;
IF @SignContract_Pipeline_ID IS NULL SET @SignContract_Pipeline_ID = 0;
IF @Terminate_Pipeline_ID IS NULL SET @Terminate_Pipeline_ID = 0;
IF @Drop_Pipeline_ID IS NULL SET @Drop_Pipeline_ID = 0;

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
        h.Created_Date,
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
	-- Pipeline Counts by Project_Position_ID (from getPipeline.sql logic)
	PipelineCounts AS (
		SELECT
			MC.Project_Position_ID,
			Total_Candidate = CASE WHEN @Candidate_Pipeline_ID > 0
							  THEN SUM(CASE WHEN MC.Pipeline_ID = @Candidate_Pipeline_ID  THEN 1 ELSE 0 END)
							  ELSE 0 END,
			Total_RSO_SentToClient = CASE WHEN @RSO_Sent_Pipeline_ID > 0 
									 THEN SUM(CASE WHEN MC.Pipeline_ID = @RSO_Sent_Pipeline_ID THEN 1 ELSE 0 END)
									 ELSE 0 END,
			Total_Appointment = CASE WHEN @Appointment_Pipeline_ID > 0
								THEN SUM(CASE WHEN MC.Pipeline_ID = @Appointment_Pipeline_ID THEN 1 ELSE 0 END)
								ELSE 0 END,
			Total_Pass = CASE WHEN @Pass_Pipeline_ID > 0
						 THEN SUM(CASE WHEN MC.Pipeline_ID = @Pass_Pipeline_ID THEN 1 ELSE 0 END)
						 ELSE 0 END,
			Total_SignContract = CASE WHEN @SignContract_Pipeline_ID > 0
								 THEN SUM(CASE WHEN MC.Pipeline_ID = @SignContract_Pipeline_ID  THEN 1 ELSE 0 END) 
								 ELSE 0 END,
			Total_Terminate = CASE WHEN @Terminate_Pipeline_ID > 0
							  THEN SUM(CASE WHEN MC.Pipeline_ID = @Terminate_Pipeline_ID  THEN 1 ELSE 0 END) 
							  ELSE 0 END,
			Total_Drop = CASE WHEN @Drop_Pipeline_ID > 0
						 THEN SUM(CASE WHEN MC.Pipeline_ID = @Drop_Pipeline_ID  THEN 1 ELSE 0 END)
						 ELSE 0 END,
			Total_All = SUM(CASE WHEN MC.Pipeline_ID IN (@Candidate_Pipeline_ID
													 ,@RSO_Sent_Pipeline_ID
													 ,@Appointment_Pipeline_ID
													 ,@Pass_Pipeline_ID
													 ,@SignContract_Pipeline_ID
													 ,@Terminate_Pipeline_ID
													 ,@Drop_Pipeline_ID) THEN 1 ELSE 0 END)
		FROM Ranked MC
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
		WHERE MC.rn = 1
			AND (Own.Person_ID IS NOT NULL OR T_Own.Title_Name IS NOT NULL)
		GROUP BY MC.Project_Position_ID
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
	-- Get Client List from sp_GetList_Com_Client logic
	Client_List AS (
		SELECT [COMP].[Company_ID] AS [Client_ID],
			[COMP].[Company_Name] AS [Client_Name]
		FROM [Company].[dbo].[Company] COMP
		WHERE [COMP].[Com_ID_Of_Com_Type] = @Company_ID
			AND [COMP].[Company_Type_ID] = @COMPANY_TYPE_ID
			AND [COMP].[Is_Active] = 1
			AND [COMP].[Is_Delete] = 0
	),
	-- Get Project Position details (from sp_GetProjectPosition_By_PCID logic)
	PP_ProjectPosition AS (
		SELECT 
			COM.Company_ID AS Client_ID,
			PP.Project_Position_ID,
			PP.Position_ID AS Position_ID_OF_Com,
			PP.Position_By_Comp_ID,
			[P].[Position_ID],
			CASE WHEN [P].[Position_Name] IS NOT NULL THEN [P].[Position_Name] ELSE '-' END AS Position_Name,
			CASE WHEN [MUP].[Owner_Name] IS NOT NULL THEN [MUP].[Owner_Name] ELSE '-' END AS Owner_Name,
			[MUP].[Person_ID] AS Owner_Person_ID
			,PP.Job_Req_Date
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
			-- Apply Role-based filtering (matching sp_GetProjectPosition_By_PCID logic exactly)
			AND (
				@Role_ID IS NULL 
				OR @Role_ID = ''
				OR (
					-- Match all 7 combinations from sp_GetProjectPosition_By_PCID
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
	-- CTE: Split Owner Name/ID values
	OwnerFilter AS (
		SELECT LTRIM(RTRIM([value])) AS [Owner_Value]
		FROM STRING_SPLIT(@Owner_ID_str, ',')
		WHERE @Owner_ID_str <> '' AND @Owner_ID_str IS NOT NULL
	),
	-- CTE: Split Client Name/ID values
	ClientFilter AS (
		SELECT LTRIM(RTRIM([value])) AS [Client_Value]
		FROM STRING_SPLIT(@Client_ID_str, ',')
		WHERE @Client_ID_str <> '' AND @Client_ID_str IS NOT NULL
	),
	-- CTE: Split Position ID values
	PositionFilter AS (
		SELECT TRY_CAST(LTRIM(RTRIM([value])) AS INT) AS [Position_ID_Value]
		FROM STRING_SPLIT(@Position_ID_str, ',')
		WHERE @Position_ID_str <> '' AND @Position_ID_str IS NOT NULL
			AND TRY_CAST(LTRIM(RTRIM([value])) AS INT) IS NOT NULL
	)
	-- Combined Result
	SELECT 
		CL.Client_ID,
		[PP].[Owner_Person_ID],
		PP.Owner_Name,
		CL.Client_Name,
		PP.Position_ID,
		PP.Position_Name,
		PP.Project_Position_ID,
		pp.Job_Req_Date,
		-- Pipeline Counts from getPipeline.sql
		ISNULL(PC.Total_Candidate, 0) AS Total_Candidate,
		ISNULL(PC.Total_RSO_SentToClient, 0) AS Total_RSO_SentToClient,
		ISNULL(PC.Total_Appointment, 0) AS Total_Appointment,
		ISNULL(PC.Total_Pass, 0) AS Total_Pass,
		ISNULL(PC.Total_SignContract, 0) AS Total_SignContract,
		ISNULL(PC.Total_Terminate, 0) AS Total_Terminate,
		ISNULL(PC.Total_Drop, 0) AS Total_Drop,
		ISNULL(PC.Total_All, 0) AS Total_All
	FROM Client_List CL
		INNER JOIN PP_ProjectPosition PP ON PP.Client_ID = CL.Client_ID
		Left JOIN ID_Position IP ON IP.Project_Position_ID = PP.Project_Position_ID
		LEFT JOIN PipelineCounts PC ON PC.Project_Position_ID = PP.Project_Position_ID
	WHERE 
		-- Filter by Owner Name/ID (if provided) - supports multiple values, handles both IDs and names
		(@Owner_ID_str = '' OR @Owner_ID_str IS NULL OR 
			EXISTS (
				SELECT 1 FROM OwnerFilter OFilt
				WHERE (TRY_CAST(OFilt.[Owner_Value] AS INT) IS NOT NULL AND [PP].[Owner_Person_ID] = TRY_CAST(OFilt.[Owner_Value] AS INT))
					OR (TRY_CAST(OFilt.[Owner_Value] AS INT) IS NULL AND [PP].[Owner_Name] = OFilt.[Owner_Value])
			)
		)
		-- Filter by Client Name/ID (if provided) - supports multiple values, handles both IDs and names
		AND (@Client_ID_str = '' OR @Client_ID_str IS NULL OR 
			EXISTS (
				SELECT 1 FROM ClientFilter CF
				WHERE (TRY_CAST(CF.[Client_Value] AS INT) IS NOT NULL AND [CL].[Client_ID] = TRY_CAST(CF.[Client_Value] AS INT))
					OR (TRY_CAST(CF.[Client_Value] AS INT) IS NULL AND [CL].[Client_Name] = CF.[Client_Value])
			)
		)
		-- Filter by Position ID (if provided) - supports multiple IDs
		-- If Position_ID_OF_Com != 0, filter by Position_ID_OF_Com, otherwise filter by resolved Position_ID
		AND (@Position_ID_str = '' OR @Position_ID_str IS NULL OR 
			(
				([PP].[Position_ID_OF_Com] != 0 AND [PP].[Position_ID_OF_Com] IS NOT NULL 
				 AND [PP].[Position_ID_OF_Com] IN (SELECT [Position_ID_Value] FROM PositionFilter))
				OR
				(([PP].[Position_ID_OF_Com] = 0 OR [PP].[Position_ID_OF_Com] IS NULL) 
				 AND [PP].[Position_ID] IN (SELECT [Position_ID_Value] FROM PositionFilter))
			)
		)AND (
               ( @DateFrom IS NULL AND @DateTo IS NULL )
            OR ( @DateFrom IS NOT NULL AND @DateTo IS NULL
                 AND pp.Job_Req_Date >= @DateFrom )
            OR ( @DateFrom IS NULL AND @DateTo IS NOT NULL
                 AND pp.Job_Req_Date < DATEADD(DAY, 1, @DateTo) )
            OR ( @DateFrom IS NOT NULL AND @DateTo IS NOT NULL
                 AND pp.Job_Req_Date >= @DateFrom
                 AND pp.Job_Req_Date < DATEADD(DAY, 1, @DateTo) )
        )

	ORDER BY PP.Owner_Name, CL.Client_Name, PP.Project_Position_ID;


END
