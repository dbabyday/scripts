set long 2000000
set pagesize 0
set linesize 32767
set trimout on
set trimspool on
set feedback off
set termout on
set verify off

column stmt format a32000

prompt ;
prompt Substitution variable 1 is for OWNER;
prompt Substitution variable 2 is for TABLE_NAME;
column myowner new_value _owner noprint;
column mytbl new_value _tbl noprint;
select '&1' myowner, '&2' mytbl from dual;






EXECUTE DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'STORAGE',false);



-- script table
select   dbms_metadata.get_ddl('TABLE',t.table_name,t.owner)||';' stmt
from     dba_tables t
where    t.owner='&&_owner'
         and t.table_name='&&_tbl';

-- script indexes for the table
select    dbms_metadata.get_ddl('INDEX',i.index_name,i.owner)||';' stmt
from      dba_indexes i
where     i.owner='&&_owner'
          and i.table_name='&&_tbl'
          and i.owner||'.'||i.index_name not in (  select c.index_owner||'.'||c.index_name
                                                   from   dba_constraints c
                                                   where  c.constraint_type='P'
                                                )
order by  i.owner
        , i.index_name;




EXECUTE DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'DEFAULT');



set pagesize 70
set feedback on

undefine _owner
undefine _tbl
undefine 1
undefine 2