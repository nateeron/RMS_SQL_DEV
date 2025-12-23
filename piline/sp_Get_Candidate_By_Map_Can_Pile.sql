USE [Pipeline]
GO
/****** Object:  StoredProcedure [dbo].[sp_Get_Candidate_By_Map_Can_Pile]    Script Date: 12/12/2025 3:18:17 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
--1
--18
--19
--20
--2
--3
--4
-- [sp_Get_Candidate_By_Map_Can_Pile] 4,3111,3357
-- =============================================
ALTER PROCEDURE [dbo].[sp_Get_Candidate_By_Map_Can_Pile]
	@Pipeline_ID int = 0,
	@Project_Position_ID int = 0,
	@Company_ID int = 0
AS
BEGIN TRY
	SELECT
		[MC].[Map_Can_Pile_Com_ID],
		[MC].[Candidate_ID],
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
						 ELSE FORMAT([MC].[Created_Date], 'dd MMM yyyy HH:mm') END
	FROM [dbo].[Map_Can_Pile_Com] MC
	LEFT JOIN [Candidate].[dbo].[Candidate] C ON [C].[Candidate_ID] = [MC].[Candidate_ID]
	LEFT JOIN [Person].[dbo].[Person] P ON [P].[Person_ID] = [C].[Person_ID]
	LEFT JOIN [Title].[dbo].[Title] T ON [T].[Title_ID] = [P].[Title_ID]
	LEFT JOIN [Employee].[dbo].[Employee] EMP ON [EMP].[Candidate_ID] = [MC].[Candidate_ID]  AND [EMP].[Is_Deleted] = 0
	WHERE [MC].[Pipeline_ID] = @Pipeline_ID
	AND [MC].[Project_Position_ID] = @Project_Position_ID
	AND [MC].[Company_ID] = @Company_ID
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
				,'DB Pipeline - sp_Get_Candidate_By_Map_Can_Pile'
				,ERROR_MESSAGE()
				,999
				,GETDATE());
END CATCH
