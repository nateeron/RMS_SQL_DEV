USE [Pipeline]
GO
/****** Object:  StoredProcedure [dbo].[sp_Get_Report_Recruitment_Process_ByRecruiters]    Script Date: 1/20/2026 1:25:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



  DECLARE  @Company_ID INT =2,
    @Project_Position_ID INT = 0,
    @DateFromStr VARCHAR(30) = NULL,
    @DateToStr   VARCHAR(30) = NULL,
    @Owner_ID_str  NVARCHAR(500) = NULL


    -------------------------------------------------------
    -- Date convert
    -------------------------------------------------------
    DECLARE @DateFrom DATETIME = TRY_CONVERT(DATETIME, NULLIF(@DateFromStr, ''));
    DECLARE @DateTo   DATETIME = TRY_CONVERT(DATETIME, NULLIF(@DateToStr, ''));

    -------------------------------------------------------
    -- Pipeline Type
    -------------------------------------------------------
    DECLARE @Pipeline_Type_ID INT = 0;
    SELECT TOP 1 @Pipeline_Type_ID = PT.Pipeline_Type_ID
    FROM dbo.Pipeline_Type PT
    WHERE PT.Pipeline_Type_Name = 'System';

    -------------------------------------------------------
    -- Pipelines list (แทน #PipelineTemp)
    -------------------------------------------------------
    DECLARE @Pipelines TABLE (
        Pipeline_ID INT,
        Pipeline_Name NVARCHAR(100),
        Priority INT
    );

    INSERT INTO @Pipelines (Pipeline_ID, Pipeline_Name, Priority)
    SELECT
        P.Pipeline_ID,
        P.Pipeline_Name,
        P.Number_Step
    FROM dbo.Pipeline P
    WHERE
    (
        P.Pipeline_Type_ID = @Pipeline_Type_ID
        OR (P.Pipeline_Type_ID <> @Pipeline_Type_ID AND P.Company_ID = @Company_ID)
    )
    AND P.Is_Active = 1
    AND P.Is_Delete = 0;

    -------------------------------------------------------
    -- Dynamic SQL variables
    -------------------------------------------------------
    DECLARE @SQL NVARCHAR(MAX) = N'';
    DECLARE @SelectColumns NVARCHAR(MAX) = N'';
    DECLARE @TotalAllExpression NVARCHAR(MAX) = N'';

    DECLARE @Pipeline_ID INT;
    DECLARE @Pipeline_Name NVARCHAR(100);
    DECLARE @EscapedPipelineName NVARCHAR(200);
    DECLARE @ColNum INT = 1;

    -------------------------------------------------------
    -- Build dynamic columns (cursor)
    -------------------------------------------------------
    DECLARE pipeline_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT Pipeline_ID, Pipeline_Name
    FROM @Pipelines
    ORDER BY Priority;

    OPEN pipeline_cursor;
    FETCH NEXT FROM pipeline_cursor INTO @Pipeline_ID, @Pipeline_Name;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @SelectColumns <> N'' SET @SelectColumns += N', ';

        SET @EscapedPipelineName = REPLACE(@Pipeline_Name, N'''', N''''''); -- escape '

        SET @SelectColumns +=
              CAST(@Pipeline_ID AS NVARCHAR(10)) + N' AS collumID' + CAST(@ColNum AS NVARCHAR(10))
            + N', ''' + @EscapedPipelineName + N''' AS collumName' + CAST(@ColNum AS NVARCHAR(10))
            + N', SUM(CASE WHEN Pipeline_ID = ' + CAST(@Pipeline_ID AS NVARCHAR(10)) +
              N' THEN 1 ELSE 0 END) AS collumCount' + CAST(@ColNum AS NVARCHAR(10));

        SET @ColNum += 1;
        FETCH NEXT FROM pipeline_cursor INTO @Pipeline_ID, @Pipeline_Name;
    END;

    CLOSE pipeline_cursor;
    DEALLOCATE pipeline_cursor;

    -------------------------------------------------------
    -- Total_All
    -------------------------------------------------------
    DECLARE @PipelineIdList NVARCHAR(MAX);

	SELECT @PipelineIdList =
	    STUFF((
	        SELECT N',' + CAST(p.Pipeline_ID AS NVARCHAR(10))
	        FROM @Pipelines p
	        ORDER BY p.Priority
	        FOR XML PATH(''), TYPE
	    ).value('.', 'NVARCHAR(MAX)'), 1, 1, N'');
	
	-- กันกรณีไม่มี pipeline
	IF @PipelineIdList IS NULL OR @PipelineIdList = N''
	    SET @PipelineIdList = N'-1';
	
	SET @TotalAllExpression =
	    N'SUM(CASE WHEN Pipeline_ID IN (' + @PipelineIdList + N') THEN 1 ELSE 0 END) AS Total_All';

    -------------------------------------------------------
    -- Final Dynamic SQL (Owner join "เหมือนเดิม" ผ่าน Candidate C)
    -------------------------------------------------------
   
    ;WITH AllData AS (
        -- MAP
        SELECT
            m.Map_Can_Pile_Com_ID,
            m.Candidate_ID,
            m.Project_Position_ID,
            m.Pipeline_ID,
            m.Company_ID,
            m.Updated_Date AS Created_Date,
            'MAP' AS SourceType
        FROM Pipeline.dbo.Map_Can_Pile_Com m
        WHERE m.Is_Active = 1
          AND m.Is_Delete = 0
          AND m.Company_ID = @Company_ID
          AND (
                ( @DateFrom IS NULL AND @DateTo IS NULL )
             OR ( @DateFrom IS NOT NULL AND @DateTo IS NULL AND m.Updated_Date >= @DateFrom )
             OR ( @DateFrom IS NULL AND @DateTo IS NOT NULL AND m.Updated_Date < DATEADD(DAY,1,@DateTo) )
             OR ( @DateFrom IS NOT NULL AND @DateTo IS NOT NULL
                  AND m.Updated_Date >= @DateFrom
                  AND m.Updated_Date < DATEADD(DAY,1,@DateTo) )
          )

        UNION ALL

        -- HISTORY
        SELECT
            h.Map_Can_Pile_Com_ID,
            h.Candidate_ID,
            h.Project_Position_ID,
            h.Pipeline_ID,
            h.Company_ID,
            h.Updated_Date AS Created_Date,
            'HISTORY' AS SourceType
      FROM Pipeline.dbo.His_Can_Pile_Com h
        WHERE h.Is_Active = 1
          AND h.Is_Delete = 0
          AND h.Company_ID = @Company_ID
          AND (
                ( @DateFrom IS NULL AND @DateTo IS NULL )
             OR ( @DateFrom IS NOT NULL AND @DateTo IS NULL AND h.Updated_Date >= @DateFrom )
             OR ( @DateFrom IS NULL AND @DateTo IS NOT NULL AND h.Updated_Date < DATEADD(DAY,1,@DateTo) )
             OR ( @DateFrom IS NOT NULL AND @DateTo IS NOT NULL
                  AND h.Updated_Date >= @DateFrom
                  AND h.Updated_Date < DATEADD(DAY,1,@DateTo) )
          )
    ),
    Ranked AS (
        SELECT
            *,
            ROW_NUMBER() OVER (
                PARTITION BY Candidate_ID, Project_Position_ID
                ORDER BY Created_Date DESC
            ) AS rn
        FROM AllData
    ),
    LatestPipelineData AS (
        SELECT
            Map_Can_Pile_Com_ID,
            Candidate_ID,
            Project_Position_ID,
            Pipeline_ID,
            Company_ID,
            Created_Date,
            SourceType
        FROM Ranked
        WHERE (Project_Position_ID = @Project_Position_ID OR @Project_Position_ID = 0)
    ),
    OwnerData AS (
        SELECT
            MC.Map_Can_Pile_Com_ID,
            MC.Candidate_ID,
			C.Candidate_ID as C_Candidate_ID,
            MC.Pipeline_ID,
            PL.Pipeline_Name,
            MC.Project_Position_ID,

            LUC.Owner_ID,

			C.Person_ID ,
			 Own.Full_Name,
          --  -- ✅ ใช้ CONCAT แบบเดิม: ถ้าไม่มี owner จะได้ '' '' (space)
           -- CONCAT(
           --     LTRIM(RTRIM(T_Own.Title_Name)), '' '', Own.Full_Name
           -- ) AS Owner_Name
			Own.Full_Name as Owner_Name
        FROM LatestPipelineData MC

        -- ✅ สำคัญ: ต้องผ่าน Candidate ที่ Is_Deleted = 0 ก่อน (เหมือนเดิม)
        LEFT JOIN Candidate.dbo.Candidate C
               ON C.Candidate_ID = MC.Candidate_ID
              AND C.Is_Deleted = 0

        -- ✅ สำคัญ: join LUC ผ่าน C.Candidate_ID (ไม่ใช่ MC.Candidate_ID)
        LEFT JOIN (
            SELECT
                tt.Update_By AS Owner_ID,
                tt.Candidate_ID
            FROM Candidate.dbo.Log_Update_Candidate tt
            INNER JOIN (
                SELECT
                    ss.Candidate_ID,
                    MAX(ss.Update_Date) AS MaxDateTime
               FROM Candidate.dbo.Log_Update_Candidate ss
                WHERE ss.Is_Employee = 0
                  AND ss.Is_Terminate = 0
                GROUP BY ss.Candidate_ID
            ) groupedtt
                ON tt.Candidate_ID = groupedtt.Candidate_ID
               AND tt.Update_Date = groupedtt.MaxDateTime
               AND tt.Is_Employee = 0
               AND tt.Is_Terminate = 0
        ) LUC ON LUC.Candidate_ID = C.Candidate_ID

        LEFT JOIN Person.dbo.Person Own
               ON Own.Person_ID = LUC.Owner_ID
        LEFT JOIN Title.dbo.Title T_Own
               ON T_Own.Title_ID = Own.Title_ID
        LEFT JOIN Pipeline.dbo.Pipeline PL
               ON PL.Pipeline_ID = MC.Pipeline_ID

        WHERE
            @Owner_ID_str IS NULL
            OR @Owner_ID_str = ''
            OR LTRIM(RTRIM(@Owner_ID_str)) = ''
            OR LUC.Owner_ID IN (
                SELECT CAST(LTRIM(RTRIM(value)) AS INT)
                FROM STRING_SPLIT(@Owner_ID_str, ',')
                WHERE LTRIM(RTRIM(value)) <> ''
                  AND ISNUMERIC(LTRIM(RTRIM(value))) = 1
            )
    )

    SELECT
	*
     --   Owner_Name,Owner_ID, ' + @SelectColumns + N', ' + @TotalAllExpression + N'
    FROM OwnerData --OwnerData LatestPipelineData
   -- WHERE Owner_Name IS NOT NULL
  --  GROUP BY Owner_Name,Owner_ID
   -- ORDER BY Owner_Name;
   

--    SELECT
--            *
--            FROM Candidate.dbo.Log_Update_Candidate tt
--            INNER JOIN (
--                SELECT
--                    ss.Candidate_ID,
--                    MAX(ss.Update_Date) AS MaxDateTime
--                FROM Candidate.dbo.Log_Update_Candidate ss
--                WHERE ss.Is_Employee = 0
--                  AND ss.Is_Terminate = 0
--                GROUP BY ss.Candidate_ID
--            ) groupedtt
--                ON tt.Candidate_ID = groupedtt.Candidate_ID
--               AND tt.Update_Date = groupedtt.MaxDateTime
--               AND tt.Is_Employee = 0
--               AND tt.Is_Terminate = 0
--			 where tt.Candidate_ID= 712
--			 order by tt.Candidate_ID
			 
----			 297,289,288


--			    SELECT 
--				*
--            FROM Candidate.dbo.Candidate tt
--            INNER JOIN (
--			       SELECT
--				  ss.Candidate_ID ,
--                  MAX(ss.Updated_Date) AS MaxDateTime
--                FROM Candidate.dbo.Candidate ss
--                WHERE ss.Is_Employee = 0
--				 GROUP BY ss.Candidate_ID
--			) groupedtt
--                ON tt.Candidate_ID = groupedtt.Candidate_ID
--               AND tt.Updated_Date = groupedtt.MaxDateTime
--               AND tt.Is_Employee = 0
--			   where   tt.Candidate_ID in ( 297,289,288,712)
--			   order by tt.Candidate_ID
--			   --*******************************************
--      SELECT
--	  tt.Person_ID,
--                tt.Updated_By AS Owner_ID,
--                tt.Candidate_ID
--             FROM Candidate.dbo.Candidate tt
--            INNER JOIN (
--			       SELECT
--				  ss.Candidate_ID ,
--                  MAX(ss.Updated_Date) AS MaxDateTime
--                FROM Candidate.dbo.Candidate ss
--                WHERE ss.Is_Employee = 0
--				 GROUP BY ss.Candidate_ID
--				) groupedtt
--                ON tt.Candidate_ID = groupedtt.Candidate_ID
--               AND tt.Updated_Date = groupedtt.MaxDateTime
--               AND tt.Is_Employee = 0
--			    where   tt.Candidate_ID in( 712)

--				  SELECT * from  Person.dbo.Person Own
--				  where Person_ID in (786,787,786, 781)
--SELECT * from  Person.dbo.Person


--select Candidate_ID,	c.Person_ID	,Company_ID, Created_By	Updated_By
--,p.Full_Name ,p.First_Name
-- from  Candidate.dbo.Candidate c
-- left join Person.dbo.Person p on c.Person_ID =  p.Person_ID  or c.Person_ID =  p.[Updated By]
-- where c.Company_ID = 2
-- and Candidate_ID in (786,787, 781,288,297,289)


-- select Candidate_ID,	Update_By	
--,p.Full_Name ,p.First_Name
-- from   Candidate.dbo.Log_Update_Candidate c
-- left join Person.dbo.Person p on c.Update_By =  p.Person_ID  or c.Update_By =  p.[Updated By]
-- where  Candidate_ID in (786,787, 781,288,297,289)


-- select * FROM Candidate.dbo.Log_Update_Candidate
-- where Candidate_ID in (786,787, 781)

--  select * from   Candidate.dbo.Log_Update_Candidate c

--				;with tb_candidate as (
--               SELECT
--                    ss.Candidate_ID,
--                    MAX(ss.Update_Date) AS MaxDateTime
--					,ss.Update_By
--                FROM Candidate.dbo.Log_Update_Candidate ss
--                WHERE ss.Is_Employee = 0
--                  AND ss.Is_Terminate = 0
--                GROUP BY ss.Candidate_ID,ss.Update_By
--				)
--				select * 
--				FROM Candidate.dbo.Log_Update_Candidate ss
--				INNER JOIN  tb_candidate c on c.Candidate_ID = ss.Candidate_ID AND ss.Update_Date = c.MaxDateTime
--				where ss.Candidate_ID = 
             