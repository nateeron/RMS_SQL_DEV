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
	@Owner_ID INT = 0,
	@Start_Date NVARCHAR(100) = NULL,
	@End_Date NVARCHAR(100) = NULL
AS
BEGIN TRY
	DECLARE @Company_Type_Client INT = 0,
			@sqlCommand NVARCHAR(MAX) = NULL;

	SET @Company_Type_Client = (SELECT TOP 1 [CT].[Company_Type_ID]
								FROM [Company].[dbo].[Company_Type] CT
								WHERE [CT].[Company_Type_Name] = 'Client'
								AND [CT].[Is_Active] = 1);

	IF @Company_Type_Client IS NULL
		BEGIN
			SET @Company_Type_Client = 0;
		END

	SET @sqlCommand = 'SELECT [C].[Company_ID]
								,[C].[Company_Name]
								,[C].[Created_Date]
								,[Created_Date_Str] = CASE WHEN [C].[Created_Date] IS NULL 
														THEN ''-''
													  ELSE 
														FORMAT([C].[Created_Date], ''dd MMM yyyy'') 
													  END
								,[Owner_Name] = CASE WHEN [T].[Title_Name] IS NOT NULL 
												THEN CONCAT(RTRIM(LTRIM([T].[Title_Name])), '' '',[P].[Full_Name])
												ELSE [P].[Full_Name] END
						FROM [Company].[dbo].[Company] C
						LEFT JOIN [Person].[dbo].[Person] P ON [P].[Person_ID] = [C].[Updated_By]
						LEFT JOIN [Title].[dbo].[Title] T ON [T].[Title_ID] = [P].[Title_ID]
						WHERE [C].[Company_Type_ID] = @Company_Type_Client
						AND [C].[Com_ID_Of_Com_Type] = @Company_ID
						AND [C].[Is_Delete] = 0';

	IF @Owner_ID = 0 AND @Start_Date IS NOT NULL AND @Start_Date <> '' AND (@End_Date IS NULL OR @End_Date = '')
		BEGIN
			SET @sqlCommand = CONCAT(@sqlCommand, ' AND [C].[Created_Date] >= ''@Start_Date'' ');
			SET @sqlCommand = REPLACE(@sqlCommand, '@Start_Date', @Start_Date);
		END
	ELSE IF @Owner_ID = 0 AND @Start_Date IS NOT NULL AND @Start_Date <> '' AND @End_Date IS NOT NULL AND @End_Date <> ''
		BEGIN
			SET @sqlCommand = CONCAT(@sqlCommand, ' AND CAST([C].[Created_Date] AS DATE) BETWEEN'' @Start_Date'' AND ''@End_Date'' ');
			SET @sqlCommand = REPLACE(@sqlCommand, '@Start_Date', @Start_Date);
			SET @sqlCommand = REPLACE(@sqlCommand, '@End_Date', @End_Date);
		END
	ELSE IF @Owner_ID > 0 AND (@Start_Date IS NULL OR @Start_Date = '') AND (@End_Date IS NULL OR @End_Date = '')
		BEGIN
			SET @sqlCommand = CONCAT(@sqlCommand, ' AND [C].[Updated_By] = @Owner_ID ');
		END
	ELSE IF @Owner_ID > 0 AND @Start_Date IS NOT NULL AND @Start_Date <> '' AND (@End_Date IS NULL OR @End_Date = '')
		BEGIN
			SET @sqlCommand = CONCAT(@sqlCommand, ' AND [C].[Updated_By] = @Owner_ID
													AND [C].[Created_Date] >= ''@Start_Date'' ');
			SET @sqlCommand = REPLACE(@sqlCommand, '@Start_Date', @Start_Date);
		END
	ELSE IF @Owner_ID > 0 AND @Start_Date IS NOT NULL AND @Start_Date <> '' AND @End_Date IS NOT NULL AND @End_Date <> ''
		BEGIN
			SET @sqlCommand = CONCAT(@sqlCommand, ' AND [C].[Updated_By] = @Owner_ID
													AND CAST([C].[Created_Date] AS DATE) BETWEEN ''@Start_Date'' AND ''@End_Date'' ');		
			SET @sqlCommand = REPLACE(@sqlCommand, '@Start_Date', @Start_Date);
			SET @sqlCommand = REPLACE(@sqlCommand, '@End_Date', @End_Date);
		END

	SET @sqlCommand = REPLACE(@sqlCommand, '@Company_Type_Client', @Company_Type_Client);
	SET @sqlCommand = REPLACE(@sqlCommand, '@Company_ID', @Company_ID);
	SET @sqlCommand = REPLACE(@sqlCommand, '@Owner_ID', @Owner_ID);

	EXEC(@sqlCommand);
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
