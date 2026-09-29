use CentralAdmin;


if object_id(N'tempdb..#PerformanceBaselines',N'U') is not null
	drop table #PerformanceBaselines;

with
	  CpuUtilization as (
		select CheckDate, Details
		from   dbo.BlitzFirst
		where  Finding='CPU Utilization'
	  )
	, PercentageOfRunnableQueries as (
		select   CheckDate, max(cast(substring(Details,charindex(', ',Details)+2,charindex('.',Details)-charindex(', ',Details)-2) as int)) Details
		from     dbo.BlitzFirst
		where    Finding='High Percentage Of Runnable Queries'
		group by CheckDate
	  )
	, WaitTimePerCorePerSec as (
		select CheckDate, Details
		from   dbo.BlitzFirst
		where  Finding='Wait Time per Core per Sec'
	  )
	, BatchRequestsPerSec as (
		select CheckDate, cntr_delta_per_second
		from   dbo.BlitzFirst_PerfmonStats_Deltas
		where  counter_name='Batch Requests/sec'
	  )
	, SqlCompilationsPerSec as (
		select CheckDate, cntr_delta_per_second
		from   dbo.BlitzFirst_PerfmonStats_Deltas
		where  counter_name='SQL Compilations/sec'
	  )
	, SqlReCompilationsPerSec as (
		select CheckDate, cntr_delta_per_second
		from   dbo.BlitzFirst_PerfmonStats_Deltas
		where  counter_name='SQL Re-Compilations/sec'
	  )
	, 
	  ForwardedRecordsPerSec as (
		select CheckDate, cntr_delta_per_second
		from   dbo.BlitzFirst_PerfmonStats_Deltas
		where  counter_name='Forwarded Records/sec'
	  )
select
	  format(brps.CheckDate, 'yyyy-MM-dd HH:mm') CheckDate
	, format(dateadd(minute,datediff(minute,'',brps.CheckDate AT TIME ZONE 'UTC'), ' '), 'yyyy-MM-dd HH:mm') CheckDate_UTC
	, left(cu.Details,charindex('%',cu.Details)-1) [CPU Utilization Pct]
	, porq.Details [Percentage Of Runnable Queries]
	, cast(wtpcps.Details as decimal(9,2)) [Wait Time per Core per Sec]
	, cast(round(brps.cntr_delta_per_second,0) as int) [Batch Requests/sec]
	, cast(round(scps.cntr_delta_per_second,0) as int) [SQL Compilations/sec]
	, case
		when brps.cntr_delta_per_second <= 0 then 0
		else cast(round(scps.cntr_delta_per_second/brps.cntr_delta_per_second*100,1) as decimal(4,1))
	  end [Compilations/Batch Reqests]
	, cast(round(srcps.cntr_delta_per_second,1) as decimal (9,1)) [SQL Re-Compilations/sec]
	, case
		when scps.cntr_delta_per_second <= 0 then 0
		else cast(round(srcps.cntr_delta_per_second/scps.cntr_delta_per_second*100,1) as decimal(4,1))
	  end [Re-compilations/Compilations]
	, cast(round(frps.cntr_delta_per_second,0) as int) [Forwarded Records/sec]
into
	#PerformanceBaselines
from
	CpuUtilization cu
left join
	PercentageOfRunnableQueries porq on porq.CheckDate=cu.CheckDate
join
	WaitTimePerCorePerSec wtpcps on wtpcps.CheckDate=cu.CheckDate
join
	BatchRequestsPerSec brps on brps.CheckDate=cu.CheckDate
join
	SqlCompilationsPerSec scps on scps.CheckDate=cu.CheckDate
join
	SqlReCompilationsPerSec srcps on srcps.CheckDate=cu.CheckDate
join
	ForwardedRecordsPerSec frps on frps.CheckDate=cu.CheckDate;



declare
	  @startDate datetimeoffset(7)
	, @weeks int = -1;

-- set the time to midnight
set @startDate = dateadd(day, 0, datediff(day, 0, sysdatetimeoffset()));
-- set the date to most recent Monday
set datefirst 2;
set @startDate = dateadd(day,-datepart(weekday,@startDate),@startDate);

while @weeks>=-4 and (select min(CheckDate) from #PerformanceBaselines)<dateadd(week,@weeks+1,@startDate)
begin
	select
		  @@servername [SQL Server]
		, [CheckDate]
		, [CheckDate_UTC]
		, [CPU Utilization Pct]
		, [Percentage Of Runnable Queries]
		, case
			when [Wait Time per Core per Sec] < 0.0 then 0.0
			else [Wait Time per Core per Sec]
		  end [Wait Time per Core per Sec]
		, case
			when [Batch Requests/sec] < 0 then 0
			else [Batch Requests/sec]
		  end [Batch Requests/sec]
		, case
			when [SQL Compilations/sec] < 0 then 0
			else [SQL Compilations/sec]
		  end [SQL Compilations/sec]
		, [Compilations/Batch Reqests]
		, case
			when [SQL Re-Compilations/sec] < 0 then 0
			else [SQL Re-Compilations/sec]
		  end [SQL Re-Compilations/sec]
		, [Re-compilations/Compilations]
		, case
			when [Forwarded Records/sec] < 0 then 0
			else [Forwarded Records/sec]
		  end [Forwarded Records/sec]
	from
		#PerformanceBaselines
	where
		CheckDate >= dateadd(week,@weeks,@startDate)
		and CheckDate < dateadd(week,@weeks+1,@startDate)
	order by
		CheckDate;

	set @weeks = @weeks - 1;
end

	

if object_id(N'tempdb..#PerformanceBaselines',N'U') is not null
	drop table #PerformanceBaselines;