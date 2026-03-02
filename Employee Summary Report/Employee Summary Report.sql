USE [Employee]
GO
/****** Object:  StoredProcedure [dbo].[sp_Get_Employee_Summary_Report]    Script Date: 2/5/2026 4:30:19 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: 05-02-2026
-- Description:	<Description,,>
-- sp_Get_Employee_Summary_Report @Company_ID =3357 
-- sp_Get_Employee_Summary_Report @Company_ID =3357, @DateFrom = '2025-01-01', @DateTo = '2025-12-31'
-- sp_Get_Employee_Summary_Report_Detail @Company_ID =3357  ,@RespID ='2025-01' ,@KEYID = 'Terminate'
-- =============================================
ALTER PROCEDURE [dbo].[sp_Get_Employee_Summary_Report] 
	@Company_ID INT = 0,
	@DateFrom VARCHAR(50) = NULL,
	@DateTo VARCHAR(50) = NULL

AS

BEGIN TRY
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
										OUTER APPLY (
												SELECT TOP 1 *
												FROM [Employee].[dbo].[Contract_EMP] AS E
												WHERE E.Employee_ID = EMP.Employee_ID
												ORDER BY E.Updated_Date DESC
										) CE
										LEFT JOIN [Employee].[DBO].[Status_Contract_EMP] StC on StC.[Status_Contract_EMP_ID] = CE.Status_Contract_EMP_ID
										--LEFT JOIN [Employee].[dbo].[Contact_Type] CT on CT.Contact_Type_ID = CE.Contract_Type_ID_OF_Com AND CT.Is_Active = 1 AND CT.Is_Deleted = 0
											where [EMP].Company_ID = @Company_ID
									  and [EMP].Is_Deleted = 0
									  	  and [EMP].Status_Employee =  'Active'
									  AND (@DateFrom IS NULL OR @DateFrom = '' OR CE.Start_Date >= CAST(@DateFrom AS DATETIME))
									  AND (@DateTo IS NULL OR @DateTo = '' OR CE.Start_Date <= CAST(@DateTo AS DATETIME))
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
										OUTER APPLY (
												SELECT TOP 1 *
												FROM [Employee].[dbo].[Contract_EMP] AS E
												WHERE E.Employee_ID = EMP.Employee_ID
												ORDER BY E.Updated_Date DESC
										) CE
										LEFT JOIN [Employee].[DBO].[Status_Contract_EMP] StC on StC.[Status_Contract_EMP_ID] = CE.Status_Contract_EMP_ID
										--LEFT JOIN [Employee].[dbo].[Contact_Type] CT on CT.Contact_Type_ID = CE.Contract_Type_ID_OF_Com AND CT.Is_Active = 1 AND CT.Is_Deleted = 0
											where [EMP].Company_ID = @Company_ID
									  --and [EMP].Is_Deleted = 0
									  and [EMP].Status_Employee =  'Released' 
									  AND (@DateFrom IS NULL OR @DateFrom = '' OR CE.Start_Date >= CAST(@DateFrom AS DATETIME))
									  AND (@DateTo IS NULL OR @DateTo = '' OR CE.Start_Date <= CAST(@DateTo AS DATETIME))
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
										OUTER APPLY (
												SELECT TOP 1 *
												FROM [Employee].[dbo].[Contract_EMP] AS E
												WHERE E.Employee_ID = EMP.Employee_ID
												ORDER BY E.Updated_Date DESC
										) CE
										LEFT JOIN [Employee].[DBO].[Status_Contract_EMP] StC on StC.[Status_Contract_EMP_ID] = CE.Status_Contract_EMP_ID
										--LEFT JOIN [Employee].[dbo].[Contact_Type] CT on CT.Contact_Type_ID = CE.Contact_Type_ID_OF_Com AND CT.Is_Active = 1 AND CT.Is_Deleted = 0
											where [EMP].Company_ID = @Company_ID
									  --and [EMP].Is_Deleted = 0
									  and [EMP].Status_Employee =  'On Process' 
									  AND (@DateFrom IS NULL OR @DateFrom = '' OR CE.Start_Date >= CAST(@DateFrom AS DATETIME))
									  AND (@DateTo IS NULL OR @DateTo = '' OR CE.Start_Date <= CAST(@DateTo AS DATETIME))
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
										OUTER APPLY (
												SELECT TOP 1 *
												FROM [Employee].[dbo].[Contract_EMP] AS E
												WHERE E.Employee_ID = EMP.Employee_ID
												ORDER BY E.Updated_Date DESC
										) CE
										LEFT JOIN [Employee].[DBO].[Status_Contract_EMP] StC on StC.[Status_Contract_EMP_ID] = CE.Status_Contract_EMP_ID
										--LEFT JOIN [Employee].[dbo].[Contact_Type] CT on CT.Contact_Type_ID = CE.Contract_Type_ID_OF_Com AND CT.Is_Active = 1 AND CT.Is_Deleted = 0
											where [EMP].Company_ID = @Company_ID
									  and [EMP].Is_Deleted = 1
									 -- and [EMP].Status_Employee =  'Released' 
									  AND (@DateFrom IS NULL OR @DateFrom = '' OR CE.Terminate_Date >= CAST(@DateFrom AS DATETIME))
									  AND (@DateTo IS NULL OR @DateTo = '' OR CE.Terminate_Date <= CAST(@DateTo AS DATETIME))
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
					FORMAT(DATEFROMPARTS(m.Yr, m.Mo, 1), 'yyyy-MM') AS RespID,
					m.Month_Year AS [Month-Year],
					ISNULL(a.Num_Active, 0) AS Num_Active,
					ISNULL(r.Num_Released, 0) AS Num_Released,
					ISNULL(t.Num_Terminate, 0) AS Num_Terminate,
					ISNULL(p.Num_OnProcess, 0) AS Num_OnProcess,
					-- KEYID สำหรับส่งไปดู Detail: ส่ง RespID + KEYID ไปที่ Detail Report
					'Active'    AS [KEYID_Active],
					'Released'  AS [KEYID_Released],
					'Terminate' AS [KEYID_Terminate],
					'OnProcess' AS [KEYID_OnProcess]
				FROM AllMonths m
				LEFT JOIN ActiveByMonth a ON m.Yr = a.Yr AND m.Mo = a.Mo
				LEFT JOIN ReleasedByMonth r ON m.Yr = r.Yr AND m.Mo = r.Mo
				LEFT JOIN TerminateByMonth t ON m.Yr = t.Yr AND m.Mo = t.Mo
				LEFT JOIN OnProcessByMonth p ON m.Yr = p.Yr AND m.Mo = p.Mo
				ORDER BY m.Yr, m.Mo
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
					,'DB Employee - sp_Get_Employee_Summary_Report'
					,ERROR_MESSAGE()
					,999
					,GETDATE());
END CATCH
