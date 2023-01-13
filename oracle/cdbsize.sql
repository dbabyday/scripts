

column myorder noprint
column category format a8
column gb format 999,999

break on report
compute sum label Total of gb on report

select
	  'Used' category
	, round(sum(bytes)/1024/1024/1024,0) gb
	, 1 myorder from dba_extents
union all
select
	  'Free' category
	, round(sum(bytes)/1024/1024/1024,0) gb
	, 2 myorder from dba_free_space
union all
select
	  'Temp' category
	, round(sum(bytes)/1024/1024/1024,0) gb
	, 3 myorder from dba_temp_files
order by
	myorder;

clear computes
clear breaks