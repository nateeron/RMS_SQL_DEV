-- =============================================
-- Employee Summary - Detail Report (Drill-down by RespID + KEYID)
-- ส่ง RespID (จาก summary) + KEYID (ต้องการดูข้อมูลของอะไร) แล้วได้ detail ตามประเภท
-- KEYID: 'Active' | 'Released' | 'Terminate' | 'OnProcess'
-- =============================================

DECLARE @Company_ID INT = 3357,
        @RespID VARCHAR(7) = '2025-01',   -- yyyy-MM จาก summary (เดือนที่คลิก)
        @KEYID VARCHAR(20) = 'Active',   -- ต้องการดูข้อมูลของอะไร: Active | Released | Terminate | OnProcess
        @Yr INT,
        @Mo INT,
        @Company_Parent_ID INT,
        @TYPE_SYSTEM_ID INT,
        @TYPE_TEMP_ID INT;

SET @Yr = CAST(LEFT(@RespID, 4) AS INT);
SET @Mo = CAST(RIGHT(@RespID, 2) AS INT);

SELECT @Company_Parent_ID = ISNULL(Company_Parent_ID, 0)
FROM [Company].[dbo].[Company]
WHERE Company_ID = @Company_ID;

SELECT 
    @TYPE_SYSTEM_ID = MAX(CASE WHEN Contract_Type_By_Comp_Type_Name = 'System'  THEN Contract_Type_By_Comp_Type_ID END),
    @TYPE_TEMP_ID   = MAX(CASE WHEN Contract_Type_By_Comp_Type_Name = 'Company' THEN Contract_Type_By_Comp_Type_ID END)
FROM [RMS_Contract_Type].dbo.Contract_Type_By_Comp_Type;

;WITH CompanyScope AS (
    SELECT Company_ID
    FROM [Company].[dbo].[Company]
    WHERE Company_ID = CASE WHEN @Company_Parent_ID = 0 THEN @Company_ID ELSE @Company_Parent_ID END
       OR Company_Parent_ID = CASE WHEN @Company_Parent_ID = 0 THEN @Company_ID ELSE @Company_Parent_ID END
),
ContractType AS (
    SELECT CTT.Contract_Type_Temp_ID AS Contract_Type_ID, CTT.Contract_Type_Temp_Name AS Contract_Type_Name, @TYPE_TEMP_ID AS Type_Contract
    FROM [RMS_Contract_Type].dbo.Contract_Type_Temp CTT
    JOIN CompanyScope CS ON CS.Company_ID = CTT.Company_ID
    WHERE CTT.Is_Active = 1 AND CTT.Is_Deleted = 0
    UNION ALL
    SELECT CT.Contract_Type_ID, CT.Contract_Type_Name, @TYPE_SYSTEM_ID AS Type_Contract
    FROM [RMS_Contract_Type].dbo.Contract_Type CT
    WHERE CT.Is_Active = 1 AND CT.Is_Deleted = 0
),
Contract_Type AS (
    SELECT CT.Contract_Type_ID, CT.Contract_Type_Name
    FROM ContractType CT
    LEFT JOIN [RMS_Contract_Type].dbo.Contract_Type_By_Comp CTC
        ON CTC.Contract_Type_ID = CT.Contract_Type_ID AND CTC.Contract_Type_By_Comp_Type_ID = CT.Type_Contract AND CTC.Is_Deleted = 0
    WHERE CTC.Company_ID IN (SELECT Company_ID FROM CompanyScope) AND ISNULL(CTC.Is_Active, 0) = 1
),
-- Project Position: Client name (Company), Position name, Sales (Owner)
ProjectPositions AS (
    SELECT 
        PP.Project_Position_ID,
        [ComCliantName] = ISNULL(COM.Company_Name, '-')
    FROM [Company].[dbo].[Project_Position] PP
    LEFT JOIN [Company].[dbo].[Map_Comp_Position] MCPP ON MCPP.Project_Position_ID = PP.Project_Position_ID AND MCPP.Is_Active = 1 AND MCPP.Is_Delete = 0
    LEFT JOIN [Company].[dbo].[Company] COM ON COM.Company_ID = MCPP.Company_ID
    WHERE PP.Is_Delete = 0
),
PositionNames AS (
    SELECT PP.Project_Position_ID,
        [Position_Name] = ISNULL(
            CASE WHEN PB.Position_By_Com_Type_ID = 1 THEN PT.Position_Name ELSE P.Position_Name END,
            '-'
        )
    FROM [Company].[dbo].[Project_Position] PP
    LEFT JOIN [RMS_Position].[dbo].[Position_By_Comp] PB ON PB.Position_By_Com_ID = PP.Position_By_Comp_ID
    LEFT JOIN [RMS_Position].[dbo].[Position_Temp] PT ON PT.Position_Temp_ID = PB.Position_ID AND PB.Position_By_Com_Type_ID = 1
    LEFT JOIN [RMS_Position].[dbo].[Position] P ON P.Position_ID = PB.Position_ID AND PB.Position_By_Com_Type_ID = 2
),
SalesByPosition AS (
    SELECT MUP.Project_Position_ID, [Sales_Name] = ISNULL(P.Full_Name, '-')
    FROM [Company].[dbo].[Map_User_PrjPosi] MUP
    LEFT JOIN [Person].[dbo].[Person] P ON P.Person_ID = MUP.Person_ID
    WHERE MUP.Is_Active = 1
),
-- ใช้ OUTER APPLY ดึงสัญญาล่าสุดแค่ 1 รายการต่อคน เพื่อไม่ให้ข้อมูลเบิ้น (ซ้ำจากหลาย Contract_EMP)
Employee_info AS (
    SELECT
        EMP.Employee_ID, EMP.Candidate_ID, EMP.Status_Employee, EMP.Is_Active, EMP.Is_Deleted,
        PER.Full_Name,
        CE.Start_Date, CE.End_Date, CE.Terminate_Date, CE.Terminate_Status_ID, CE.Terminate_Remark,
        CE.Contract_Type_ID_OF_Com, CE.Project_Position_ID
    FROM [Employee].[dbo].[Employee] EMP
    LEFT JOIN [Candidate].[DBO].[Candidate] CAN ON CAN.Candidate_ID = EMP.Candidate_ID
    LEFT JOIN [Person].[DBO].[Person] PER ON PER.Person_ID = CAN.Person_ID
    OUTER APPLY (
        SELECT TOP 1 Start_Date, End_Date, Terminate_Date, Terminate_Status_ID, Terminate_Remark,
            Contract_Type_ID_OF_Com, Project_Position_ID
        FROM [Employee].[dbo].[Contract_EMP] CE
        WHERE CE.Employee_ID = EMP.Employee_ID
        ORDER BY CE.Updated_Date DESC
    ) CE
    WHERE EMP.Company_ID = @Company_ID
),
DetailBase AS (
    SELECT
        e.Full_Name,
        [Client_Name] = ISNULL(PP.ComCliantName, '-'),
        [Position_Name] = ISNULL(PN.Position_Name, '-'),
        [Sales_Name] = ISNULL(SB.Sales_Name, '-'),
        [Contract_Type] = ISNULL(ct.Contract_Type_Name, '-'),
        e.Start_Date,
        e.End_Date,
        e.Terminate_Date,
        [Terminate_Reason] = ISNULL(ts.Terminate_Name, '-'),
        e.Terminate_Remark,
        e.Status_Employee,
        e.Is_Deleted
    FROM Employee_info e
    LEFT JOIN Contract_Type ct ON ct.Contract_Type_ID = e.Contract_Type_ID_OF_Com
    LEFT JOIN [Terminate_Status].[dbo].[Terminate_Status] ts ON ts.Terminate_ID = e.Terminate_Status_ID
    LEFT JOIN ProjectPositions PP ON PP.Project_Position_ID = e.Project_Position_ID
    LEFT JOIN PositionNames PN ON PN.Project_Position_ID = e.Project_Position_ID
    LEFT JOIN SalesByPosition SB ON SB.Project_Position_ID = e.Project_Position_ID
)
-- ========== Detail ตาม KEYID (ส่ง @RespID + @KEYID จาก summary) ==========
SELECT
    @KEYID AS KEYID,
    [Employee Name] = Full_Name,
    [Client Name] = Client_Name,
    [Position Name] = Position_Name,
    [Sales Name] = Sales_Name,
    [Contract Type] = Contract_Type,
    [Start Date]     = CASE WHEN @KEYID IN ('Active','OnProcess') THEN FORMAT(Start_Date, 'd-MMM-yy') ELSE NULL END,
    [Released Date] = CASE WHEN @KEYID = 'Released' THEN FORMAT(ISNULL(Terminate_Date, End_Date), 'd-MMM-yy') ELSE NULL END,
    [Terminate Date]   = CASE WHEN @KEYID = 'Terminate' THEN FORMAT(Terminate_Date, 'd-MMM-yy') ELSE NULL END,
    [Terminate Reason] = CASE WHEN @KEYID = 'Terminate' THEN Terminate_Reason ELSE NULL END,
    [Remark]           = CASE WHEN @KEYID = 'Terminate' THEN ISNULL(Terminate_Remark, '') ELSE NULL END
FROM DetailBase
WHERE (
    (@KEYID = 'Active'    AND Status_Employee = 'Active'    AND Is_Deleted = 0 AND YEAR(Start_Date) = @Yr AND MONTH(Start_Date) = @Mo AND Start_Date IS NOT NULL)
 OR (@KEYID = 'Released'  AND Status_Employee = 'Released' AND YEAR(Start_Date) = @Yr AND MONTH(Start_Date) = @Mo AND Start_Date IS NOT NULL)
 OR (@KEYID = 'Terminate' AND Is_Deleted = 1              AND YEAR(Terminate_Date) = @Yr AND MONTH(Terminate_Date) = @Mo AND Terminate_Date IS NOT NULL)
 OR (@KEYID = 'OnProcess' AND Status_Employee = 'On Process' AND YEAR(Start_Date) = @Yr AND MONTH(Start_Date) = @Mo AND Start_Date IS NOT NULL)
)
ORDER BY [Employee Name];
