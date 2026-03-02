	
USE [Employee]
GO

-- ALTER PROCEDURE [dbo].[sp_Get_Employee_Terminate_By_Date] 
	DECLARE @Company_ID INT = 3357,
	@Date NVARCHAR(100) = NULL
 
 DECLARE @Status_Contract_Terminate INT = 0,
			@Terminate_Status_Type_ID_System INT = 0,
			@Terminate_Status_Type_ID_Company INT = 0

	SET @Status_Contract_Terminate = (SELECT TOP 1 [Status_Contract_EMP_ID]
									  FROM [Employee].[dbo].[Status_Contract_EMP] 
									  WHERE [Status_Contract_EMP_Name] = 'Terminate'
									  AND [Is_Active] = 1);

	IF @Status_Contract_Terminate IS NULL
		BEGIN
			SET @Status_Contract_Terminate = 0;
		END

	SET @Terminate_Status_Type_ID_System = (SELECT TOP 1 [TST].[Terminate_Status_Type_ID]
											FROM [Terminate_Status].[dbo].[Terminate_Status_Type] TST
											WHERE [TST].[Terminate_Status_Type_Name] = 'System');

	IF @Terminate_Status_Type_ID_System IS NULL
		BEGIN
			SET @Terminate_Status_Type_ID_System = 0;
		END

	SET @Terminate_Status_Type_ID_Company = (SELECT TOP 1 [TST].[Terminate_Status_Type_ID]
											 FROM [Terminate_Status].[dbo].[Terminate_Status_Type] TST
											 WHERE [TST].[Terminate_Status_Type_Name] = 'Company');

	IF @Terminate_Status_Type_ID_Company IS NULL
		BEGIN
			SET @Terminate_Status_Type_ID_Company = 0;
		END

	SELECT [A].[Contract_EMP_ID]
			,[A].[Employee_ID]
			,[Title_Name] = CASE WHEN [A].[Title_Name] IS NULL THEN '' ELSE [A].[Title_Name] END
			,[Employee_Name] = CASE WHEN [A].[Employee_Name] IS NULL THEN '' ELSE [A].[Employee_Name] END
			,[A].[Terminate_Date]
			,[Terminate_Date_Str] = CASE WHEN [A].[Terminate_Date_Str] IS NULL THEN '-' ELSE [A].[Terminate_Date_Str] END
			,[Terminate_Status_ID] = CASE WHEN [A].[Terminate_Status_ID] IS NULL THEN 0 ELSE [A].[Terminate_Status_ID] END
			,[Terminate_Name] = CASE WHEN [A].[Terminate_Name] IS NULL THEN '' ELSE [A].[Terminate_Name] END
			,[Terminate_Remark] = CASE WHEN [A].[Terminate_Remark] IS NULL THEN '' ELSE [A].[Terminate_Remark] END
	FROM (
			SELECT [Terminate_Date_By_Month] = FORMAT([C].[Terminate_Date], 'MMM yyyy')
					,[Terminate_Date_Str] = FORMAT([C].[Terminate_Date], 'dd MMM yyyy')
					,[C].[Terminate_Date]
					,[EMP].[Employee_ID]
					,[T].[Title_Name]
					,[Employee_Name] = [P].[Full_Name]
					,[C].[Contract_EMP_ID]
					,[C].[Terminate_Status_ID]
					,[TS].[Terminate_Name]
					,[C].[Terminate_Remark]
			FROM [Employee].[dbo].[Contract_EMP] C
			LEFT JOIN [Employee].[dbo].[Employee] EMP ON [EMP].[Employee_ID] = [C].[Employee_ID]
			LEFT JOIN [Candidate].[dbo].[Candidate] CAN ON [CAN].[Candidate_ID] = [EMP].[Candidate_ID]
			LEFT JOIN [Person].[dbo].[Person] P ON [P].[Person_ID] = [CAN].[Person_ID]
			LEFT JOIN [Title].[dbo].[Title] T ON [T].[Title_ID] = [P].[Title_ID]
			LEFT JOIN [Terminate_Status].[dbo].[Terminate_Status] TS ON [TS].[Terminate_ID] = [C].[Terminate_Status_ID]
			WHERE [C].[Company_ID] = @Company_ID
			AND [C].[Status_Contract_EMP_ID] = @Status_Contract_Terminate
			AND [C].[Terminate_Status_ID] IN (
													SELECT [TS].[Terminate_ID]
													FROM [Terminate_Status].[dbo].[Terminate_Status] TS
													WHERE [TS].[Terminate_ID] NOT IN (SELECT [S].[Terminate_ID]
																						FROM [Terminate_Status].[dbo].[Terminate_Status] S
																						WHERE [S].[Terminate_Name] IN ('Retained', 'End Contract', 'Resign')
																						AND [S].[Terminate_Status_Type_ID] = @Terminate_Status_Type_ID_System)
													AND (
															([TS].[Company_ID] = @Company_ID AND [TS].[Terminate_Status_Type_ID] = @Terminate_Status_Type_ID_Company) OR
															([TS].[Terminate_Status_Type_ID] = @Terminate_Status_Type_ID_System)
														)
												)
	) A
	WHERE [A].[Terminate_Date_By_Month] = @Date
	ORDER BY [A].[Terminate_Date] ASC

	-- ============ GET Position ====================
;WITH Position_All AS (
		 -- Position (System)
		 SELECT
		     P.Position_ID,
		     P.Position_Name,
		     2 AS Position_By_Com_Type_ID
		 FROM RMS_Position.dbo.Position P
		 UNION ALL
		 -- Position Temp (Company)
		 SELECT
		     PT.Position_Temp_ID AS Position_ID,
		     PT.Position_Name,
		     1 AS Position_By_Com_Type_ID
		 FROM RMS_Position.dbo.Position_Temp PT
),
ProjectPositionResolved AS (
    SELECT
        PP.*,
        CASE
            WHEN ISNULL(PP.Position_By_Comp_ID, 0) = 0 THEN PP.Position_ID
            WHEN PB.Position_By_Com_Type_ID = 1 THEN PT.Position_Temp_ID
            ELSE PB.Position_ID
        END AS Final_Position_ID
    FROM Company.dbo.Project_Position PP
    LEFT JOIN RMS_Position.dbo.Position_By_Comp PB
        ON PB.Position_By_Com_ID = PP.Position_By_Comp_ID
    LEFT JOIN RMS_Position.dbo.Position_Temp PT
        ON PT.Position_Temp_ID = PB.Position_ID
)
SELECT
    PP.Position_By_Comp_ID,
    PP.*,
    P.Position_Name
	,P.Position_By_Com_Type_ID
FROM ProjectPositionResolved PP
LEFT JOIN Position_All P
    ON P.Position_ID = PP.Final_Position_ID
