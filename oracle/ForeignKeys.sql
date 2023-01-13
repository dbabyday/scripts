/*
    Foreign Keys
*/

col constraint_name format a35
col owner format a20
col table_name format a30
col column_name format a25
col REFERENCE_OWNER format a20
col REFERENCE_TABLE format a30
col REFERENCE_COLUMN format a25

SELECT   cons1.constraint_name
       , cons1.owner
       , cons1.table_name
       , cols1.column_name
       , cons2.owner       REFERENCE_OWNER
       , cons2.table_name  REFERENCE_TABLE
       , cols2.column_name REFERENCE_COLUMN
       -- , 'select dbms_metadata.get_ddl(''REF_CONSTRAINT'','''||cons1.constraint_name||''','''||cons1.owner||''')||'';'' from dual;' GET_DEFINITION
FROM     dba_constraints  cons1
JOIN     dba_cons_columns cols1 ON cols1.owner = cons1.owner AND cols1.constraint_name = cons1.constraint_name
JOIN     dba_constraints  cons2 ON cons2.owner = cons1.r_owner AND cons2.constraint_name = cons1.r_constraint_name
JOIN     dba_cons_columns cols2 ON cols2.owner = cons2.owner AND cols2.constraint_name = cons2.constraint_name
WHERE    cons1.constraint_type = 'R'
         and cons1.owner = '&&OWNER'
         --and cons1.table_name = ''
         and cons2.owner = '&&OWNER'
         --and cons2.table_name = ''
ORDER BY cons1.owner,
         cons1.table_name,
         cons2.owner,
         cons2.table_name;