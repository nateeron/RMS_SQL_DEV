-- Group by Key_Table_ID, get top 1 by latest Created Date per Key_Table_ID
SELECT Log_Audit_ID, Log_Audit_Type_ID, DB_Name, Table_Name, Key_Table_ID, Column_Name,
       Old_Value, New_Value, [Created By], [Created Date], Old_Show_Data, New_Data_Name
FROM (
    SELECT B.*,
           Old_Show_Data = SD.Show_Data_Name,
           New_Data_Name = SD2.Show_Data_Name,
           ROW_NUMBER() OVER (PARTITION BY B.Key_Table_ID ORDER BY B.[Created Date] DESC) AS rn
    FROM [Log_Audit].[dbo].[Log_Audit] B
    LEFT JOIN [Candidate].[dbo].[Show_Data] SD ON SD.Show_Data_ID = CONVERT(INT, CONVERT(NVARCHAR(MAX), B.Old_Value))
    LEFT JOIN [Candidate].[dbo].[Show_Data] SD2 ON SD2.Show_Data_ID = CONVERT(INT, CONVERT(NVARCHAR(MAX), B.New_Value))
    WHERE B.DB_Name = 'Candidate'
      AND B.Table_Name = 'Candidate'
      AND B.Column_Name = 'Show_Data_ID'
) T
WHERE rn = 1
ORDER BY Key_Table_ID, [Created Date] DESC;
