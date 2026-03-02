DECLARE @Full_Name NVARCHAR(512) = NULL,
  @Current_Position NVARCHAR(512) = NULL,
  @Current_Position_By_Com_ID NVARCHAR(512) = NULL,
  @Looking_Position NVARCHAR(512) = NULL,
  @Looking_Position_By_Com_ID NVARCHAR(512) = NULL,
  @Gender_ID INT = 0,
  @Min_Expected_Salary NVARCHAR(512) = NULL,
  @Max_Expected_Salary NVARCHAR(512) = NULL,
  @Skill_By_Company_ID NVARCHAR(512) = NULL, 
  @Map_Skill_ID NVARCHAR(512) = NULL,
  @Country_ID INT = 0,
  @City_ID INT = 0,
  @Company_ID INT = 3357, --3390
  @User_ID INT = 3862

-- Per Candidate_ID: if multiple Company_ID (e.g. >2) → non-Expired Top 1; if only Expired → Company_ID Top 1.
;WITH MC AS (
  SELECT [Company_ID] = [MC].[Company_ID]
    ,[Person_ID] = [CAN].[Person_ID]
    ,[Candidate_ID] = [CAN].[Candidate_ID]
    ,[Owner_ID] = 0
    ,[Show_Data_ID] = [MC].[Show_Data_ID]
    ,[Show_Data_Name] = [SD].[Show_Data_Name]
    ,[Is_Expired] = CASE WHEN [SD].[Show_Data_Name] = N'Expired' THEN 1 ELSE 0 END
    ,[Rn] = ROW_NUMBER() OVER (PARTITION BY [CAN].[Candidate_ID]
                              ORDER BY CASE WHEN [SD].[Show_Data_Name] = N'Expired' THEN 1 ELSE 0 END, [MC].[Company_ID], [MC].[Show_Data_ID])
  FROM [Candidate].[dbo].[Candidate] CAN
  LEFT JOIN [Candidate].[dbo].[Map_Candidadte_Company] MC ON [MC].[Candidate_ID] = [CAN].[Candidate_ID]
  LEFT JOIN [Candidate].[dbo].[Show_Data] SD ON [SD].[Show_Data_ID] = [MC].[Show_Data_ID]
  WHERE [CAN].[Candidate_ID] IN (5008, 4977)
)
SELECT [Company_ID], [Person_ID], [Candidate_ID], [Owner_ID], [Show_Data_ID], [Show_Data_Name]
FROM MC
WHERE [Rn] = 1
ORDER BY [Candidate_ID], [Company_ID], [Show_Data_Name]
