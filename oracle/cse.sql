column ora_login_user format a14
column host format a25
column module format a20
column ora_server_error_msg format a50
column sql format a50
select	  error_date
	, ora_login_user
	, host
	, module
	, ora_server_error_msg
	, sql
from	  sys.server_errors
--where	  ora_server_error_msg like 'ORA-00001: unique constraint%PRODDTA.F5530269_PK%'
order by  error_date;


