


;with Company AS (
				SELECT
					[COM].[Company_ID] 
				FROM [Company].[dbo].[Company] COM
				WHERE  [COM].[Company_ID] = 3357 OR [COM].[Company_Parent_ID] = 3357 and
				 Is_Delete = 0 AND Is_Active = 1
		
		),Skill_Group AS (
		
			SELECT 
				[SSG].[Skill_Group_ID]
				,[SSG].[Parent_Skill_Group_ID]
				, [Skill_Group_Name] = CASE WHEN [SSG].[Parent_Skill_Group_ID] = 0 
											THEN 
												[SSG].[Skill_Group_Name]
											ELSE
												(SELECT TOP (1) [dbo].[Skill_Group].[Skill_Group_Name] 
												FROM [dbo].[Skill_Group] 
												WHERE [dbo].[Skill_Group].[Skill_Group_ID] = [SSG].[Parent_Skill_Group_ID])
											END
				,[Sub_Skill_Group_Name] = CASE WHEN [SSG].[Parent_Skill_Group_ID] <> 0 
														THEN 
															[SSG].[Skill_Group_Name]
														ELSE
															''
													END
					,Is_Active 
					,Is_Delete 
			FROM [dbo].[Skill_Group] SSG
			
		),All_Skill AS (
				SELECT  
				      mk.Map_Skill_ID
				    , 1 AS Map_Type
				    , mk.Skill_Group_ID
				    , mk.Skill_ID               AS Skill_Ref_ID
				    , mk.Is_Active              AS Map_Is_Active
				    , mk.Is_Delete              AS Map_Is_Delete
				    , sk.Skill_ID               AS Skill_ID
				    , NULL                      AS Dup_Skill_ID
				    , NULL                      AS Software_ID
				    , NULL                      AS Company_ID
				    , sk.Skill_Name
				    , NULL                      AS Detail
				    , sk.Is_Active              AS Skill_Is_Active
				    , sk.Is_Deleted             AS Skill_Is_Deleted
					,sg.Parent_Skill_Group_ID
					,sg.Skill_Group_Name
					,sg.Is_Active 
					,sg.Is_Delete 

				FROM [Skill].[dbo].[Map_Skill] mk
				LEFT JOIN [Skill].[dbo].[Skill] sk 
				       ON mk.Skill_ID = sk.Skill_ID
				LEFT JOIN Skill_Group sg ON sg.Skill_Group_ID = mk.Skill_Group_ID
					where  mk.Is_Delete = 0
				
				UNION ALL
				
				SELECT  
				      mt.Map_Skill_Temp_ID
				    , 2 AS Map_Type
				    , mt.Skill_Group_ID
				    , mt.Skill_Temp_ID          AS Skill_Ref_ID
				    , mt.Is_Active
				    , mt.Is_Delete
				    , skt.Skill_Temp_ID
				    , skt.Dup_Skill_ID
				    , skt.Software_ID
				    , skt.Company_ID
				    , skt.Skill_Name
				    , skt.Detail
				    , skt.Is_Active    AS Skill_Is_Active 
				    , skt.Is_Deleted   AS Skill_Is_Deleted 
						,sg.Parent_Skill_Group_ID
					,sg.Skill_Group_Name
					,sg.Is_Active 
					,sg.Is_Delete 

				FROM [Skill].[dbo].[Map_Skill_Temp] mt
				LEFT JOIN [Skill].[dbo].[Skill_Temp] skt 
				       ON skt.Skill_Temp_ID = mt.Skill_Temp_ID
				LEFT JOIN Skill_Group sg ON sg.Skill_Group_ID = mt.Skill_Group_ID
				where mt.Is_Delete = 0 and skt.Company_ID in (select Company_ID from Company)

		) , BYCOM AS (
				SELECT  
					[Skill_By_Com_ID]
					,kc.[Map_Skill_ID]
					,kc.[Company_ID]
					,kc.[Map_Skill_Type_ID]
					,kc.[Is_Active]
					,kc.[Is_Deleted]
				FROM [Skill].[dbo].[Skill_By_Company] kc
				where  kc.[Company_ID] in (SELECT Company_ID FROM Company )
						AND kc.Is_Deleted = 0 
					--	AND kc.Is_Active = 1
				
		) select * from All_Skill where Map_Type = 2 and Is_Active = 1 and Is_Delete = 0
