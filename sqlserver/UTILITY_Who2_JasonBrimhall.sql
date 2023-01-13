/***************************************************************************************************************
* 
* UTILITY_Who2_JasonBrimhall.sql
* Author: Jason Brimhall
* Date: 06/14/2010
* Source: http://www.sqlservercentral.com/articles/sp_who2/70222/
* 
***************************************************************************************************************/


DECLARE
    @IsUserProcess  TINYINT = 0,
    @CurrentSpid  TINYINT = 1;

SET NOCOUNT ON;

SELECT 
    es.session_id AS SPID,
    ROW_NUMBER() OVER (partition by es.session_id order by es.login_time) AS SubProcessID,
    DB_NAME(COALESCE(er.database_id,tl1.resource_database_id,' - ')) AS DBName,
    COALESCE(ot.task_state,es.status,' - ') AS TaskStatus,
    es.login_name AS LoginName,
    COALESCE(ec.client_net_address,' - ') AS IPAddress,
    COALESCE
    (
        (
            SELECT text AS [processing-instruction(definition)]
            FROM sys.dm_exec_sql_text(ec.most_recent_sql_handle)
            FOR XML PATH(''), TYPE
        ),''
    ) AS QueryText,
    COALESCE(er.wait_type,wt.wait_type,er.last_wait_type,' - ') AS WaitType,
    COALESCE(es.host_name,' - ') AS HostName,
    COALESCE(tl.request_session_id,'') AS BlockedBy,
    COALESCE
    (
        (
            SELECT p.text
            FROM 
            (
                SELECT MIN(sql_handle) AS sql_handle
                FROM sys.dm_exec_requests r2
                WHERE r2.session_id = tl.request_session_id
            ) AS rb
            CROSS APPLY
            (
                SELECT text AS [processing-instruction(definition)]
                FROM sys.dm_exec_sql_text(rb.sql_handle)
                FOR XML PATH(''), TYPE
            ) p (text)
        ),''
    ) AS BlockingText,
    COALESCE(es.program_name,' - ') AS ProgramName,
    COALESCE(es.client_interface_name,' - ') AS ClientInterface,
    COALESCE(es.host_process_id,' - ') AS UserProcessID,
    es.login_time AS LoginTime,
    es.last_request_start_time AS LastBatch,
    es.total_elapsed_time *.001 AS SessionElapsedTime,
    es.total_scheduled_time * .001 AS CPUTime,
    es.memory_usage AS Num8kPages,
    COALESCE(ec.num_reads,'') AS NumReads,
    COALESCE(ec.num_writes,'') AS NumWrites,
    COALESCE(er.open_transaction_count,st.TranCount,0) AS OpenTranCount,
    COALESCE(dt.lockcount,0) AS LockCount
FROM 
    sys.dm_exec_sessions es
LEFT OUTER JOIN 
    sys.dm_exec_connections ec
    ON ec.session_id = es.session_id
LEFT OUTER JOIN 
    sys.dm_os_waiting_tasks wt
    ON wt.session_id = es.session_id
LEFT OUTER JOIN 
    sys.dm_os_tasks ot
    ON es.session_id = ot.session_id
LEFT OUTER JOIN 
    sys.dm_tran_locks tl
    ON wt.blocking_session_id = tl.request_session_id
LEFT OUTER JOIN 
    sys.dm_tran_locks tl1
    ON ec.session_id = tl1.request_session_id
LEFT OUTER JOIN 
    sys.dm_exec_requests er
    ON tl.request_session_id = er.session_id
LEFT OUTER JOIN 
    (
        Select request_session_id,COUNT(request_session_id) AS LockCount
        From sys.dm_tran_locks
        Group By request_session_id
    ) dt
    ON ec.session_id = dt.request_session_id
LEFT OUTER JOIN 
    (
        Select session_id,COUNT(session_id) AS TranCount
        From sys.dm_tran_session_transactions
        Group By session_id
    ) st
    ON ec.session_id = st.session_id
Where 
    es.is_user_process >= (CASE WHEN @IsUserProcess = 0 THEN 0 ELSE 1 END)
    AND es.session_id <> (CASE WHEN @CurrentSPID = 0 THEN 0 ELSE @@SPID END)  --@@SPID if current Spid is to be excluded
