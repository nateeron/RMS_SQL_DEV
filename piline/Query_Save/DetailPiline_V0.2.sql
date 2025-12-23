use Pipeline
go

declare	@Project_Position_ID int = 3111;
declare	@Company_ID int =3357;
declare @Owner_Name Nvarchar(100) =''

	
	SELECT
		[MC].[Map_Can_Pile_Com_ID],
		[MC].[Candidate_ID],
		[MC].[Pipeline_ID],

		CONCAT(TRIM([T].[Title_Name]) + ' ', [P].[Full_Name]) AS [Candidate_Name],
		[P].[Profile_Image_Gen],
		[Is_Employee] = (
							SELECT [Is_Employee] = CASE WHEN [A].[Sum_Is_Employee] > 0 THEN 1
													ELSE 0 END
							FROM (
								SELECT [Sum_Is_Employee] = COUNT(*) 
								FROM [Candidate].[dbo].[Candidate] C
								WHERE [C].[Candidate_ID] = [MC].[Candidate_ID]
								AND [C].[Is_Employee] = 1
							) A
						),
		[Employee_ID] = CASE WHEN [EMP].[Employee_ID] IS NULL THEN 0
						ELSE [EMP].[Employee_ID] END,
		[Created_Date] = CASE WHEN [MC].[Created_Date] IS NULL THEN '-'
						 ELSE FORMAT([MC].[Created_Date], 'dd MMM yyyy HH:mm') END,
		[LUC].[Owner_ID],
		CONCAT(LTRIM(RTRIM([T_Own].[Title_Name])) + ' ' ,[Own].[Full_Name]) AS [Owner_Name]
	FROM [dbo].[Map_Can_Pile_Com] MC
	LEFT JOIN [Candidate].[dbo].[Candidate] C ON [C].[Candidate_ID] = [MC].[Candidate_ID]
	LEFT JOIN [Person].[dbo].[Person] P ON [P].[Person_ID] = [C].[Person_ID]
	LEFT JOIN [Title].[dbo].[Title] T ON [T].[Title_ID] = [P].[Title_ID]
	LEFT JOIN [Employee].[dbo].[Employee] EMP ON [EMP].[Candidate_ID] = [MC].[Candidate_ID]  AND [EMP].[Is_Deleted] = 0
	LEFT JOIN (
					SELECT [CAN].*
					FROM (
								SELECT [tt].[Update_By] AS [Owner_ID]
										,[tt].[Update_Date]
										,[tt].[Candidate_ID]
								FROM [Candidate].[dbo].[Log_Update_Candidate] tt
								INNER JOIN (
												SELECT [ss].[Candidate_ID]
														,MAX([ss].[Update_Date]) AS MaxDateTime
												FROM [Candidate].[dbo].[Log_Update_Candidate] ss
												WHERE [ss].[Is_Employee] = 0
												AND [ss].[Is_Terminate] = 0
												GROUP BY [ss].[Candidate_ID]
								) groupedtt ON tt.[Candidate_ID] = groupedtt.[Candidate_ID] AND tt.[Update_Date] = groupedtt.MaxDateTime AND [tt].[Is_Employee] = 0 AND [tt].[Is_Terminate] = 0
								GROUP BY [tt].[Update_By], [tt].[Update_Date], [tt].[Candidate_ID]
					) CAN
	) LUC ON [LUC].[Candidate_ID] = [C].[Candidate_ID] AND [C].[Is_Deleted] = 0
	LEFT JOIN [Person].[dbo].[Person] Own ON [Own].[Person_ID] = [LUC].[Owner_ID]
	LEFT JOIN [Title].[dbo].[Title] T_Own ON [T_Own].[Title_ID] = [Own].[Title_ID]
	WHERE
	
	 [MC].[Project_Position_ID] = @Project_Position_ID AND
	 [MC].[Company_ID] = @Company_ID
	 AND CONCAT(LTRIM(RTRIM([T_Own].[Title_Name])) + ' ' ,[Own].[Full_Name]) like '%'+@Owner_Name+'%'
--select * from [Map_Can_Pile_Com] where Company_ID = @Company_ID
--SELECT * FROM [dbo].[Map_Can_Pile_Com] MC