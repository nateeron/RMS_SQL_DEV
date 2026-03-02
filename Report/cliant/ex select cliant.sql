USE [Company]
GO

DECLARE @Company_ID INT = 3357

DECLARE @COMPANY_TYPE_ID INT = 0,
	@Address_Type_ID INT = 0,
	@Category_Type_ID INT = 0,
	@Type_Contract_ID_System INT = 0,
	@Type_Contract_ID_Company INT = 0,
	@Position_Type_Comp INT = 0,
	@Position_Type_System INT = 0;

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
SET @Type_Contract_ID_Company = (
		SELECT TOP(1) [CTYPE].[Contract_Type_By_Comp_Type_ID] --1
		FROM [RMS_Contract_Type].[dbo].[Contract_Type_By_Comp_Type] CTYPE
		WHERE [CTYPE].[Contract_Type_By_Comp_Type_Name] = 'Company'
	);
SET @Type_Contract_ID_System = (
		SELECT TOP(1) [CTYPE].[Contract_Type_By_Comp_Type_ID] --2
		FROM [RMS_Contract_Type].[dbo].[Contract_Type_By_Comp_Type] CTYPE
		WHERE [CTYPE].[Contract_Type_By_Comp_Type_Name] = 'System'
	);
SET @Position_Type_Comp = (
		SELECT TOP(1) [PT].[Position_By_Com_Type_ID] --1
		FROM [RMS_Position].[dbo].[Position_By_Comp_Type] PT
		WHERE [PT].[Position_By_Com_Type_Name] = 'Company'
	)
SET @Position_Type_System = (
		SELECT TOP(1) [PT].[Position_By_Com_Type_ID] --2
		FROM [RMS_Position].[dbo].[Position_By_Comp_Type] PT
		WHERE [PT].[Position_By_Com_Type_Name] = 'System'
	) BEGIN
	
	WITH MBP_MapBranchProject AS (
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
	TBPosition_ID AS (
		SELECT PB.[Position_By_Com_Type_ID],
			Position_ID = CASE
				WHEN PB.[Position_By_Com_Type_ID] = 1 THEN PT.[Position_Temp_ID]
				ELSE PB.[Position_ID]
			END,
			PB.Position_By_Com_ID
		FROM [RMS_Position].[dbo].[Position_By_Comp] PB
			LEFT JOIN [RMS_Position].[dbo].[Position_Temp] PT ON PT.[Position_Temp_ID] = PB.[Position_ID]
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
	PP_ProjectPosition AS (
		SELECT COM.Company_ID AS Client_ID,
			COM.Company_Name AS Client_Name,
			PP.Position_By_Comp_ID,
			PP.Project_Position_ID,
			PP.QTY,
			[Hiring] = CASE
				WHEN [MCP2].[Hiring] IS NULL
				OR [MCP2].[Hiring] = 0 THEN 0
				ELSE [MCP2].[Hiring]
			END,
			PP.Is_Active,
			PP.Budget_Negotiate,
			P.Position_Name,
			P.Position_By_Com_Type_ID,
			[Profile_Image_Gen] = CASE
				WHEN [COM].[Profile_Image_Gen] IS NULL THEN ''
				ELSE [COM].[Profile_Image_Gen]
			END,
			[Branch_Name] = CASE
				WHEN [MPP].[Branch_Name] IS NOT NULL THEN [MPP].[Branch_Name]
				ELSE CASE
					WHEN [MSP].[Branch_Name] IS NOT NULL THEN [MSP].[Branch_Name]
					ELSE CASE
						WHEN [MBP].[Branch_Name] IS NOT NULL THEN [MBP].[Branch_Name]
						ELSE '-'
					END
				END
			END,
			[Site_Name] = CASE
				WHEN [MPP].[Site_Name] IS NOT NULL THEN [MPP].[Site_Name]
				ELSE CASE
					WHEN [MSP].[Site_Name] IS NOT NULL THEN [MSP].[Site_Name]
					ELSE '-'
				END
			END,
			[Project_Name] = CASE
				WHEN [MPP].[Project_Name] IS NOT NULL THEN [MPP].[Project_Name]
				ELSE '-'
			END,
			CASE
				WHEN [PS].[Owner] IS NOT NULL THEN [PS].[Owner]
				ELSE '-'
			END AS [Owner]
		FROM Company.dbo.Project_Position PP
			LEFT JOIN P_Position P ON P.Position_ID = ISNULL(
				(
					SELECT Position_ID
					FROM TBPosition_ID
					WHERE Position_By_Com_ID = PP.Position_By_Comp_ID
				),
				PP.Position_ID
			)
			AND P.Position_By_Com_Type_ID = ISNULL(
				(
					SELECT PB.Position_By_Com_Type_ID
					FROM RMS_Position.dbo.Position_By_Comp PB
					WHERE PB.Position_By_Com_ID = PP.Position_By_Comp_ID
				),
				2
			)
			LEFT JOIN Company.dbo.Map_Comp_Position MCPP ON MCPP.Project_Position_ID = PP.Project_Position_ID
			AND MCPP.Is_Active = 1
			AND MCPP.Is_Delete = 0
			LEFT JOIN MPP_Map_Project_Position MPP ON MPP.Project_Position_ID = PP.Project_Position_ID
			LEFT JOIN MSP_Map_Site_Position MSP ON MSP.Project_Position_ID = PP.Project_Position_ID
			LEFT JOIN MBP_Map_Branch_Position MBP ON MBP.Project_Position_ID = PP.Project_Position_ID
			LEFT JOIN (
				SELECT MUP.Project_Position_ID,
					P.Full_Name AS Owner
				FROM Company.dbo.Map_User_PrjPosi MUP
					LEFT JOIN Person.dbo.Person P ON P.Person_ID = MUP.Person_ID
				WHERE MUP.Is_Active = 1
			) PS ON PS.Project_Position_ID = PP.Project_Position_ID
			LEFT JOIN (
				SELECT M.Project_Position_ID,
					COUNT(*) AS Hiring
				FROM Pipeline.dbo.Map_Can_Pile_Com M
				WHERE M.Is_Active = 1
					AND M.Pipeline_ID IN (
						SELECT P.Pipeline_ID
						FROM Pipeline.dbo.Pipeline P
						WHERE P.Pipeline_Name = 'Sign Contract'
							AND P.Pipeline_Type_ID = 1 --  @Pipeline_Type_System
					)
				GROUP BY M.Project_Position_ID
			) MCP2 ON MCP2.Project_Position_ID = PP.Project_Position_ID
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
			AND COM.Com_ID_Of_Com_Type = @Company_ID
	)
select Client_ID,
	Client_Name,
	SUM(QTY) AS QTY,
	SUM(Hiring) AS Hiring,
	SUM([QTY]) - SUM([Hiring]) AS Left_Position into #Position_Hiring
from PP_ProjectPosition
GROUP BY Client_ID,
	Client_Name
END BEGIN
SELECT [A].[Client_ID],
	[A].[Client_Name],
	[A].[Client_Abbreviation],
	[A].[Industry_ID],
	[A].[Industry_Name],
	[A].[Company_Type_Name],
	[A].[Profile_Image_Gen] AS [Profile_Image],
	[A].[Country_Name],
	[A].[City_Name],
	[A].QTY,
	[A].Hiring,
	[A].Left_Position,
	[A].[Owner_ID]
FROM (
		SELECT [COMP].[Company_ID] AS [Client_ID],
			[COMP].[Company_Name] AS [Client_Name],
			[COMP].[Company_abbreviation] AS [Client_Abbreviation],
			[COMP].[Industry_ID],
			[IND].[Industry_Name],
			[CT].[Company_Type_Name],
			[COMP].[Profile_Image_Gen],
			[ADS].[Country_Name],
			[ADS].[City_Name],
			PPP.QTY,
			PPP.Hiring,
			PPP.Left_Position,
			[Owner_ID] = [COMP].[Updated_By]
		FROM [Company].[dbo].[Company] COMP
			LEFT JOIN [Industry].[dbo].[Industry] IND ON [IND].[Industry_ID] = [COMP].[Industry_ID]
			LEFT JOIN [Company].[dbo].[Company_Type] CT ON [CT].[Company_Type_ID] = [COMP].[Company_Type_ID]
			LEFT JOIN #Position_Hiring PPP ON [PPP].[Client_ID] = [COMP].[Company_ID]
			LEFT JOIN (
				SELECT [ADDR].[Address_ID],
					[ADDR].[Reference_ID],
					[ADDR].[City_ID],
					[COUN].[City_Name],
					[ADDR].[Country_ID],
					[COUN].[Country_Name]
				FROM [Address].[dbo].[Address] ADDR
					LEFT JOIN (
						SELECT [C].[Country_ID],
							[C].[Country_Name],
							[CT].[City_ID],
							[CT].[City_Name]
						FROM [Country].[dbo].[Country] C
							LEFT JOIN [Country].[dbo].[City] CT ON [CT].[Country_ID] = [C].[Country_ID]
					) COUN ON [ADDR].[Country_ID] = [COUN].[Country_ID]
					AND [ADDR].[City_ID] = [COUN].[City_ID]
				WHERE [ADDR].[Address_Type_ID] = @Address_Type_ID
					AND [ADDR].[Category_Type_ID] = @Category_Type_ID
			) ADS ON [ADS].[Reference_ID] = [COMP].[Company_ID]
		WHERE [COMP].[Com_ID_Of_Com_Type] = @Company_ID
			AND [COMP].[Company_Type_ID] = @COMPANY_TYPE_ID
			AND [COMP].[Is_Active] = 1
			AND [COMP].[Is_Delete] = 0
		GROUP BY [COMP].[Company_ID],
			[COMP].[Company_abbreviation],
			[COMP].[Industry_ID],
			[IND].[Industry_Name],
			[CT].[Company_Type_Name],
			[COMP].[Profile_Image_Gen],
			[ADS].[Country_Name],
			[ADS].[City_Name],
			[COMP].[Company_Name],
			COMP.Updated_By,
			PPP.QTY,
			PPP.Hiring,
			PPP.Left_Position
	) A
	ORDER BY [A].[Client_Name] ASC;

END 
	IF OBJECT_ID('tempdb..#Position_Hiring') IS NOT NULL DROP TABLE #Position_Hiring;

