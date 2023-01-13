set echo off
set lines 32767
set pages 50000
set trimout on
set feedback on

column sql_fulltext format a20000

select   sql_id
       , last_active_time
       , sql_fulltext
from     (    select   sql_id
                     , last_active_time
                     , max(last_active_time) over (partition by sql_id) most_recent
                     , sql_fulltext
              from     v$sql
              where    sql_text not like '%sql_text%'
                       and sql_text like '%&SQL_TEXT%'
         )
where    last_active_time=most_recent
order by last_active_time;

set pages 70