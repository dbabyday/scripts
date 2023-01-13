
SELECT
	  dt.transaction_id
	, st.session_id
	, database_transaction_begin_time
	, CASE database_transaction_type
		WHEN 1 THEN 'Read/write transaction'
		WHEN 2 THEN 'Read-only transaction'
		WHEN 3 THEN 'System transaction'
	  END database_transaction_type
	, CASE database_transaction_state
		WHEN 1 THEN 'The transaction has not been initialized.'
		WHEN 3 THEN 'The transaction has been initialized but has not generated any log recorst.'
		WHEN 4 THEN 'The transaction has generated log recorst.'
		WHEN 5 THEN 'The transaction has been prepared.'
		WHEN 10 THEN 'The transaction has been committed.'
		WHEN 11 THEN 'The transaction has been rolled back.'
		WHEN 12 THEN 'The transaction is being committed. In this state the log record is being generated, but it has not been materialized or persisted'
	  END database_transaction_state
	, database_transaction_log_bytes_used
	, database_transaction_log_bytes_reserved
FROM
	sys.dm_tran_database_transactions dt
INNER JOIN
	sys.dm_tran_session_transactions st ON st.transaction_id = dt.transaction_id;

	