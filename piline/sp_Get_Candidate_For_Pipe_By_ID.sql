USE [Candidate]
GO
/****** Object:  StoredProcedure [dbo].[sp_Get_Candidate_For_Pipe_By_ID]    Script Date: 12/12/2025 3:29:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- [sp_Get_Candidate_For_Pipe_By_ID] 5021
-- =============================================
ALTER PROCEDURE [dbo].[sp_Get_Candidate_For_Pipe_By_ID]
	@Candidate_ID int = 0
AS
BEGIN TRY
	SELECT
		[C].[Candidate_ID],
		CONCAT(LTRIM(RTRIM([T].[Title_Name])) + ' ' ,[P].[Full_Name]) AS [Candidate_Name],
		[P].[Profile_Image_Gen],
		[POS].[Position_Name],
		[MCP].[Map_Can_Pile_Com_ID],
		[EMP].[Employee_ID],
		[C].[Is_Employee],
		[LUC].[Owner_ID],
		CONCAT(LTRIM(RTRIM([T_Own].[Title_Name])) + ' ' ,[Own].[Full_Name]) AS [Owner_Name]
	FROM [dbo].[Candidate] C
	LEFT JOIN [Person].[dbo].[Person] P ON [P].[Person_ID] = [C].[Person_ID]
	LEFT JOIN [Title].[dbo].[Title] T ON [T].[Title_ID] = [P].[Title_ID]
	LEFT JOIN (
			SELECT [P].[Position_ID] , [P].[Position_Name] , 2 AS [Position_By_Com_Type_ID]  FROM  [RMS_Position].[dbo].[Position] P
			UNION
			SELECT [PT].[Position_Temp_ID] AS [Position_ID] , [PT].[Position_Name] , 1 AS [Position_By_Com_Type_ID] FROM [RMS_Position].[DBO].[Position_Temp] PT
		) POS ON [POS].[Position_ID] = (
												CASE 
													WHEN [C].[Current_Position_By_Com] = 0 OR [C].[Current_Position_By_Com]  IS NULL  THEN
															[C].[Current_Position]

													ELSE
															(SELECT  [Position_ID_OF_Com] = (CASE  WHEN [PB].[Position_By_Com_Type_ID] = 1 THEN 
																										(SELECT [PT].[Position_Temp_ID]
																										FROM [RMS_Position].[dbo].[Position_Temp] PT
																										WHERE [PT].[Position_Temp_ID] = [PB].[Position_ID])
																								ELSE
																										[PB].[Position_ID]
																								END)
															FROM [RMS_Position].[dbo].[Position_By_Comp] PB 
															WHERE [PB].[Position_By_Com_ID] = [C].[Current_Position_By_Com]
															)
													END
											)
			AND [POS].[Position_By_Com_Type_ID] = (
													CASE 
															WHEN [C].[Current_Position_By_Com] = 0 OR [C].[Current_Position_By_Com] IS NULL  THEN
																2
															ELSE
																(SELECT [PB].[Position_By_Com_Type_ID]
																FROM [RMS_Position].[dbo].[Position_By_Comp] PB WHERE [PB].[Position_By_Com_ID] = [C].[Current_Position_By_Com])
													END
													)
	LEFT JOIN [Pipeline].[dbo].[Map_Can_Pile_Com] MCP ON [MCP].[Candidate_ID] = @Candidate_ID
	LEFT JOIN [Employee].[dbo].[Employee] EMP ON [EMP].[Candidate_ID] = @Candidate_ID
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
	WHERE [C].[Candidate_ID] = @Candidate_ID
END TRY
BEGIN CATCH
	INSERT INTO [LOG].[dbo].[Log]
			([Software_ID]
			,[Function_Name]
			,[Detail]
			,[Created By]
			,[Created Date])
		VALUES
			('1'
			,'DB Candidate - sp_Get_Candidate_For_Pipe_By_ID'
			,ERROR_MESSAGE()
			,999
			,GETDATE());
END CATCH
