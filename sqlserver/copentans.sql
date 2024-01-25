SELECT
	  GETDATE() as now
	, at.transaction_begin_time
	, cast(datediff(second, at.transaction_begin_time, getdate())/86400 as varchar(11)) + ' days ' 
		+ right('00' + cast(datediff(second, at.transaction_begin_time, getdate())%86400/3600 as varchar(2)),2) + ':' 
		+ right('00' + cast(datediff(second, at.transaction_begin_time, getdate())%86400%3600/60 as varchar(2)),2) + ':'  
		+ right('00' + cast(datediff(second, at.transaction_begin_time, getdate())%86400%3600%60 as varchar(2)),2) transaction_duration
	, case at.transaction_type
		when 1 then 'Read/write transaction'
		when 2 then 'Read-only transaction'
		when 3 then 'System transaction'
		when 4 then 'Distributed transaction'
		else 'Undocumented'
	  end transaction_type
	, case at.transaction_state
		when 0 then 'The transaction has not been completely initialized yet.'
		when 1 then 'The transaction has been initialized but has not started.'
		when 2 then 'The transaction is active.'
		when 3 then 'The transaction has ended. This is used for read-only transactions.'
		when 4 then 'The commit process has been initiated on the distributed transaction. This is for distributed transactions only. The distributed transaction is still active but further processing cannot take place.'
		when 5 then 'The transaction is in a prepared state and waiting resolution.'
		when 6 then 'The transaction has been committed.'
		when 7 then 'The transaction is being rolled back.'
		when 8 then 'The transaction has been rolled back.'
	  end transaction_state
	, txt.text
	--, sess.open_transaction_count
	, st.session_id
	, db_name(sess.database_id) database_name
	, sess.login_time
	, sess.login_name
	, sess.host_name
	, sess.program_name
	, sess.host_process_id
	, sess.status session_status
	, sess.last_request_start_time
	, sess.last_request_end_time
	, case sess.transaction_isolation_level
		when 0 then 'Unspecified'
		when 1 then 'ReadUncommitted'
		when 2 then 'ReadCommitted'
		when 3 then 'RepeatableRead'
		when 4 then 'Serializable'
		when 5 then 'Snapshot'
	  end transaction_isolation_level
	, conn.last_read
	, conn.last_write
FROM
	sys.dm_tran_active_transactions at
INNER JOIN
	sys.dm_tran_session_transactions st ON st.transaction_id = at.transaction_id
LEFT OUTER JOIN
	sys.dm_exec_sessions sess ON st.session_id = sess.session_id
LEFT OUTER JOIN
	sys.dm_exec_connections conn ON conn.session_id = sess.session_id
OUTER APPLY
	sys.dm_exec_sql_text(conn.most_recent_sql_handle)  AS txt
ORDER BY
	transaction_duration DESC;