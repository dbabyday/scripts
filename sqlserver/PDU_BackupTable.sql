IF @@SERVERNAME <> '{Enter Production Server Name Here}'
BEGIN
        PRINT 'Wrong Server';
        RETURN;
END;

--{PDU123456}
USE [{Your Database Name}];
SET XACT_ABORT ON;
BEGIN TRANSACTION;

BEGIN TRY
        --Begin Data backup process
        SELECT *
        INTO   PDU.dbo.[{PDU123456_yyyymmdd_tablename}]
        FROM   [{Your Database Name}].[{Your Schema}].[{Your Table}]
        WHERE  col1 IN (1,2);
        --End Data backup process
END TRY
BEGIN CATCH
        SELECT N'Msg ' + CONVERT(NVARCHAR(10),ERROR_NUMBER()) +
               N', Level ' + CONVERT(NVARCHAR(10),ERROR_SEVERITY()) +
               N', State ' + CONVERT(NVARCHAR(10),ERROR_STATE()) +
               N', Line ' + CONVERT(NVARCHAR(10),ERROR_LINE()) + NCHAR(0x000D) + NCHAR(0x000A) +
               ERROR_MESSAGE() + NCHAR(0x000D) + NCHAR(0x000A) +
               N'Executed: ROLLBACK TRANSACTION;' + NCHAR(0x000D) + NCHAR(0x000A) +
               N'Executed: RETURN;';
        ROLLBACK TRANSACTION;
        RETURN;
END CATCH;


--Begin Replace with PDU DELETE SQL code
DELETE FROM dbo.SomeTable
WHERE  col1 IN (1,2);
--End Replace with PDU UPDATE SQL code

IF @@ROWCOUNT <> {Enter Row Count Here}
BEGIN
        PRINT 'Row count mismatch. Transaction Rollback.';
        ROLLBACK TRANSACTION;
END

-- ROLLBACK TRANSACTION;
-- COMMIT TRANSACTION;
-- SELECT @@TRANCOUNT AS [TransactionCount];