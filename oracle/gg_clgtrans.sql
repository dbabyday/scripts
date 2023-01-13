
alter session set nls_date_format='YYYY-MM-DD HH24:MI:SS';

select   *
from     ca.ogg_lgtrans
where    tran_time>=sysdate-1
order by tran_time desc
--fetch next 100 rows only
/


