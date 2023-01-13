
col username for a30
col stmt for a70


with first_archive as (
	select t.archive_time
	     , u.username
	     , u.pw_values
	     , u.default_tablespace
	     , u.temporary_tablespace
	     , u.profile
	     , u.account_status
	from   ca.arc_times t
	join   ca.arc_users u on u.arc_times_id=t.id
	where  t.id=642
)
, second_archive as (
	select t.archive_time
	     , u.username
	     , u.pw_values
	     , u.default_tablespace
	     , u.temporary_tablespace
	     , u.profile
	     , u.account_status
	from   ca.arc_times t
	join   ca.arc_users u on u.arc_times_id=t.id
	where  t.id=643
)
select   f.archive_time time1
       , s.archive_time time2
       , f.username
       , f.account_status status1
       , s.account_status status2
       , 'alter user "'||f.username||'" account unlock;' stmt
       -- , f.pw_values pw_values1
       -- , s.pw_values pw_values2
from     first_archive f
join     second_archive s on s.username=f.username
where    f.account_status not like '%LOCKED%'
         and s.account_status like '%LOCKED%'
-- where    f.pw_values<>s.pw_values
order by f.username;




