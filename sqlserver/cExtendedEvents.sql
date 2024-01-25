/*


-- get the extended event names
select
	  s.name extended_event_session
	, case 
		when xes.name is not null then 'running'
		else 'stopped'
	  end status
from
	sys.server_event_sessions s
left join
	sys.dm_xe_sessions xes on xes.name=s.name
order by
	s.name;



*/


declare @xe_name sysname = N'monitor_usp_SSISWipCompletionBySite_Update';



select
	  s.name extended_event_session
	, case 
		when xes.name is not null then 'running'
		else 'stopped'
	  end status
	, e.package
	, e.name event
	, a.name action
from
	sys.server_event_sessions s
left join
	sys.dm_xe_sessions xes on xes.name=s.name
join
	sys.server_event_session_events e on e.event_session_id=s.event_session_id
join
	sys.server_event_session_actions a on 
		a.event_session_id=e.event_session_id
		and a.event_id=e.event_id
where
	s.name=@xe_name
order by
	  e.package
	, e.name
	, a.name;



select
	  f.event_session_id
	, f.name field
	, f.value field_value
	, t.package
	, t.name target
from
	sys.server_event_sessions s
join
	sys.server_event_session_fields f on f.event_session_id=s.event_session_id
left join 
	sys.server_event_session_targets t on 
		t.event_session_id=f.event_session_id
		and t.target_id=f.object_id
where
	s.name=@xe_name
order by
	f.name;

