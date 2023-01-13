
prompt ;
prompt Substitution variable 1 is for OWNER;
column myowner new_value _OWNER noprint;
select '&1' myowner from dual;

column owner for a20
column table_name for a40

select
	  owner
	, table_name
from
	dba_tables
where
	upper(owner)=upper('&_OWNER')
order by
	  owner
	, table_name;

undefine 1
undefine _OWNER