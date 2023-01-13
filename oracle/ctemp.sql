set pagesize 60
set linesize 300
 
col "%_USED"          format 999
col allocated_gb      format 9,999
col free_gb           format 9,999
col size_gb           format 9,999
col sum_tempseg_usage format a17
 
prompt ;
prompt ;

select   tablespace_name
       , tablespace_size/1024/1024/1024                   size_gb
       , allocated_space/1024/1024/1024                   allocated_gb
       , free_space/1024/1024/1024                        free_gb
       , (tablespace_size-free_space)/tablespace_size*100 "%_USED"
from     dba_temp_free_space
order by "%_USED" desc
         --tablespace_name
/

prompt ;
prompt ;

-- total temp used
select SUBSTR('                 '||to_char(round(sum(blocks)*8/1024/1024))||' GB', -17, 17) sum_tempseg_usage
from   v$tempseg_usage
/

prompt ;
prompt ;

clear columns;

