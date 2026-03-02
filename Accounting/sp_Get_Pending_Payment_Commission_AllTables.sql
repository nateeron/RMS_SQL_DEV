USE [Accounting]
GO
-- =============================================
-- All tables used in sp_Get_Pending_Payment_Commission
-- SELECT * FROM each table (for reference / data check)
-- =============================================

-- [Accounting]
SELECT * FROM [Accounting].[dbo].[Invoice_of_Commission];

-- [Candidate]
SELECT * FROM [Candidate].[dbo].[Candidate];
SELECT * FROM [Candidate].[dbo].[Log_Update_Candidate];

-- [Company]
SELECT * FROM [Company].[dbo].[Company];
SELECT * FROM [Company].[dbo].[Project_Position];
SELECT * FROM [Company].[dbo].[Map_Comp_Position];
SELECT * FROM [Company].[dbo].[Map_Project_Position];
SELECT * FROM [Company].[dbo].[Project_Client];
SELECT * FROM [Company].[dbo].[Map_Comp_Project];
SELECT * FROM [Company].[dbo].[Map_Branch_Project];
SELECT * FROM [Company].[dbo].[Map_Comp_Branch];
SELECT * FROM [Company].[dbo].[Map_Site_Project];
SELECT * FROM [Company].[dbo].[Map_Comp_Site];
SELECT * FROM [Company].[dbo].[Map_Branch_Site];
SELECT * FROM [Company].[dbo].[Map_Site_Position];
SELECT * FROM [Company].[dbo].[Map_Branch_Position];
SELECT * FROM [Company].[dbo].[Map_Payment_Condition];
SELECT * FROM [Company].[dbo].[Payment_Condition];
SELECT * FROM [Company].[dbo].[Map_Commission_Type_Position];
SELECT * FROM [Company].[dbo].[Commission_Type];

-- [Employee]
SELECT * FROM [Employee].[dbo].[Contract_EMP];
SELECT * FROM [Employee].[dbo].[Employee];
SELECT * FROM [Employee].[dbo].[Status_Contract_EMP];

-- [Person]
SELECT * FROM [Person].[dbo].[Person];
SELECT * FROM [Person].[dbo].[Map_Person];

-- [RMS_Position]
SELECT * FROM [RMS_Position].[dbo].[Position];
SELECT * FROM [RMS_Position].[dbo].[Position_Temp];
SELECT * FROM [RMS_Position].[dbo].[Position_By_Comp];

-- [Role]
SELECT * FROM [Role].[dbo].[Role_Type];
SELECT * FROM [Role].[dbo].[Role];
SELECT * FROM [Role].[dbo].[Map_Role_User];

-- [Terminate_Status]
SELECT * FROM [Terminate_Status].[dbo].[Terminate_Status];

-- [LOG] (used in CATCH block)
-- SELECT * FROM [LOG].[dbo].[Log];
