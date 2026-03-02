USE [Company]
GO
-- =============================================
-- Query: Countries + Cities (saved list only)
-- Thailand, Vietnam, Malaysia, India, Indonesia, Singapore, Philippines
-- Tables: [Country].[dbo].[Country], [Country].[dbo].[City]
-- =============================================

SELECT
    C.Country_ID,
    C.Country_Name,
    CT.City_ID,
    CT.City_Name
FROM [Country].[dbo].[Country] C
LEFT JOIN [Country].[dbo].[City] CT ON CT.Country_ID = C.Country_ID
WHERE C.Country_Name IN (
    N'Thailand',
    N'Vietnam',
    N'Malaysia',
    N'India',
    N'Indonesia',
    N'Singapore',
    N'Philippines'
)
  AND C.Is_Active = 1
  AND C.Is_Deleted = 0
ORDER BY C.Country_Name, CT.City_Name;
