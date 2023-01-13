set linesize 32767
set pagesize 50000
set long 10000

col createuser format a1000

select dbms_metadata.get_ddl('USER',username) as createuser
from   dba_users where upper(username) = upper('&USERNAME');













