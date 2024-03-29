set linesize 32767
set pagesize 50000

column username       format a25
column profile        format a20
column account_status format a20
column created        format a12
column lock_date      format a21
column expire_date    format a21
column last_login    format a21

select username
     , profile
     , account_status
     , to_char(created,    'YYYY-MM-DD')            created
     , to_char(lock_date,  'YYYY-MM-DD HH24:MI:SS') lock_date
     , to_char(expiry_date,'YYYY-MM-DD HH24:MI:SS') expire_date
     , to_char(last_login,'YYYY-MM-DD HH24:MI:SS')  last_login
from   dba_users
where  oracle_maintained='N'
order by username;

