SELECT [R].[Role_ID],
				[R].[Role_Name],
				[R].[Role_Type_ID],
				[MRU].[User_Login_ID],
				[RT].[Role_Type_Name] 
		FROM [DBO].[Map_Role_User] MRU 
		LEFT JOIN [DBO].[Role] R ON [R].[Role_ID] = [MRU].[Role_ID]
		LEFT JOIN [DBO].[Role_Type] RT ON [RT].[Role_Type_ID] = [R].[Role_Type_ID]
		WHERE [MRU].[Is_Active] = 1; 