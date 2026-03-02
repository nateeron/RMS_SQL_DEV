USE [Employee]
GO
/****** Object:  StoredProcedure [dbo].[sp_GetById_Employee]    Script Date: 12/12/2025 11:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




-- =============================================
-- Procedure name: [dbo].[sp_GetById_Employee]
-- Function: GetAll of Faculty
-- Create date: 1/4/23
-- Description:	Select function seach getall
-- =============================================
ALTER PROCEDURE [dbo].[sp_GetById_Employee]
@Employee_ID INT = 0
AS
DECLARE @Status_New_ID INT = 0;
BEGIN TRY
	SET @Status_New_ID = (SELECT TOP 1 [SC].[Status_Contract_EMP_ID] 
							FROM [DBO].[Status_Contract_EMP] SC
							WHERE [SC].[Status_Contract_EMP_Name] = 'New' );
	SELECT [dbo].[Employee].[Candidate_ID],
		   [dbo].[Employee].[Employee_ID],
		   [dbo].[Employee].[Company_ID],
		   [C].[Company_Name],
		   FORMAT([CONTR].[Start_Date] , 'dd MMM yyyy') AS [Start_Date_str],  
		   FORMAT([CONTR].[DOJ] , 'dd MMM yyyy') AS [Date_Of_Join_str],  
		  [End_Date_str] = CASE WHEN [CONTR].[End_Date] IS NULL
						        THEN '-'
						   ELSE
						        FORMAT([CONTR].[End_Date] , 'dd MMM yyyy')   
						   END, 
		   [CONTR].[Start_Date] ,
		   [CONTR].[DOJ] ,
		   [CONTR].[End_Date] ,
		   [CONTR].[Contract_EMP_ID], 
		   --[SCEMP].[Status_Contract_EMP_Name],
		   [POS].[Position_Name] ,
		   [CONTR].[Contract_Type_Name],
		   [CONTR].[Salary],
		   [CONTR].[Refer_By_Name],
		   [dbo].[Employee].[Status_Employee],
		   [CONTR].[Project_Position_ID],
		   [dbo].[Employee].[Employee_No],
		   [dbo].[Employee].[Manager_ID],
		   [MN].[Manager_Name]
	FROM [dbo].[Employee]
	LEFT JOIN [Company].[dbo].[Company] C ON [dbo].[Employee].[Company_ID] = [C].[Company_ID]
	LEFT JOIN 
			( 
			SELECT [CTEMP].*
					,[ER].[Refer_By_Name]
					,[CONTYP].[Contract_Type_Name]
				FROM [DBO].[Contract_EMP] CTEMP
				LEFT JOIN 
			(
				SELECT [P].[Contract_Type_ID] , [P].[Contract_Type_Name] , 2 AS [Contract_Type_By_Comp_Type_ID]  
				FROM  [RMS_Contract_Type].[dbo].[Contract_Type] P  
			UNION
				SELECT [PT].[Contract_Type_Temp_ID] AS [Contract_Type_ID] , [PT].[Contract_Type_Temp_Name] , 1 AS [Contract_Type_By_Comp_Type_ID]
				FROM [RMS_Contract_Type].[dbo].[Contract_Type_Temp] PT
			)CONTYP ON [CONTYP].[Contract_Type_ID] = (
														CASE WHEN [CTEMP].[Contract_Type_By_Comp_ID] = 0 OR [CTEMP].[Contract_Type_By_Comp_ID] IS NULL
															 THEN [CTEMP].[Contract_Type_ID_OF_Com]
														ELSE
															 (
																SELECT [Contract_Type_ID_OF_Com] = (
																										CASE WHEN [PB].[Contract_Type_By_Comp_Type_ID] = 1
																											 THEN (
																													SELECT [PT].[Contract_Type_Temp_ID]
																													FROM [RMS_Contract_Type].[dbo].[Contract_Type_Temp] PT
																													WHERE [PT].[Contract_Type_Temp_ID] = [PB].[Contract_Type_ID]
																											      )
																										 ELSE
																											 [PB].[Contract_Type_ID]
																										 END
																								   )
																FROM [RMS_Contract_Type].[dbo].[Contract_Type_By_Comp] PB
																WHERE [PB].[Contract_Type_By_Comp_ID] = [CTEMP].[Contract_Type_By_Comp_ID]
															 )
														END
													 )
					AND [CONTYP].[Contract_Type_By_Comp_Type_ID] = (
																	CASE WHEN [CTEMP].[Contract_Type_By_Comp_ID] = 0 OR [CTEMP].[Contract_Type_By_Comp_ID] IS NULL 
																			THEN 2
																	ELSE
																		(
																			SELECT [PB].[Contract_Type_By_Comp_Type_ID]
																			FROM [RMS_Contract_Type].[dbo].[Contract_Type_By_Comp] PB
																			WHERE [PB].[Contract_Type_By_Comp_ID] = [CTEMP].[Contract_Type_By_Comp_ID]
																		)
																	END
																)
				LEFT JOIN (SELECT [Refer_By_Name] = (CASE WHEN [T].[Title_Name] IS NOT NULL THEN TRIM([T].[Title_Name]) + ' ' + [P].[Full_Name]
												 ELSE [P].[Full_Name] END),
							  [EMP].[Employee_ID]
					   FROM [Employee].[dbo].[Employee] EMP
					   LEFT JOIN [Candidate].[dbo].[Candidate] C ON [C].[Candidate_ID] = [EMP].[Candidate_ID]
					   LEFT JOIN [Person].[dbo].[Person] P ON [P].[Person_ID] = [C].[Person_ID]
					   LEFT JOIN [Title].[dbo].[Title] T ON [T].[Title_ID] = [P].[Title_ID]) ER ON [ER].[Employee_ID] = [CTEMP].[Refer_By]
				WHERE [CTEMP].[Employee_ID] = @Employee_ID
				AND [CTEMP].[Contract_EMP_ID] = (SELECT MAX([CT].[Contract_EMP_ID] ) 
												FROM [DBO].[Contract_EMP] CT
												WHERE [CT].[Employee_ID] = @Employee_ID
												AND [CT].[Is_Active] = 1
												GROUP BY [CT].[Employee_ID])
			) CONTR  ON [DBO].[Employee].[Employee_ID] = [CONTR].[Employee_ID]
	LEFT JOIN  
					( select [P].[Position_ID] , [P].[Position_Name] , 2 AS [Position_By_Com_Type_ID]  FROM  [RMS_Position].[dbo].[Position] P  
						UNION
						SELECT [PT].[Position_Temp_ID] AS [Position_ID] , [PT].[Position_Name] , 1 AS [Position_By_Com_Type_ID]
						FROM [RMS_Position].[DBO].[Position_Temp] PT
					) POS ON [POS].[Position_ID] = 
														(
													CASE 
													WHEN [CONTR].[Position_By_Com_ID] = 0 OR [CONTR].[Position_By_Com_ID] IS NULL  THEN
															[CONTR].[Position_ID_OF_Com]
													ELSE
															(SELECT  [Position_ID_OF_Com] = (CASE  WHEN [PB].[Position_By_Com_Type_ID] = 1 THEN 
																										(SELECT TOP 1 [PT].[Position_Temp_ID]
																										FROM [RMS_Position].[dbo].[Position_Temp] PT
																										WHERE [PT].[Position_Temp_ID] = [PB].[Position_ID])
																								ELSE
																										[PB].[Position_ID]
																								END)
															FROM [RMS_Position].[dbo].[Position_By_Comp] PB 
															WHERE [PB].[Position_By_Com_ID] = [CONTR].[Position_By_Com_ID]
															)
													END
													)
							AND [POS].[Position_By_Com_Type_ID] =
														(
															CASE 
															WHEN [CONTR].[Position_By_Com_ID] = 0 OR [CONTR].[Position_By_Com_ID] IS NULL  THEN
																2
															ELSE
																(SELECT TOP 1 [PB].[Position_By_Com_Type_ID]
																FROM [RMS_Position].[dbo].[Position_By_Comp] PB WHERE [PB].[Position_By_Com_ID] = [CONTR].[Position_By_Com_ID])
															END
															) 
	LEFT JOIN [DBO].[Status_Contract_EMP] SCEMP ON [CONTR].[Status_Contract_EMP_ID] = [SCEMP].[Status_Contract_EMP_ID]
	LEFT JOIN (SELECT [Manager_Name] = (CASE WHEN [T].[Title_Name] IS NOT NULL THEN TRIM([T].[Title_Name]) + ' ' + [P].[Full_Name]
												 ELSE [P].[Full_Name] END),
							  [EMP].[Employee_ID]
					   FROM [Employee].[dbo].[Employee] EMP
					   LEFT JOIN [Candidate].[dbo].[Candidate] C ON [C].[Candidate_ID] = [EMP].[Candidate_ID]
					   LEFT JOIN [Person].[dbo].[Person] P ON [P].[Person_ID] = [C].[Person_ID]
					   LEFT JOIN [Title].[dbo].[Title] T ON [T].[Title_ID] = [P].[Title_ID]
				) MN ON [MN].[Employee_ID] = [dbo].[Employee].[Manager_ID]
	WHERE [dbo].[Employee].[Is_Deleted] = 0
	AND [dbo].[Employee].[Employee_ID] = @Employee_ID;
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
				,'DB Employee - sp_GetById_Employee'
				,ERROR_MESSAGE()
				,999
				,GETDATE());
END CATCH

