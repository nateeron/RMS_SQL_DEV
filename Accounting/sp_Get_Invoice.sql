USE [Accounting]
GO
/****** Object:  StoredProcedure [dbo].[sp_Get_Invoice]    Script Date: 2/18/2026 9:11:49 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		DEV01
-- Create date: 17-02-2026
-- Description:	<Description,,>
-- [dbo].[sp_Get_Invoice] @Company_ID = 3357 ,@Invoice_ID ='',@User_ID = 1 ,@Status_Code = null
-- [dbo].[sp_Get_Invoice] @Company_ID = 3357 ,@Invoice_ID ='1,2,3,4',@User_ID = 1 ,@Status_Code = null
-- dateFrom/dateTo empty = select all; else filter iv.Created_Date
-- =============================================
ALTER PROCEDURE [dbo].[sp_Get_Invoice]
	@Company_ID INT ,
	@Invoice_ID Nvarchar(max) = null,
	@User_ID INT ,
	@DateFrom NVARCHAR(20) = '',
	@DateTo NVARCHAR(20) = '',
	@Status_Code Nvarchar(50) OUTPUT
AS
BEGIN TRY


	;WITH CTE AS
		(
		    SELECT 
		          iv.Invoice_ID,
		          iv.Invoice_no,
		          ic.Contract_EMP_ID,
		          iv.Invoice_Type_ID,
		          iv.Company_ID,
		          iv.Created_Date,
		          ic.Recruiter_ID,
		          ic.Amount,
		          ic.Currency_ID,
		          CREATED.Full_Name AS Recruiter_Name,
		          (
		                SELECT 
		                    f.File_ID,
		                    f.File_Name,
		                    f.Created_Date
		                FROM [Accounting].[dbo].[File_Invoice] f
		                WHERE f.Invoice_ID = iv.Invoice_ID
		                FOR JSON PATH
		          ) AS Files,
		          ROW_NUMBER() OVER (
		                PARTITION BY ic.Contract_EMP_ID
		                ORDER BY iv.Created_Date DESC
		          ) AS rn
		    FROM [Accounting].[dbo].[Invoice] iv
		    LEFT JOIN [Accounting].[dbo].[Invoice_of_Commission] ic 
		        ON ic.Invoice_ID = iv.Invoice_ID
		    LEFT JOIN [PERSON].[DBO].[Person] CREATED 
		        ON CREATED.Person_ID = ic.Recruiter_ID
		    WHERE 
		        (
		            @Invoice_ID IS NULL 
		            OR @Invoice_ID = ''
		            OR iv.Invoice_ID IN (
		                    SELECT CAST(value AS INT)
		                    FROM STRING_SPLIT(@Invoice_ID, ',')
		               )
		        )
		        AND iv.Company_ID = @Company_ID
		        AND (
		            ((@DateFrom IS NULL OR LTRIM(RTRIM(@DateFrom)) = '') AND (@DateTo IS NULL OR LTRIM(RTRIM(@DateTo)) = ''))
		            OR (
		                iv.Created_Date >= CASE WHEN @DateFrom IS NULL OR LTRIM(RTRIM(@DateFrom)) = '' THEN CAST('1900-01-01' AS DATE) ELSE CAST(@DateFrom AS DATE) END
		                AND iv.Created_Date < CASE WHEN @DateTo IS NULL OR LTRIM(RTRIM(@DateTo)) = '' THEN CAST('9999-12-31' AS DATE) ELSE DATEADD(DAY, 1, CAST(@DateTo AS DATE)) END
		            )
		        )
		)
		
		SELECT *
		FROM CTE
		WHERE rn = 1
		ORDER BY Created_Date DESC;

	SET @Status_Code = '200';
	

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
				,'DB Accounting - sp_Get_Invoice'
				,ERROR_MESSAGE()
				,@User_ID
				,GETDATE());
	SET @Status_Code = '999';
END CATCH  


