set serveroutput on termout on echo off feedback off define on

DECLARE
    exec_time   varchar2(20)   := '';
    qty         number(38)     := 0;
    stmt        varchar2(1000) := '';
    tran_status varchar2(16)   := '';
BEGIN
    stmt := 'select to_char(sysdate,''YYYY-MM-DD HH24:MI:SS''),count(*) from v$transaction t join v$session s on t.ses_addr = s.saddr where s.sid = sys_context(''USERENV'',''SID'')';
    execute immediate stmt into exec_time,qty;

    IF qty=0 THEN
        dbms_output.put_line(chr(10)||exec_time||' | This session does NOT have an open transaction'||chr(10));
    ELSE
        stmt := 'select t.status from v$transaction t join v$session s on t.ses_addr = s.saddr where s.sid = sys_context(''USERENV'',''SID'')';
        execute immediate stmt into tran_status;
        dbms_output.put_line(chr(10)||exec_time||' | Transaction status for this session: '||tran_status||chr(10));
    END IF;
END;
/


set feedback on