/*

https://github.com/dbabyday
Warranty: The software is provided "AS IS", without warranty of any kind

Name: carguments.sql
Description: See arguemnts for a specified object

*/


set define on

column fully_qualified_object_name format a50
column overload format a8
column argument_name format a25
column data_type format a25
column defaulted format a9

set pagesize 50000
break on object_type nodup on fully_qualified_object_name nodup on overload skip 1 nodup

select	  o.object_type
	, case	when a.package_name is null then o.owner||'.'||o.object_name
		else a.owner||'.'||a.package_name||'.'||a.object_name
	  end fully_qualified_object_name
	, a.overload
	, a.argument_name
	, case	when a.data_type='NUMBER' and a.data_precision is not null and a.data_scale is not null then a.data_type||'('||to_char(a.data_precision)||','||to_char(a.data_scale)||')'
		when a.data_type='NUMBER' and a.data_precision is not null and a.data_scale is null then a.data_type||'('||to_char(a.data_precision)||')'
		when a.data_type='NUMBER' and a.data_precision is null then a.data_type
		when a.char_length is not null and a.char_used='B' then a.pls_type||'('||to_char(a.char_length)||' BYTE)'
		when a.char_length is not null and a.char_used='C' then a.pls_type||'('||to_char(a.char_length)||' CHAR)'
		when a.type_owner is not null and a.type_subname is not null then a.type_owner||'.'||a.type_name||'.'||a.type_subname
		when a.type_owner is not null and a.type_subname is null then a.type_owner||'.'||a.type_name
		else a.data_type
	  end data_type
	, a.in_out
	, a.defaulted
	, a.sequence
from	  dba_objects o
left join dba_arguments a on a.object_id=o.object_id
where     o.owner='&_OWNER'
          and o.object_name='&_OBJECT_NAME'
          and a.argument_name is not null
order by  fully_qualified_object_name
	, a.overload
	, a.sequence;

clear breaks