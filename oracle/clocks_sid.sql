set scan on define "&"

column object_name format a30
column locked_mode format a35
column username format a15
column osuser format a30
column machine format a30

prompt ;
prompt substitution variable 1 is for SID
column mysid new_value _SID noprint;
set feedback off
select '&1' mysid from dual;
set feedback on

select   c.owner||'.'||c.object_name object_name
       , c.object_type
       , case a.locked_mode when 0 then 'lock requested but not yet obtained'
                            when 1 then NULL
                            when 2 then 'Row Share Lock'
                            when 3 then 'Row Exclusive Table Lock'
                            when 4 then 'Share Table Lock'
                            when 5 then 'Share Row Exclusive Table Lock'
                            when 6 then 'Exclusive Table Lock'
         end locked_mode
       , b.sid
       , b.serial#
       , b.status
       , b.username
       , b.osuser
       , b.machine
from     v$locked_object a
join     v$session b on b.sid=a.session_id
join     dba_objects c on c.object_id=a.object_id
where    b.sid='&&_SID'
order by c.owner
       , c.object_name;


undefine 1
undefine _SID