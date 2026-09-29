DECLARE @exitcode INT
DECLARE @sqlerrorcode INT

EXECUTE master..sqlbackup
	'-SQL "RESTORE DATABASE [Stapf] 
	FROM DISK = ''\\NA\databackup\Neen_SQL_Backups\co-db-037\Stapf\*.sqb'' 
	SOURCE = ''Stapf'' 
	LATEST_FULL WITH MAILTO = ''drew.wilson@plexus.com'', 
	RECOVERY, 
	DISCONNECT_EXISTING, 
	MOVE ''Stapf_Test'' TO ''F:\Stapf.mdf'', 
	MOVE ''Stapf_Test_log'' TO ''G:\Stapf.ldf'', 
	REPLACE, ORPHAN_CHECK, CHECKDB = ''NO_INFOMSGS, ALL_ERRORMSGS, TABLOCK, DATA_PURITY, EXTENDED_LOGICAL_CHECKS''"'
	,
	@exitcode OUT,
	@sqlerrorcode OUT

IF (@exitcode >= 500)
    OR (@sqlerrorcode <> 0)
    BEGIN
        RAISERROR ('SQL Backup failed with exit code: %d  SQL error code: %d',16,1,@exitcode,@sqlerrorcode)
    END 
