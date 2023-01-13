
set linesize 300 pagesize 50000
col tbl format a20
col idx format a30
col column_name format a20

select    i.table_owner||'.'||i.table_name tbl
        , i.index_owner||'.'||i.index_name idx
        , i.column_name
        , i.column_position
from      dba_ind_columns i
left join (  select owner, table_name, index_owner, index_name
             from   dba_constraints
             where  constraint_type='P'  ) c on c.index_owner=i.index_owner and c.index_name=i.index_name
where     i.table_owner in ('PRODCLT','PRODDTA')
          and c.index_owner is null
order by  i.table_owner
        , i.table_name
        , i.index_owner
        , i.index_name
        , i.column_position;

