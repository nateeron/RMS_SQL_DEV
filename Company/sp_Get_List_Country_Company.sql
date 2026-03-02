USE [Company]
GO
/****** Object:  StoredProcedure [dbo].[sp_Get_List_Country_Company]    Script Date: 2/17/2026 11:44:23 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:	sp_Get_List_Country_Company
-- Create date: 2025 01 20
-- Description:	Created by Serm
-- =============================================
ALTER PROCEDURE [dbo].[sp_Get_List_Country_Company] 
@User_Login_ID NVARCHAR(50) = NULL,
@Company_ID INT = 0
AS
BEGIN TRY
	DECLARE @Cate_Type_ID INT = 0,
			@Address_Type_ID INT = 0,
			@Company_Type_ID INT = 0,
			@Company_Parent_ID INT = 0,
			@sqlCommand NVARCHAR(MAX) = NULL;

	SET @Cate_Type_ID = (SELECT TOP(1) [CATE].[Category_Type_ID]
						 FROM [Address].[dbo].[Address_Category_Type] CATE
						 WHERE [CATE].[Category_Type_Name] = 'Company');

	SET @Address_Type_ID = (SELECT TOP(1) [ADSTYPE].[Address_Type_ID]
							FROM [Address].[dbo].[Address_Type] ADSTYPE
							WHERE [ADSTYPE].[Address_Type_Name] = 'Register');

	SET @Company_Type_ID = (SELECT TOP(1) [CT].[Company_Type_ID]
							FROM [Company].[dbo].[Company_Type] CT 
							WHERE [CT].[Is_Active] = 1
							AND [CT].[Company_Type_Name] = 'System');

	SET @Company_Parent_ID = (SELECT [COM].[Company_Parent_ID]
							  FROM [Company].[dbo].[Company] COM
							  WHERE [COM].[Company_ID] = @Company_ID);

	IF @Company_Parent_ID IS NULL
		BEGIN
			SET @Company_Parent_ID = 0;
		END

	SET @sqlCommand = 'SELECT *
						FROM
								(
									SELECT  [BIGM].[Company_ID], 
											[BIGM].[Country_ID],
											[BIGM].[Country_Name],
											[BIGM].[Company_Name],
											0 AS [Is_Active]
									FROM 
											(
														SELECT [ADS].[Country_ID] 
																,[COMP].[Company_ID]
																,[COMP].[Company_Name]
																,[COU].[Country_Name]
														FROM [Company].[dbo].[Company] COMP 
														LEFT JOIN [Address].[dbo].[Address] ADS ON [ADS].[Reference_ID] = [COMP].[Company_ID]
														LEFT JOIN [Country].[dbo].[Country] COU ON [COU].[Country_ID] = [ADS].[Country_ID]
														WHERE [ADS].[Category_Type_ID] = @Cate_Type_ID
														AND [ADS].[Address_Type_ID] = @Address_Type_ID
														AND [COU].[Is_Active] = 1
														AND [COU].[Is_Deleted] = 0
														AND [COMP].[Company_Type_ID] = @Company_Type_ID
														AND [COMP].[Is_Active] = 1
														AND [COMP].[Is_Delete] = 0 ';

	IF @Company_Parent_ID = 0
		BEGIN
			SET @sqlCommand = CONCAT(@sqlCommand, '		AND ([COMP].[Company_ID] = @Company_ID
														OR [COMP].[Company_Parent_ID] = @Company_ID) ');
		END
	ELSE 
		BEGIN
			SET @sqlCommand = CONCAT(@sqlCommand, '		AND ([COMP].[Company_ID] = @Company_Parent_ID
														OR [COMP].[Company_Parent_ID] = @Company_Parent_ID) ');
		END

	SET @sqlCommand = CONCAT(@sqlCommand, ' ) BIGM
									WHERE [BIGM].[Company_ID] NOT IN (
																		SELECT [MUC].[Company_ID]
																		FROM [User_Login].[dbo].[Map_User_Company] MUC 
																		LEFT JOIN
																		(
																					SELECT [COMP].[Company_ID]
																						  ,[COMP].[Company_Name]
																						  ,[ADS].[Country_ID]
																						  ,[COU].[Country_Name]
																					FROM [Company].[dbo].[Company] COMP 
																					LEFT JOIN [Address].[dbo].[Address] ADS ON [ADS].[Reference_ID] = [COMP].[Company_ID]
																					LEFT JOIN [Country].[dbo].[Country] COU ON [COU].[Country_ID] = [ADS].[Country_ID]
																					WHERE [ADS].[Category_Type_ID] = @Cate_Type_ID
																					AND [ADS].[Address_Type_ID] = @Address_Type_ID
																					AND [COMP].[Company_Type_ID] = @Company_Type_ID
																					AND [COMP].[Is_Active] = 1
																					AND [COMP].[Is_Delete] = 0
																					AND [COU].[Is_Active] = 1
																					AND [COU].[Is_Deleted] = 0
																			UNION

																					SELECT [COMP].[Company_ID]
																							,[COMP].[Company_Name]
																							,[ADS].[Country_ID]
																							,[COU].[Country_Name]
																					FROM [Company].[dbo].[Company] COMP 
																					LEFT JOIN [Address].[dbo].[Address] ADS ON [ADS].[Reference_ID] = [COMP].[Company_ID]
																					LEFT JOIN [Country].[dbo].[Country] COU ON [COU].[Country_ID] = [ADS].[Country_ID]
																					WHERE [ADS].[Category_Type_ID] = @Cate_Type_ID
																					AND [ADS].[Address_Type_ID] = @Address_Type_ID
																					AND [COMP].[Company_Type_ID] = @Company_Type_ID
																					AND [COMP].[Is_Active] = 1
																					AND [COMP].[Is_Delete] = 0
																					AND [COU].[Is_Active] = 1
																					AND [COU].[Is_Deleted] = 0

																		) ADSS ON [ADSS].[Company_ID] = [MUC].[Company_ID]
																		WHERE [MUC].[Is_Active] = 1
																		AND [MUC].[User_Login_ID] = ''@User_Login_ID''
																	 )

									UNION

										SELECT [MUC].[Company_ID]
											  ,[COMP].[Country_ID]
											  ,[COMP].[Country_Name]
											  ,[COMP].[Company_Name]
											  ,1 AS [Is_Active]
										FROM [User_Login].[dbo].[Map_User_Company] MUC 
										LEFT JOIN
												(
													SELECT [COM].[Company_ID]
														  ,[COM].[Company_Name]
														  ,[ADSS].[Country_ID]
														  ,[ADSS].[Country_Name]
													FROM [Company].[dbo].[Company] COM
													LEFT JOIN 
															(
																SELECT [ADS].[Reference_ID]
																	  ,[ADS].[Country_ID]
																	  ,[COU].[Country_Name]
																FROM [Address].[dbo].[Address] ADS
																LEFT JOIN [Country].[dbo].[Country] COU ON [COU].[Country_ID] = [ADS].[Country_ID]
																WHERE [ADS].[Address_Type_ID] = @Address_Type_ID
																AND [ADS].[Category_Type_ID] = @Cate_Type_ID
																AND [COU].[Is_Active] = 1
																AND [COU].[Is_Deleted] = 0

															) ADSS ON [ADSS].[Reference_ID] = [COM].[Company_ID]
													WHERE [COM].[Company_Type_ID] = @Company_Type_ID
													AND [COM].[Is_Active] = 1
													AND [COM].[Is_Delete] = 0

												) COMP ON [COMP].[Company_ID] = [MUC].[Company_ID]
										WHERE [MUC].[Is_Active] = 1
										AND [MUC].[User_Login_ID] = ''@User_Login_ID''
								) MAPCOMP
								WHERE [MAPCOMP].[Country_ID] IS NOT NULL
						ORDER BY [MAPCOMP].[Is_Active] ASC , [MAPCOMP].[Country_Name] ASC ');

	SET @sqlCommand = REPLACE(@sqlCommand, '@User_Login_ID', @User_Login_ID);
	SET @sqlCommand = REPLACE(@sqlCommand, '@Company_ID', @Company_ID);
	SET @sqlCommand = REPLACE(@sqlCommand, '@Cate_Type_ID', @Cate_Type_ID);
	SET @sqlCommand = REPLACE(@sqlCommand, '@Address_Type_ID', @Address_Type_ID);
	SET @sqlCommand = REPLACE(@sqlCommand, '@Company_Type_ID', @Company_Type_ID);
	SET @sqlCommand = REPLACE(@sqlCommand, '@Company_Parent_ID', @Company_Parent_ID);
								
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
				,'DB Company - sp_Get_List_Country_Company'
				,ERROR_MESSAGE()
				,999
				,GETDATE());
END CATCH
