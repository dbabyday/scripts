-- I use this as a quick-and-dirty "show me the users and SQLs who are sorting":
set long 32000

SELECT a.username, a.sid, a.serial#, a.osuser, b.tablespace, b.blocks*8/1024/1024 gb, c.sql_fulltext
FROM v$session a, v$tempseg_usage b, v$sqlarea c
WHERE a.saddr = b.session_addr
AND c.address= a.sql_address
AND c.hash_value = a.sql_hash_value
ORDER BY b.blocks desc
/

-- total temp used
select sum(blocks)*8/1024/1024 gb
from   v$tempseg_usage
/

-- sessions using temp
select   s.username, s.sid, s.serial#, s.osuser, u.tablespace, round(sum(u.blocks)*8/1024/1024) gb, s.STATUS, s.wait_class, s.SECONDS_IN_WAIT/60 min_in_wait
from     v$tempseg_usage u
join     v$session       s on s.saddr=u.session_addr
group by s.username, s.sid, s.serial#, s.osuser, u.tablespace, s.STATUS, s.wait_class, s.SECONDS_IN_WAIT
order by gb desc
/

-- same filtering as idle_jde_ses report
SELECT a.username, a.sid, a.serial#, a.osuser, b.tablespace, b.blocks*8/1024/1024 gb, c.sql_fulltext
FROM v$session a, v$tempseg_usage b, v$sqlarea c
WHERE a.saddr = b.session_addr
AND c.address= a.sql_address
AND c.hash_value = a.sql_hash_value
and a.status='INACTIVE'
and a.wait_class='Idle'
and a.seconds_in_wait>10800
--and (  a.username in ('JDE','JDER','JDEX') or a.username like '%\_ADMIN' escape '\'  )
ORDER BY b.blocks desc
/



SELECT sum(b.blocks)*8/1024/1024 gb
FROM v$session a, v$tempseg_usage b, v$sqlarea c
WHERE a.saddr = b.session_addr
AND c.address= a.sql_address
AND c.hash_value = a.sql_hash_value
and a.status='INACTIVE'
                and a.wait_class='Idle'
                and a.seconds_in_wait>10800
                and (  a.username in ('JDE','JDER','JDEX')
                       or a.username like '%\_ADMIN' escape '\'
                    );
/

-- I use this as an inexact "how much temp is being used" right now:
SELECT sum(b.blocks)*8192/1048576
FROM v$session a, v$tempseg_usage b, v$sqlarea c
WHERE a.saddr = b.session_addr
AND c.address= a.sql_address
AND c.hash_value = a.sql_hash_value
/


-- One of the top sorters is this session, which has been idle for a very long time
select event, seconds_in_wait from v$session where sid = 12449
/
-- SQL*Net message from client  186958
-- This would tell us the user abandoned their query but the connection remained open and retained a hook on the SQL statement and memory
