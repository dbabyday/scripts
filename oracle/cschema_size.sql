
column schema_name format a20
column schema_size format a15

prompt ## substitution variable 1 is for SCHEMA_NAME
set feedback off
column my_owner new_value _SCHEMA_NAME noprint;
select '&1' my_owner from dual;
set feedback on

select
	  owner schema_name
	, case
		when sum(bytes)>1024*1024*1024*1024 then to_char(round(sum(bytes)/1024/1024/1024/1024,1))||' TB'
		when sum(bytes)>1024*1024*1024      then to_char(round(sum(bytes)/1024/1024/1024,1))     ||' GB'
		when sum(bytes)>1024*1024           then to_char(round(sum(bytes)/1024/1024,1))          ||' MB'
		when sum(bytes)>1024                then to_char(round(sum(bytes)/1024,1))               ||' KB'
		else                                     to_char(sum(bytes))                             ||' bytes'
	  end schema_size
from
	dba_segments
where
	owner='&&_SCHEMA_NAME'
group by
	owner;

undefine 1
undefine _SCHEMA_NAME


