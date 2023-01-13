
/*

-- <trace path> 
select *
from sys.fn_trace_getinfo(1);

-- tr.EventClass event_id's
select distinct
    ei.eventid,
    e.name
from sys.fn_trace_geteventinfo(1) ei
inner join sys.trace_events e
on e.trace_event_id = ei.eventid
where name like '%grow%';

*/

select *
    --te.name as event_name,
    --tr.DatabaseName,
    --tr.FileName,
    --tr.StartTime,
    --tr.EndTime
from sys.fn_trace_gettable('<trace path>', 0) tr
inner join sys.trace_events te
on tr.EventClass = te.trace_event_id
where tr.EventClass in (92, 93)
order by EndTime;
