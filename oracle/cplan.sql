set feedback off

execute dbms_output.put_line(chr(10)||'Substitution variable 1 = sqlid');
col my_sqlid new_value _SQLID noprint;
select '&1' my_sqlid from dual;


select * from table(dbms_xplan.display_cursor(sql_id=>'&&_SQLID', format=>'ALL'));


set feedback on

undefine 1
undefine _SQLID