USE [Company]
GO
/****** Object:  StoredProcedure [dbo].[sp_Get_Report_Clients_Summary]    Script Date: 12/22/2025 3:14:01 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[sp_Get_Report_Clients_Summary]
	@Company_ID INT = 0,
	@Client_ID_str NVARCHAR(500) = '',
	@Owner_ID_str NVARCHAR(500) = '',
	@Start_Date NVARCHAR(100) = NULL,
	@End_Date NVARCHAR(100) = NULL
AS
BEGIN TRY
	DECLARE @Company_Type_Client INT = 0,
			@DateFrom DATETIME = NULL,
			@DateTo DATETIME = NULL;

	-- Get Company Type ID for Client
	SET @Company_Type_Client = (SELECT TOP 1 [CT].[Company_Type_ID]
								FROM [Company].[dbo].[Company_Type] CT
								WHERE [CT].[Company_Type_Name] = 'Client'
								AND [CT].[Is_Active] = 1);

	IF @Company_Type_Client IS NULL
		BEGIN
			SET @Company_Type_Client = 0;
		END

	-- Convert date strings to DATETIME
	SET @DateFrom = TRY_CONVERT(DATETIME, NULLIF(@Start_Date, ''));
	SET @DateTo = TRY_CONVERT(DATETIME, NULLIF(@End_Date, ''));

	-- CTE: Split Client ID values
	WITH ClientIDFilter AS (
		SELECT TRY_CAST(LTRIM(RTRIM([value])) AS INT) AS [Client_ID_Value]
		FROM STRING_SPLIT(@Client_ID_str, ',')
		WHERE @Client_ID_str <> '' AND @Client_ID_str IS NOT NULL
			AND TRY_CAST(LTRIM(RTRIM([value])) AS INT) IS NOT NULL
	),
	-- CTE: Split Owner ID values
	OwnerIDFilter AS (
		SELECT TRY_CAST(LTRIM(RTRIM([value])) AS INT) AS [Owner_ID_Value]
		FROM STRING_SPLIT(@Owner_ID_str, ',')
		WHERE @Owner_ID_str <> '' AND @Owner_ID_str IS NOT NULL
			AND TRY_CAST(LTRIM(RTRIM([value])) AS INT) IS NOT NULL
	)
	-- Main Query
	SELECT [C].[Company_ID],
			[C].[Company_Name],
			[C].[Created_Date],
			[Created_Date_Str] = CASE WHEN [C].[Created_Date] IS NULL 
									THEN '-'
									ELSE 
									FORMAT([C].[Created_Date], 'dd MMM yyyy') 
									END,
			[Owner_Name] = CASE WHEN [T].[Title_Name] IS NOT NULL 
							THEN CONCAT(RTRIM(LTRIM([T].[Title_Name])), ' ', [P].[Full_Name])
							ELSE [P].[Full_Name] 
							END
	FROM [Company].[dbo].[Company] C
		LEFT JOIN [Person].[dbo].[Person] P ON [P].[Person_ID] = [C].[Updated_By]
		LEFT JOIN [Title].[dbo].[Title] T ON [T].[Title_ID] = [P].[Title_ID]
	WHERE [C].[Company_Type_ID] = @Company_Type_Client
		AND [C].[Com_ID_Of_Com_Type] = @Company_ID
		AND [C].[Is_Delete] = 0
		-- Filter by Client ID (if provided) - supports multiple IDs
		AND (@Client_ID_str = '' OR @Client_ID_str IS NULL OR 
			[C].[Company_ID] IN (SELECT [Client_ID_Value] FROM ClientIDFilter)
		)
		-- Filter by Owner ID (if provided) - supports multiple IDs
		AND (@Owner_ID_str = '' OR @Owner_ID_str IS NULL OR 
			[C].[Updated_By] IN (SELECT [Owner_ID_Value] FROM OwnerIDFilter)
		)
		-- Filter by Created Date (if provided)
		AND (@DateFrom IS NULL OR [C].[Created_Date] >= @DateFrom)
		AND (@DateTo IS NULL OR CAST([C].[Created_Date] AS DATE) <= CAST(@DateTo AS DATE))
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
				,'DB Company - sp_Get_Report_Clients_Summary'
				,ERROR_MESSAGE()
				,999
				,GETDATE()); 
END CATCH
