set lines 32767

column sql_fulltext format a9000
column avg_elapsed_seconds format 999,999,999.999
column elapsed_seconds format 999,999,999.999
column parsing_schema_name format a15
column module format a20

select   sql_id
       , executions
       , elapsed_time/1000000/executions avg_elapsed_seconds
       , elapsed_time/1000000             elapsed_seconds
       , parsing_schema_name
       , module
       , sql_fulltext
from     v$sql
where    (  upper(sql_text) like '%F5541043%'
            or upper(sql_text) like '%F5541046%'
            or upper(sql_text) like '%F5541047%'
            or upper(sql_text) like '%F5542024%'
            or upper(sql_text) like '%F5542088%'
         )
         and (  upper(sql_text) like '%INSERT%'
                or upper(sql_text) like '%DELETE%'
             )
         and parsing_schema_name like '%GSF%'
order by avg_elapsed_seconds desc;


