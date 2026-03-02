USE [Skill]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- ProcedureName: [dbo].[sp_Ins_Import_Skill_byCompany]
-- Function: Import Skill by Company
-- Create date: 26-01-2026
-- Updated: Logic per requirements
-- การทำงานที่ต้องการ

--[1] ถ้าเคยมี แต่ ที่ Skill = Not Active ให้ปล่อยใว้ ไม่ให้ใช้ = Return 402
	-- Check Skill in Company ,System
--[2] ถ้าเคยมี แต่ Map ไม่ได้เปิดใช้  Return 200 id
	-- Check Skill in Company ,System  อยู่ที่ไหน ส่งที่นั้นไป
	-- ถ้ามี set	[Skill_By_Company] [Is_Active] = 1
	-- ถ้าไม่มี INSERT MAP	[Skill_By_Company] [Is_Active] = 1

--[3] ถ้าไม่เคยมี   INSERT Skill in Company Return 200 id 
	-- insert ไปที่	-- insert to [Skill_Temp]
	-- insert to [Map_Skill_Temp]
	-- insert to [Skill_By_Company]


-- [1] ถ้าเคยมี แต่ Skill = Not Active → Return 402 (ไม่ให้ใช้)
-- [2] ถ้าเคยมี แต่ Map ไม่ได้เปิดใช้ → Return 200 + id (UPDATE/INSERT Skill_By_Company Is_Active=1)
-- [3] ถ้าไม่เคยมี → INSERT Skill_Temp, Map_Skill_Temp, Skill_By_Company → Return 200 + id
--
-- exec [dbo].[sp_Ins_Import_Skill_byCompany] @Skill_Name = N'SQL', @Company_ID = 3357, @Software_ID = 1, @User_ID = 999
-- =============================================
ALTER PROCEDURE [dbo].[sp_Ins_Import_Skill_byCompany] 
	@Skill_Name NVARCHAR(512) = NULL,
	@Company_ID INT = 0,
	@Software_ID INT = 0,
	@User_ID INT = 0,

	@Map_Skill_ID INT = 0 OUTPUT,
	@Skill_Group_Name NVARCHAR(512) = NULL OUTPUT,
	@Sub_Skill_Group_Name NVARCHAR(512) = NULL OUTPUT,

	@Status_Code NVARCHAR(100) = NULL OUTPUT,
	@Skill_By_Comp_ID INT = 0 OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

BEGIN TRY
	-- Validate input
	IF (@Skill_Name IS NULL OR LTRIM(RTRIM(@Skill_Name)) = '')
		BEGIN
			SET @Status_Code = '404';
			SET @Map_Skill_ID = 0;
			SET @Skill_Group_Name = NULL;
			SET @Sub_Skill_Group_Name = NULL;
			SET @Skill_By_Comp_ID = 0;
			RETURN;
		END

	DECLARE @Skill_ID INT = 0,
			@Skill_Temp_ID INT = 0,
			@Map_Skill_Type INT = 0,
			@Company_Parent_ID INT = 0,
			@Map_Skill_Type_System INT = 0,
			@Map_Skill_Type_Company INT = 0,
			@Skill_Group_ID_INS INT = 0,
			@Skill_ID_INS INT = 0,
			@Map_Skill_ID_INS INT = 0,
			@Skill_Is_Active INT = 0,
			@Skill_Temp_Is_Active INT = 0,
			@SBC_Is_Active INT = 0,
			@Group_ID INT = 0,
			@Parent_Group_ID INT = 0,
			@Sub_Skill_Group_ID INT = 0;

	-- Map_Skill_Type lookups
	SELECT @Map_Skill_Type_System = [Map_Skill_Type_ID]
	FROM [Skill].[dbo].[Map_Skill_Type]
	WHERE [Is_Active] = 1 AND [Map_Skill_Type_Name] = 'System';

	SELECT @Map_Skill_Type_Company = [Map_Skill_Type_ID]
	FROM [Skill].[dbo].[Map_Skill_Type]
	WHERE [Is_Active] = 1 AND [Map_Skill_Type_Name] = 'Company';

	-- Company Parent
	SELECT @Company_Parent_ID = ISNULL([Company_Parent_ID], 0)
	FROM [Company].[dbo].[Company]
	WHERE [Company_ID] = @Company_ID AND [Is_Active] = 1 AND [Is_Delete] = 0;

	-- Skill (System)
	SELECT @Skill_ID = ISNULL([Skill_ID], 0), @Skill_Is_Active = ISNULL([Is_Active], 0)
	FROM [Skill].[dbo].[Skill]
	WHERE [Is_Deleted] = 0 AND [Skill_Name] = @Skill_Name;

	-- Skill_Temp (Company) by hierarchy
	SELECT TOP (1) @Skill_Temp_ID = ISNULL(ST.[Skill_Temp_ID], 0), @Skill_Temp_Is_Active = ST.[Is_Active]
	FROM [Skill].[dbo].[Skill_Temp] ST
	WHERE ST.[Skill_Name] = @Skill_Name AND ST.[Is_Deleted] = 0
		AND  ST.[Company_ID] IN (SELECT [Company_ID] FROM [Company].[dbo].[Company] WHERE [Company_Parent_ID] = @Company_Parent_ID AND [Is_Active] = 1 AND [Is_Delete] = 0);

	-- ========== [1] เคยมี แต่ Skill = Not Active → Return 402 ==========
	IF (@Skill_ID <> 0 AND @Skill_Is_Active = 0)
		BEGIN
			SET @Status_Code = '402';
			SET @Map_Skill_ID = 0;
			SET @Skill_Group_Name = NULL;
			SET @Sub_Skill_Group_Name = NULL;
			SET @Skill_By_Comp_ID = 0;
			RETURN;
		END
	IF (@Skill_Temp_ID <> 0 AND @Skill_Temp_Is_Active = 0)
		BEGIN
			SET @Status_Code = '402';
			SET @Map_Skill_ID = 0;
			SET @Skill_Group_Name = NULL;
			SET @Sub_Skill_Group_Name = NULL;
			SET @Skill_By_Comp_ID = 0;
			RETURN;
		END

	-- Determine type and Map_Skill_ID for [2]
	IF (@Skill_ID <> 0)
		SET @Map_Skill_Type = @Map_Skill_Type_System;
	ELSE IF (@Skill_Temp_ID <> 0)
		SET @Map_Skill_Type = @Map_Skill_Type_Company;

	IF (@Skill_ID <> 0)
		SELECT @Map_Skill_ID = [Map_Skill_ID]
		FROM [Skill].[dbo].[Map_Skill]
		WHERE [Skill_ID] = @Skill_ID AND [Is_Delete] = 0 AND [Is_Active] = 1;
	ELSE IF (@Skill_Temp_ID <> 0)
		SELECT @Map_Skill_ID = [Map_Skill_Temp_ID]
		FROM [Skill].[dbo].[Map_Skill_Temp]
		WHERE [Skill_Temp_ID] = @Skill_Temp_ID AND [Is_Delete] = 0 AND [Is_Active] = 1;

	-- Look up existing Skill_By_Company (for [2])
	DECLARE @Search_Company_ID INT = CASE WHEN @Company_Parent_ID <> 0 THEN @Company_Parent_ID ELSE @Company_ID END;

	IF (@Map_Skill_ID <> 0)
		SELECT TOP (1) @Skill_By_Comp_ID = SBC.[Skill_By_Com_ID], @SBC_Is_Active = SBC.[Is_Active]
		FROM [Skill].[dbo].[Skill_By_Company] SBC
		WHERE SBC.[Map_Skill_ID] = @Map_Skill_ID
			AND SBC.[Map_Skill_Type_ID] = @Map_Skill_Type
			AND SBC.[Is_Deleted] = 0
			AND (SBC.[Company_ID] = @Search_Company_ID
				OR SBC.[Company_ID] IN (SELECT [Company_ID] FROM [Company].[dbo].[Company] WHERE [Company_Parent_ID] = @Search_Company_ID AND [Is_Active] = 1 AND [Is_Delete] = 0));

	SET @Skill_By_Comp_ID = ISNULL(@Skill_By_Comp_ID, 0);

	-- ========== [3] ไม่เคยมี → INSERT Skill_Temp, Map_Skill_Temp, Skill_By_Company ==========
	IF (@Skill_ID = 0 AND @Skill_Temp_ID = 0)
		BEGIN
			SELECT @Skill_Group_ID_INS = [Skill_Group_ID]
			FROM [Skill].[dbo].[Skill_Group]
			WHERE [Skill_Group_Name] = 'Other Skill' AND [Is_Active] = 1 AND [Is_Delete] = 0;

			INSERT INTO [Skill].[dbo].[Skill_Temp]
				([Software_ID], [Company_ID], [Skill_Name], [Detail], [Is_Active], [Is_Deleted], [Created_By], [Updated_By], [Created_Date], [Updated_Date])
			VALUES (@Software_ID, @Company_ID, @Skill_Name, '', 1, 0, @User_ID, @User_ID, GETDATE(), GETDATE());
			SET @Skill_ID_INS = SCOPE_IDENTITY();

			INSERT INTO [Skill].[dbo].[Map_Skill_Temp]
				([Skill_Group_ID], [Skill_Temp_ID], [Is_Active], [Created_By], [Updated_By], [Created_Date], [Updated_Date], [Is_Delete])
			VALUES (@Skill_Group_ID_INS, @Skill_ID_INS, 1, @User_ID, @User_ID, GETDATE(), GETDATE(), 0);
			SET @Map_Skill_ID_INS = SCOPE_IDENTITY();

			INSERT INTO [Skill].[dbo].[Skill_By_Company]
				([Map_Skill_ID], [Company_ID], [Map_Skill_Type_ID], [Is_Active], [Is_Deleted], [Created_By], [Updated_By], [Created_Date], [Updated_Date])
			VALUES (@Map_Skill_ID_INS, @Company_ID, @Map_Skill_Type_Company, 1, 0, @User_ID, @User_ID, GETDATE(), GETDATE());

			SET @Skill_By_Comp_ID = SCOPE_IDENTITY();
			SET @Map_Skill_ID = @Map_Skill_ID_INS;
			SET @Status_Code = '200';

			SELECT @Skill_Group_Name = [Skill_Group_Name]
			FROM [Skill].[dbo].[Skill_Group]
			WHERE [Skill_Group_ID] = @Skill_Group_ID_INS AND [Is_Active] = 1 AND [Is_Delete] = 0;
			SET @Sub_Skill_Group_Name = NULL;
			RETURN;
		END

	-- ========== [2] เคยมี แต่ Map ไม่ได้เปิดใช้ → 200 + id (UPDATE or INSERT Skill_By_Company) ==========
	IF (@Skill_By_Comp_ID <> 0)
		BEGIN
			-- มี record อยู่แล้ว: เปิดใช้ถ้ายังไม่เปิด
			IF (@SBC_Is_Active = 0)
				BEGIN
					UPDATE [Skill].[dbo].[Skill_By_Company]
					SET [Is_Active] = 1, [Updated_By] = @User_ID, [Updated_Date] = GETDATE()
					WHERE [Skill_By_Com_ID] = @Skill_By_Comp_ID;
				END
			SET @Status_Code = '200';
			-- Populate group names for output
			IF (@Map_Skill_Type = @Map_Skill_Type_System)
				BEGIN
					SELECT @Group_ID = [Skill_Group_ID] FROM [Skill].[dbo].[Map_Skill] WHERE [Map_Skill_ID] = @Map_Skill_ID AND [Is_Active] = 1 AND [Is_Delete] = 0;
					SELECT @Parent_Group_ID = [Parent_Skill_Group_ID] FROM [Skill].[dbo].[Skill_Group] WHERE [Skill_Group_ID] = @Group_ID AND [Is_Active] = 1 AND [Is_Delete] = 0;
				END
			ELSE
				BEGIN
					SELECT @Group_ID = [Skill_Group_ID] FROM [Skill].[dbo].[Map_Skill_Temp] WHERE [Map_Skill_Temp_ID] = @Map_Skill_ID AND [Is_Active] = 1 AND [Is_Delete] = 0;
					SELECT @Parent_Group_ID = [Parent_Skill_Group_ID] FROM [Skill].[dbo].[Skill_Group] WHERE [Skill_Group_ID] = @Group_ID AND [Is_Active] = 1 AND [Is_Delete] = 0;
				END
			IF (@Parent_Group_ID IS NULL OR @Parent_Group_ID = 0)
				BEGIN
					SELECT @Skill_Group_Name = [Skill_Group_Name] FROM [Skill].[dbo].[Skill_Group] WHERE [Skill_Group_ID] = @Group_ID AND [Is_Active] = 1 AND [Is_Delete] = 0;
					SET @Sub_Skill_Group_Name = NULL;
				END
			ELSE
				BEGIN
					SELECT @Skill_Group_Name = [Skill_Group_Name] FROM [Skill].[dbo].[Skill_Group] WHERE [Skill_Group_ID] = @Parent_Group_ID AND [Is_Active] = 1 AND [Is_Delete] = 0;
					SELECT @Sub_Skill_Group_Name = [Skill_Group_Name] FROM [Skill].[dbo].[Skill_Group] WHERE [Skill_Group_ID] = @Group_ID AND [Is_Active] = 1 AND [Is_Delete] = 0;
				END
			RETURN;
		END

	-- [2] ไม่มี record Skill_By_Company → INSERT
	INSERT INTO [Skill].[dbo].[Skill_By_Company]
		([Map_Skill_ID], [Company_ID], [Map_Skill_Type_ID], [Is_Active], [Is_Deleted], [Created_By], [Updated_By], [Created_Date], [Updated_Date])
	VALUES (@Map_Skill_ID, @Company_ID, @Map_Skill_Type, 1, 0, @User_ID, @User_ID, GETDATE(), GETDATE());

	SET @Skill_By_Comp_ID = SCOPE_IDENTITY();
	SET @Status_Code = '200';

	-- Group names
	IF (@Map_Skill_Type = @Map_Skill_Type_System)
		BEGIN
			SELECT @Group_ID = [Skill_Group_ID] FROM [Skill].[dbo].[Map_Skill] WHERE [Map_Skill_ID] = @Map_Skill_ID AND [Is_Active] = 1 AND [Is_Delete] = 0;
			SELECT @Parent_Group_ID = [Parent_Skill_Group_ID] FROM [Skill].[dbo].[Skill_Group] WHERE [Skill_Group_ID] = @Group_ID AND [Is_Active] = 1 AND [Is_Delete] = 0;
		END
	ELSE
		BEGIN
			SELECT @Group_ID = [Skill_Group_ID] FROM [Skill].[dbo].[Map_Skill_Temp] WHERE [Map_Skill_Temp_ID] = @Map_Skill_ID AND [Is_Active] = 1 AND [Is_Delete] = 0;
			SELECT @Parent_Group_ID = [Parent_Skill_Group_ID] FROM [Skill].[dbo].[Skill_Group] WHERE [Skill_Group_ID] = @Group_ID AND [Is_Active] = 1 AND [Is_Delete] = 0;
		END
	IF (@Parent_Group_ID IS NULL OR @Parent_Group_ID = 0)
		BEGIN
			SELECT @Skill_Group_Name = [Skill_Group_Name] FROM [Skill].[dbo].[Skill_Group] WHERE [Skill_Group_ID] = @Group_ID AND [Is_Active] = 1 AND [Is_Delete] = 0;
			SET @Sub_Skill_Group_Name = NULL;
		END
	ELSE
		BEGIN
			SELECT @Skill_Group_Name = [Skill_Group_Name] FROM [Skill].[dbo].[Skill_Group] WHERE [Skill_Group_ID] = @Parent_Group_ID AND [Is_Active] = 1 AND [Is_Delete] = 0;
			SELECT @Sub_Skill_Group_Name = [Skill_Group_Name] FROM [Skill].[dbo].[Skill_Group] WHERE [Skill_Group_ID] = @Group_ID AND [Is_Active] = 1 AND [Is_Delete] = 0;
		END

END TRY
BEGIN CATCH
	INSERT INTO [LOG].[dbo].[Log] ([Software_ID], [Function_Name], [Detail], [Created By], [Created Date])
	VALUES ('1', 'DB Map_Skill - sp_Ins_Import_Skill_byCompany', ERROR_MESSAGE(), 999, GETDATE());
	SET @Status_Code = '999';
	SET @Map_Skill_ID = 0;
	SET @Skill_Group_Name = NULL;
	SET @Sub_Skill_Group_Name = NULL;
	SET @Skill_By_Comp_ID = 0;
END CATCH

END
