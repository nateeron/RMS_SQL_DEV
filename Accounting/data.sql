SELECT TOP (1000) [Invoice_Code_ID]
      ,[Invoice_Code]
      ,[Invoice_Type_ID]
      ,[Company_ID]
      ,[Is_Active]
      ,[Is_Delete]
      ,[Created_By]
      ,[Created_Date]
      ,[Updated_By]
      ,[Updated_Date]
  FROM [Accounting].[dbo].[Invoice_Setting_Code]

  Invoice_Code_ID	Invoice_Code	Invoice_Type_ID	Company_ID	Is_Active	Is_Delete	Created_By	Created_Date	Updated_By	Updated_Date
1	PV	1	3357	1	0	1	2026-02-13 09:48:49.510	1	2026-02-13 09:48:49.510

SELECT TOP (1000) [Invoice_Type_ID]
      ,[Invoice_Type_Name]
      ,[Company_ID]
      ,[Is_Active]
      ,[Created_By]
      ,[Created_Date]
      ,[Updated_By]
      ,[Updated_Date]
  FROM [Accounting].[dbo].[Invoice_Type]

  Invoice_Type_ID	Invoice_Type_Name	Company_ID	Is_Active	Created_By	Created_Date	Updated_By	Updated_Date
1	Commission Freelance	3357	1	1	2026-02-13 09:47:38.040	1	2026-02-13 09:47:38.040