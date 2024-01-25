
set feedback off
prompt substitution variable 1 = SQL_ID;
column my_sql_id new_value _SQL_ID noprint;
select '&1' my_sql_id from dual;
set feedback on



DECLARE
    l_address  varchar2(100)  := '';
    l_hash_value number         := 0;
    l_sql_id  varchar2(13)   := '&&_SQL_ID';
    l_stmt    varchar2(1000) := '';
BEGIN
    l_stmt := 'select address from v$sqlarea where sql_id = ''' || l_sql_id || '''';
    execute immediate l_stmt into l_address;
    l_stmt := 'select hash_value from v$sqlarea where sql_id = ''' || l_sql_id || '''';
    execute immediate l_stmt into l_hash_value;
    dbms_output.put_line(to_char(sysdate,'YYYY-MM-DD HH24:MI:SS')||' - purging sql_id: '||l_sql_id||', address: '||l_address||', hash_value: '||to_char(l_hash_value));
    sys.dbms_shared_pool.purge(l_address||' '||l_hash_value,'C');
END;
/


undefine 1
undefine _SQL_ID