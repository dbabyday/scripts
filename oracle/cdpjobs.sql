col owner_name format a15
col job_name format a25
col operation format a10
col job_mode format a10
col state format a15

select * from dba_datapump_jobs order by owner_name, job_name;
