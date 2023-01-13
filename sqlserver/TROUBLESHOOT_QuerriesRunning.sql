USE [master];

SELECT 
	sp.SPID                        AS spid,
    sp.[loginame]                  AS loginname,
    sp.status                      AS status,
    sp.cmd                         AS command,
    --a.percent_complete             AS percent_complete,
    sp.Blocked                     AS BlockedBy,
    DB_NAME(sp.dbid)               AS DatabaseName,
    sp.hostname                    AS Hostname,
    sp.physical_io                 AS Physical_IO,
    sp.cpu                         AS CPU,
    --sp.waittype                    AS WaitType,
    (sp.waittime / 1000)           AS WaitTimeSec,
    sp.lastwaittype                AS LastWaitType,
    sp.waitresource                AS WaitResource,
    sp.login_time                  AS LoginTime,
    a.total_elapsed_time / 1000    AS BatchElapsedTimeSec,
	(SELECT	SUBSTRING
			(
				C.text,
				a.statement_start_offset / 2,
				(CASE
					WHEN a.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(max), c.text)) * 2
					ELSE a.statement_end_offset
				END - a.statement_start_offset) / 2
			)
	)								AS SQLStatementText,
    c.text                          AS SQLBatchText,
    b.query_plan                    AS QueryPlan
FROM   
	sys.sysprocesses AS sp
    INNER JOIN sys.dm_exec_requests AS a ON sp.spid = a.session_id
    CROSS APPLY sys.dm_exec_query_plan(A.plan_handle) AS b
    CROSS APPLY sys.dm_exec_sql_text(A.sql_handle) AS c
WHERE   
	sp.spid <> @@spid
--ORDER BY BatchElapsedTimeSec desc;
