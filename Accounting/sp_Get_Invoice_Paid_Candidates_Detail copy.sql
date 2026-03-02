USE [Accounting]
GO
/****** Object:  StoredProcedure [dbo].[sp_Get_Invoice_Paid_Candidates_Detail]    Script Date: 2/20/2026 9:45:06 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
-- Commission Data by Contract_EMP_ID + Invoice (sp_Get_Invoice style)
-- Filter: @Company_ID (required), @Contract_EMP_ID (comma-separated or '' = all).
-- Optional: @DateFrom, @DateTo for invoice date fil
-- [dbo].[sp_Get_Invoice_Paid_Candidates_Detail] 3357 ,@Status_Code  = ''

ALTER PROCEDURE [dbo].[sp_Get_Invoice_Paid_Candidates_Detail] 
    @Company_ID      INT,
    @Contract_EMP_ID NVARCHAR(512) = '',  -- comma-separated or '' = all
    @Invoice_ID      NVARCHAR(512) = '',  -- comma-separated or '' = all
    @Invoice_no      NVARCHAR(512) = '',  -- comma-separated or '' = all
    @DateFrom        NVARCHAR(20)  = '',
    @DateTo          NVARCHAR(20)  = '',
	@Status_Code    NVARCHAR(20) OUTPUT 
AS
BEGIN



;WITH Inv AS (
    -- Latest invoice per Contract_EMP_ID (same logic as sp_Get_Invoice)
    SELECT Invoice_ID, Invoice_no, Contract_EMP_ID, Company_ID, Invoice_Created_Date, Recruiter_ID, Amount, Currency_ID, Files
    FROM (
        SELECT iv.Invoice_ID, iv.Invoice_no, ic.Contract_EMP_ID, iv.Company_ID, iv.Created_Date AS Invoice_Created_Date,
               ic.Recruiter_ID, ic.Amount, ic.Currency_ID,
               (SELECT f.File_ID, f.File_Name, f.Created_Date FROM [Accounting].[dbo].[File_Invoice] f WHERE f.Invoice_ID = iv.Invoice_ID FOR JSON PATH) AS Files,
               ROW_NUMBER() OVER (PARTITION BY ic.Contract_EMP_ID ORDER BY iv.Created_Date DESC) AS rn
        FROM [Accounting].[dbo].[Invoice] iv
        LEFT JOIN [Accounting].[dbo].[Invoice_of_Commission] ic ON ic.Invoice_ID = iv.Invoice_ID
        WHERE iv.Company_ID = @Company_ID
          AND ((@DateFrom IS NULL OR LTRIM(RTRIM(@DateFrom)) = '') AND (@DateTo IS NULL OR LTRIM(RTRIM(@DateTo)) = '')
               OR (iv.Created_Date >= CASE WHEN @DateFrom IS NULL OR LTRIM(RTRIM(@DateFrom)) = '' THEN CAST('1900-01-01' AS DATE) ELSE CAST(@DateFrom AS DATE) END
                   AND iv.Created_Date < CASE WHEN @DateTo IS NULL OR LTRIM(RTRIM(@DateTo)) = '' THEN CAST('9999-12-31' AS DATE) ELSE DATEADD(DAY, 1, CAST(@DateTo AS DATE)) END))
    ) t
    WHERE t.rn = 1
),
CON AS (
    SELECT *
    FROM (
        SELECT [b].*
            , ROW_NUMBER() OVER (PARTITION BY [c].[Employee_ID] ORDER BY [b].[Contract_EMP_ID]) AS rn
        FROM [Employee].[dbo].[Contract_EMP] b
        INNER JOIN [Employee].[dbo].[Employee] c ON [c].[Employee_ID] = [b].[Employee_ID]
    ) c
    WHERE [c].[rn] = 1
),
CommissionData AS (
SELECT
    [Recruiter_ID]      = [CREATED].[Person_ID],
    [Recruiter_Name]    = [CREATED].[Full_Name],
    [Contract_EMP_ID]    = [CON].[Contract_EMP_ID],
    [Candidate_ID]       = [CAN].[Candidate_ID],
    [Candidate_Name]    = [P].[Full_Name],
    [Position_By_Com_ID] = [CON].[Position_By_Com_ID],
    [Position_Name]     = [POS].[Position_Name],
    [Client_ID]         = [PP].[Company_ID],
    [Client_Name]       = [PP].[Company_Name]
FROM CON
LEFT JOIN [Employee].[dbo].[Status_Contract_EMP] SCE ON [SCE].[Status_Contract_EMP_ID] = [CON].[Status_Contract_EMP_ID]
LEFT JOIN [Accounting].[dbo].[Invoice_of_Commission] INC ON [INC].[Contract_EMP_ID] = [CON].[Contract_EMP_ID]
LEFT JOIN [Employee].[dbo].[Employee] EMP ON [EMP].[Employee_ID] = [CON].[Employee_ID]
LEFT JOIN [Candidate].[dbo].[Candidate] CAN ON [CAN].[Candidate_ID] = [EMP].[Candidate_ID]
LEFT JOIN [Person].[dbo].[Person] P ON [P].[Person_ID] = [CAN].[Person_ID]
LEFT JOIN (
    SELECT [P].[Position_ID], [P].[Position_Name], 2 AS [Position_By_Com_Type_ID] FROM [RMS_Position].[dbo].[Position] P
    UNION
    SELECT [PT].[Position_Temp_ID] AS [Position_ID], [PT].[Position_Name], 1 AS [Position_By_Com_Type_ID] FROM [RMS_Position].[dbo].[Position_Temp] PT
) POS ON [POS].[Position_ID] = (
    CASE WHEN [CON].[Position_By_Com_ID] = 0 OR [CON].[Position_By_Com_ID] IS NULL THEN [CON].[Position_ID_OF_Com]
    ELSE (
        SELECT CASE WHEN [PB].[Position_By_Com_Type_ID] = 1
                    THEN (SELECT [PT].[Position_Temp_ID] FROM [RMS_Position].[dbo].[Position_Temp] PT WHERE [PT].[Position_Temp_ID] = [PB].[Position_ID])
                    ELSE [PB].[Position_ID] END
        FROM [RMS_Position].[dbo].[Position_By_Comp] PB
        WHERE [PB].[Position_By_Com_ID] = [CON].[Position_By_Com_ID]
    )
    END
)
AND [POS].[Position_By_Com_Type_ID] = (
    CASE WHEN [CON].[Position_By_Com_ID] = 0 OR [CON].[Position_By_Com_ID] IS NULL THEN 2
    ELSE (SELECT [PB].[Position_By_Com_Type_ID] FROM [RMS_Position].[dbo].[Position_By_Comp] PB WHERE [PB].[Position_By_Com_ID] = [CON].[Position_By_Com_ID])
    END
)
LEFT JOIN (
    SELECT [PP].[Project_Position_ID]
        , [COM].[Company_ID]
        , [COM].[Company_Name]
    FROM [Company].[dbo].[Project_Position] PP
    LEFT JOIN [Company].[dbo].[Map_Comp_Position] MCPP ON [MCPP].[Project_Position_ID] = [PP].[Project_Position_ID] AND [MCPP].[Is_Active] = 1 AND [MCPP].[Is_Delete] = 0
    LEFT JOIN (
        SELECT [MPP].[Project_Position_ID]
            , [PC].[Comp_Branch_Project], [PC].[Comp_Branch_Site_Project], [PC].[Comp_Project], [PC].[Comp_Site_Project]
        FROM [Company].[dbo].[Map_Project_Position] MPP
        LEFT JOIN (
            SELECT [PC].[Project_Client_ID]
                , [Comp_Project] = [MCP].[Company_ID]
                , [MBP].[Comp_Branch_Project]
                , [MSP].[Comp_Branch_Site_Project], [MSP].[Comp_Site_Project]
            FROM [Company].[dbo].[Project_Client] PC
            LEFT JOIN [Company].[dbo].[Map_Comp_Project] MCP ON [MCP].[Project_Client_ID] = [PC].[Project_Client_ID] AND [MCP].[Is_Active] = 1 AND [MCP].[Is_Delete] = 0
            LEFT JOIN (SELECT [Comp_Branch_Project] = [MCB].[Company_ID], [MBP].[Project_Client_ID]
                FROM [Company].[dbo].[Map_Branch_Project] MBP
                LEFT JOIN [Company].[dbo].[Map_Comp_Branch] MCB ON [MCB].[Branch_ID] = [MBP].[Branch_ID] AND [MCB].[Is_Active] = 1 AND [MCB].[Is_Delete] = 0
                WHERE [MBP].[Is_Active] = 1 AND [MBP].[Is_Delete] = 0) MBP ON [MBP].[Project_Client_ID] = [PC].[Project_Client_ID]
            LEFT JOIN (SELECT [MSP].[Project_Client_ID], [Comp_Site_Project] = [MCS].[Company_ID], [Comp_Branch_Site_Project] = [MCB].[Company_ID]
                FROM [Company].[dbo].[Map_Site_Project] MSP
                LEFT JOIN [Company].[dbo].[Map_Comp_Site] MCS ON [MCS].[Site_ID] = [MSP].[Site_ID] AND [MSP].[Is_Active] = 1 AND [MSP].[Is_Delete] = 0
                LEFT JOIN [Company].[dbo].[Map_Branch_Site] MBS ON [MBS].[Site_ID] = [MSP].[Site_ID] AND [MBS].[Is_Active] = 1 AND [MBS].[Is_Delete] = 0
                LEFT JOIN [Company].[dbo].[Map_Comp_Branch] MCB ON [MCB].[Branch_ID] = [MBS].[Branch_ID] AND [MCB].[Is_Active] = 1 AND [MCB].[Is_Delete] = 0
                WHERE [MSP].[Is_Active] = 1 AND [MSP].[Is_Delete] = 0) MSP ON [MSP].[Project_Client_ID] = [PC].[Project_Client_ID]
            WHERE [PC].[Is_Active] = 1 AND [PC].[Is_Delete] = 0
        ) PC ON [PC].[Project_Client_ID] = [MPP].[Project_Client_ID]
        WHERE [MPP].[Is_Active] = 1 AND [MPP].[Is_Delete] = 0
    ) MPP ON [MPP].[Project_Position_ID] = [PP].[Project_Position_ID]
    LEFT JOIN (SELECT [MSP].[Project_Position_ID], [Comp_Site] = [MCS].[Company_ID], [Comp_Branch_Site] = [MCB].[Company_ID]
        FROM [Company].[dbo].[Map_Site_Position] MSP
        LEFT JOIN [Company].[dbo].[Map_Comp_Site] MCS ON [MCS].[Site_ID] = [MSP].[Site_ID] AND [MSP].[Is_Active] = 1 AND [MSP].[Is_Delete] = 0
        LEFT JOIN [Company].[dbo].[Map_Branch_Site] MBS ON [MBS].[Site_ID] = [MSP].[Site_ID] AND [MBS].[Is_Active] = 1 AND [MBS].[Is_Delete] = 0
        LEFT JOIN [Company].[dbo].[Map_Comp_Branch] MCB ON [MCB].[Branch_ID] = [MBS].[Branch_ID] AND [MCB].[Is_Active] = 1 AND [MCB].[Is_Delete] = 0
        WHERE [MSP].[Is_Active] = 1 AND [MSP].[Is_Delete] = 0) MSP ON [MSP].[Project_Position_ID] = [PP].[Project_Position_ID]
    LEFT JOIN (SELECT [MBP].[Project_Position_ID], [Comp_Branch] = [MCB].[Company_ID]
        FROM [Company].[dbo].[Map_Branch_Position] MBP
        LEFT JOIN [Company].[dbo].[Map_Comp_Branch] MCB ON [MCB].[Branch_ID] = [MBP].[Branch_ID] AND [MCB].[Is_Active] = 1 AND [MCB].[Is_Delete] = 0
        WHERE [MBP].[Is_Active] = 1 AND [MBP].[Is_Delete] = 0) MBP ON [MBP].[Project_Position_ID] = [PP].[Project_Position_ID]
    LEFT JOIN [Company].[dbo].[Company] COM ON (
        [COM].[Company_ID] = [MCPP].[Company_ID]
        OR [COM].[Company_ID] = [MPP].[Comp_Branch_Project]
        OR [COM].[Company_ID] = [MPP].[Comp_Branch_Site_Project]
        OR [COM].[Company_ID] = [MPP].[Comp_Project]
        OR [COM].[Company_ID] = [MPP].[Comp_Site_Project]
        OR [COM].[Company_ID] = [MSP].[Comp_Branch_Site]
        OR [COM].[Company_ID] = [MSP].[Comp_Site]
        OR [COM].[Company_ID] = [MBP].[Comp_Branch]
    )
) PP ON [PP].[Project_Position_ID] = [CON].[Project_Position_ID]
LEFT JOIN (
    SELECT [tt].[Update_By] AS [Owner_ID], [tt].[Candidate_ID]
    FROM [Candidate].[dbo].[Log_Update_Candidate] tt
    INNER JOIN (
        SELECT [ss].[Candidate_ID], MAX([ss].[Update_Date]) AS MaxDateTime
        FROM [Candidate].[dbo].[Log_Update_Candidate] ss
        INNER JOIN (
            SELECT [E].[Candidate_ID], [CE].[Created_Date]
            FROM [Employee].[dbo].[Contract_EMP] CE
            LEFT JOIN [Employee].[dbo].[Employee] E ON [E].[Employee_ID] = [CE].[Employee_ID]
        ) CE ON [CE].[Candidate_ID] = [ss].[Candidate_ID]
        WHERE [ss].[Is_Employee] = 0 AND [ss].[Is_Terminate] = 0 AND [ss].[Update_Date] <= [CE].[Created_Date]
        GROUP BY [ss].[Candidate_ID]
    ) g ON [tt].[Candidate_ID] = [g].[Candidate_ID] AND [tt].[Update_Date] = [g].[MaxDateTime] AND [tt].[Is_Employee] = 0 AND [tt].[Is_Terminate] = 0
) LUC ON [LUC].[Candidate_ID] = [CAN].[Candidate_ID] AND [CAN].[Is_Deleted] = 0
LEFT JOIN [Person].[dbo].[Person] CREATED ON [CREATED].[Person_ID] = [LUC].[Owner_ID]
WHERE [CON].[Company_ID] = @Company_ID
)
SELECT cd.Recruiter_ID, cd.Recruiter_Name, cd.Contract_EMP_ID, cd.Candidate_ID, cd.Candidate_Name,
       cd.Position_By_Com_ID, cd.Position_Name, cd.Client_ID, cd.Client_Name,
       Inv.Invoice_ID, Inv.Invoice_no, Inv.Invoice_Created_Date, Inv.Amount AS Invoice_Amount, Inv.Currency_ID AS Invoice_Currency_ID, Inv.Files
FROM CommissionData cd
LEFT JOIN Inv ON Inv.Contract_EMP_ID = cd.Contract_EMP_ID AND (Inv.Recruiter_ID = cd.Recruiter_ID OR Inv.Recruiter_ID IS NULL)
WHERE (
    (ISNULL(LTRIM(RTRIM(@Contract_EMP_ID)), '') = '' AND ISNULL(LTRIM(RTRIM(@Invoice_ID)), '') = '' AND ISNULL(LTRIM(RTRIM(@Invoice_no)), '') = '')
    OR (LTRIM(RTRIM(@Contract_EMP_ID)) <> '' AND cd.Contract_EMP_ID IN (SELECT TRY_CAST(LTRIM(RTRIM([value])) AS INT) FROM STRING_SPLIT(@Contract_EMP_ID, ',') WHERE TRY_CAST(LTRIM(RTRIM([value])) AS INT) IS NOT NULL))
    OR (LTRIM(RTRIM(@Invoice_ID)) <> '' AND Inv.Invoice_ID IN (SELECT TRY_CAST(LTRIM(RTRIM([value])) AS INT) FROM STRING_SPLIT(@Invoice_ID, ',') WHERE TRY_CAST(LTRIM(RTRIM([value])) AS INT) IS NOT NULL))
    OR (LTRIM(RTRIM(@Invoice_no)) <> '' AND Inv.Invoice_no IN (SELECT LTRIM(RTRIM([value])) FROM STRING_SPLIT(@Invoice_no, ',') WHERE LTRIM(RTRIM([value])) <> ''))
)
ORDER BY cd.Contract_EMP_ID;

END
