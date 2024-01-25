/*

https://github.com/dbabyday
Warranty: The software is provided "AS IS", without warranty of any kind

Name: cblocking.sql
Description: See Blocking in the database with a quick and lightweight query

*/


set echo off
set linesize 500
set pagesize 100
set serveroutput on

exec dbms_output.put_line(chr(10)||to_char(sysdate,'YYYY-MM-DD HH24:MI:SS'));

column username format a15
column wait_class format a20
column event format a40
column machine format a20
column client_os_process_id format a20
column program format a50


select   blocking_session
       , sid
       -- , serial#
       , username
       -- , substr(machine,1,20) machine
       -- , process client_os_process_id
       -- , program
       , round(seconds_in_wait/60,0) minutes_in_wait
       , wait_class
       , event
       , sql_id
from     v$session
where    blocking_session is not NULL
order by blocking_session;