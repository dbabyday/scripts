use master;

declare @path nvarchar(4000);
select @path=path from sys.traces where is_default=1;

select 
	  t.StartTime
	, t.LoginName
	, t.HostName
	, t.ApplicationName
	, t.DatabaseName
	, t.ObjectName
	, case t.ObjectType
		when 8259  then 'Check Constraint'
		when 8260  then 'Default (constraint or standalone)'
		when 8262  then 'Foreign-key Constraint'
		when 8272  then 'Stored Procedure'
		when 8274  then 'Rule'
		when 8275  then 'System Table'
		when 8276  then 'Trigger on Server'
		when 8277  then 'User-defined) Table'
		when 8278  then 'View'
		when 8280  then 'Extended Stored Procedure'
		when 16724 then 'CLR Trigger'
		when 16964 then 'Database'
		when 16975 then 'Object'
		when 17222 then 'FullText Catalog'
		when 17232 then 'CLR Stored Procedure'
		when 17235 then 'Schema'
		when 17475 then 'Credential'
		when 17491 then 'DDL Event'
		when 17741 then 'Management Event'
		when 17747 then 'Security Event'
		when 17749 then 'User Event'
		when 17985 then 'CLR Aggregate Function'
		when 17993 then 'Inline Table-valued SQL Function'
		when 18000 then 'Partition Function'
		when 18002 then 'Replication Filter Procedure'
		when 18004 then 'Table-valued SQL Function'
		when 18259 then 'Server Role'
		when 18263 then 'Microsoft Windows Group'
		when 19265 then 'Asymmetric Key'
		when 19277 then 'Master Key'
		when 19280 then 'Primary Key'
		when 19283 then 'ObfusKey'
		when 19521 then 'Asymmetric Key Login'
		when 19523 then 'Certificate Login'
		when 19538 then 'Role'
		when 19539 then 'SQL Login'
		when 19543 then 'Windows Login'
		when 20034 then 'Remote Service Binding'
		when 20036 then 'Event Notification on Database'
		when 20037 then 'Event Notification'
		when 20038 then 'Scalar SQL Function'
		when 20047 then 'Event Notification on Object'
		when 20051 then 'Synonym'
		when 20307 then 'Sequence'
		when 20549 then 'End Point'
		when 20801 then 'Adhoc Queries which may be cached'
		when 20816 then 'Prepared Queries which may be cached'
		when 20819 then 'Service Broker Service Queue'
		when 20821 then 'Unique Constraint'
		when 21057 then 'Application Role'
		when 21059 then 'Certificate'
		when 21075 then 'Server'
		when 21076 then 'Transact-SQL Trigger'
		when 21313 then 'Assembly'
		when 21318 then 'CLR Scalar Function'
		when 21321 then 'Inline scalar SQL Function'
		when 21328 then 'Partition Scheme'
		when 21333 then 'User'
		when 21571 then 'Service Broker Service Contract'
		when 21572 then 'Trigger on Database'
		when 21574 then 'CLR Table-valued Function'
		when 21577 then 'Internal Table (For example, XML Node Table, Queue Table.)'
		when 21581 then 'Service Broker Message Type'
		when 21586 then 'Service Broker Route'
		when 21587 then 'Statistics'
		when 21825 then 'User'
		when 21827 then 'User'
		when 21831 then 'User'
		when 21843 then 'User'
		when 21847 then 'User'
		when 22099 then 'Service Broker Service'
		when 22601 then 'Index'
		when 22604 then 'Certificate Login'
		when 22611 then 'XMLSchema'
		when 22868 then 'Type'
		else cast(t.ObjectType as varchar(10))
	  end ObjectType
	, e.name EventName
from
	::fn_trace_gettable(@path, default) t
join
	sys.trace_events e on e.trace_event_id=t.EventClass
where
	t.DatabaseName=N'SMS_DEV'
	and t.ObjectType=16964 -- Database
	--and e.trace_event_id in (46,47)  -- Object:Created, Object:Delete
order by
	t.StartTime;


