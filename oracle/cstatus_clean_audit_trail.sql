column event_time format a30
select 
	  to_char(event_time,'DD-MON-YYYY HH24:MI:SS.FF') event_time
	, database_id
	, to_char(last_archive_time,'YYYY-MM-DD') last_archive_time
	, description 
from
	ca.status_clean_audit_trail
order by
	  event_time;
