select * from ca.ogg_lgtrans order by tran_time;

select * from ca.ogg_lgtrans where tran_time>to_date('20191108 13:50','YYYYMMDD HH24:MI') order by tran_time DESC;


select * from ca.ogg_lgtrans where trail_file in ('/orahome/oracle/goldengate/dirdat/ra000024464'
                                                 ,'/orahome/oracle/goldengate/dirdat/ra000024501'
                                                 ,'/orahome/oracle/goldengate/dirdat/ra000024601')
order by tran_time;

select * 
from ca.ogg_lgtrans 
where to_number(substr(trail_file,-5,5))>=24464
      and to_number(substr(trail_file,-5,5))<=25196
order by tran_time;



select * from ca.ogg_lgtrans_lasttrail;

select   table_owner||'.'||table_name as tbl
       , count(*) as entries
       , min(record_count) as min_record_count
       , max(record_count) as max_record_count
       , round(avg(record_count)) as avg_record_count
       , min(tran_time) as min_tran_time
       , max(tran_time) as max_tran_time
from     ca.ogg_lgtrans
group by table_owner
       , table_name
order by entries desc,tbl;


describe ca.ogg_lgtrans;


select * 
from ca.ogg_lgtrans 
where tran_time>to_date('20191115 0800','YYYYMMDD HH24MI')
--      and tran_time<to_date('20191113 1400','YYYYMMDD HH24MI')
      and record_count>20000
order by tran_time;


