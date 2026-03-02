USE [Contact]
GO

-- =============================================
-- Author:		Auto Generated
-- Create date: 2024
-- Description:	Get all map contact for clients
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[sp_Get_CliantContact_Report]
	@Reference_ID INT = 0,
	@Company_ID INT = 3357
AS
BEGIN
	SET NOCOUNT ON;

	-- Declare variables
	DECLARE @Contact_Category_Type_ID INT = 0;
	DECLARE @COMPANY_TYPE_ID INT = 0;
	DECLARE @Address_Type_ID INT = 0;
	DECLARE @Category_Type_ID INT = 0;
	DECLARE @Type_Contract_ID_System INT = 0;
	DECLARE @Type_Contract_ID_Company INT = 0;
	DECLARE @Position_Type_Comp INT = 0;
	DECLARE @Position_Type_System INT = 0;
	DECLARE @Category_Mobile_Type_ID INT = 0;

	-- Get Contact Category Type ID
	SET @Contact_Category_Type_ID = (
		SELECT TOP 1 [Category_Type_ID]
		FROM [Contact].[dbo].[Contact_Category_Type]
		WHERE [Category_Name] = 'Client'
	);

	-- Get Company Type ID
	SET @COMPANY_TYPE_ID = (
		SELECT TOP 1 [Company_Type_ID]
		FROM [Company].[dbo].[Company_Type]
		WHERE [Company_Type_Name] = 'Client'
	);

	-- Get Category Type ID
	SET @Category_Type_ID = (
		SELECT TOP 1 [Category_Type_ID]
		FROM [Address].[dbo].[Address_Category_Type]
		WHERE [Category_Type_Name] = 'Company'
	);

	-- Get Mobile Category Type ID
	SET @Category_Mobile_Type_ID = (
		SELECT TOP 1 [Category_Type_ID]
		FROM [Mobile].[dbo].[Mobile_Category_Type]
		WHERE [Category_Type_Name] = 'Client'
	);

	-- Main Query
	WITH TB_Cliant AS (
		SELECT 
			Company_ID,
			Company_Name,
			Com_ID_Of_Com_Type
		FROM [Company].[dbo].[Company] COMP
		WHERE Is_Active = 1 
			AND Is_Delete = 0
			AND Com_ID_Of_Com_Type = @Company_ID
			AND Company_Type_ID = @COMPANY_TYPE_ID
	),
	TB_Position AS (
		SELECT 
			[P].[Position_ID],
			[P].[Position_Name],
			2 AS [Position_By_Com_Type_ID]
		FROM [RMS_Position].[dbo].[Position] P
		UNION
		SELECT 
			[PT].[Position_Temp_ID] AS [Position_ID],
			[PT].[Position_Name],
			1 AS [Position_By_Com_Type_ID]
		FROM [RMS_Position].[dbo].[Position_Temp] PT
	),
	TB_Contact AS (
		SELECT 
			[c].[Contact_ID],
			[c].[Title_ID],
			[c].[First_Name],
			[c].[Middle_Name],
			[c].[Last_Name],
			[c].[Email],
			[c].[Department_Name],
			[POS].[Position_Name],
			[c].[Is_Active],
			[c].[Is_Delete]
		FROM [Contact].[dbo].[Contact] c
		LEFT JOIN TB_Position POS ON [POS].[Position_ID] = (
			CASE 
				WHEN [c].[Position_By_Comp_ID] = 0 OR [c].[Position_By_Comp_ID] IS NULL THEN
					[c].[Position_ID]
				ELSE
					(
						SELECT [Position_ID_OF_Com] = (
							CASE 
								WHEN [PB].[Position_By_Com_Type_ID] = 1 THEN 
									(SELECT [PT].[Position_Temp_ID] 
									 FROM [RMS_Position].[dbo].[Position_Temp] PT 
									 WHERE [PT].[Position_Temp_ID] = [PB].[Position_ID])
								ELSE
									[PB].[Position_ID]
							END
						)
						FROM [RMS_Position].[dbo].[Position_By_Comp] PB 
						WHERE [PB].[Position_By_Com_ID] = [c].[Position_By_Comp_ID]
					)
			END
		)
		AND [POS].[Position_By_Com_Type_ID] = (
			CASE 
				WHEN [c].[Position_By_Comp_ID] = 0 OR [c].[Position_By_Comp_ID] IS NULL THEN 2
				ELSE
					(SELECT [PB].[Position_By_Com_Type_ID] 
					 FROM [RMS_Position].[dbo].[Position_By_Comp] PB 
					 WHERE [PB].[Position_By_Com_ID] = [c].[Position_By_Comp_ID])
			END
		)
	),
	Address_2 AS (
		SELECT 
			[Reference_ID],
			Address_Line2
		FROM [Address].[dbo].[Address] A
		WHERE Address_Type_ID = 2
	),
	Address_1 AS (
		SELECT 
			A.[Address_ID],
			A.[Category_Type_ID],
			A.[Reference_ID],
			A.[Address_Type_ID],
			A.[Address_Line1],
			a2.[Address_Line2],
			A.[City_ID],
			[C].[City_Name],
			A.[District_ID],
			[D].[District_Name],
			A.[Sub_District_ID],
			[SD].[Sub_District_Name],
			A.[Country_ID],
			[CT].[Country_Name],
			A.[Postal_Code_ID],
			Ats.[Address_Type_Name],
			CyT.[Category_Type_Name]
		FROM [Address].[dbo].[Address] A
		LEFT JOIN [Address].[dbo].[Address_Type] Ats ON A.[Address_Type_ID] = Ats.[Address_Type_ID]
		LEFT JOIN [Address].[dbo].[Address_Category_Type] CyT ON CyT.[Category_Type_ID] = A.[Category_Type_ID]
		LEFT JOIN [Country].[dbo].[City] C ON A.[City_ID] = [C].[City_ID]
		LEFT JOIN [Country].[dbo].[District] D ON A.[District_ID] = [D].[District_ID]
		LEFT JOIN [Country].[dbo].[Sub_District] SD ON A.[Sub_District_ID] = [SD].[Sub_District_ID]
		LEFT JOIN [Country].[dbo].[Country] CT ON A.[Country_ID] = [CT].[Country_ID]
		LEFT JOIN Address_2 a2 ON a2.Reference_ID = A.Reference_ID
		WHERE A.[Category_Type_ID] = @Category_Type_ID 
			AND A.Address_Type_ID = 1
	),
	Mobile_contact AS (
		SELECT 
			t.[Tel_ID],
			t.[Reference_ID],
			t.[Tel_Type_ID],
			tt.[Tel_Type_Name],
			t.[Tel_Country_ID],
			[tc].[Tel_Country_Code],
			t.[Tel_Number],
			t.[Category_Type_ID],
			mc.[Category_Type_Name]
		FROM [Mobile].[dbo].[Tel] t
		LEFT JOIN [Mobile].[dbo].[Tel_Type] tt ON t.[Tel_Type_ID] = tt.[Tel_Type_ID]
		LEFT JOIN [Mobile].[dbo].[Mobile_Category_Type] mc ON t.[Category_Type_ID] = mc.[Category_Type_ID]
		LEFT JOIN [Tel_Country].[dbo].[Tel_Country] tc ON tc.[Tel_Country_ID] = t.[Tel_Country_ID]
		WHERE t.[Category_Type_ID] = @Category_Mobile_Type_ID
			AND t.[Is_Active] = 1
			AND t.Tel_Type_ID = 2
	)
	SELECT 
		[cn].Company_ID,
		[cn].Company_Name,
		Map_Contact_ID = ISNULL([MC].[Map_Contact_ID], 0),
		Reference_ID = ISNULL([MC].[Reference_ID], 0),
		Contact_ID = ISNULL([MC].[Contact_ID], 0),
		[Full_Name] = ISNULL(
			CASE 
				WHEN [C].[Middle_Name] IS NULL OR TRIM([C].[Middle_Name]) = '' THEN
					ISNULL(TRIM([T].[Title_Name]), '') + [C].[First_Name] + ' ' + [C].[Last_Name]
				ELSE
					ISNULL(TRIM([T].[Title_Name]), '') + [C].[First_Name] + ' (' + [C].[Middle_Name] + ') ' + [C].[Last_Name]
			END,
			'-'
		),
		[Email] = ISNULL([C].[Email], '-'),
		[Department_Name] = CASE 
			WHEN [C].[Department_Name] IS NULL THEN '-' 
			ELSE [C].[Department_Name] 
		END,
		[Position_Name] = ISNULL([C].[Position_Name], '-'),
		Tel_Country_Code = ISNULL(M.Tel_Country_Code, '-'),
		Tel_Number = ISNULL(M.Tel_Number, '-'),
		[Contact_Category_Type_Name] = ISNULL([CCT].[Category_Name], '-'),
		Address_ID = ISNULL(A.Address_ID, 0),
		Category_Type_ID = ISNULL(A.Category_Type_ID, 0),
		Reference_ID = ISNULL(A.Reference_ID, 0),
		Address_Type_ID = ISNULL(A.Address_Type_ID, 0),
		Address_Line1 = ISNULL(A.Address_Line1, '-'),
		Address_Line2 = ISNULL(A.Address_Line2, '-'),
		City_ID = ISNULL(A.City_ID, 0),
		City_Name = ISNULL(A.City_Name, '-'),
		District_ID = ISNULL(A.District_ID, 0),
		District_Name = ISNULL(A.District_Name, '-'),
		Sub_District_ID = ISNULL(A.Sub_District_ID, 0),
		Sub_District_Name = ISNULL(A.Sub_District_Name, '-'),
		Country_ID = ISNULL(A.Country_ID, 0),
		Country_Name = ISNULL(A.Country_Name, '-'),
		Postal_Code_ID = ISNULL(A.Postal_Code_ID, 0),
		Address_Type_Name = ISNULL(A.Address_Type_Name, '-'),
		Category_Type_Name = ISNULL(A.Category_Type_Name, '-')
	FROM TB_Cliant cn
	LEFT JOIN [Contact].[dbo].[Map_Contact] MC ON cn.Company_ID = MC.Reference_ID
	LEFT JOIN TB_Contact C ON [C].[Contact_ID] = [MC].[Contact_ID]
	LEFT JOIN [Title].[dbo].[Title] T ON [T].[Title_ID] = [C].[Title_ID]
	LEFT JOIN [Contact].[dbo].[Contact_Category_Type] CCT ON [CCT].[Category_Type_ID] = [MC].[Contact_Category_Type_ID]
	LEFT JOIN Address_1 A ON A.Reference_ID = cn.Company_ID
	LEFT JOIN Mobile_contact M ON M.Reference_ID = [MC].Contact_ID
	WHERE ([MC].[Reference_ID] = @Reference_ID OR @Reference_ID = 0)
	ORDER BY [cn].Company_Name, MC.Reference_ID DESC;

END
GO

-- Example usage:
-- EXEC [dbo].[sp_Get_ALL_Map_Contact] @Reference_ID = 3441, @Company_ID = 3357
-- EXEC [dbo].[sp_Get_ALL_Map_Contact] @Reference_ID = 0, @Company_ID = 3357
