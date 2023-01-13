set feedback off
set trimspool on
set trimout on
set pagesize 50000
set head off
set echo off
set linesize 500

spool ru.sh

select 'rman target / catalog rman/BackupS@rmnprd01 <<-EOF' from dual;

select   'change archivelog '''||name||''' uncatalog;'
from     v$archived_log
where    name is not null
         and recid < (select recid from v$archived_log where name = '/archive1/windpd/archive1/1_151366_805037634.arc')
order by recid;

select 'EOF' from dual;

spool off
