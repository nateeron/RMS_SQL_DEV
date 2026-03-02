USE [Employee]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Procedure name: [dbo].[sp_Get_Terminated_Employees]
-- Function: List employees that have a Terminate_Date
-- Create date: 12/17/2025
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[sp_Get_Terminated_Employees]
	@Company_ID INT = 0,
	@From_Terminate_Date NVARCHAR(50) = '',
	@To_Terminate_Date NVARCHAR(50) = ''
AS
BEGIN TRY
	SELECT
		EMP.[Employee_ID],
		EMP.[Candidate_ID],
		CN.[Full_Name] AS [Employee_Name],
		EMP.[Company_ID],
		C.[Company_Name],
		CE.[Contract_EMP_ID],
		CE.[Terminate_Status_ID],
		CE.[Terminate_Remark],
		CE.[Terminate_Date]
	FROM [Employee].[dbo].[Contract_EMP] CE
	INNER JOIN [Employee].[dbo].[Employee] EMP ON EMP.[Employee_ID] = CE.[Employee_ID] AND EMP.[Is_Deleted] = 0
	LEFT JOIN [Candidate].[dbo].[Candidate] CAN ON CAN.[Candidate_ID] = EMP.[Candidate_ID]
	LEFT JOIN [Person].[dbo].[Person] CN ON CN.[Person_ID] = CAN.[Person_ID]
	LEFT JOIN [Company].[dbo].[Company] C ON C.[Company_ID] = EMP.[Company_ID]
	WHERE CE.[Terminate_Date] IS NOT NULL
		AND CE.[Is_Deleted] = 0
		AND (@Company_ID = 0 OR EMP.[Company_ID] = @Company_ID)
		AND (
			@From_Terminate_Date = '' 
			OR TRY_CAST(@From_Terminate_Date AS DATE) IS NULL 
			OR CE.[Terminate_Date] >= TRY_CAST(@From_Terminate_Date AS DATE)
		)
		AND (
			@To_Terminate_Date = '' 
			OR TRY_CAST(@To_Terminate_Date AS DATE) IS NULL 
			OR CE.[Terminate_Date] <= TRY_CAST(@To_Terminate_Date AS DATE)
		)
	ORDER BY CE.[Terminate_Date] DESC;
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
				,'DB Employee - sp_Get_Terminated_Employees'
				,ERROR_MESSAGE()
				,999
				,GETDATE());
END CATCH

