

use CentralAdmin;


/* USER INPUT */
declare
	  @sample_seconds int = 0            /* 0 = since startup */
	, @Units varchar(20)  = 'seconds';   /* milliseconds, seconds, minutes, hours, days */






/* verify @Units...if not set correctly, default to milliseconds */
IF @Units NOT IN ('milliseconds', 'seconds', 'minutes', 'hours', 'days')
	SET @Units='milliseconds';

/* set the value to convert from ms to the desired @Units */
DECLARE @ConversionFromMs decimal(18,1);
SELECT @ConversionFromMs =
	CASE @Units
		WHEN 'milliseconds' THEN 1.0
		WHEN 'seconds'      THEN 1000.0
		WHEN 'minutes'      THEN 1000.0 * 60
		WHEN 'hours'        THEN 1000.0 * 60 * 60
		WHEN 'days'         THEN 1000.0 * 60 * 60 * 24
	END;






/* format the sample seconds into a parameter we can use in waitfor delay */
declare @waitfor varchar(8);
set @waitfor =
	right('0' + cast(@sample_seconds / 3600 as varchar(2)), 2) + ':' +
	right('0' + cast((@sample_seconds % 3600) / 60 as varchar(2)), 2) + ':' +
	right('0' + cast(@sample_seconds % 60 as varchar(2)), 2);


/* get some startup time and cpu count */
declare @sqlserver_start_time datetime, @cpu_count int;
select @sqlserver_start_time=sqlserver_start_time, @cpu_count=cpu_count from sys.dm_os_sys_info;


/* temp tables to store metrics from separate times */
create table #Waits1 (
	  wait_category nvarchar(128)
	, wait_type nvarchar(60)
	, wait_time_ms bigint
	, check_date datetime
);

create table #Waits2 (
	  wait_category nvarchar(128)
	, wait_type nvarchar(60)
	, wait_time_ms bigint
	, check_date datetime
);



/* get the first set of metrics */
insert into #Waits1 (
	  wait_category
	, wait_type
	, wait_time_ms
	, check_date
)
select
	  coalesce(cat.WaitCategory,'Other')
	, os.wait_type
	, case
		when @sample_seconds > 0 then os.wait_time_ms
		else 0
	  end
	, case
		when @sample_seconds > 0 then getdate()
		else @sqlserver_start_time
	  end
from
	sys.dm_os_wait_stats os
left join
	dbo.BlitzFirst_WaitStats_Categories cat on cat.WaitType=os.wait_type
where 
	not exists(
		select
			1
		from
			dbo.BlitzFirst_WaitStats_Categories cat
		where
			cat.Ignorable=1
			and cat.WaitType=os.wait_type
	);






/* delay for the designated sample time */
waitfor delay @waitfor;





/* get the second set of metrics */
insert into #Waits2 (
	  wait_category
	, wait_type
	, wait_time_ms
	, check_date
)
select
	  coalesce(cat.WaitCategory,'Other')
	, os.wait_type
	, os.wait_time_ms
	, getdate()
from
	sys.dm_os_wait_stats os
left join
	dbo.BlitzFirst_WaitStats_Categories cat on cat.WaitType=os.wait_type
where 
	not exists(
		select
			1
		from
			dbo.BlitzFirst_WaitStats_Categories cat
		where
			cat.Ignorable=1
			and cat.WaitType=os.wait_type
	);






declare @time1 datetime, @time2 datetime;
select top(1) @time1=check_date from #Waits1;
select top(1) @time2=check_date from #Waits2;


/* ratio and totals */
select
	  cast(round((sum(w2.wait_time_ms-w1.wait_time_ms) / 1000.0) / (datediff(second,@time1,@time2)) / @cpu_count,1) as decimal(18,1)) AS WaitTimeRatio
	, cast(round(sum(w2.wait_time_ms-w1.wait_time_ms) / @ConversionFromMs,0) as int) wait_time
	, CASE
		WHEN @Units = 'milliseconds' THEN DATEDIFF(MILLISECOND, @time1, @time2)
		WHEN @Units = 'seconds' THEN DATEDIFF(SECOND, @time1, @time2)
		WHEN @Units = 'minutes' THEN DATEDIFF(MINUTE, @time1, @time2)
		WHEN @Units = 'hours' THEN DATEDIFF(HOUR, @time1, @time2)
		WHEN @Units = 'days' THEN DATEDIFF(DAY, @time1, @time2)
	  END AS sample_duration
	, @cpu_count as cpu_count
	, @time1 as sample_start_time
	, @time2 as sample_end_time
	, @sqlserver_start_time as sqlserver_start_time
	, @Units as Units
from
	#Waits1 w1
join
	#Waits2 w2 on w2.wait_category=w1.wait_category and w2.wait_type=w1.wait_type;









/* individual wait types */
select
	  w1.wait_category
	, w1.wait_type
	, cast(round((w2.wait_time_ms - w1.wait_time_ms) / @ConversionFromMs,0) as int) as wait_time
	, cast(round((w2.wait_time_ms - w1.wait_time_ms) * 100.0 / sum(w2.wait_time_ms - w1.wait_time_ms) over(),0) as int) as percent_wait_time
	, cast(round(((w2.wait_time_ms - w1.wait_time_ms) / 1000.0) / (datediff(second,@time1,@time2)) / @cpu_count,1) as decimal(19,1)) AS WaitTimeRatio
	, @Units AS Units
from
	#Waits1 w1
join
	#Waits2 w2 on w2.wait_category=w1.wait_category and w2.wait_type=w1.wait_type
order by
	  wait_time desc
	, percent_wait_time desc;








/* Reference */
SELECT '0' as WaitTimeRatio, 'Your server is not doing anything' AS [Wait time per core per sample duration]
UNION ALL
SELECT '1' as WaitTimeRatio, 'Okay' AS [Wait time per core per sample duration]
UNION ALL
SELECT 'Multiple per core' as WaitTimeRatio, 'Now we are working! And should be tuning' AS [Wait time per core per sample duration];




drop table if exists #Waits1;
drop table if exists #Waits2;