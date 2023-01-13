USE Gsfdistribution_PROD;

GO

/* use this script to see the recent errors, or change parameters to create a different date range */
DECLARE
    @start DATETIME,
    @stop  DATETIME;

SET @start = DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0);
SET @stop = GETDATE()
SET @start = '20180609'
--SET @stop = '20150828'

SELECT TOP 10 *
FROM   dbo.MSrepl_errors
WHERE  [time] >= @start
ORDER BY [time] desc



/*
EXECUTE dbo.sp_browsereplcmds
    @xact_seqno_start      = '0x0013241000031D6200DE00000000',
    @xact_seqno_end        = '0x0013241000031D6200DE00000000'
*/

