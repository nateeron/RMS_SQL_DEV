USE [Role]
GO
/****** Object:  StoredProcedure [dbo].[SP_Get_Role_ID_From_Map_All]    Script Date: 2/27/2026 10:15:36 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[SP_Get_Role_ID_From_Map_All]    

AS
BEGIN TRY
		SELECT [R].[Role_ID],
				[R].[Role_Name],
				[R].[Role_Type_ID],
				[MRU].[User_Login_ID],
				[RT].[Role_Type_Name] 
		FROM [DBO].[Map_Role_User] MRU 
		LEFT JOIN [DBO].[Role] R ON [R].[Role_ID] = [MRU].[Role_ID]
		LEFT JOIN [DBO].[Role_Type] RT ON [RT].[Role_Type_ID] = [R].[Role_Type_ID]
		WHERE [MRU].[Is_Active] = 1; 
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
				,'DB Role - SP_Get_Role_ID_From_Map_All'
				,ERROR_MESSAGE()
				,999
				,GETDATE());
END CATCH
