select * from table(dbms_xplan.display_cursor(sql_id=>'&sqlid', format=>'ALL'));
undefine sqlid