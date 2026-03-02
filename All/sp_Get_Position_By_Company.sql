USE [Pipeline]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  StoredProcedure [dbo].[sp_Get_Position_By_Company]    Script Date: 12/17/2025 ******/
-- Procedure name: [dbo].[sp_Get_Position_By_Company]
-- Description   : Return Position_By_Com_Type_ID and Position_Name for a company
-- Example       : EXEC [dbo].[sp_Get_Position_By_Company] @Company_ID = 3357;
CREATE OR ALTER PROCEDURE [dbo].[sp_Get_Position_By_Company]
    @Company_ID INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT
            Position_ID = PB.Position_ID,
            Position_Name = CASE
                                WHEN PB.Position_By_Com_Type_ID = 1 THEN PT.Position_Name
                                ELSE P.Position_Name
                            END
        FROM [RMS_Position].[dbo].[Position_By_Comp] PB
            LEFT JOIN [RMS_Position].[dbo].[Position_Temp] PT
                ON PB.Position_By_Com_Type_ID = 1
                AND PT.Position_Temp_ID = PB.Position_ID
            LEFT JOIN [RMS_Position].[dbo].[Position] P
                ON PB.Position_By_Com_Type_ID = 2
                AND P.Position_ID = PB.Position_ID
        WHERE PB.Company_ID = @Company_ID
            AND PB.Is_Delete = 0
        ORDER BY Position_Name;
    END TRY
    BEGIN CATCH
        INSERT INTO [LOG].[dbo].[Log] (
            [Software_ID],
            [Function_Name],
            [Detail],
            [Created By],
            [Created Date]
        )
        VALUES (
            '1',
            'DB Company - sp_Get_Position_By_Company',
            ERROR_MESSAGE(),
            999,
            GETDATE()
        );
    END CATCH
END
GO

