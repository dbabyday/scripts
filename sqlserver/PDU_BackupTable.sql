IF LOWER(@@SERVERNAME) != N'' 
BEGIN
    RAISERROR('wrong server - setting NOEXEC ON',16,1);
    RETURN;
END

-- TicketNumber


-----------------------------------------------------------------------


BEGIN TRY
    SELECT *
    INTO   PDU.dbo.
    FROM   
    WHERE  ;
END TRY
BEGIN CATCH
    SELECT  N'Msg '     + CONVERT(NVARCHAR(10),ERROR_NUMBER())   +
            N', Level ' + CONVERT(NVARCHAR(10),ERROR_SEVERITY()) +
            N', State ' + CONVERT(NVARCHAR(10),ERROR_STATE())    +
            N', Line '  + CONVERT(NVARCHAR(10),ERROR_LINE())     + NCHAR(0x000D) + NCHAR(0x000A) +
            ERROR_MESSAGE()                                      + NCHAR(0x000D) + NCHAR(0x000A) +
            N'Executed: ROLLBACK TRANSACTION;'                   + NCHAR(0x000D) + NCHAR(0x000A) +
            N'Executed: RETURN;';
    ROLLBACK TRANSACTION;
    RETURN;
END CATCH


-----------------------------------------------------------------------


-- ROLLBACK TRANSACTION;
-- COMMIT TRANSACTION;
-- SELECT @@TRANCOUNT AS [TransactionCount];

