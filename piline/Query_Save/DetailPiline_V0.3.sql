/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP (1000) [Map_Can_Pile_Com_ID]
      ,[Candidate_ID]
      ,[Pipeline_ID]
      ,[Company_ID]
      ,[Project_Position_ID]
      ,[Is_Active]
      ,[Is_Delete]
      ,[Created_By]
      ,[Updated_By]
      ,[Created_Date]
      ,[Updated_Date]
  FROM [Pipeline].[dbo].[Map_Can_Pile_Com]
  where Candidate_ID = 113
  --4964
  --Map_Can_Pile_Com_ID in (3758,3755)
  order by Project_Position_ID,Created_Date desc


SELECT 
    COUNT(*) AS num,
    Candidate_ID,[Pipeline_ID]
    Project_Position_ID
FROM [Pipeline].[dbo].[Map_Can_Pile_Com]
GROUP BY 
    Candidate_ID,[Pipeline_ID],
    Project_Position_ID
HAVING 
    COUNT(*) > 1;

SELECT 
    COUNT(*) AS num,
    Candidate_ID,
    Project_Position_ID
FROM [Pipeline].[dbo].[Map_Can_Pile_Com]
where Company_ID = 3357
GROUP BY 
    Candidate_ID,
    Project_Position_ID
HAVING 
    COUNT(*) = 1;