use ssisdb;

/*

-- find object_name
use ssisdb;
select distinct opr.object_name
from     catalog.operation_messages as msg
join     catalog.operations as opr on opr.operation_id=msg.operation_id
where opr.object_name like '%pact%'
--where msg.message_time>='2022-10-27 16:24:31.000000 -05:00'
--		 and msg.message_time<='2022-10-27 16:39:05.000000 -05:00'

*/


-- get error messages
select
	  opr.object_name 
	, msg.message_time
	--, case msg.message_type
	--	when -1  then 'Unknown'
	--	when 120 then 'Error'
	--	when 110 then 'Warning'
	--	when 70  then 'Information'
	--	when 10  then 'Pre-validate'
	--	when 20  then 'Post-validate'
	--	when 30  then 'Pre-execute'
	--	when 40  then 'Post-execute'
	--	when 60  then 'Progress'
	--	when 50  then 'StatusChange'
	--	when 100 then 'QueryCancel'
	--	when 130 then 'TaskFailed'
	--	when 90  then 'Diagnostic'
	--	when 200 then 'Custom'
	--	when 140 then 'DiagnosticEx'
	--	when 400 then 'NonDiagnostic'
	--	when 80  then 'VariableValueChanged'
	--	else          'other'
	--  end message_type
	, msg.message
from
	catalog.operation_messages as msg
join
	catalog.operations as opr on opr.operation_id=msg.operation_id
where
	opr.object_name='JdeToPACT'
	and msg.message_type=120
	--and msg.message_type in (110,120)
	--and msg.message_time>dateadd(day,-1,getdate())
	--and msg.message_time>='2022-12-12 12:00:00.0000000 -05:00'
	--and msg.message_time<='2022-08-18 09:49:17.0000000 -05:00'
order by
	message_time;


/*

-- get variables
select
	  e.name  environment_name
	, v.name  variable_name
	, v.value
from
	catalog.environments e
join
	catalog.environment_variables v on v.environment_id=e.environment_id
where
	e.name = N'MedtronicTraceability'
order by
	v.name;

*/