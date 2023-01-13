store set james_sqlplus_set.sql replace
set feedback off
prompt Substitution variable 1 is for OWNER;
prompt Substitution variable 2 is for INDEX_NAME;
column myOwner new_value _OWNER noprint;
column myIndexName new_value _INDEX_NAME noprint;
select '&1' myOwner, '&2' myIndexName from dual;
set feedback on

column tbl format a30
column idx format a30
column index_degree format a12
column table_degree format a12

select
	  i.owner||'.'||i.index_name idx
	, i.degree index_degree
	, i.table_owner||'.'||i.table_name tbl
	, t.degree table_degree
from
	dba_indexes i
join
	dba_tables t on i.table_owner=t.owner and i.table_name=t.table_name
where
	i.owner='&&_OWNER'
	and i.index_name='&&_INDEX_NAME';

undefine 1
undefine 2
undefine _OWNER
undefine _INDEX_NAME

@james_sqlplus_set.sql