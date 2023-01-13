set linesize 500
set pagesize 60
set define "&"

undefine _OWNER
undefine _OBJECT_NAME



prompt ;
prompt 'Substitution variable 1 is for OWNER: ';
prompt 'Substitution variable 2 is for OBJECT_NAME: ';
column MY_OWNER new_value _OWNER noprint;
column MY_OBJECT_NAME new_value _OBJECT_NAME noprint;
select '&1' MY_OWNER
     , '&2' MY_OBJECT_NAME
from   dual;


column name format a40
column error_text format a75
column line_text for a100


select
	  e.owner||'.'||e.name as name
	, e.type
	, e.line
	, e.position
	, e.text error_text
	, s.text line_text
from
	dba_errors e
left join
	dba_source s on
		s.owner=e.owner
		and s.name=e.name
		and s.type=e.type
		and s.line=e.line
where
	e.owner='&&_OWNER'
	and e.name='&&_OBJECT_NAME'
order by
	  e.line
	, e.position;


undefine 1
undefine 2
undefine _OWNER
undefine _OBJECT_NAME

