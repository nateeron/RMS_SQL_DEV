DECLARE @DateFrom DATETIME = '';
DECLARE @DateTo   DATETIME = '';
DECLARE @Project_Position_ID INT = 3111;
DECLARE @Company_ID INT = 3357;
		--  @Candidate_ID INT = 4964,
SET @DateFrom = NULLIF(@DateFrom, '');
SET @DateTo   = NULLIF(@DateTo, '');
SELECT
    m.Map_Can_Pile_Com_ID,
    m.Candidate_ID,
    m.Project_Position_ID,
	m.Pipeline_ID,
    m.Company_ID,
    m.Is_Active,
    m.Is_Delete,
    m.Created_Date AS Created_Date,
    'MAP' AS SourceType
FROM [Pipeline].[dbo].[Map_Can_Pile_Com] m
WHERE 
    m.Is_Active = 1
    AND m.Is_Delete = 0
    --AND m.Candidate_ID = @Candidate_ID
    --AND m.Project_Position_ID = @Project_Position_ID
    AND m.Company_ID = @Company_ID
	 AND (
            @DateFrom IS NULL 
            OR @DateTo IS NULL
            OR (
                m.Created_Date >= @DateFrom
                AND m.Created_Date < DATEADD(DAY, 1, @DateTo)
            )
        )
UNION ALL

SELECT
	h.Map_Can_Pile_Com_ID,
    h.Candidate_ID,
    h.Project_Position_ID,
	h.Pipeline_ID,
    h.Company_ID,
    h.Is_Active,
    h.Is_Delete,
    h.Created_Date_His AS Created_Date,
    'HISTORY' AS SourceType
FROM [Pipeline].[dbo].[His_Can_Pile_Com] h
WHERE 
    h.Is_Active = 1
    AND h.Is_Delete = 0
   -- AND h.Candidate_ID = @Candidate_ID
    --AND h.Project_Position_ID = @Project_Position_ID
    AND h.Company_ID = @Company_ID
	AND (
            @DateFrom IS NULL 
            OR @DateTo IS NULL
            OR (
                h.Created_Date_His >= @DateFrom
                AND h.Created_Date_His < DATEADD(DAY, 1, @DateTo)
            )
        );

use Company
GO
Begin
exec [dbo].[sp_Get_Report_ClientProjectPosition_Combined] 3357, '3,42,1063'


end


-- [dbo].[sp_Get_Report_ClientProjectPosition_Combined] 3357, '3,42,1063'
