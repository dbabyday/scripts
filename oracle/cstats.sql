column owner format a15
column table_name format a15
column days_ago format 99,999.9
column num_rows format 999,999,999,999
column modifications format 999,999,999,999
column pct_modified format 9999999999.9
column inserts format 999,999,999,999
column updates format 999,999,999,999
column deletes format 999,999,999,999

select   s.owner
       , s.table_name
       , s.stale_stats
       , s.last_analyzed
       , round(sysdate - s.last_analyzed,1) days_ago
       , s.num_rows
       , m.inserts + m.updates + m.deletes modifications
       , round((m.inserts + m.updates + m.deletes) / s.num_rows * 100,1) pct_modified
       , m.inserts
       , m.updates
       , m.deletes
from     dba_tab_statistics s
join     dba_tab_modifications m on m.table_owner=s.owner and m.table_name=s.table_name
where    s.owner='&owner'
         and s.table_name='&table_name'
         -- and s.table_name in ('F0006','F581750S','F1755','F0101','F4801','F0005')
ORDER BY pct_modified desc;


-- select   s.owner
--        , s.table_name
--        , s.stale_stats
--        , s.last_analyzed
--        , round(sysdate - s.last_analyzed,1) days_ago
--        , s.num_rows
--        , m.inserts + m.updates + m.deletes modifications
--        , round((m.inserts + m.updates + m.deletes) / s.num_rows * 100,1) pct_modified
--        , m.inserts
--        , m.updates
--        , m.deletes
-- from     dba_tab_statistics s
-- join     dba_tab_modifications m on m.table_owner=s.owner and m.table_name=s.table_name
-- where    (m.inserts + m.updates + m.deletes) / s.num_rows > 0.05
--          and s.num_rows > 0
--          and s.owner in ('PRODCTL','PRODDTA')
--          and s.table_name not in ('F4111','F0911')
-- ORDER BY pct_modified desc;


/*


begin
       dbms_stats.gather_table_stats(
                ownname => ''
              , tabname => ''
       );

*/

