set define "&"
set feedback off
prompt Substitution variable 1 = OWNER;
column my_owner new_value _OWNER noprint;
select '&1' my_owner from dual;
set feedbac on


column obj format a50
column procedure_name format a30


select   object_type
       , subprogram_id
       , case when procedure_name is null then owner||'.'||object_name
              else owner||'.'||object_name||'.'||procedure_name
         end obj
from     dba_procedures
where    upper(owner)=upper('&&_OWNER')
order by object_name
       , subprogram_id;


undefine 1
undefine _OWNER