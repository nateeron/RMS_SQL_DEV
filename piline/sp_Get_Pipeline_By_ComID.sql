USE [Pipeline]
GO
/****** Object:  StoredProcedure [dbo].[sp_Get_Pipeline_By_ComID]    Script Date: 12/12/2025 3:16:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- [sp_Get_Pipeline_By_ComID] 3357
-- =============================================
ALTER PROCEDURE [dbo].[sp_Get_Pipeline_By_ComID] 
	-- Add the parameters for the stored procedure here
	@Company_ID int = 0
AS
DECLARE @Pipeline_Type_ID int = 0; 
	SET @Pipeline_Type_ID = (SELECT TOP 1 [PT].[Pipeline_Type_ID]
									FROM  [dbo].[Pipeline_Type] PT
									WHERE [PT].[Pipeline_Type_Name] = 'System');
BEGIN TRY
	SELECT
		[dbo].[Pipeline].[Pipeline_ID],
		[dbo].[Pipeline].[Pipeline_Name],
		[dbo].[Pipeline].[Number_Step] AS [Priority]
	FROM [dbo].[Pipeline]
	WHERE [dbo].[Pipeline].[Pipeline_Type_ID] = @Pipeline_Type_ID
	OR ([dbo].[Pipeline].[Pipeline_Type_ID] != @Pipeline_Type_ID AND [dbo].[Pipeline].[Company_ID] = @Company_ID)
	AND [dbo].[Pipeline].[Is_Active] = 1
	AND [dbo].[Pipeline].[Is_Delete] = 0
	ORDER BY [dbo].[Pipeline].[Number_Step] ASC
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
				,'DB Pipeline - sp_Get_Pipeline_By_ComID'
				,ERROR_MESSAGE()
				,999
				,GETDATE());
END CATCH