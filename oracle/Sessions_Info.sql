select   p.spid,
         s.sid,
         s.serial#,
         s.machine,
         s.username,
         s.server,
         s.osuser,
         s.program,
         t.*
from     v$session s
join     v$process p on p.addr = s.paddr
join     v$transaction t on t.addr = s.taddr
-- where    s.username = 'JLUTSEY'
         -- and s.machine = 'co-db-001'
--         and type = 'USER'
order by p.spid; 

-- ALTER SYSTEM KILL SESSION '8083,27039' immediate;

select   p.spid,
         s.sid,
         s.serial#,
         s.machine,
         s.username,
         s.server,
         s.osuser,
         s.program,
         s.taddr 
from     v$session s
join     v$process p on p.addr = s.paddr
where    s.username = 'JLUTSEY'
         -- and s.machine = 'co-db-001'
--         and type = 'USER'
order by p.spid; 


-- 000000263F0C91F0
select * from v$transaction
where rownum <= 100;

select     s.sid
         , s.serial#
         , s.username
         , s.machine
         , s.status
         , s.lockwait
         , t.used_ublk
         , t.used_urec
         , t.start_time
from       v$transaction t
inner join v$session     s on t.addr = s.taddr;



SELECT used_ublk FROM v$transaction 
WHERE ADDR IN (SELECT TADDR FROM v$session WHERE SID = 8083);



-- blocking
select   blocking_session
       , sid
       , serial#
       , wait_class
       , seconds_in_wait
from     v$session
where    blocking_session is not null
order by blocking_session;


SELECT l1.sid || ' is blocking ' || l2.sid blocking_sessions
FROM   v$lock l1
JOIN   v$lock l2 on l1.id1 = l2.id1 AND l1.id2 = l2.id2
WHERE  l1.block = 1 
       AND l2.request > 0;


SELECT s1.username || '@' || s1.machine || ' ( SID=' || s1.sid || ' )  is blocking ' || s2.username || '@' || s2.machine || ' ( SID=' || s2.sid || ' ) ' AS blocking_status
FROM   v$lock    l1
JOIN   v$session s1 on s1.sid=l1.sid
join   v$lock    l2 on l1.id1 = l2.id1 and l1.id2 = l2.id2
join   v$session s2 on s2.sid=l2.sid
WHERE  l1.BLOCK=1 AND l2.request > 0;



