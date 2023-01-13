/****************************************************************************************************
* 
* troubleshoot_jde_job_queue_status.sql
* 
* Purpose: How to view the status of the JDE job queues
* When you need to do it:  If a user complains that JDE jobs are not processing, or processing slowly.
* 
* Info needed: Ask the user which region has the issue (Americas, Europe, APAC).
* 
****************************************************************************************************/




-- Check the status of the JDE jobs currently running or in queue.  
-- Run the following query in the JDEPD01 database:
select   '10'
       , jcjobsts
       , count(*)
from     SV10920.f986110
where    jcjobsts not in ( 'D', 'E')
group by jcjobsts
union
select   '11'
       , jcjobsts
       , count(*)
from     SV11920.f986110
where    jcjobsts not in ( 'D', 'E')
group by jcjobsts
union
select   '12'
       , jcjobsts
       , count(*)
from     SV12920.f986110
where    jcjobsts not in ( 'D', 'E')
group by jcjobsts
order by 2,1
/

/*
	Example output:
	11 H           1
	10 P           2
	11 P           4
	12 P          10

	Region 10 (AMER) has 2 jobs (P)rocessing.
	Region 11 (EUR) has 4 jobs (P)rocessing and 1 job on (H)old.
	Region 12 (APAC) has 12 jobs (P)rocessing.

	Jobs that are waiting in queue will have a status of W.  When you see jobs 
	starting to accumulate in a W status, this may mean there is a job running 
	longer than anticipated.  JDE has two types of queues – single-threaded, 
	where only one job at a time can run in a job queue, and multi-threaded, 
	where multiple jobs may run concurrently.  The job queue in which a job 
	runs is in the column named JCJOBQUE in the F986110 table.
*/