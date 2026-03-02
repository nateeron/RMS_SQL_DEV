USE [Skill]
GO
/****** Object:  StoredProcedure [dbo].[sp_UPD_Skill_Temp]    Script Date: 2/6/2026 5:37:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- ProcedureName: [dbo].[sp_UPD_Skill_Temp]
-- Function: Update of National
-- Create date: 1/4/23
-- =============================================
-- exec [dbo].[sp_UPD_Skill_Temp] @Skill_Temp_ID =1059  ,@Skill_Temp_Name = 'AA2' , @Is_Active = 0 
ALTER PROCEDURE [dbo].[sp_UPD_Skill_Temp] 

	@Skill_Temp_ID int = 0, 
	@Skill_Temp_Name nvarchar(512) = NULL, 
	@Software_ID int = 0,
	@Company_ID int = 0,
	@Detail nvarchar(1024) = null,
	@Is_Active int = 0, 
	@User_ID int = 0, 
	@Status_Code nvarchar(100) = NULL OUTPUT
AS
BEGIN TRY
	DECLARE   @OtherGorup int = 0,
	@Numrows int = 0,
	 @Skill_By_Company int = 0;
	 -- Update Skill Chang Name  /
	 -- Update Skill IS_Active  X Check map [Skill_By_Company] = 0
		--SET @OtherGorup = (  SELECT TOP (1) Skill_Group_ID 
		--					FROM [Skill].[dbo].[Skill_Group] 
		--					where Skill_Group_Name = 'Other Skill' )


		--SET @Numrows = (SELECT COUNT([dbo].[Map_Skill_Temp].[Map_Skill_Temp_ID]) 
		--		FROM [dbo].[Map_Skill_Temp] 
		--		WHERE [dbo].[Map_Skill_Temp].[Skill_Temp_ID] =  @Skill_Temp_ID
		--		AND [dbo].[Map_Skill_Temp].[Is_Delete] = 0
		--		--AND Skill_Group_ID = @OtherGorup
		--		);

	SET @Numrows =(	
						 SELECT COUNT(*) FROM [dbo].[Map_Skill_Temp] ST
						 where Skill_Temp_ID = @Skill_Temp_ID
						 AND ST.Is_Delete = 0 
						)

		SET @Skill_By_Company =(	
								SELECT COUNT(*) FROM [dbo].[Map_Skill_Temp] ST
								left join  [Skill].[dbo].[Skill_By_Company] BC ON BC.Map_Skill_ID = ST.Map_Skill_Temp_ID 
								where Skill_Temp_ID = @Skill_Temp_ID
								AND BC.Is_Active = 1 
								)
	IF (@Numrows <> 0)
		BEGIN
			IF (@Skill_By_Company = 0  )
					BEGIN
						UPDATE [dbo].[Skill_Temp] 
						SET  [dbo].[Skill_Temp].[Skill_Name] = @Skill_Temp_Name
							,[dbo].[Skill_Temp].[Detail] = @Detail
							,[dbo].[Skill_Temp].[Is_Active] =  @Is_Active
							,[dbo].[Skill_Temp].[Updated_By] = @User_ID
							,[dbo].[Skill_Temp].[Updated_Date] = GETDATE()
						WHERE [dbo].[Skill_Temp].[Skill_Temp_ID] = @Skill_Temp_ID
						AND [dbo].[Skill_Temp].[Company_ID] = @Company_ID
						AND [dbo].[Skill_Temp].[Software_ID] = @Software_ID
						AND [dbo].[Skill_Temp].[Is_Deleted] = 0; 
						SET @Status_Code = '200';
					END

		END
	ELSE
		BEGIN
			SET @Status_Code = '402';
		END
END TRY
BEGIN CATCH  
	INSERT INTO [LOG].[dbo].[Log]
				([Software_ID]
				,[Function_Name]
				,[Detail]
				,[Created By]
				,[Created Date])
			VALUES
				('1'
				,'DB Skill - sp_Upt_Map_Sk'
				,ERROR_MESSAGE()
				,999
				,GETDATE());
	SET @Status_Code = '999';  
END CATCH


