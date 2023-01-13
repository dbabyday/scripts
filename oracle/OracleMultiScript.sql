whenever sqlerror exit sql.sqlcode
whenever oserror exit failure

-- set echo on
-- set feedback on
-- set serveroutput on format wrapped
-- set lines 500
-- set trimout on
-- set trimspool on
-- set pages 100

-- set feedback off pages 0
-- select (select name from v$database)||' - '||(select to_char(expiry_date,'YYYY-MM-DD') from dba_users where username='JLUTSEY') from dual;


set linesize 500

col owner format a15
col db_link format a20
col username format a20
col host format a10

set termout off
column mydbname new_value _DBNAME noprint;
select name mydbname from v$database;
set termout on

set pages 0
set feedback off

select   '&&_DBNAME' db_name
       , owner
       , db_link
       , username
       , host
       , created
from     dba_db_links
where    username='JLUTSEY'
order by db_link;





exit;