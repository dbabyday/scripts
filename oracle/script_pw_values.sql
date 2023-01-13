set pagesize 0;
set linesize 32767;
set trimout on;
set trimspool on;
set echo off;
set feedback off;

col stmt format a1000

-- spool
column v_spoolname new_value _SPOOLNAME noprint;
select 'script_pw_values_'||name||to_char(sysdate,'_YYYYMMDD_HH24MISS')||'.sql' v_spoolname from v$database;

spool &_SPOOLNAME


-- heading info
select chr(10)||
       rpad('-',50,'-')                                                                  ||chr(10)||
       rpad('--// Database: '|| name,46,' ')||'//--'                                     ||chr(10)||
       rpad('--// Date:     '|| to_char(sysdate,'YYYY-MM-DD HH24:MI:SS'),46,' ')||'//--' ||chr(10)||
       rpad('-',50,'-')
from   v$database;

-- script alter statements with password values
select   case when u.password_versions like '%11G%'     then 'alter user "' || s.name || '" identified by values ''' || s.spare4 || ''';'
              when u.password_versions not like '%11G%' then 'alter user "' || s.name || '" identified by values ''' || s.password || ''';'
         end as stmt
from     sys.user$ s
join     dba_users u on u.username=s.name
where    u.username not in (select username from dba_users where oracle_maintained='Y' and password_versions is null)
         and u.password_versions is not null
order by s.name;

-- heading info: no pw values
select chr(10)||
       rpad('-',50,'-')                                                ||chr(10)||
       rpad('--// USERS WITHOUT STORED PASSWORD VALUES',46,' ')||'//--'||chr(10)||
       rpad('-',50,'-')
from   dual;

-- list users with no stored password values
select   '-- ' || s.name as stmt
from     sys.user$ s
join     dba_users u on u.username=s.name
where    u.password_versions is null
         and username not in (select username from dba_users where oracle_maintained='Y' and password_versions is null)
order by s.name;


spool off
