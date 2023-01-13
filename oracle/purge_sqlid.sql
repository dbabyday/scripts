



DECLARE
    SQ_ADD  varchar2(100)  := '';
    SQ_HASH number         := 0;
    SQL_ID  varchar2(13)   := '&sql_id';
    STMT    varchar2(1000) := '';
BEGIN
    STMT := 'select address from v$sqlarea where sql_id = ''' || SQL_ID || '''';
    execute immediate STMT into SQ_ADD;
    STMT := 'select hash_value from v$sqlarea where sql_id = ''' || SQL_ID || '''';
    execute immediate STMT into SQ_HASH;
    sys.dbms_shared_pool.purge(SQ_ADD||' '||SQ_HASH,'C');
END;
/
