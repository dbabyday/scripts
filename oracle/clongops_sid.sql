rem   Huge caveat is that in version prior to 11g this view
rem   will hang (library cache) if someone is doing an operation
rem   on the underlying table like a PK constraint build, so
rem   we probably need some way to check ahead of time - ouch

set lines 300
set long 2000000

prompt ;
prompt substitution variable 1 is for SID
column mysid new_value _SID noprint;
set termout off
select '&1' mysid from dual;
set termout on

column inst_id format 999990    heading "Instance"
column sid     format 99990     heading "SID"
column target  format a30 wrap  heading "Table"
column timer   format 999999.90 heading "Est. |Minutes|Left"
column pct     format 99990  heading "% Complete"
column sql_fulltext format a80
column username format a20

SELECT    l.sid
        --, l.inst_id
        , l.username
        , l.target
        , l.start_time
        -- , l.sofar
        -- , l.totalwork
        , l.time_remaining/60 timer
        , round(l.sofar/l.totalwork*100) pct
        , sysdate + l.time_remaining/60/60/24 est_end_time
        , l.sql_id
        -- , s.sql_fulltext
from      gv$session_longops l
left join v$sql             s on s.sql_id=l.sql_id
where     l.opname not like '%aggregate%'
          and l.totalwork != 0
          and l.sofar <> l.totalwork
          and l.sid=&_SID
order by  l.time_remaining desc;


undefine 1
undefine _SID