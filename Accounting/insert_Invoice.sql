USE [Accounting]
GO
-- =============================================
-- Insert 1 Invoice + multiple Invoice_of_Commission
-- Input: comma-separated Contract_EMP_ID, Amount, Currency_ID (same order = same row)
-- Invoice_no format: PV-2026-02-13-001 (PV-date-runningnumber)
-- =============================================

DECLARE @Company_ID        INT = 3357,
        @Created_By        INT = 1,
        @Recruiter_ID      INT = 5162,
        @Contract_EMP_ID   NVARCHAR(MAX) = '1786,1787',
        @Amount            NVARCHAR(MAX) = '8000,300',
        @Currency_ID       NVARCHAR(MAX) = '150,150';

DECLARE @Current_Date     DATETIME = GETDATE(),
        @Set_Invoice      NVARCHAR(100) = NULL,
        @Invoice_Type_ID  INT = 0,
        @Invoice_Code     NVARCHAR(100) = NULL,
        @Run_Number       INT = 0,
        @New_Invoice_ID   INT = 0;

-- Invoice_Type (e.g. Commission)
SET @Invoice_Type_ID = (
    SELECT TOP 1 T.Invoice_Type_ID
    FROM [Accounting].[dbo].[Invoice_Type] T
    WHERE T.Company_ID = @Company_ID AND T.Is_Active = 1
);
IF @Invoice_Type_ID IS NULL SET @Invoice_Type_ID = 0;

-- Invoice_Code prefix (e.g. PV) from Invoice_Setting_Code
SET @Invoice_Code = (
    SELECT TOP 1 SC.Invoice_Code
    FROM [Accounting].[dbo].[Invoice_Setting_Code] SC
    WHERE SC.Invoice_Type_ID = @Invoice_Type_ID
      AND SC.Company_ID = @Company_ID
      AND SC.Is_Active = 1 AND SC.Is_Delete = 0
);

IF @Invoice_Code IS NULL
    SET @Invoice_Code = N'PV';

-- Running number: count same prefix + date (PV-2026-02-13-*) then +1
SET @Run_Number = (
    SELECT ISNULL(COUNT(*), 0) + 1
    FROM [Accounting].[dbo].[Invoice] INV
    WHERE INV.Company_ID = @Company_ID
      AND INV.Invoice_no LIKE @Invoice_Code + N'-' + FORMAT(@Current_Date, 'yyyy-MM-dd') + N'-%'
);

-- Full format: PV-2026-02-13-001
SET @Set_Invoice = CONCAT(
    @Invoice_Code,
    N'-',
    FORMAT(@Current_Date, 'yyyy-MM-dd'),
    N'-',
    RIGHT(N'000' + CAST(@Run_Number AS NVARCHAR(10)), 3)
);

-- Insert 1 Invoice
INSERT INTO [Accounting].[dbo].[Invoice]
    (Invoice_no, Invoice_Type_ID, Company_ID, Created_By, Created_Date)
VALUES
    (@Set_Invoice, @Invoice_Type_ID, @Company_ID, @Created_By, @Current_Date);

SET @New_Invoice_ID = SCOPE_IDENTITY();

-- Insert multiple Invoice_of_Commission (one row per position in comma lists; order by [key])
INSERT INTO [Accounting].[dbo].[Invoice_of_Commission]
    (Invoice_ID, Contract_EMP_ID, Recruiter_ID, Amount, Currency_ID, Created_By, Created_Date)
SELECT
    @New_Invoice_ID,
    CAST(c.[value] AS INT),
    @Recruiter_ID,
    CAST(a.[value] AS DECIMAL(12,2)),
    CAST(cur.[value] AS INT),
    @Created_By,
    @Current_Date
FROM OPENJSON(N'["' + REPLACE(LTRIM(RTRIM(@Contract_EMP_ID)), N',', N'","') + N'"]') c
JOIN OPENJSON(N'["' + REPLACE(LTRIM(RTRIM(@Amount)), N',', N'","') + N'"]') a ON a.[key] = c.[key]
JOIN OPENJSON(N'["' + REPLACE(LTRIM(RTRIM(@Currency_ID)), N',', N'","') + N'"]') cur ON cur.[key] = c.[key];

-- Result
SELECT @New_Invoice_ID AS New_Invoice_ID, @Set_Invoice AS Invoice_no;
