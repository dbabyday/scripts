set termout off
set echo off
set feedback off
set pages 0
set lines 32767
set trimout on
set trimspool on
set markup csv on delimiter ',' quote on

spool \\na.plexus.com\neendata\Swap\<SUB_DIRECTORY>\<FILE_NAME>.csv

-- put your query here

spool off

set termout on
set feedback on
set pages 70
set markup csv off