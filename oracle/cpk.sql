/*
    Primary Keys
*/

set feedback off
prompt substitution variable 1 is for OWNER;
prompt substitution variable 1 is for TABLE_NAME;
column my_owner new_value _OWNER noprint;
column my_table_name new_value _TABLE_NAME noprint;
select '&1' my_owner, '&2' my_table_name from dual;
set feedback on

column owner format a15
column table_name format a15
column column_name format a15
column constraint_name format a15
column data_type format a15

SELECT   cons.owner
       , cons.table_name
       , cols.column_name
       , tc.data_type
       , cols.position
       , cons.constraint_name
       , cons.constraint_type
       , cons.status
       -- , 'select dbms_metadata.get_ddl(''CONSTRAINT'','''||cons.constraint_name||''','''||cons.owner||''')||'';'' from dual;' GET_DEFINITION
FROM     dba_constraints  cons
JOIN     dba_cons_columns cols ON cons.owner = cols.owner AND cons.constraint_name = cols.constraint_name
JOIN     dba_tab_columns  tc   ON tc.owner=cols.owner AND tc.table_name=cols.table_name AND tc.column_name=cols.column_name
WHERE    cons.constraint_type = 'P'
         AND cons.owner = UPPER('&&_OWNER')
         AND cons.table_name = UPPER('&&_TABLE_NAME')
ORDER BY cons.owner
       , cons.table_name
       , cols.position;

undefine 1
undefine 2
undefine _OWNER
undefine _TABLE_NAME