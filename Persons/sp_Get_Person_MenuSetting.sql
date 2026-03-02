USE [Person]
GO
/****** Object:  StoredProcedure [dbo].[sp_Get_Person_MenuSetting]    Script Date: 2/26/2026 5:47:34 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[sp_Get_Person_MenuSetting]    
@Company_ID INT = 0  
AS
BEGIN TRY   
	DECLARE @Company_Parent_ID INT = 0,
			@sqlCommand NVARCHAR(MAX) = NULL;

	SET @Company_Parent_ID = (SELECT [COM].[Company_Parent_ID]
							  FROM [Company].[dbo].[Company] COM
							  WHERE [COM].[Company_ID] = @Company_ID);

	IF @Company_Parent_ID IS NULL
		BEGIN
			SET @Company_Parent_ID = 0;
		END

	SET @sqlCommand = 'SELECT [P].[Person_ID],
							[UL].[Username],
							[MPP].[User_Login_ID],
							[T].[Title_Name],
							[P].[Full_Name],
							[P].[Email],
							[Is_Active] = CASE WHEN [UL].[Is_Active] IS NOT NULL THEN [UL].[Is_Active] ELSE 0 END
					FROM [Person].[DBO].[Person] P 
					LEFT JOIN [Title].[DBO].[Title] T ON [P].[Title_ID] = [T].[Title_ID]
					LEFT JOIN [Person].[dbo].[Map_Person] MPP ON [MPP].[Person_ID] = [P].[Person_ID]
					LEFT JOIN [User_Login].[DBO].[User_Login] UL ON [UL].[User_Login_ID] = [MPP].[User_Login_ID]
					WHERE [P].[Person_ID] IN (  SELECT [MP].[Person_ID]
												FROM [Person].[dbo].[Map_Person] MP
												WHERE [MP].[User_Login_ID] IN (		SELECT [MUC].[User_Login_ID]
																					FROM [User_Login].[DBO].[Map_User_Company] MUC
																					LEFT JOIN
																							( ';

													IF @Company_Parent_ID = 0
														BEGIN
															SET @sqlCommand = CONCAT(@sqlCommand, ' SELECT [COM].[Company_ID] 
																									FROM [Company].[dbo].[Company] COM
																									WHERE ([COM].[Company_ID] = @Company_ID
																									OR [COM].[Company_Parent_ID] = @Company_ID)
																									AND [COM].[Is_Active] = 1
																									AND [COM].[Is_Delete] = 0 ');
														END
													ELSE
														BEGIN
															SET @sqlCommand = CONCAT(@sqlCommand, ' SELECT [COM].[Company_ID] 
																									FROM [Company].[dbo].[Company] COM
																									WHERE ([COM].[Company_ID] = @Company_Parent_ID
																									OR [COM].[Company_Parent_ID] = @Company_Parent_ID)
																									AND [COM].[Is_Active] = 1
																									AND [COM].[Is_Delete] = 0 ');
														END

	SET @sqlCommand = CONCAT(@sqlCommand, '                                                     ) COMPAN ON [COMPAN].[Company_ID] = [MUC].[Company_ID]
																					WHERE [COMPAN].[Company_ID] IS NOT NULL
																				)
												AND [MP].[Is_Active] = 1 ) ');

	SET @sqlCommand = REPLACE(@sqlCommand, '@Company_ID', @Company_ID);
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
				,'DB Person - sp_Get_Person_MenuSetting'
				,ERROR_MESSAGE()
				,999
				,GETDATE());
END CATCH