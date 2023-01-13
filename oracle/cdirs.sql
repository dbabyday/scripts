set linesize 200
set pagesize 100

col directory_name format a25
col directory_path format a75

select   directory_name
       , directory_path
from     dba_directories
order by directory_name;

clear columns