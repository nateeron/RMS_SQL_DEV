/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP (1000) [Skill_By_Com_ID]
      ,kc.[Map_Skill_ID]
      ,kc.[Company_ID]
      ,kc.[Map_Skill_Type_ID]
      ,kc.[Is_Active]
      ,kc.[Is_Deleted]
      ,kc.[Is_Deleted]
	  ,'mk' as mk
	  ,mk.Map_Skill_ID	
	  ,mk.Skill_Group_ID	
	  ,mk.Skill_ID	
	  ,mk.Is_Active 
	  ,mk.Is_Delete
	  ,'SK' AS SK
	  ,sk.Skill_ID	
	  ,sk.Skill_Name	
	  ,sk.Is_Active	
	  ,sk.Is_Deleted
  FROM [Skill].[dbo].[Skill_By_Company] kc
  left join [Skill].[dbo].[Map_Skill] mk ON mk.Map_Skill_ID = kc.Map_Skill_ID
  left join [Skill].[dbo].[Skill] sk ON mk.Skill_ID = sk.Skill_ID
  where Company_ID in ( SELECT [COM].[Company_ID] 
		FROM [Company].[dbo].[Company] COM
		WHERE [COM].[Company_ID] = 3357
		OR [COM].[Company_Parent_ID] = 3357)
   AND KC.Is_Deleted = 0
   AND mk.Is_Delete = 0
   AND sk.Is_Deleted = 0
   AND Skill_Name like 'Test9%'
   --select Skill_ID	,Skill_Name	,Is_Active	,Is_Deleted  from [Skill].[dbo].[Skill] 
   --select Map_Skill_ID	,Skill_Group_ID	,Skill_ID	,Is_Active ,Is_Delete from  [Skill].[dbo].[Map_Skill]



SELECT TOP (1000) [Skill_By_Com_ID]
      ,kc.[Map_Skill_ID]
      ,kc.[Company_ID]
      ,kc.[Map_Skill_Type_ID]
      ,kc.[Is_Active]
      ,kc.[Is_Deleted]
	  ,'MT' AS MT
	  ,mt.Map_Skill_Temp_ID	
	  ,mt.Skill_Group_ID	
	  ,mt.Skill_Temp_ID	
	  ,mt.Is_Active 
	  ,mt.Is_Delete
	  ,'SKT' AS SKT
		,skt.Skill_Temp_ID	
		,skt.Dup_Skill_ID	
		,skt.Software_ID	
		,skt.Company_ID	
		,skt.Skill_Name	
		,skt.Detail	
		,skt.Is_Active	
		,skt.Is_Deleted
	  FROM [Skill].[dbo].[Skill_By_Company] kc
	  LEFT JOIN [Skill].[dbo].Map_Skill_Temp mt ON mt.Map_Skill_Temp_ID = kc.Map_Skill_ID
	  LEFT JOIN  [Skill].[dbo].Skill_Temp skt ON skt.Skill_Temp_ID = mt.Skill_Temp_ID
	   where 
	   kc.Company_ID in ( SELECT [COM].[Company_ID] 
		FROM [Company].[dbo].[Company] COM
		WHERE 
		[COM].[Company_ID] = 3357
		OR [COM].[Company_Parent_ID] = 3357) AND
		 KC.Is_Deleted = 0
		--AND mt.Is_Delete = 0
		AND skt.Is_Deleted = 0
	AND [Map_Skill_Type_ID] =  ( select Map_Skill_Type_ID  FROM Map_Skill_Type where Map_Skill_Type_Name = 'Company' ) 
	--  select Map_Skill_Temp_ID	,Skill_Group_ID	,Skill_Temp_ID	,Is_Active ,Is_Delete From [Skill].[dbo].Map_Skill_Temp	 System
	
  select Skill_Temp_ID	,Dup_Skill_ID	,Software_ID	,Company_ID	,Skill_Name	,Detail	,Is_Active	,Is_Deleted  
  FROM [Skill].[dbo].Skill_Temp 
  where  Skill_Name like 'F%'

 select * from  [Skill].[dbo].Map_Skill_Temp
 where Skill_Temp_ID in (1035,1050,1051)
  select * from  [Skill].[dbo].[Skill_By_Company]
 where Map_Skill_ID  in (1082,1083)

	select Skill_ID	,Skill_Name	,Is_Active	,Is_Deleted  from [Skill].[dbo].[Skill] 
	 where  Skill_Name like  'A%'
  


       SELECT [COM].[Company_ID] 
		FROM [Company].[dbo].[Company] COM
		WHERE [COM].[Company_ID] = 3357
		OR [COM].[Company_Parent_ID] = 3357



		SELECT 
		 mt.Map_Skill_Temp_ID	
		,skt.Skill_Name	
		,skt.Company_ID	
		,mt.Skill_Group_ID	
		,skt.Skill_Temp_ID	as skt_Skill_Temp_ID
		,mt.Skill_Temp_ID	as mt_Skill_Temp_ID
		,mt.Is_Active 
		,mt.Is_Delete
		,'SKT' AS SKT
		,skt.Dup_Skill_ID	
		,skt.Software_ID	
		,skt.Detail	
		,skt.Is_Active	
		,skt.Is_Deleted
	  FROM  [Skill].[dbo].Map_Skill_Temp mt 
	  LEFT JOIN  [Skill].[dbo].Skill_Temp skt ON skt.Skill_Temp_ID = mt.Skill_Temp_ID
	  where Skill_Name = 'F1'


