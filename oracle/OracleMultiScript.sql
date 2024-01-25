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


set pages 0
set feedback off
column my_name new_value _NAME noprint;
select name my_name from v$database;

col db_name format a10
col NLS_CHARACTERSET format a16
set heading off

spool OracleMultiScript.out append

select '&&_NAME' db_name, value NLS_CHARACTERSET from nls_database_parameters where parameter='NLS_CHARACTERSET';

undefine _NAME
-- EXECUTE DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'STORAGE',false);


-- /* change database link passwords */
-- begin
--        for x in (
--               select   'drop database link '||db_link stmt_drop
--                      , replace(dbms_metadata.get_ddl('DB_LINK',DB_LINK,OWNER),q'^VALUES ':1'^','"my_password"') stmt_create
--               from     dba_db_links
--               where    username='JLUTSEY'
--               order by db_link
--        )
--        loop
--               -- dbms_output.put_line(x.stmt_drop);
--               -- dbms_output.put_line(x.stmt_create);
--               execute immediate x.stmt_drop;
--               execute immediate x.stmt_create;
--        end loop;
-- end;
-- /


-- declare
--        l_qty number;
--        l_dbname varchar2(9);
-- begin
--        select count(*) into l_qty from dba_users where username='SRVCLOGICMONITOR';
--        select name into l_dbname from v$database;

--        if l_qty>0 then
--               dbms_output.put_line('SRVCLOGICMONITOR - '||l_dbname);
--        end if;
-- end;
-- /





-- declare
--        l_name varchar(10);
--        l_used number;
--        l_free number;
--        l_temp number;
-- begin
--        select name into l_name from v$database;
--        select sum(bytes) into l_used from dba_extents;
--        select sum(bytes) into l_free from dba_free_space;
--        select sum(bytes) into l_temp from dba_temp_files;
--        dbms_output.put_line(l_name||' - '||to_char(round((l_used+l_free+l_temp)/1024/1024/1024,0))||' GB');
-- end;
-- /


exit;