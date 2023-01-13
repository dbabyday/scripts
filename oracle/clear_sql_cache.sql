-- select sql_id, count(*) from v$sql group by sql_id having count(*)>20 order by count(*);
-- select count(*) from v$sql where sql_id='7zc5z87xhu6j7';

-- enter the sql_id value you want to clear when prompted
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
    sys.dbms_shared_pool.purge (SQ_ADD||' ' || SQ_HASH,'C');
END;
/



-- jdepd01
-- -------------------
-- d45nzrx4hc7hy
-- 7d4ytnnjd0adm
-- 3ax8hh3bv2d9g
-- 3ms7w0c6ph91t
-- aaz3bayav0jwj
-- c8h20n1d0k95m

-- jdepd03
-- -------------------
-- 3v2u3xy9n1aku
-- 121ffmrc95v7g
-- 6rag3nvam9fsk
-- 318x2n7k56nz5
-- 7nj3m58dfta1a


-- SR - heap warning
-- BizTalk - Oracle Client

