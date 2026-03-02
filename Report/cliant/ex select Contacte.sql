USE [Contact]
GO

-- sp_Get_ALL_Map_Contact 3441 , "Client"

DECLARE @Reference_ID INT = 0

DECLARE @Contact_Category_Type_ID INT = 0

SET @Contact_Category_Type_ID = (SELECT TOP (1) [Contact].[dbo].[Contact_Category_Type].[Category_Type_ID]
							FROM [Contact].[dbo].[Contact_Category_Type]
							WHERE [Contact].[dbo].[Contact_Category_Type].[Category_Name] ='Client')


SELECT	[MC].[Map_Contact_ID],
		[MC].[Reference_ID],
		[MC].[Contact_ID], 
		[MC].[Is_Active],
		[T].[Title_Name],
		[Full_Name] = CASE WHEN [C].[Middle_Name] IS NULL OR TRIM([C].[Middle_Name]) = '' THEN [C].[First_Name] + ' ' + [C].[Last_Name] 
						  ELSE [C].[First_Name] + ' ' + '(' + [C].[Middle_Name] + ')' + ' ' + [C].[Last_Name] END,
	   [C].[Email],
	   [Department_Name] = CASE WHEN [C].[Department_Name] IS NULL THEN '-' ELSE [C].[Department_Name] END,
	   [C].[Position_Name],
	   [CCT].[Category_Name] AS [Contact_Category_Type_Name]
FROM [Contact].[dbo].[Map_Contact] MC
LEFT JOIN  
	(
		SELECT [c].[Contact_ID],
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
		LEFT JOIN (
			SELECT [P].[Position_ID] , [P].[Position_Name] , 2 AS [Position_By_Com_Type_ID]  FROM  [RMS_Position].[dbo].[Position] P 
			UNION
			SELECT [PT].[Position_Temp_ID] AS [Position_ID] , [PT].[Position_Name] , 1 AS [Position_By_Com_Type_ID]
			FROM [RMS_Position].[DBO].[Position_Temp] PT) POS ON [POS].[Position_ID] = (CASE 
																						WHEN [c].[Position_By_Comp_ID] = 0 OR [c].[Position_By_Comp_ID] IS NULL  THEN
																							[c].[Position_ID]
																						ELSE
																							(SELECT  [Position_ID_OF_Com] = (CASE  WHEN [PB].[Position_By_Com_Type_ID] = 1 THEN 
																																(SELECT [PT].[Position_Temp_ID] FROM [RMS_Position].[dbo].[Position_Temp] PT WHERE [PT].[Position_Temp_ID] = [PB].[Position_ID])
																															ELSE
																																[PB].[Position_ID]
																															END)
																							FROM [RMS_Position].[dbo].[Position_By_Comp] PB WHERE [PB].[Position_By_Com_ID] = [c].[Position_By_Comp_ID])
																						END)
													AND [POS].[Position_By_Com_Type_ID] = (CASE 
																								WHEN [c].[Position_By_Comp_ID] = 0 OR [c].[Position_By_Comp_ID] IS NULL  THEN
																									2
																								ELSE
																									(SELECT [PB].[Position_By_Com_Type_ID]
																									FROM [RMS_Position].[dbo].[Position_By_Comp] PB WHERE [PB].[Position_By_Com_ID] = [c].[Position_By_Comp_ID])
																								END) 
		
	) C ON [C].[Contact_ID] = [MC].[Contact_ID]

LEFT JOIN [Title].[dbo].[Title] T ON [T].[Title_ID] = [C].[Title_ID]
LEFT JOIN [Contact].[dbo].[Contact_Category_Type] CCT ON [CCT].[Category_Type_ID] = [MC].[Contact_Category_Type_ID]
WHERE [C].[Is_Active] = 1
AND [C].[Is_Delete] = 0
AND ( [MC].[Reference_ID] = @Reference_ID or @Reference_ID = 0)
AND ([MC].[Contact_Category_Type_ID] = @Contact_Category_Type_ID OR @Contact_Category_Type_ID  = 0 )
	

