
column username format a30

select   count(*) qty
       , username
       , status
       , round(min(seconds_in_wait)/60,1) minutes
from     v$session
where    username like '%JDE%'
group by username
       , status
order by status
       , minutes;