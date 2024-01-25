set feedback off
prompt substitution variable 1 is for OBJECT_TYPE;
prompt substitution variable 2 is for OBJECT_NAME;
prompt substitution variable 3 is for OWNER;
column my_object_type new_value _OBJECT_TYPE noprint;
column my_object_name new_value _OBJECT_NAME noprint;
column my_owner       new_value _OWNER       noprint;
select '&1' my_object_type, '&2' my_object_name, '&3' my_owner from dual;
set feedback on

select dbms_metadata.get_ddl('&&_OBJECT_TYPE','&&_OBJECT_NAME','&&_OWNER') stmt from dual;

undefine 1
undefine 2
undefine 3
undefine _OBJECT_TYPE
undefine _OBJECT_NAME
undefine _OWNER