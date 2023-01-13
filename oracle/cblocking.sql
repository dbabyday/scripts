set echo off
set linesize 500
set pagesize 100
set serveroutput on

exec dbms_output.put_line(chr(10)||to_char(sysdate,'YYYY-MM-DD HH24:MI:SS'));

column username format a15
column wait_class format a20
column event format a40
column sid format 9999999999

select   blocking_session
       , sid
       , serial#
       , username
       , wait_class
       , event
       , round(seconds_in_wait/60,0) minutes_in_wait
       , sql_id
from     v$session
where    blocking_session is not NULL
order by blocking_session;