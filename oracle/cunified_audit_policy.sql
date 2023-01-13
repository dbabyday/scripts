
/* get the names of unified audit policies

select   distinct policy_name
from     audit_unified_policies
order by policy_name;

*/


set echo off
set feedback off
set verify off
set define "&"
set linesize 300

prompt substitution variable 1 is for POLICY_NAME
column my_policy_name new_value _POLICY_NAME noprint;
select '&1' my_policy_name from dual;

set feedback on

column policy_name           format a30
column entity_names          format a30
column audit_options         format a50
column object_qualified_name format a30
column success               format a7
column failure               format a7



/* see what a policy is auditing */
prompt ===============================;
prompt ==// POLICY ACTIONS        //==;
prompt ===============================;
select   policy_name
       , audit_option_type
       , object_type
       , object_schema||'.'||object_name object_qualified_name
       , listagg(audit_option,', ') within group (order by audit_option) audit_options
from     audit_unified_policies
where    policy_name='&&_POLICY_NAME'
         and audit_option_type='OBJECT ACTION'
group by policy_name
       , audit_option_type
       , object_schema
       , object_name
       , object_type
union all
select   policy_name
       , audit_option_type
       , object_type
       , object_schema||'.'||object_name object_qualified_name
       , audit_option audit_options
from     audit_unified_policies
where    policy_name='&&_POLICY_NAME'
         and audit_option_type<>'OBJECT ACTION'
order by audit_option_type
       , object_qualified_name
       , audit_options;
prompt ;


/* see what a policy is enabled for */
prompt ===============================;
prompt ==// POLICY ENABLED FOR    //==;
prompt ===============================;
select   policy_name
       , enabled_option
       , listagg(entity_name,', ') within group (order by entity_name) entity_names
       , success
       , failure
from     audit_unified_enabled_policies
where    policy_name='&&_POLICY_NAME'
group by policy_name
       , enabled_option
       , success
       , failure;
prompt ;


undefine 1
undefine _POLICY_NAME