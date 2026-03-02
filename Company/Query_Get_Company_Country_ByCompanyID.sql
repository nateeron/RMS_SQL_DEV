USE [Company]
GO
-- =============================================
-- Query: Company_ID, Company_Name, Country_ID, Country_Name
-- WHERE Company_ID = @Company_ID
-- =============================================

DECLARE @Company_ID INT = 0; -- 0 , 3357

DECLARE @Cate_Type_ID   INT = (SELECT TOP 1 Category_Type_ID FROM [Address].[dbo].[Address_Category_Type] WHERE Category_Type_Name = 'Company');
DECLARE @Address_Type_ID INT = (SELECT TOP 1 Address_Type_ID FROM [Address].[dbo].[Address_Type] WHERE Address_Type_Name = 'Register');

SELECT
    COMP.Company_ID,
    COMP.Company_Name,
    ADS.Country_ID,
    COU.Country_Name
FROM [Company].[dbo].[Company] COMP
LEFT JOIN [Address].[dbo].[Address] ADS
    ON ADS.Reference_ID = COMP.Company_ID
   AND ADS.Category_Type_ID = @Cate_Type_ID
   AND ADS.Address_Type_ID = @Address_Type_ID
LEFT JOIN [Country].[dbo].[Country] COU
    ON COU.Country_ID = ADS.Country_ID
   AND COU.Is_Active = 1
   AND COU.Is_Deleted = 0
WHERE (COMP.Company_ID = @Company_ID or @Company_ID = 0)
  AND COMP.Is_Active = 1
  AND COMP.Is_Delete = 0
  AND ADS.Country_ID IS NOT NULL
ORDER BY COU.Country_Name;
