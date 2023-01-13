set scan on define "&" feedback off

column sid format 999999999
column object_name format a30
column locked_mode format a35
column username format a15
column osuser format a30
column machine format a30

prompt ;
prompt Substitution variable 1 is for OWNER;
prompt Substitution variable 2 is for OBJECT_NAME;
column myowner new_value _OWNER noprint;
column myobject_name new_value _OBJECT_NAME noprint;
select '&1' myowner, '&2' myobject_name from dual;
set feedback on

select
	  c.owner||'.'||c.object_name object_name
	, c.object_type
	, case a.locked_mode 
		when 0 then 'lock requested but not yet obtained'
		when 1 then NULL
		when 2 then 'Row Share Lock'
		when 3 then 'Row Exclusive Table Lock'
		when 4 then 'Share Table Lock'
		when 5 then 'Share Row Exclusive Table Lock'
		when 6 then 'Exclusive Table Lock'
	  end locked_mode
	, b.sid
	, b.serial#
	, b.status
	, b.username
	, b.osuser
	, b.machine
from
	v$locked_object a
join
	v$session b on b.sid=a.session_id
join
	dba_objects c on c.object_id=a.object_id
where
	c.owner='&_OWNER'
	and c.object_name='&_OBJECT_NAME'
order by
	  c.owner
	, c.object_name;


undefine 1
undefine 2
undefine _OWNER
undefine _OBJECT_NAME