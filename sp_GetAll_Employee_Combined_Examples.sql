-- =============================================
-- Examples: sp_GetAll_Employee_Combined
-- Description: Example usage of sp_GetAll_Employee_Combined with multi-value filtering
-- =============================================

USE [Employee]
GO

-- =============================================
-- Example 1: Basic usage - Get all employees for a company
-- =============================================
EXEC [dbo].[sp_GetAll_Employee_Combined]
	@Company_ID = 3357

-- =============================================
-- Example 2: Filter by date range (using Start_Date only)
-- =============================================
EXEC [dbo].[sp_GetAll_Employee_Combined]
	@Company_ID = 3357,
	@From_Date_str = '2025-01-01',
	@To_Date_str = '2025-12-31'

-- =============================================
-- Example 3: Filter by multiple Sales Person IDs
-- =============================================
EXEC [dbo].[sp_GetAll_Employee_Combined]
	@Company_ID = 3357,
	@Sales_Name_str = '3869,3864'

-- =============================================
-- Example 4: Filter by multiple Sales Person Names
-- =============================================
EXEC [dbo].[sp_GetAll_Employee_Combined]
	@Company_ID = 3357,
	@Sales_Name_str = 'John Doe,Jane Smith'

-- =============================================
-- Example 5: Filter by multiple Client Company IDs
-- =============================================
EXEC [dbo].[sp_GetAll_Employee_Combined]
	@Company_ID = 3357,
	@Client_Name_str = '3396,3399'

-- =============================================
-- Example 6: Filter by multiple Client Company Names
-- =============================================
EXEC [dbo].[sp_GetAll_Employee_Combined]
	@Company_ID = 3357,
	@Client_Name_str = 'ABC Company,XYZ Corporation'

-- =============================================
-- Example 7: Filter by multiple Employee Names
-- =============================================
EXEC [dbo].[sp_GetAll_Employee_Combined]
	@Company_ID = 3357,
	@Employee_Name_str = 'M09 (K.) M09,htrfuh qqqqq'

-- =============================================
-- Example 8: Filter by multiple Employee Status Names
-- =============================================
EXEC [dbo].[sp_GetAll_Employee_Combined]
	@Company_ID = 3357,
	@Employee_Status_id = 'Active,Released'

-- =============================================
-- Example 9: Filter by multiple Contract Type IDs
-- =============================================
EXEC [dbo].[sp_GetAll_Employee_Combined]
	@Company_ID = 3357,
	@Contract_Type_id = '6,1'

-- =============================================
-- Example 10: Combined filters - Multiple parameters
-- =============================================
EXEC [dbo].[sp_GetAll_Employee_Combined]
	@Company_ID = 3357,
	@From_Date_str = '2025-01-01',
	@To_Date_str = '2025-12-31',
	@Sales_Name_str = '3869,3864',
	@Client_Name_str = '3396,3399',
	@Employee_Name_str = 'M09 (K.) M09,htrfuh qqqqq',
	@Employee_Status_id = 'Active,Released',
	@Contract_Type_id = '6,1'

-- =============================================
-- Example 11: Filter by Sales Person ID and Client Company ID
-- =============================================
EXEC [dbo].[sp_GetAll_Employee_Combined]
	@Company_ID = 3357,
	@Sales_Name_str = '3869,3864',
	@Client_Name_str = '3396,3399'

-- =============================================
-- Example 12: Filter by Employee Status and Contract Type
-- =============================================
EXEC [dbo].[sp_GetAll_Employee_Combined]
	@Company_ID = 3357,
	@Employee_Status_id = 'Active,Released',
	@Contract_Type_id = '6,1'

-- =============================================
-- Example 13: Filter by date range and employee name
-- =============================================
EXEC [dbo].[sp_GetAll_Employee_Combined]
	@Company_ID = 3357,
	@From_Date_str = '2025-06-01',
	@To_Date_str = '2025-06-30',
	@Employee_Name_str = 'M09 (K.) M09'

-- =============================================
-- Example 14: Single value filters (still works with comma-separated format)
-- =============================================
EXEC [dbo].[sp_GetAll_Employee_Combined]
	@Company_ID = 3357,
	@Sales_Name_str = '3869',
	@Client_Name_str = '3396',
	@Employee_Status_id = 'Active',
	@Contract_Type_id = '6'

-- =============================================
-- Example 15: Empty/Default values (no filtering)
-- =============================================
EXEC [dbo].[sp_GetAll_Employee_Combined]
	@Company_ID = 3357,
	@From_Date_str = '',
	@To_Date_str = '',
	@Sales_Name_str = '',
	@Client_Name_str = '',
	@Employee_Name_str = '',
	@Employee_Status_id = '',
	@Contract_Type_id = ''

-- =============================================
-- NOTES:
-- =============================================
-- 1. @Sales_Name_str: Can accept Person IDs (e.g., '3869,3864') or Names (e.g., 'John Doe,Jane Smith')
-- 2. @Client_Name_str: Can accept Company IDs (e.g., '3396,3399') or Names (e.g., 'ABC Company,XYZ Corp')
-- 3. @Employee_Name_str: Accepts employee names separated by commas
-- 4. @Employee_Status_id: Accepts status names like 'Active,Released' (not IDs)
-- 5. @Contract_Type_id: Accepts contract type IDs separated by commas (e.g., '6,1')
-- 6. Date filters (@From_Date_str, @To_Date_str) use Start_Date only (not End_Date)
-- 7. All filters support multiple values separated by commas
-- 8. Empty strings ('') or NULL values will skip that filter
-- 9. The procedure returns both terminated and non-terminated employees





