/*

https://blog.sqlauthority.com/2017/10/20/sql-server-turn-optimize-ad-hoc-workloads/

Pinal Dave

Based on the result you can make your own conclusion and change your settings. 
I, personally, prefer to turn Optimize for Ad Hoc Workloads settings on when 
I see AdHoc Percentages between 20-30%. Please note that this value gets reset 
when you restart SQL Server services. Hence, before you change the settings, 
make sure that your server is up for a quite a few days.

*/


WITH 
	totals AS (
		SELECT
			  SUM(CASE WHEN objtype = 'adhoc' THEN size_in_bytes*1.0 ELSE 0.0 END) / 1024.0 / 1024.0 AdHoc_Plan_MB
			, SUM(size_in_bytes*1.0) / 1024.0 / 1024.0 Total_Cache_MB
		FROM
			sys.dm_exec_cached_plans
	)
SELECT
	  CAST(ROUND(AdHoc_Plan_MB,0) AS INT) AdHoc_Plan_MB
	, CAST(ROUND(Total_Cache_MB,0) AS INT) Total_Cache_MB
	, CAST(ROUND(AdHoc_Plan_MB*100.0 / Total_Cache_MB,0) AS INT) AS 'AdHoc %'
FROM
	totals;