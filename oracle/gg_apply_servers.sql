set pages 100

COMPUTE SUM OF TOTAL_MESSAGES_APPLIED ON REPORT
BREAK ON REPORT

column TOTAL_MESSAGES_APPLIED format 999,999,999,999,999,999
col apply_name for a15
col transaction_id for a20


select
	  server_id
	, apply_name
	, state
	, total_messages_applied
	, transaction_id
from
	v$gg_apply_server
order by
	  apply_name
	, server_id;