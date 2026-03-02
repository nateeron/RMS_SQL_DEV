DECLARE @Status_ID INT = 0,
	@Company_ID int = 3357;
	SET  @Status_ID = (SELECT TOP 1 [SCE].[Status_Contract_EMP_ID]
						FROM [Employee].[dbo].[Status_Contract_EMP] SCE
						WHERE [SCE].[Status_Contract_EMP_Name] = 'New');

	with Employee_info AS (
	

		--SELECT
		--	[EMP].[Employee_ID]
		--	,CONCAT(TRIM([CANDIDATE].[Title_Name]) + ' ',  [CANDIDATE].[Full_Name]) AS [Employee_Name]
		SELECT
		'| EMP |' AS EMP,
		EMP.Company_ID,
		EMP.Employee_ID,
		EMP.Candidate_ID,
		EMP.Status_Employee,
		EMP.Is_Active,
		EMP.Is_Deleted,
		'| CANDIDATE |' AS CANDIDATE,
		CANDIDATE.Person_ID,
		CANDIDATE.Title_Name,
		CANDIDATE.Full_Name,
		'| CE |' AS CE,
		CE.DOJ AS Date_Of_Join,
		CE.Start_Date,
		CE.End_Date,
		CE.Status_Contract_EMP_ID,
		CE.Terminate_Date,
		CE.Terminate_Status_ID,
		CE.Terminate_Remark,
		CE.Position_ID_OF_Com,
		CE.Position_By_Com_ID,
		CE.Project_Position_ID,
		CE.Contract_EMP_ID,
		CE.Contract_Type_By_Comp_ID,
		CE.Contract_Type_ID_OF_Com,
		CE.Created_By,
		CE.Updated_By
		--,'##' as __,
		--*
		FROM [Employee].[dbo].[Employee] EMP
		LEFT JOIN 
			(	SELECT [CAN].[Candidate_ID],
						[TIT].[Title_Name] ,
						[CAN].[Person_ID],
						[PER].[Full_Name]
				FROM [Candidate].[DBO].[Candidate] CAN 
				LEFT JOIN [Person].[DBO].[Person] PER ON [CAN].[Person_ID] = [PER].[Person_ID]
				LEFT JOIN [Title].[DBO].[Title] TIT ON [TIT].[Title_ID] = [PER].[Title_ID]
			) CANDIDATE ON [CANDIDATE].[Candidate_ID] = [EMP].[Candidate_ID]
			--LEFT JOIN  [dbo].[Contract_EMP]  CE ON [CE].[Employee_ID] = [EMP].[Employee_ID] 
			LEFT JOIN (select  Top 1 * FROM [Employee].[dbo].[Contract_EMP] order by Updated_Date) CE ON [CE].[Employee_ID] = [EMP].[Employee_ID] 
		where [EMP].[Company_ID] = @Company_ID
		--AND [EMP].[Is_Deleted] = 0
		--AND [CE].[Status_Contract_EMP_ID] = @Status_ID
		--AND [CE].Is_Active = 1
		--order by Terminate_Date desc
	
	) 
	-- select [ACTIVE]
	select Full_Name , *  from  Employee_info where  Is_Active = 1 AND Is_Deleted = 0  -- and Employee_ID = 1336

select * FROM [Employee].[dbo].[Employee] EMP
		LEFT JOIN 
			(	SELECT [CAN].[Candidate_ID],
						[TIT].[Title_Name] ,
						[CAN].[Person_ID],
						[PER].[Full_Name]
				FROM [Candidate].[DBO].[Candidate] CAN 
				LEFT JOIN [Person].[DBO].[Person] PER ON [CAN].[Person_ID] = [PER].[Person_ID]
				LEFT JOIN [Title].[DBO].[Title] TIT ON [TIT].[Title_ID] = [PER].[Title_ID]
			) CANDIDATE ON [CANDIDATE].[Candidate_ID] = [EMP].[Candidate_ID]
			LEFT JOIN (select  Top 1 * FROM [Employee].[dbo].[Contract_EMP] order by Updated_Date) CE ON [CE].[Employee_ID] = [EMP].[Employee_ID] 
			where EMP.Company_ID = 3357 and EMP.Is_Active = 1 and EMP.Is_Deleted = 0


		select * FROM	[Employee].[dbo].[Contract_EMP] where Company_ID = 3357 and Employee_ID = 1336
		order by Employee_ID, Updated_Date desc