USE [Employee]
GO
/****** Object:  StoredProcedure [dbo].[sp_GetAll_Employee]    Script Date: 12/12/2025 11:40:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Procedure name: [dbo].[sp_GetAll_Employee]
-- Function: GetAll of Faculty
-- Create date: 1/4/23
-- Description:	Select function seach getall
-- sp_GetAll_Employee 3357
-- =============================================
ALTER PROCEDURE [dbo].[sp_GetAll_Employee]
@Company_ID INT = 1,
@Title_ID INT = 0,
@Employee_Name NVARCHAR(512) = NULL,
@Contact_Type_ID INT = 0,
@Start_Date NVARCHAR(1024) = NULL,
@End_Date NVARCHAR(64) = NULL,
@Date_Of_Join NVARCHAR(64) = NULL 

AS
DECLARE @Status_ID INT = 0,
        @sqlcommand NVARCHAR(MAX) = NULL;

SET  @Status_ID = (SELECT TOP 1 [SCE].[Status_Contract_EMP_ID]
					FROM [Employee].[dbo].[Status_Contract_EMP] SCE
					WHERE [SCE].[Status_Contract_EMP_Name] = 'New');

BEGIN TRY
	SET @sqlcommand = 'SELECT
							[EMP].[Employee_ID],
							[CANDIDATE].[Title_Name],
							[CANDIDATE].[Full_Name] AS [Employee_Name],
							[Contract_Type_Name] = CASE WHEN [SED].[Contract_Type_Name] IS NOT NULL
														THEN [SED].[Contract_Type_Name]
													ELSE
														''-''
													END,
							[C].[Company_Name],
							[Start_Date_str] = CASE WHEN [SED].[Start_Date] IS NULL THEN ''-''
												ELSE FORMAT([SED].[Start_Date], ''dd MMM yyyy'') END,
							[End_Date_str] = CASE WHEN [SED].[End_Date] IS NULL THEN ''-''
												ELSE FORMAT([SED].[End_Date], ''dd MMM yyyy'') END,
							[Date_Of_Join_str] = CASE WHEN [SED].[Date_Of_Join] IS NULL THEN ''-''
												ELSE FORMAT([SED].[Date_Of_Join], ''dd MMM yyyy'') END,
							[CANDIDATE].[Person_ID],
							[SED].[Date_Of_Join],
							[SED].[Start_Date],
							[SED].[End_Date]
						FROM [Employee].[dbo].[Employee] EMP
						LEFT JOIN [Company].[dbo].[Company] C ON [C].[Company_ID] = [EMP].[Company_ID]
						LEFT JOIN (
										SELECT
											[CAN].[Candidate_ID],
											[T].[Title_ID],
											[T].[Title_Name],
											[CAN].[Person_ID],
											[P].[Full_Name]
										FROM [Candidate].[dbo].[Candidate] CAN
										LEFT JOIN [Person].[dbo].[Person] P ON [P].[Person_ID] = [CAN].[Person_ID]
										LEFT JOIN [Title].[dbo].[Title] T ON [T].[Title_ID] = [P].[Title_ID]
									) CANDIDATE ON [CANDIDATE].[Candidate_ID] = [EMP].[Candidate_ID]
						LEFT JOIN (
										SELECT
											[CE].[Employee_ID],
											[CE].[DOJ] AS [Date_Of_Join],
											[CT].[Contract_Type_ID],
											[CT].[Contract_Type_Name],
											[CE].[Start_Date],
											[CE].[End_Date],
											[CE].[Is_Active],
											[CE].[Status_Contract_EMP_ID]
										FROM [Employee].[dbo].[Contract_EMP] CE
										LEFT JOIN
													(
														SELECT [P].[Contract_Type_ID] , [P].[Contract_Type_Name] , 2 AS [Contract_Type_By_Comp_Type_ID]  
														FROM  [RMS_Contract_Type].[dbo].[Contract_Type] P  
													UNION
														SELECT [PT].[Contract_Type_Temp_ID] AS [Contract_Type_ID] , [PT].[Contract_Type_Temp_Name] , 1 AS [Contract_Type_By_Comp_Type_ID]
														FROM [RMS_Contract_Type].[dbo].[Contract_Type_Temp] PT
													)CT ON [CT].[Contract_Type_ID] = (
																						CASE WHEN [CE].[Contract_Type_By_Comp_ID] = 0 OR [CE].[Contract_Type_By_Comp_ID] IS NULL
																								THEN [CE].[Contract_Type_ID_OF_Com]
																						ELSE (
																								SELECT [Contract_Type_ID_Of_Com] = (
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
																								WHERE [PB].[Contract_Type_By_Comp_ID] = [CE].[Contract_Type_By_Comp_ID]
																								)
																						END
																						)
														AND [CT].[Contract_Type_By_Comp_Type_ID] = (
																										CASE WHEN [CE].[Contract_Type_By_Comp_ID] = 0 OR [CE].[Contract_Type_By_Comp_ID] IS NULL 
																												THEN 2
																										ELSE
																											(
																												SELECT [PB].[Contract_Type_By_Comp_Type_ID]
																												FROM [RMS_Contract_Type].[dbo].[Contract_Type_By_Comp] PB
																												WHERE [PB].[Contract_Type_By_Comp_ID] = [CE].[Contract_Type_By_Comp_ID]
																											)
																										END
																									)
									) SED ON [SED].[Employee_ID] = [EMP].[Employee_ID]
						WHERE [EMP].[Company_ID] = @Company_ID
						AND [EMP].[Is_Deleted] = 0
						AND [SED].[Status_Contract_EMP_ID] = @Status_ID
						AND [SED].[Is_Active] = 1';

	SET @sqlCommand = REPLACE(@sqlCommand, '@Company_ID', @Company_ID); 
	SET @sqlCommand = REPLACE(@sqlCommand, '@Status_ID', @Status_ID); 

	IF @Title_ID <> 0
		BEGIN
			SET @sqlCommand = CONCAT(@sqlCommand, 'AND [CANDIDATE].[Title_ID]  = @Title_ID '); 
			SET @sqlCommand = REPLACE(@sqlCommand, '@Title_ID', @Title_ID); 
		END

	IF @Employee_Name IS NOT NULL
		BEGIN
			IF LTRIM(RTRIM(@Employee_Name)) IS NOT NULL
			BEGIN
				SET @sqlCommand = CONCAT(@sqlCommand, 'AND [CANDIDATE].[Full_Name] LIKE ''%@Employee_Name%'' ');
				SET @sqlCommand = REPLACE(@sqlCommand, '@Employee_Name', TRIM(@Employee_Name) );
			END
		END

	IF @Contact_Type_ID <> 0
		BEGIN
			SET @sqlCommand = CONCAT(@sqlCommand, 'AND [SED].[Contact_Type_ID]  = @Contact_Type_ID '); 
			SET @sqlCommand = REPLACE(@sqlCommand, '@Contact_Type_ID', @Contact_Type_ID); 
		END

	IF LTRIM(RTRIM(@Start_Date)) IS NOT NULL AND @Start_Date <> ''
		BEGIN
			SET @sqlCommand = CONCAT(@sqlCommand, 'AND DATEADD(DAY, DATEDIFF(DAY, 0, [SED].[Start_Date]), 0) = DATEADD(DAY, DATEDIFF(DAY, 0, CAST(''@StartDate'' as date)), 0) ');
			SET @sqlCommand = REPLACE(@sqlCommand, '@StartDate', @Start_Date);
		END

	IF LTRIM(RTRIM(@End_Date)) IS NOT NULL AND @End_Date <> ''
		BEGIN
			SET @sqlCommand = CONCAT(@sqlCommand, 'AND DATEADD(DAY, DATEDIFF(DAY, 0, [SED].[End_Date]), 0) = DATEADD(DAY, DATEDIFF(DAY, 0, CAST(''@End_Date'' as date)), 0) ');
			SET @sqlCommand = REPLACE(@sqlCommand, '@End_Date', @End_Date);
		END

	IF LTRIM(RTRIM(@Date_Of_Join)) IS NOT NULL AND @Date_Of_Join <> '' 
		BEGIN
				SET @sqlCommand = CONCAT(@sqlCommand, 'AND DATEADD(DAY, DATEDIFF(DAY, 0, [SED].[Date_Of_Join]), 0) = DATEADD(DAY, DATEDIFF(DAY, 0, CAST(''@Date_Of_Join'' as date)), 0) ');
				SET @sqlCommand = REPLACE(@sqlCommand, '@Date_Of_Join', @Date_Of_Join);
		END

	BEGIN   
		EXEC (@sqlCommand);
	END  
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
				,'DB Employee - sp_GetAll_Employee'
				,ERROR_MESSAGE()
				,999
				,GETDATE());

END CATCH
