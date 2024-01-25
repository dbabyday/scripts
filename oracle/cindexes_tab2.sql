set linesize 500
set pagesize 100
set trimout on
set feedback off

column index_name format a45
column table_name format a45
column columns    format a100
column degree     format a7
column visibility format a10
column total_access_count format 999,999,999,999,999

prompt ;
prompt substitution variable 1 is for TABLE_OWNER
set termout off
column myusername new_value _TABLE_OWNER noprint;
select '&1' myusername from dual;
set termout on

prompt substitution variable 2 is for TABLE_NAME
set termout off
column mytablename new_value _TABLE_NAME noprint;
select '&2' mytablename from dual;
set termout on

set feedback on



with objects as (
       /* group objects by name so partitioned indexes only show up once */
       select
                owner
              , object_name
              , max(created) created
              , max(last_ddl_time) last_ddl_time
       from
              dba_objects
       group by
                owner
              , object_name
)
select
         c.table_owner||'.'||c.table_name table_name
       , c.index_owner||'.'||c.index_name index_name
       , listagg(c.column_name,', ') within group (order by c.column_position) columns
       , i.degree
       , i.visibility
       , i.status
       , u.total_access_count
       , o.created
       , o.last_ddl_time
from
       dba_indexes i
join
       dba_ind_columns c on c.index_owner=i.owner and c.index_name=i.index_name
join
       objects o on o.owner=c.index_owner and o.object_name=c.index_name
left join
       dba_index_usage u on u.owner=i.owner and u.name=i.index_name
where
       i.table_owner='&_TABLE_OWNER'
       and i.table_name='&_TABLE_NAME'
group by
         c.table_owner
       , c.table_name
       , c.index_owner
       , c.index_name
       , o.created
       , o.last_ddl_time
       , i.degree
       , i.visibility
       , i.status
       , u.total_access_count
order by 
       3
         -- 5
       --   c.index_owner
       -- , length(c.index_name)
       -- , c.index_name
/


undefine 1
undefine 2
undefine _TABLE_OWNER
undefine _TABLE_NAME