
column constraint_name format a30
column table_name format a30
column column_name format a30
column r_constraint_name format a30
column r_table_name format a30
column r_column_name format a30

select    cons.constraint_name
        , cons.table_name
        , cols.column_name
        , cons.r_constraint_name
        , cons_r.table_name r_table_name
        , cols_r.column_name r_column_name
from      dba_constraints  cons
left join dba_cons_columns cols   on cols.constraint_name   = cons.constraint_name
left join dba_constraints  cons_r on cons_r.constraint_name = cons.r_constraint_name
left join dba_cons_columns cols_r on cols_r.constraint_name = cons.r_constraint_name
where     cons.constraint_type = 'R'
          and cons.owner in ('TCUSER1','TCUSER2')
order by  cons.table_name
        , cols.column_name;
