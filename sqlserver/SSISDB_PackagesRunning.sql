
/*
match the operation_guid up with the guid listed in task manager's command line
Task Manager > Details > Right Click on Column Headings > Select columns > Command line
*/

USE ssisdb;

-- see what packages are running
select   object_name
       , start_time
       , end_time
       , operation_guid
from     internal.operations
--where  object_name like '%%'
--where  operation_guid like '%%'
where    start_time is not null and end_time is null
order by start_time desc;

