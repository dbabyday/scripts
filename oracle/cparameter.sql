set lines 500
set serveroutput on format wrapped
set trimout on
set verify off
set define "&"

prompt ;
prompt Substitution variable 1 is for PARMETER_NAME_LIKE;
column my_parameter_names_like new_value _PARMETER_NAME_LIKE noprint
set feedback off
select '&1' my_parameter_names_like from dual;


BEGIN
	dbms_output.put_line(chr(10)||'-----------------------------------------------------------------------------');
	FOR x IN (    select   name
	                     , value
	                     , display_value
	                     , default_value
	                     , isdefault
	                     , isses_modifiable
	                     , issys_modifiable
	                     , isinstance_modifiable
	                     , ismodified
	                     , isadjusted
	                     , isdeprecated
	                     , isbasic
	                     , description
	                     , update_comment
	              from     v$parameter
	              where    lower(name) like lower('%&_PARMETER_NAME_LIKE%')
	              order by name
	          )
	LOOP
		dbms_output.put_line('NAME                  : '||x.name);
		dbms_output.put_line('VALUE                 : '||x.value);
		dbms_output.put_line('DISPLAY_VALUE         : '||x.display_value);
		dbms_output.put_line('ISDEFAULT             : '||x.isdefault);
		dbms_output.put_line('ISSES_MODIFIABLE      : '||x.isses_modifiable);
		dbms_output.put_line('ISSYS_MODIFIABLE      : '||x.issys_modifiable);
		dbms_output.put_line('ISINSTANCE_MODIFIABLE : '||x.isinstance_modifiable);
		dbms_output.put_line('ISMODIFIED            : '||x.ismodified);
		dbms_output.put_line('ISADJUSTED            : '||x.isadjusted);
		dbms_output.put_line('ISDEPRECATED          : '||x.isdeprecated);
		dbms_output.put_line('ISBASIC               : '||x.isbasic);
		dbms_output.put_line('DESCRIPTION           : '||x.description);
		dbms_output.put_line('UPDATE_COMMENT        : '||x.update_comment);
		dbms_output.put_line('-----------------------------------------------------------------------------');
	END LOOP;
	dbms_output.put_line(chr(10));
END;
/

undefine 1
undefine _PARMETER_NAME_LIKE

set feedback on