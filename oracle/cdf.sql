set feedback off define "&"
prompt Substitution variable 1 = TABLESPACE_NAME;
column my_tablespace_name new_value _TABLESPACE_NAME noprint;
select '&1' my_tablespace_name from dual;
set feedback on

select
	file_name
from
	dba_data_files
where
	tablespace_name='&&_TABLESPACE_NAME'
order by
	  length(file_name)
	, file_name;

undefine 1
undefine _TABLESPACE_NAME