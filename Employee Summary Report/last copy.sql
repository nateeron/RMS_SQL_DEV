  
  
  
  with ACTIVE AS (
					 SELECT [EMP].[Employee_ID]
					     ,[EMP].[Candidate_ID]
					     ,[EMP].[Is_Active]
					     ,[EMP].[Is_Deleted]
					     ,[EMP].[Created_By]
					     ,[EMP].[Updated_By]
					     ,[EMP].[Created_Date]
					     ,[EMP].[Updated_Date]
					     ,[EMP].[Company_ID]
					     ,[EMP].[Employee_No]
					     ,[EMP].[Bank_ID]
					     ,[EMP].[Bank_Account_Number]
					     ,[EMP].[Manager_ID]
					     ,[EMP].[Status_Employee]
						 ,CANDIDATE.Person_ID
						 ,CANDIDATE.Title_Name
						 ,CANDIDATE.Full_Name
						 ,CE.Start_Date
						 ,CE.End_Date
						 ,CE.DOJ
						 ,CE.Not_End_Date
						 ,CE.Terminate_Date
						 ,CE.Terminate_Status_ID
						 ,CE.Terminate_Remark
						  ,StC.Status_Contract_EMP_Name
						  --,CT.Contact_type_Name
					 FROM [Employee].[dbo].[Employee] [EMP]
					 LEFT JOIN 
								(	SELECT [CAN].[Candidate_ID],
											[TIT].[Title_Name] ,
											[CAN].[Person_ID],
											[PER].[Full_Name]
									FROM [Candidate].[DBO].[Candidate] CAN 
									LEFT JOIN [Person].[DBO].[Person] PER ON [CAN].[Person_ID] = [PER].[Person_ID]
									LEFT JOIN [Title].[DBO].[Title] TIT ON [TIT].[Title_ID] = [PER].[Title_ID]
								) CANDIDATE ON [CANDIDATE].[Candidate_ID] = [EMP].[Candidate_ID]
						-- OUTER APPLY (
						--        SELECT   TOP (1) *
						--        FROM [Employee].[dbo].[Contract_EMP] AS E
						--        WHERE E.Employee_ID = EMP.Employee_ID
						--        ORDER BY E.Updated_Date DESC
						--) AS CE
						LEFT JOIN [Employee].[dbo].[Contract_EMP]  CE on CE.Employee_ID = EMP.Employee_ID
						LEFT JOIN [Employee].[DBO].[Status_Contract_EMP] StC on StC.[Status_Contract_EMP_ID] = CE.Status_Contract_EMP_ID
						--LEFT JOIN [Employee].[dbo].[Contact_Type] CT on CT.Contact_Type_ID = CE.Contract_Type_ID_OF_Com AND CT.Is_Active = 1 AND CT.Is_Deleted = 0
							where [EMP].Company_ID = 3357
					  and [EMP].Is_Deleted = 0
					  	  and [EMP].Status_Employee =  'Active'
					  --AND [EMP].Employee_ID = 1339
					-- AND EMP.Candidate_ID = 3798
 ),Released AS (
					 SELECT [EMP].[Employee_ID]
					     ,[EMP].[Candidate_ID]
					     ,[EMP].[Is_Active]
					     ,[EMP].[Is_Deleted]
					     ,[EMP].[Created_By]
					     ,[EMP].[Updated_By]
					     ,[EMP].[Created_Date]
					     ,[EMP].[Updated_Date]
					     ,[EMP].[Company_ID]
					     ,[EMP].[Employee_No]
					     ,[EMP].[Bank_ID]
					     ,[EMP].[Bank_Account_Number]
					     ,[EMP].[Manager_ID]
					     ,[EMP].[Status_Employee]
						 ,CANDIDATE.Person_ID
						 ,CANDIDATE.Title_Name
						 ,CANDIDATE.Full_Name
						 ,CE.Start_Date
						 ,CE.End_Date
						 ,CE.DOJ
						 ,CE.Not_End_Date
						 ,CE.Terminate_Date
						 ,CE.Terminate_Status_ID
						 ,CE.Terminate_Remark
						  ,StC.Status_Contract_EMP_Name
						  --,CT.Contact_type_Name
					 FROM [Employee].[dbo].[Employee] [EMP]
					 LEFT JOIN 
								(	SELECT [CAN].[Candidate_ID],
											[TIT].[Title_Name] ,
											[CAN].[Person_ID],
											[PER].[Full_Name]
									FROM [Candidate].[DBO].[Candidate] CAN 
									LEFT JOIN [Person].[DBO].[Person] PER ON [CAN].[Person_ID] = [PER].[Person_ID]
									LEFT JOIN [Title].[DBO].[Title] TIT ON [TIT].[Title_ID] = [PER].[Title_ID]
								) CANDIDATE ON [CANDIDATE].[Candidate_ID] = [EMP].[Candidate_ID]
						-- OUTER APPLY (
						--        SELECT   TOP (1) *
						--        FROM [Employee].[dbo].[Contract_EMP] AS E
						--        WHERE E.Employee_ID = EMP.Employee_ID
						--        ORDER BY E.Updated_Date DESC
						--) AS CE
						LEFT JOIN [Employee].[dbo].[Contract_EMP]  CE on CE.Employee_ID = EMP.Employee_ID
						LEFT JOIN [Employee].[DBO].[Status_Contract_EMP] StC on StC.[Status_Contract_EMP_ID] = CE.Status_Contract_EMP_ID
						--LEFT JOIN [Employee].[dbo].[Contact_Type] CT on CT.Contact_Type_ID = CE.Contract_Type_ID_OF_Com AND CT.Is_Active = 1 AND CT.Is_Deleted = 0
							where [EMP].Company_ID = 3357
					  --and [EMP].Is_Deleted = 0
					  and [EMP].Status_Employee =  'Released' 
					  --AND [EMP].Employee_ID = 1339
					-- AND EMP.Candidate_ID = 3798
 ),OnProcess AS (
					 SELECT [EMP].[Employee_ID]
					     ,[EMP].[Candidate_ID]
					     ,[EMP].[Is_Active]
					     ,[EMP].[Is_Deleted]
					     ,[EMP].[Created_By]
					     ,[EMP].[Updated_By]
					     ,[EMP].[Created_Date]
					     ,[EMP].[Updated_Date]
					     ,[EMP].[Company_ID]
					     ,[EMP].[Employee_No]
					     ,[EMP].[Bank_ID]
					     ,[EMP].[Bank_Account_Number]
					     ,[EMP].[Manager_ID]
					     ,[EMP].[Status_Employee]
						 ,CANDIDATE.Person_ID
						 ,CANDIDATE.Title_Name
						 ,CANDIDATE.Full_Name
						 ,CE.Start_Date
						 ,CE.End_Date
						 ,CE.DOJ
						 ,CE.Not_End_Date
						 ,CE.Terminate_Date
						 ,CE.Terminate_Status_ID
						 ,CE.Terminate_Remark
						  ,StC.Status_Contract_EMP_Name
						  --,CT.Contact_type_Name
					 FROM [Employee].[dbo].[Employee] [EMP]
					 LEFT JOIN 
								(	SELECT [CAN].[Candidate_ID],
											[TIT].[Title_Name] ,
											[CAN].[Person_ID],
											[PER].[Full_Name]
									FROM [Candidate].[DBO].[Candidate] CAN 
									LEFT JOIN [Person].[DBO].[Person] PER ON [CAN].[Person_ID] = [PER].[Person_ID]
									LEFT JOIN [Title].[DBO].[Title] TIT ON [TIT].[Title_ID] = [PER].[Title_ID]
								) CANDIDATE ON [CANDIDATE].[Candidate_ID] = [EMP].[Candidate_ID]
						-- OUTER APPLY (
						--        SELECT   TOP (1) *
						--        FROM [Employee].[dbo].[Contract_EMP] AS E
						--        WHERE E.Employee_ID = EMP.Employee_ID
						--        ORDER BY E.Updated_Date DESC
						--) AS CE
						LEFT JOIN [Employee].[dbo].[Contract_EMP]  CE on CE.Employee_ID = EMP.Employee_ID
						LEFT JOIN [Employee].[DBO].[Status_Contract_EMP] StC on StC.[Status_Contract_EMP_ID] = CE.Status_Contract_EMP_ID
						--LEFT JOIN [Employee].[dbo].[Contact_Type] CT on CT.Contact_Type_ID = CE.Contract_Type_ID_OF_Com AND CT.Is_Active = 1 AND CT.Is_Deleted = 0
							where [EMP].Company_ID = 3357
					  --and [EMP].Is_Deleted = 0
					  and [EMP].Status_Employee =  'On Process' 
					  --AND [EMP].Employee_ID = 1339
					-- AND EMP.Candidate_ID = 3798
 ),Terminate AS (
					 SELECT [EMP].[Employee_ID]
					     ,[EMP].[Candidate_ID]
					     ,[EMP].[Is_Active]
					     ,[EMP].[Is_Deleted]
					     ,[EMP].[Created_Date]
					     ,[EMP].[Updated_Date]
					     ,[EMP].[Company_ID]
					     ,[EMP].[Employee_No]
					     ,[EMP].[Bank_ID]
					     ,[EMP].[Bank_Account_Number]
					     ,[EMP].[Manager_ID]
					     ,[EMP].[Status_Employee]
						 ,CANDIDATE.Person_ID
						 ,CANDIDATE.Title_Name
						 ,CANDIDATE.Full_Name
						 ,CE.Start_Date
						 ,CE.End_Date
						 ,CE.DOJ
						 ,CE.Not_End_Date
						 ,CE.Terminate_Date
						 ,CE.Terminate_Status_ID
						 ,CE.Terminate_Remark
						  ,StC.Status_Contract_EMP_Name
						  --,CT.Contact_type_Name
					 FROM [Employee].[dbo].[Employee] [EMP]
					 LEFT JOIN 
								(	SELECT [CAN].[Candidate_ID],
											[TIT].[Title_Name] ,
											[CAN].[Person_ID],
											[PER].[Full_Name]
									FROM [Candidate].[DBO].[Candidate] CAN 
									LEFT JOIN [Person].[DBO].[Person] PER ON [CAN].[Person_ID] = [PER].[Person_ID]
									LEFT JOIN [Title].[DBO].[Title] TIT ON [TIT].[Title_ID] = [PER].[Title_ID]
								) CANDIDATE ON [CANDIDATE].[Candidate_ID] = [EMP].[Candidate_ID]
						-- OUTER APPLY (
						--        SELECT   TOP (1) *
						--        FROM [Employee].[dbo].[Contract_EMP] AS E
						--        WHERE E.Employee_ID = EMP.Employee_ID
						--        ORDER BY E.Updated_Date DESC
						--) AS CE
						LEFT JOIN [Employee].[dbo].[Contract_EMP]  CE on CE.Employee_ID = EMP.Employee_ID
						LEFT JOIN [Employee].[DBO].[Status_Contract_EMP] StC on StC.[Status_Contract_EMP_ID] = CE.Status_Contract_EMP_ID
						--LEFT JOIN [Employee].[dbo].[Contact_Type] CT on CT.Contact_Type_ID = CE.Contract_Type_ID_OF_Com AND CT.Is_Active = 1 AND CT.Is_Deleted = 0
							where [EMP].Company_ID = 3357
					  and [EMP].Is_Deleted = 1
					 -- and [EMP].Status_Employee =  'Released' 
					  --AND [EMP].Employee_ID = 1339
					-- AND EMP.Candidate_ID = 3798
 ),
-- Count by Month-Year: ACTIVE, Released, OnProcess ใช้ Start_Date | Terminate ใช้ Terminate_Date
ActiveByMonth AS (
	SELECT
		YEAR(Start_Date) AS Yr,
		MONTH(Start_Date) AS Mo,
		FORMAT(Start_Date, 'MMM-yy') AS Month_Year,
		COUNT(*) AS Num_Active
	FROM ACTIVE
	WHERE Start_Date IS NOT NULL
	GROUP BY YEAR(Start_Date), MONTH(Start_Date), FORMAT(Start_Date, 'MMM-yy')
),
ReleasedByMonth AS (
	SELECT
		YEAR(Start_Date) AS Yr,
		MONTH(Start_Date) AS Mo,
		FORMAT(Start_Date, 'MMM-yy') AS Month_Year,
		COUNT(*) AS Num_Released
	FROM Released
	WHERE Start_Date IS NOT NULL
	GROUP BY YEAR(Start_Date), MONTH(Start_Date), FORMAT(Start_Date, 'MMM-yy')
),
OnProcessByMonth AS (
	SELECT
		YEAR(Start_Date) AS Yr,
		MONTH(Start_Date) AS Mo,
		FORMAT(Start_Date, 'MMM-yy') AS Month_Year,
		COUNT(*) AS Num_OnProcess
	FROM OnProcess
	WHERE Start_Date IS NOT NULL
	GROUP BY YEAR(Start_Date), MONTH(Start_Date), FORMAT(Start_Date, 'MMM-yy')
),
TerminateByMonth AS (
	SELECT
		YEAR(Terminate_Date) AS Yr,
		MONTH(Terminate_Date) AS Mo,
		FORMAT(Terminate_Date, 'MMM-yy') AS Month_Year,
		COUNT(*) AS Num_Terminate
	FROM Terminate
	WHERE Terminate_Date IS NOT NULL
	GROUP BY YEAR(Terminate_Date), MONTH(Terminate_Date), FORMAT(Terminate_Date, 'MMM-yy')
),
AllMonths AS (
	SELECT Yr, Mo, FORMAT(DATEFROMPARTS(Yr, Mo, 1), 'MMM-yy') AS Month_Year
	FROM (
		SELECT Yr, Mo FROM ActiveByMonth
		UNION
		SELECT Yr, Mo FROM ReleasedByMonth
		UNION
		SELECT Yr, Mo FROM OnProcessByMonth
		UNION
		SELECT Yr, Mo FROM TerminateByMonth
	) u
)
SELECT
	m.Month_Year AS [Month-Year],
	ISNULL(a.Num_Active, 0) AS [Number of Active Employees],
	ISNULL(r.Num_Released, 0) AS [Number of Released Employees],
	ISNULL(t.Num_Terminate, 0) AS [Number of Terminate Employees],
	ISNULL(p.Num_OnProcess, 0) AS [Number of On Process Employees]
FROM AllMonths m
LEFT JOIN ActiveByMonth a ON m.Yr = a.Yr AND m.Mo = a.Mo
LEFT JOIN ReleasedByMonth r ON m.Yr = r.Yr AND m.Mo = r.Mo
LEFT JOIN TerminateByMonth t ON m.Yr = t.Yr AND m.Mo = t.Mo
LEFT JOIN OnProcessByMonth p ON m.Yr = p.Yr AND m.Mo = p.Mo
ORDER BY m.Yr, m.Mo


SELECT *  FROM [Employee].[dbo].[Employee] [EMP] where Candidate_ID = 3793
SELECT [CAN].[Candidate_ID],
						[TIT].[Title_Name] ,
						[CAN].[Person_ID],
						[PER].[Full_Name]
				FROM [Candidate].[DBO].[Candidate] CAN 
				LEFT JOIN [Person].[DBO].[Person] PER ON [CAN].[Person_ID] = [PER].[Person_ID]
				LEFT JOIN [Title].[DBO].[Title] TIT ON [TIT].[Title_ID] = [PER].[Title_ID]
				where Candidate_ID = 3793

select * from .[Contract_EMP]  where Company_ID = 3357 AND Employee_ID = 1339








-- =============================================
-- Procedure name: [dbo].[sp_Get_CTBC_FOR_USER]
-- Function: GetById of Contract Type For User
-- Create date: 1/4/23
-- Description:	Select function seach getall
-- =============================================

DECLARE @Company_ID INT =3357, -- 3442,

		@TYPE_SYSTEM_ID INT = 0,
		@TYPE_TEMP_ID INT = 0,
		@Company_Parent_ID INT = 0;

		SET @TYPE_SYSTEM_ID = (SELECT [CBCT].[Contract_Type_By_Comp_Type_ID] 
								FROM [RMS_Contract_Type].[DBO].[Contract_Type_By_Comp_Type] CBCT 
								WHERE [CBCT].[Contract_Type_By_Comp_Type_Name] = 'System' );

		SET @TYPE_TEMP_ID = (SELECT [CBCT].[Contract_Type_By_Comp_Type_ID] 
								FROM [RMS_Contract_Type].[DBO].[Contract_Type_By_Comp_Type] CBCT 
								WHERE [CBCT].[Contract_Type_By_Comp_Type_Name] = 'Company' );
							
		SET @Company_Parent_ID = (SELECT  [C].[Company_Parent_ID]
								  FROM [Company].[dbo].[Company] C
								  WHERE [C].[Company_ID] = @Company_ID
								 );

		IF(@Company_Parent_ID IS NULL)
			BEGIN 
				SET @Company_Parent_ID = 0;
			END
	IF (@Company_Parent_ID <> 0)
	BEGIN
		SET @Company_ID =	@Company_Parent_ID

	END
			SELECT [CTC].[Contract_Type_By_Comp_ID]
			      ,[CONTRACTTYPE].[Contract_Type_ID]
				  ,[CONTRACTTYPE].[Contract_Type_Name]
				  ,[CONTRACTTYPE].[Type_Contract]
				  ,[Is_Active] = CASE WHEN [CTC].[Is_Active] IS NULL 
									  THEN 0 
								 ELSE [CTC].[Is_Active] 
								 END
			FROM (
						SELECT [CTT].[Contract_Type_Temp_ID] AS [Contract_Type_ID]
							  ,[CTT].[Contract_Type_Temp_Name] AS [Contract_Type_Name]
							  ,@TYPE_TEMP_ID AS [Type_Contract]
							  ,[CTCT].[Contract_Type_By_Comp_Type_Name]
						FROM [RMS_Contract_Type].[dbo].[Contract_Type_Temp] CTT
						LEFT JOIN [RMS_Contract_Type].[dbo].[Contract_Type_By_Comp_Type] CTCT ON [CTCT].[Contract_Type_By_Comp_Type_ID] = @TYPE_TEMP_ID
						WHERE [CTT].[Is_Active] = 1
						AND [CTT].[Company_ID] IN (
													SELECT [COMP].[Company_ID]
													FROM [Company].[dbo].[Company] COMP 
													WHERE [COMP].[Company_Parent_ID] = @Company_ID
													OR [COMP].[Company_ID] = @Company_ID
												  )
						AND [CTT].[Is_Deleted] = 0
					UNION
						SELECT [CT].[Contract_Type_ID]
							  ,[CT].[Contract_Type_Name]
							  ,@TYPE_SYSTEM_ID AS [Type_Contract]
							  ,[CTCT].[Contract_Type_By_Comp_Type_Name]
						FROM [RMS_Contract_Type].[dbo].[Contract_Type] CT
						LEFT JOIN [RMS_Contract_Type].[dbo].[Contract_Type_By_Comp_Type] CTCT ON [CTCT].[Contract_Type_By_Comp_Type_ID] = @TYPE_SYSTEM_ID
						WHERE [CT].[Is_Active] = 1
						AND [CT].[Is_Deleted] = 0
				) CONTRACTTYPE
			LEFT JOIN [RMS_Contract_Type].[dbo].[Contract_Type_By_Comp] CTC ON [CTC].[Contract_Type_ID] = [CONTRACTTYPE].[Contract_Type_ID] 
												        AND [CTC].[Contract_Type_By_Comp_Type_ID] = [CONTRACTTYPE].[Type_Contract] 
												        AND [CTC].[Is_Deleted] = 0
			WHERE [Is_Active] = 1
			AND [CTC].[Company_ID] IN (
										SELECT [COMP].[Company_ID]
										FROM [Company].[dbo].[Company] COMP
										WHERE [COMP].[Company_Parent_ID] = @Company_ID
										OR [COMP].[Company_ID] = @Company_ID
									  )
			ORDER BY [CONTRACTTYPE].[Contract_Type_By_Comp_Type_Name] ASC, [CONTRACTTYPE].[Contract_Type_Name] ASC;
	

	--select *  FROM [RMS_Contract_Type].[dbo].[Contract_Type_By_Comp_Type]
	--select *  FROM  [RMS_Contract_Type].[dbo].[Contract_Type_By_Comp] 
	--select *  FROM [RMS_Contract_Type].[dbo].[Contract_Type]
	--LEFT JOIN [RMS_Contract_Type].[dbo].[Contract_Type_By_Comp_Type] CTCT ON [CTCT].[Contract_Type_By_Comp_Type_ID] = @TYPE_TEMP_ID