SELECT DISTINCT
    a.Name AS DatabaseName ,
    CONVERT(SYSNAME, DATABASEPROPERTYEX(a.name, 'Recovery')) AS RecoveryModel ,
	a.create_date,
    COALESCE(( SELECT   CONVERT(VARCHAR(12), MAX(backup_finish_date), 101)
                FROM     msdb.dbo.backupset
                WHERE    database_name = a.name
                        AND type = 'd'
                        AND is_copy_only = '0'
                ), 'No Full') AS 'Full' ,
    COALESCE(( SELECT   CONVERT(VARCHAR(12), MAX(backup_finish_date), 101)
                FROM     msdb.dbo.backupset
                WHERE    database_name = a.name
                        AND type = 'i'
                        AND is_copy_only = '0'
                ), 'No Diff') AS 'Diff' ,
    COALESCE(( SELECT   CONVERT(VARCHAR(20), MAX(backup_finish_date), 120)
                FROM     msdb.dbo.backupset
                WHERE    database_name = a.name
                        AND type = 'l'
                ), 'No Log') AS 'Log'
FROM
    sys.databases a
LEFT OUTER JOIN 
    msdb.dbo.backupset b 
	ON b.database_name = a.name
WHERE
    a.name <> 'tempdb'
    AND a.state_desc = 'online'
GROUP BY
    a.Name ,
    a.compatibility_level,
	a.create_date
ORDER BY 
    a.name

SELECT GETDATE() AS [CurrentTime];