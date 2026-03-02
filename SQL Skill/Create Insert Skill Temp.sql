

DECLARE @Skill_Name NVARCHAR(512) = 'F1sd',
	@Company_ID INT = 3357,
	@User_ID INT = 0,
	
	-- RESP --
	@Map_Skill_ID INT = 0 ,
	@Skill_Group_Name NVARCHAR(512) = NULL ,
	@Sub_Skill_Group_Name NVARCHAR(512) = NULL ,
	@Status_Code  NVARCHAR(100) = NULL ,
	@Skill_By_Comp_ID INT = 0 ;

DECLARE @Skill_ID INT = 0,
				@Skill_Temp_ID INT = 0,
				@Map_Skill_Type INT = 0,
				@Last_Skill_ID INT = 0,
				@Skill_Group_ID INT = 0,
				@Company_Parent_ID INT = 0;


				
IF (@Skill_Name IS NOT NULL OR @Skill_Name <> '')
	BEGIN

	-- Check มีหรือไม่ 
	SET @Skill_ID = ISNULL((SELECT TOP(1) [SK].[Skill_ID] 
				         FROM [Skill].[dbo].[Skill] SK 
						 WHERE [SK].[Is_Deleted] = 0
				         AND [SK].[Skill_Name] = @Skill_Name),0);

	SELECT TOP 1 
	    @Skill_Temp_ID = ST.Skill_Temp_ID
	FROM Skill.dbo.Skill_Temp ST
	WHERE ST.Skill_Name = @Skill_Name
	  AND ST.Is_Deleted = 0
	  AND ST.Company_ID IN (
								 SELECT Company_ID
								 FROM Company.dbo.Company
								 WHERE Company_ID = @Company_ID
								    OR Company_Parent_ID = @Company_ID
								    OR Company_ID = (
								         SELECT Company_Parent_ID
								         FROM Company.dbo.Company
								         WHERE Company_ID = @Company_ID
								    )
							);

		select @Skill_ID
		  select  @Skill_Temp_ID

		  -- ถ้ามี
		  IF (@Skill_ID <> 0 AND @Skill_Temp_ID <> 0)
		  BEGIN
				


								SELECT  * FROM [Skill].[dbo].[Skill_By_Company] 
								order by Map_Skill_ID
								
					--****************************************************************************
								SELECT 
									c.Company_ID ,
									c.Company_Parent_ID 
								FROM [Company].[dbo].[Company] c
								where  c.Is_Active = 1 and c.Is_Delete = 0
								and ( Company_Parent_ID = @Company_ID
								or Company_ID = @Company_ID)
								order by Company_Parent_ID
					--****************************************************************************
					
															 
				IF (@Skill_ID <> 0)
						BEGIN
								SET @Map_Skill_ID = (SELECT TOP(1) [MSK].[Map_Skill_ID]
													 FROM [Skill].[dbo].[Map_Skill] MSK
													 WHERE [MSK].[Skill_ID] = @Skill_ID
													 AND [MSK].[Is_Delete] = 0
													 AND [MSK].[Is_Active] = 1);
								
								SET @Skill_By_Comp_ID = (SELECT TOP(1) [SBC].[Skill_By_Com_ID]
														 FROM [Skill].[dbo].[Skill_By_Company] SBC
														 WHERE [SBC].[Map_Skill_ID] = @Map_Skill_ID
														 AND [SBC].[Map_Skill_Type_ID] = @Map_Skill_Type
														 AND ([SBC].[Company_ID] = @Company_Parent_ID 
															  OR [SBC].[Company_ID] IN (SELECT [C].[Company_ID]
																						FROM [Company].[dbo].[Company] C 
																						WHERE [C].[Company_Parent_ID] = @Company_Parent_ID)));
						END
					ELSE IF (@Skill_Temp_ID <> 0)
						BEGIN
								SET @Map_Skill_ID = (SELECT TOP(1) [MST].[Map_Skill_Temp_ID]
													 FROM [Skill].[dbo].[Map_Skill_Temp] MST
													 WHERE [MST].[Skill_Temp_ID] = @Skill_Temp_ID
													 AND [MST].[Is_Delete] = 0
													 AND [MST].[Is_Active] = 1);

								SET @Skill_By_Comp_ID = (SELECT TOP(1) [SBC].[Skill_By_Com_ID]
														 FROM [Skill].[dbo].[Skill_By_Company] SBC
														 WHERE [SBC].[Map_Skill_ID] = @Map_Skill_ID
														 AND [SBC].[Map_Skill_Type_ID] = @Map_Skill_Type
														 AND ([SBC].[Company_ID] = @Company_Parent_ID
															  OR [SBC].[Company_ID] IN (SELECT [C].[Company_ID]
																						FROM [Company].[dbo].[Company] C
																						WHERE [C].[Company_ID] = @Company_Parent_ID)));
						END

						IF @Skill_By_Comp_ID IS NULL
							BEGIN
									SET @Skill_By_Comp_ID = 0;
							END
		  END
		  --ถ้าไม่มี ให้ insert TO  Skill_Temp
		 ELSE
		 BEGIN

		  END

	END
ELSE

		BEGIN
			select @Status_Code = '404';
			select @Map_Skill_ID = 0;
			select @Skill_Group_Name = NULL;
			select @Sub_Skill_Group_Name = NULL;
			select @Skill_By_Comp_ID = 0;
		END