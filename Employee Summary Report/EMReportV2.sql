DECLARE @Status_ID INT = 0,
        @Company_ID INT = 3357,

		  @TYPE_SYSTEM_ID INT,
    @TYPE_TEMP_ID INT,
    @Company_Parent_ID INT;

SELECT TOP 1 
    @Status_ID = SCE.Status_Contract_EMP_ID
FROM [Employee].[dbo].[Status_Contract_EMP] SCE
WHERE SCE.Status_Contract_EMP_Name = 'New';

-- ===== Get Type IDs =====
SELECT 
    @TYPE_SYSTEM_ID = MAX(CASE WHEN Contract_Type_By_Comp_Type_Name = 'System'  THEN Contract_Type_By_Comp_Type_ID END),
    @TYPE_TEMP_ID   = MAX(CASE WHEN Contract_Type_By_Comp_Type_Name = 'Company' THEN Contract_Type_By_Comp_Type_ID END)
FROM [RMS_Contract_Type].dbo.Contract_Type_By_Comp_Type;

-- ===== Get Parent Company =====
SELECT 
    @Company_Parent_ID = ISNULL(Company_Parent_ID, 0)
FROM [Company].[dbo].[Company]
WHERE Company_ID = @Company_ID;

Declare @Terminate_TypeC	int =  ( select TOP 1 Terminate_Status_Type_ID FROM [Terminate_Status].[dbo].[Terminate_Status_Type] where Terminate_Status_Type_Name = 'Company' )
Declare @Terminate_TypeS	int =  ( select TOP 1 Terminate_Status_Type_ID FROM [Terminate_Status].[dbo].[Terminate_Status_Type] where Terminate_Status_Type_Name = 'System' )

;WITH Employee_info AS (
    SELECT
        EMP.Company_ID,
        EMP.Employee_ID,
        EMP.Candidate_ID,
        EMP.Status_Employee,
        EMP.Is_Active,
        EMP.Is_Deleted,

        -- Candidate
        CAN.Person_ID,
        TIT.Title_Name,
        PER.Full_Name,

        -- Contract (ล่าสุดต่อ Employee)
        CE.Contract_Type_ID_OF_Com,
		CE.DOJ AS Date_Of_Join,
        CE.Start_Date,
        CE.End_Date,
        CE.Status_Contract_EMP_ID,
		st.Status_Contract_EMP_Name,
        CE.Terminate_Date,
        CE.Terminate_Status_ID,
		ts.Terminate_Name,
		ts.Terminate_Status_Type_ID,
        CE.Terminate_Remark,
        CE.Position_ID_OF_Com,
        CE.Position_By_Com_ID,
        CE.Project_Position_ID,
        CE.Contract_EMP_ID,
        CE.Contract_Type_By_Comp_ID,
        CE.Created_By,
        CE.Updated_By
    FROM [Employee].[dbo].[Employee] EMP

    -- Candidate
    LEFT JOIN [Candidate].[DBO].[Candidate] CAN
        ON CAN.Candidate_ID = EMP.Candidate_ID
    LEFT JOIN [Person].[DBO].[Person] PER
        ON PER.Person_ID = CAN.Person_ID
    LEFT JOIN [Title].[DBO].[Title] TIT
        ON TIT.Title_ID = PER.Title_ID
    -- Contract ล่าสุดของแต่ละ Employee
    OUTER APPLY (
        SELECT TOP 1 *
        FROM [Employee].[dbo].[Contract_EMP] CE
        WHERE CE.Employee_ID = EMP.Employee_ID
        ORDER BY CE.Updated_Date DESC
    ) CE
	 --LEFT JOIN	 [Employee].[dbo].[Contact_Type] CT ON CT.Contact_Type_ID = CE.Contract_Type_ID_OF_Com
	 LEFT JOIN [Employee].[dbo].[Status_Contract_EMP] st ON st.Status_Contract_EMP_ID = CE.Status_Contract_EMP_ID
	  LEFT JOIN [Terminate_Status].[dbo].[Terminate_Status] ts ON ts.Terminate_ID = CE.Terminate_Status_ID 
    WHERE EMP.Company_ID = @Company_ID
	), 
		-- ===== Company Scope =====
	CompanyScope AS (
    SELECT Company_ID
    FROM [Company].[dbo].[Company]
    WHERE Company_ID = CASE WHEN @Company_Parent_ID = 0 THEN @Company_ID ELSE @Company_Parent_ID END
       OR Company_Parent_ID = CASE WHEN @Company_Parent_ID = 0 THEN @Company_ID ELSE @Company_Parent_ID END
	),
	-- ===== Contract Types (System + Company) =====
	ContractType AS (
				SELECT 
				    CTT.Contract_Type_Temp_ID AS Contract_Type_ID,
				    CTT.Contract_Type_Temp_Name AS Contract_Type_Name,
				    @TYPE_TEMP_ID AS Type_Contract,
				    CTCT.Contract_Type_By_Comp_Type_Name
				FROM [RMS_Contract_Type].dbo.Contract_Type_Temp CTT
				JOIN CompanyScope CS ON CS.Company_ID = CTT.Company_ID
				JOIN [RMS_Contract_Type].dbo.Contract_Type_By_Comp_Type CTCT 
				    ON CTCT.Contract_Type_By_Comp_Type_ID = @TYPE_TEMP_ID
				WHERE CTT.Is_Active = 1
				  AND CTT.Is_Deleted = 0

				UNION ALL

				SELECT 
				    CT.Contract_Type_ID,
				    CT.Contract_Type_Name,
				    @TYPE_SYSTEM_ID AS Type_Contract,
				    CTCT.Contract_Type_By_Comp_Type_Name
				FROM [RMS_Contract_Type].dbo.Contract_Type CT
				JOIN [RMS_Contract_Type].dbo.Contract_Type_By_Comp_Type CTCT 
				    ON CTCT.Contract_Type_By_Comp_Type_ID = @TYPE_SYSTEM_ID
				WHERE CT.Is_Active = 1
				  AND CT.Is_Deleted = 0

	) ,Contract_Type AS(
			
			-- ===== Final Result =====
			SELECT
			    CTC.Contract_Type_By_Comp_ID,
			    CT.Contract_Type_ID,
			    CT.Contract_Type_Name,
			    CT.Type_Contract,
			    Is_Active = ISNULL(CTC.Is_Active, 0)
			FROM ContractType CT
			LEFT JOIN [RMS_Contract_Type].dbo.Contract_Type_By_Comp CTC
			    ON CTC.Contract_Type_ID = CT.Contract_Type_ID
			   AND CTC.Contract_Type_By_Comp_Type_ID = CT.Type_Contract
			   AND CTC.Is_Deleted = 0
			WHERE CTC.Company_ID IN (SELECT Company_ID FROM CompanyScope)
			  AND ISNULL(CTC.Is_Active, 0) = 1
	),-- CTE: Project Position details (simplified with COALESCE)
	ProjectPositions AS (
		SELECT 
			[PP].[Project_Position_ID],
			[Site_ID] = COALESCE([MPP].[Site_ID], [MSP].[Site_ID], 0),
			[Branch_ID] = COALESCE([MPP].[Branch_ID], [MSP].[Branch_ID], [MBP].[Branch_ID], 0),
			[Project_Client_ID] = COALESCE([MPP].[Project_Client_ID], 0),
			[Company_ID] = [COM].[Company_ID],
			[ComCliantName] = [COM].[Company_Name]
		FROM [Company].[dbo].[Project_Position] PP
		LEFT JOIN [Company].[dbo].[Map_Comp_Position] MCPP ON [MCPP].[Project_Position_ID] = [PP].[Project_Position_ID] 
			AND [MCPP].[Is_Active] = 1 AND [MCPP].[Is_Delete] = 0
		LEFT JOIN (
			SELECT [MPP].[Project_Position_ID]
					,[PC].[Project_Client_ID]
					,[PC].[Project_Name]
					,[PC].[Branch_ID]
					,[PC].[Branch_Name]
					,[PC].[Site_ID]
					,[PC].[Site_Name]
					,[PC].[Comp_Branch_Project]
					,[PC].[Comp_Branch_Site_Project]
					,[PC].[Comp_Project]
					,[PC].[Comp_Site_Project]
			FROM [Company].[dbo].[Map_Project_Position] MPP
			LEFT JOIN (
				SELECT [PC].[Project_Client_ID]
						,[PC].[Project_Name]
						,[Comp_Project] = [MCP].[Company_ID]
						,[MBP].[Comp_Branch_Project]
						,[MSP].[Comp_Branch_Site_Project]
						,[MSP].[Comp_Site_Project]
						,[MSP].[Site_ID]
						,[MSP].[Site_Name]
						,[Branch_ID] = COALESCE([MBP].[Branch_ID_Of_Project], [MSP].[Branch_ID_Of_Site_Project])
						,[Branch_Name] = COALESCE([MBP].[Branch_Name_Of_Project], [MSP].[Branch_Name_Of_Site_Project])
				FROM [Company].[dbo].[Project_Client] PC
				LEFT JOIN [Company].[dbo].[Map_Comp_Project] MCP ON [MCP].[Project_Client_ID] = [PC].[Project_Client_ID] 
					AND [MCP].[Is_Active] = 1 AND [MCP].[Is_Delete] = 0
				LEFT JOIN (
					SELECT [Branch_ID_Of_Project] = [B].[Branch_ID]
							,[Branch_Name_Of_Project] = [B].[Branch_Name]
							,[Comp_Branch_Project] = [MCB].[Company_ID]
							,[MBP].[Project_Client_ID]
					FROM [Company].[dbo].[Map_Branch_Project] MBP
					LEFT JOIN [Company].[dbo].[Map_Comp_Branch] MCB ON [MCB].[Branch_ID] = [MBP].[Branch_ID] 
						AND [MCB].[Is_Active] = 1 AND [MCB].[Is_Delete] = 0
					LEFT JOIN [Company].[dbo].[Branch_By_Comp] B ON [B].[Branch_ID] = [MBP].[Branch_ID] 
						AND [B].[Is_Active] = 1 AND [B].[Is_Delete] = 0
					WHERE [MBP].[Is_Active] = 1 AND [MBP].[Is_Delete] = 0
				) MBP ON [MBP].[Project_Client_ID] = [PC].[Project_Client_ID]
				LEFT JOIN (
					SELECT [MSP].[Project_Client_ID]
							,[S].[Site_ID]
							,[S].[Site_Name]
							,[Branch_ID_Of_Site_Project] = [BS].[Branch_ID]
							,[Branch_Name_Of_Site_Project] = [BS].[Branch_Name]
							,[Comp_Site_Project] = [MCS].[Company_ID]
							,[Comp_Branch_Site_Project] = [MCB].[Company_ID]
					FROM [Company].[dbo].[Map_Site_Project] MSP
					LEFT JOIN [Company].[dbo].[Map_Comp_Site] MCS ON [MCS].[Site_ID] = [MSP].[Site_ID] 
						AND [MSP].[Is_Active] = 1 AND [MSP].[Is_Delete] = 0
					LEFT JOIN [Company].[dbo].[Site] S ON [S].[Site_ID] = [MSP].[Site_ID] AND [S].[Is_Active] = 1
					LEFT JOIN [Company].[dbo].[Map_Branch_Site] MBS ON [MBS].[Site_ID] = [MSP].[Site_ID] 
						AND [MBS].[Is_Active] = 1 AND [MBS].[Is_Delete] = 0
					LEFT JOIN [Company].[dbo].[Map_Comp_Branch] MCB ON [MCB].[Branch_ID] = [MBS].[Branch_ID] 
						AND [MCB].[Is_Active] = 1 AND [MCB].[Is_Delete] = 0
					LEFT JOIN [Company].[dbo].[Branch_By_Comp] BS ON [BS].[Branch_ID] = [MBS].[Branch_ID] 
						AND [BS].[Is_Active] = 1 AND [BS].[Is_Delete] = 0
					WHERE [MSP].[Is_Active] = 1 AND [MSP].[Is_Delete] = 0
				) MSP ON [MSP].[Project_Client_ID] = [PC].[Project_Client_ID]
				WHERE [PC].[Is_Active] = 1 AND [PC].[Is_Delete] = 0
			) PC ON [PC].[Project_Client_ID] = [MPP].[Project_Client_ID]
			WHERE [MPP].[Is_Active] = 1 AND [MPP].[Is_Delete] = 0
		) MPP ON [MPP].[Project_Position_ID] = [PP].[Project_Position_ID]
		LEFT JOIN (
			SELECT [MSP].[Project_Position_ID]
					,[S].[Site_ID]
					,[S].[Site_Name]
					,[BS].[Branch_ID]
					,[BS].[Branch_Name]
					,[Comp_Site] = [MCS].[Company_ID]
					,[Comp_Branch_Site] = [MCB].[Company_ID]
			FROM [Company].[dbo].[Map_Site_Position] MSP
			LEFT JOIN [Company].[dbo].[Map_Comp_Site] MCS ON [MCS].[Site_ID] = [MSP].[Site_ID] 
				AND [MSP].[Is_Active] = 1 AND [MSP].[Is_Delete] = 0
			LEFT JOIN [Company].[dbo].[Site] S ON [S].[Site_ID] = [MSP].[Site_ID] AND [S].[Is_Active] = 1
			LEFT JOIN [Company].[dbo].[Map_Branch_Site] MBS ON [MBS].[Site_ID] = [MSP].[Site_ID] 
				AND [MBS].[Is_Active] = 1 AND [MBS].[Is_Delete] = 0
			LEFT JOIN [Company].[dbo].[Map_Comp_Branch] MCB ON [MCB].[Branch_ID] = [MBS].[Branch_ID] 
				AND [MCB].[Is_Active] = 1 AND [MCB].[Is_Delete] = 0
			LEFT JOIN [Company].[dbo].[Branch_By_Comp] BS ON [BS].[Branch_ID] = [MBS].[Branch_ID] 
				AND [BS].[Is_Active] = 1 AND [BS].[Is_Delete] = 0
			WHERE [MSP].[Is_Active] = 1 AND [MSP].[Is_Delete] = 0
		) MSP ON [MSP].[Project_Position_ID] = [PP].[Project_Position_ID] 
		LEFT JOIN (
			SELECT [MBP].[Project_Position_ID]
					,[BS].[Branch_ID]
					,[BS].[Branch_Name]
					,[Comp_Branch] = [MCB].[Company_ID]
			FROM [Company].[dbo].[Map_Branch_Position] MBP
			LEFT JOIN [Company].[dbo].[Map_Comp_Branch] MCB ON [MCB].[Branch_ID] = [MBP].[Branch_ID] 
				AND [MCB].[Is_Active] = 1 AND [MCB].[Is_Delete] = 0
			LEFT JOIN [Company].[dbo].[Branch_By_Comp] BS ON [BS].[Branch_ID] = [MBP].[Branch_ID] 
				AND [BS].[Is_Active] = 1 AND [BS].[Is_Delete] = 0
			WHERE [MBP].[Is_Active] = 1 AND [MBP].[Is_Delete] = 0
		) MBP ON [MBP].[Project_Position_ID] = [PP].[Project_Position_ID]
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
	),
	
	-- ============= Terminate_Status =============
	
	Terminate_Status AS (
							SELECT [TS].[Terminate_ID] 
							FROM [Terminate_Status].[dbo].[Terminate_Status] TS
							WHERE [TS].[Terminate_ID] NOT IN (SELECT [S].[Terminate_ID]
																FROM [Terminate_Status].[dbo].[Terminate_Status] S
																WHERE [S].[Terminate_Name] IN ('Retained', 'End Contract', 'Resign')
																AND [S].[Terminate_Status_Type_ID] =@Terminate_TypeS)
							AND (
									([TS].[Company_ID] = @Terminate_TypeC AND [TS].[Terminate_Status_Type_ID] = @Terminate_TypeC) OR
									([TS].[Terminate_Status_Type_ID] =@Terminate_TypeS)
								)
	),

	-- ============= Select ACTIVE =============
	Table_ACTIVE AS (


					-- select [ACTIVE]
					SELECT 
					  @Company_ID as Company_ID ,
						[sell_CliantName] = CASE WHEN [MUP].[Owner_Name] IS NOT NULL THEN [MUP].[Owner_Name] ELSE '-' END,
					--PP.*,e.*,
					PP.ComCliantName,
					e.Full_Name,
					e.Employee_ID,
					e.Date_Of_Join,
					e.Start_Date,
					e.End_Date,
					e.Status_Contract_EMP_ID,
					e.Status_Employee,
					ct.Contract_Type_Name,
					ste.Status_Contract_EMP_Name,
					e.Terminate_Date,
					e.Terminate_Name,
					e.Terminate_Remark,
					e.Terminate_Status_Type_ID
					
					FROM Employee_info e
					left join Contract_Type ct on ct.Contract_Type_ID = e.Contract_Type_ID_OF_Com
					left join [Employee].[dbo].[Status_Contract_EMP] ste on ste.Status_Contract_EMP_ID = e.Status_Contract_EMP_ID

					-- Get Project Position details
					LEFT JOIN ProjectPositions PP ON [PP].[Project_Position_ID] = e.[Project_Position_ID]
					LEFT JOIN (
						SELECT [MUP].[Project_Position_ID],
							[Owner_Name] = [P].[Full_Name],
							[MUP].[Person_ID],
							[MUP].[Is_Active]
						FROM [Company].[dbo].[Map_User_PrjPosi] MUP
						LEFT JOIN [Person].[dbo].[Person] P ON [P].[Person_ID] = [MUP].[Person_ID]
					) MUP ON [MUP].[Project_Position_ID] = [PP].[Project_Position_ID] AND [MUP].[Is_Active] = 1
					WHERE e.Is_Active = 1
					AND Status_Employee = 'Active'
					AND e.Is_Deleted = 0
					--AND e.Terminate_Status_ID in (select Terminate_ID from Terminate_Status)

		 )
		,Table_Released  AS (


					  -- Released 
					  SELECT 
					--  @Company_ID as Company_ID ,
						[sell_CliantName] = CASE WHEN [MUP].[Owner_Name] IS NOT NULL THEN [MUP].[Owner_Name] ELSE '-' END,
				  --  PP.*
					--e.*
					PP.ComCliantName,
					e.Full_Name,
					e.Employee_ID,
					e.Date_Of_Join,
					e.Start_Date,
					e.End_Date,
					e.Status_Contract_EMP_ID,
					e.Status_Employee,
					ct.Contract_Type_Name,
					e.Terminate_Date,
					e.Terminate_Name,
					e.Terminate_Remark,
					e.Terminate_Status_Type_ID
					FROM Employee_info e
					left join Contract_Type ct on ct.Contract_Type_ID = e.Contract_Type_ID_OF_Com
					-- Get Project Position details
					LEFT JOIN ProjectPositions PP ON [PP].[Project_Position_ID] = e.[Project_Position_ID]
					LEFT JOIN (
						SELECT [MUP].[Project_Position_ID],
							[Owner_Name] = [P].[Full_Name],
							[MUP].[Person_ID],
							[MUP].[Is_Active]
						FROM [Company].[dbo].[Map_User_PrjPosi] MUP
						LEFT JOIN [Person].[dbo].[Person] P ON [P].[Person_ID] = [MUP].[Person_ID]
					) MUP ON [MUP].[Project_Position_ID] = [PP].[Project_Position_ID] AND [MUP].[Is_Active] = 1
					
					where Status_Employee = 'Released'
					--AND e.Terminate_Status_ID in (select Terminate_ID from Terminate_Status)

					--select * from Employee_info


	 ),Table_Terminate  AS (


					  -- Released 
					  SELECT 
					--  @Company_ID as Company_ID ,
						--[sell_CliantName] = CASE WHEN [MUP].[Owner_Name] IS NOT NULL THEN [MUP].[Owner_Name] ELSE '-' END,
				   -- PP.*,
					e.*
					--PP.ComCliantName,
					--e.Full_Name,
					--e.Employee_ID,
					--e.Date_Of_Join,
					--e.Start_Date,
					--e.End_Date,
					--e.Status_Contract_EMP_ID,
					--e.Status_Employee,
					--ct.Contract_Type_Name,
					--e.Terminate_Date,
					--e.Terminate_Name,
					--e.Terminate_Remark,
					--e.Terminate_Status_Type_ID
					FROM Employee_info e
					left join Contract_Type ct on ct.Contract_Type_ID = e.Contract_Type_ID_OF_Com
					-- Get Project Position details
					LEFT JOIN ProjectPositions PP ON [PP].[Project_Position_ID] = e.[Project_Position_ID]
					LEFT JOIN (
						SELECT [MUP].[Project_Position_ID],
							[Owner_Name] = [P].[Full_Name],
							[MUP].[Person_ID],
							[MUP].[Is_Active]
						FROM [Company].[dbo].[Map_User_PrjPosi] MUP
						LEFT JOIN [Person].[dbo].[Person] P ON [P].[Person_ID] = [MUP].[Person_ID]
					) MUP ON [MUP].[Project_Position_ID] = [PP].[Project_Position_ID] AND [MUP].[Is_Active] = 1
					
					where e.Is_Active = 1 and e.Is_Deleted =1
					--AND e.Terminate_Status_ID in (select Terminate_ID from Terminate_Status)

					--select * from Employee_info


	 )
	-- select * from Table_ACTIVE
	
	-- select * from Table_Released
	select * from Table_Terminate
	
  -- position_By_Com_ID    position_ID_Of_Com
  -- (Position Of Project)    (Position Of Employee)

  --select *   FROM [Employee].[dbo].[Employee] EMP


    --  select *   FROM [Employee].[dbo].[Contract_EMP]