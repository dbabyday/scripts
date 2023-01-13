/*********************************************************************************************************************
* 
* TROUBLESHOOT_BlockingByNegativeSpid.sql
* 
* Author: James Lutsey
* Date:   2017-12-07
* 
* Purpose: Troubleshoot orphaned distributed transactions and kill blocking spid -2
* 
* http://www.eraofdata.com/sql-server/troubleshooting-sql-server/orphaned-msdtc-transactions-2-spids/
* https://www.mssqltips.com/sqlservertip/4142/how-to-kill-a-blocking-negative-spid-in-sql-server/
* https://www.sqlskills.com/blogs/paul/disaster-recovery-101-dealing-with-negative-spids-2-and-3/
* 
*********************************************************************************************************************/



/*
    Troubleshoot MSDTC itself --> Abort In Doubt Transaction
        1. Open Component Services: Windows > Run > dcomcnfg
        2. Browse to Computers > My Computer > Distributed Transaction Coordinator
        3. Find appropirate DTC service
        4. Transaction Statistics
        5. Look at "In Doubt" transactions in the "Current" section
        6. If not 0, go to Transaction List --> see in doubt transactions marked with a question mark
        7. Note the "Unit of Work ID" guid (will be used if we need to kill transaction in SQL Server)
        7. Right click on transaction > Resolve > Abort

    Check if transaction remains in SQL Server --> Kill -2 SPID
        1. Query sys.dm_tran_locks
        2. Match request_owner_guid with unit of work id guid noted above
        3. Kill transaction using guid.
*/

USE Master;

SELECT DISTINCT 'KILL ''' + CAST(request_owner_guid AS VARCHAR(100)) + ''';' AS UoW_Guid
FROM            sys.dm_tran_locks
WHERE           request_session_id = -2;

