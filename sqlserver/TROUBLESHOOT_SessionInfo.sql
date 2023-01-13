



SELECT      r.session_id, 
            r.blocking_session_id,
            s.login_name, 
            s.host_name, 
            s.program_name,
            s.login_time,
            r.start_time, 
            r.status, 
            r.command, 
            r.cpu_time, 
            r.reads, 
            r.writes, 
            r.logical_reads,
            r.wait_type,
            r.wait_resource,
            r.wait_time,
            r.last_wait_type, 
            r.open_transaction_count,
            r.open_resultset_count,
            r.percent_complete,
            c.connect_time,
            c.last_read,
            c.last_write,
            c.net_transport, 
            c.protocol_type, 
            c.client_net_address, 
            DB_NAME(r.database_id) AS database_name,
            t.text,
            r.statement_start_offset,
            r.statement_end_offset
FROM        sys.dm_exec_requests               AS r
INNER JOIN  sys.dm_exec_sessions               AS s ON s.session_id = r.session_id
INNER JOIN  sys.dm_exec_connections            AS c ON c.connection_id = r.connection_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS t
--WHERE       r.command = N'KILLED/ROLLBACK'
ORDER BY    r.session_id;

