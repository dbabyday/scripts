column owner format a15
column object_name format a30

select
	  created
	, owner
	, object_name
from
	dba_objects o
where
	o.object_type='INDEX'
	and created>sysdate-7
order by
	created;