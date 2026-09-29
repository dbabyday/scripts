use CentralAdmin;
--select * from dbo.BlitzFirst_PowerBiData;
go
create or alter view dbo.BlitzFirst_PowerBiData as
with
	  CheckDateMinutes as (
		select   ServerName, CheckDate, format(CheckDate, 'yyyy-MM-dd HH:mm') CheckDateRounded
		from     dbo.BlitzFirst
		group by ServerName, CheckDate
	  )
	, CheckDates as (
		select    Minus0Week.ServerName
		        , Minus0Week.CheckDateRounded as Minus0WeekCheckDate
			, Minus1Week.CheckDateRounded as Minus1WeekCheckDate
			, Minus2Weeks.CheckDateRounded as Minus2WeeksCheckDate
			, Minus3Weeks.CheckDateRounded as Minus3WeeksCheckDate
			, Minus4Weeks.CheckDateRounded as Minus4WeeksCheckDate
		from      CheckDateMinutes Minus0Week
		left join CheckDateMinutes Minus1Week on Minus1Week.CheckDateRounded=dateadd(week,-1,Minus0Week.CheckDateRounded)
		left join CheckDateMinutes Minus2Weeks on Minus2Weeks.CheckDateRounded=dateadd(week,-2,Minus0Week.CheckDateRounded)
		left join CheckDateMinutes Minus3Weeks on Minus3Weeks.CheckDateRounded=dateadd(week,-3,Minus0Week.CheckDateRounded)
		left join CheckDateMinutes Minus4Weeks on Minus4Weeks.CheckDateRounded=dateadd(week,-4,Minus0Week.CheckDateRounded)
	  )
	, CpuUtilization as (
		select format(CheckDate, 'yyyy-MM-dd HH:mm') CheckDate, ServerName, Details
		from   dbo.BlitzFirst
		where  Finding='CPU Utilization'
	  )
	, PercentageOfRunnableQueries as (
		select   format(CheckDate, 'yyyy-MM-dd HH:mm') CheckDate, ServerName, max(cast(substring(Details,charindex(', ',Details)+2,charindex('.',Details)-charindex(', ',Details)-2) as int)) Details
		from     dbo.BlitzFirst
		where    Finding='High Percentage Of Runnable Queries'
		group by CheckDate, ServerName
	  )
	, WaitTimePerCorePerSec as (
		select format(CheckDate, 'yyyy-MM-dd HH:mm') CheckDate, ServerName, Details
		from   dbo.BlitzFirst
		where  Finding='Wait Time per Core per Sec'
	  )
	, BatchRequestsPerSec as (
		select format(CheckDate, 'yyyy-MM-dd HH:mm') CheckDate, ServerName, cntr_delta_per_second
		from   dbo.BlitzFirst_PerfmonStats_Deltas
		where  counter_name='Batch Requests/sec'
	  )
	, SqlCompilationsPerSec as (
		select format(CheckDate, 'yyyy-MM-dd HH:mm') CheckDate, ServerName, cntr_delta_per_second
		from   dbo.BlitzFirst_PerfmonStats_Deltas
		where  counter_name='SQL Compilations/sec'
	  )
	, SqlReCompilationsPerSec as (
		select format(CheckDate, 'yyyy-MM-dd HH:mm') CheckDate, ServerName, cntr_delta_per_second
		from   dbo.BlitzFirst_PerfmonStats_Deltas
		where  counter_name='SQL Re-Compilations/sec'
	  )
	, 
	  ForwardedRecordsPerSec as (
		select format(CheckDate, 'yyyy-MM-dd HH:mm') CheckDate, ServerName, cntr_delta_per_second
		from   dbo.BlitzFirst_PerfmonStats_Deltas
		where  counter_name='Forwarded Records/sec'
	  )
	, myMetrics as (
		select    cu.CheckDate
		        , cu.ServerName
		        , format(cu.CheckDate, 'yyyy-MM-dd HH:mm') CheckDateRounded
		        --, dateadd(minute,datediff(minute,'',cu.CheckDate AT TIME ZONE 'UTC'), ' ') CheckDate_UTC
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
		from      CpuUtilization cu
		left join PercentageOfRunnableQueries porq on porq.CheckDate=cu.CheckDate
		join      WaitTimePerCorePerSec wtpcps on wtpcps.CheckDate=cu.CheckDate
		join      BatchRequestsPerSec brps on brps.CheckDate=cu.CheckDate
		join      SqlCompilationsPerSec scps on scps.CheckDate=cu.CheckDate
		join      SqlReCompilationsPerSec srcps on srcps.CheckDate=cu.CheckDate
		join      ForwardedRecordsPerSec frps on frps.CheckDate=cu.CheckDate
	  )
select    mm0.CheckDate
        , mm0.ServerName
        , mm0.[CPU Utilization Pct]
        , mm0.[Percentage Of Runnable Queries]
        , mm0.[Wait Time per Core per Sec]
        , mm0.[Batch Requests/sec]
        , mm0.[SQL Compilations/sec]
        , mm0.[Compilations/Batch Reqests]
        , mm0.[SQL Re-Compilations/sec]
        , mm0.[Re-compilations/Compilations]
        , mm0.[Forwarded Records/sec]
        , mm1.[CPU Utilization Pct] [m1w CPU Utilization Pct]
        , mm1.[Percentage Of Runnable Queries] [m1w Percentage Of Runnable Queries]
        , mm1.[Wait Time per Core per Sec] [m1w Wait Time per Core per Sec]
        , mm1.[Batch Requests/sec] [m1w Batch Requests/sec]
        , mm1.[SQL Compilations/sec] [m1w SQL Compilations/sec]
        , mm1.[Compilations/Batch Reqests] [m1w Compilations/Batch Reqests]
        , mm1.[SQL Re-Compilations/sec] [m1w SQL Re-Compilations/sec]
        , mm1.[Re-compilations/Compilations] [m1w Re-compilations/Compilations]
        , mm1.[Forwarded Records/sec] [m1w Forwarded Records/sec]
        , mm2.[CPU Utilization Pct] [m2w CPU Utilization Pct]
        , mm2.[Percentage Of Runnable Queries] [m2w Percentage Of Runnable Queries]
        , mm2.[Wait Time per Core per Sec] [m2w Wait Time per Core per Sec]
        , mm2.[Batch Requests/sec] [m2w Batch Requests/sec]
        , mm2.[SQL Compilations/sec] [m2w SQL Compilations/sec]
        , mm2.[Compilations/Batch Reqests] [m2w Compilations/Batch Reqests]
        , mm2.[SQL Re-Compilations/sec] [m2w SQL Re-Compilations/sec]
        , mm2.[Re-compilations/Compilations] [m2w Re-compilations/Compilations]
        , mm2.[Forwarded Records/sec] [m2w Forwarded Records/sec]
        , mm3.[CPU Utilization Pct] [m3w CPU Utilization Pct]
        , mm3.[Percentage Of Runnable Queries] [m3w Percentage Of Runnable Queries]
        , mm3.[Wait Time per Core per Sec] [m3w Wait Time per Core per Sec]
        , mm3.[Batch Requests/sec] [m3w Batch Requests/sec]
        , mm3.[SQL Compilations/sec] [m3w SQL Compilations/sec]
        , mm3.[Compilations/Batch Reqests] [m3w Compilations/Batch Reqests]
        , mm3.[SQL Re-Compilations/sec] [m3w SQL Re-Compilations/sec]
        , mm3.[Re-compilations/Compilations] [m3w Re-compilations/Compilations]
        , mm3.[Forwarded Records/sec] [m3w Forwarded Records/sec]
        , mm4.[CPU Utilization Pct] [m4w CPU Utilization Pct]
        , mm4.[Percentage Of Runnable Queries] [m4w Percentage Of Runnable Queries]
        , mm4.[Wait Time per Core per Sec] [m4w Wait Time per Core per Sec]
        , mm4.[Batch Requests/sec] [m4w Batch Requests/sec]
        , mm4.[SQL Compilations/sec] [m4w SQL Compilations/sec]
        , mm4.[Compilations/Batch Reqests] [m4w Compilations/Batch Reqests]
        , mm4.[SQL Re-Compilations/sec] [m4w SQL Re-Compilations/sec]
        , mm4.[Re-compilations/Compilations] [m4w Re-compilations/Compilations]
        , mm4.[Forwarded Records/sec] [m4w Forwarded Records/sec]
from      CheckDates cd
join      myMetrics mm0 on mm0.CheckDateRounded=cd.Minus0WeekCheckDate and mm0.ServerName=cd.ServerName
left join myMetrics mm1 on mm1.CheckDateRounded=cd.Minus1WeekCheckDate and mm1.ServerName=cd.ServerName
left join myMetrics mm2 on mm2.CheckDateRounded=cd.Minus2WeeksCheckDate and mm2.ServerName=cd.ServerName
left join myMetrics mm3 on mm3.CheckDateRounded=cd.Minus3WeeksCheckDate and mm3.ServerName=cd.ServerName
left join myMetrics mm4 on mm4.CheckDateRounded=cd.Minus4WeeksCheckDate and mm4.ServerName=cd.ServerName
go




/*

with
	  CheckDateMinutes as (
		select   ServerName, format(CheckDate, 'yyyy-MM-dd HH:mm') CheckDateRounded
		from     dbo.BlitzFirst
		group by ServerName, CheckDate
	  )
	, CheckDates as (
		select
			  Minus0Week.CheckDateRounded as Minus0WeekCheckDate
			, Minus1Week.CheckDateRounded as Minus1WeekCheckDate
			, Minus2Weeks.CheckDateRounded as Minus2WeeksCheckDate
			, Minus3Weeks.CheckDateRounded as Minus3WeeksCheckDate
			, Minus4Weeks.CheckDateRounded as Minus4WeeksCheckDate
		from
			CheckDateMinutes Minus0Week
		left join
			CheckDateMinutes Minus1Week on Minus1Week.CheckDateRounded=dateadd(week,-1,Minus0Week.CheckDateRounded)
		left join
			CheckDateMinutes Minus2Weeks on Minus2Weeks.CheckDateRounded=dateadd(week,-2,Minus0Week.CheckDateRounded)
		left join
			CheckDateMinutes Minus3Weeks on Minus3Weeks.CheckDateRounded=dateadd(week,-3,Minus0Week.CheckDateRounded)
		left join
			CheckDateMinutes Minus4Weeks on Minus4Weeks.CheckDateRounded=dateadd(week,-4,Minus0Week.CheckDateRounded)
	  )
select * from CheckDates order by Minus0WeekCheckDate;


*/

