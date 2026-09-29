use CentralAdmin;
--select * from dbo.BlitzFirst_PowerBiData;
go
create or alter view dbo.BlitzFirst_PowerBiData as
with
	  CpuUtilization as (
		select CheckDate, ServerName, Details
		from   dbo.BlitzFirst
		where  Finding='CPU Utilization'
	  )
	, PercentageOfRunnableQueries as (
		select   CheckDate, ServerName, max(cast(substring(Details,charindex(', ',Details)+2,charindex('.',Details)-charindex(', ',Details)-2) as int)) Details
		from     dbo.BlitzFirst
		where    Finding='High Percentage Of Runnable Queries'
		group by CheckDate, ServerName
	  )
	, WaitTimePerCorePerSec as (
		select CheckDate, ServerName, Details
		from   dbo.BlitzFirst
		where  Finding='Wait Time per Core per Sec'
	  )
	, BatchRequestsPerSec as (
		select CheckDate, ServerName, cntr_delta_per_second
		from   dbo.BlitzFirst_PerfmonStats_Deltas
		where  counter_name='Batch Requests/sec'
	  )
	, SqlCompilationsPerSec as (
		select CheckDate, ServerName, cntr_delta_per_second
		from   dbo.BlitzFirst_PerfmonStats_Deltas
		where  counter_name='SQL Compilations/sec'
	  )
	, SqlReCompilationsPerSec as (
		select CheckDate, ServerName, cntr_delta_per_second
		from   dbo.BlitzFirst_PerfmonStats_Deltas
		where  counter_name='SQL Re-Compilations/sec'
	  )
	, 
	  ForwardedRecordsPerSec as (
		select CheckDate, ServerName, cntr_delta_per_second
		from   dbo.BlitzFirst_PerfmonStats_Deltas
		where  counter_name='Forwarded Records/sec'
	  )
select    cu.CheckDate
        , brps.CheckDate AT TIME ZONE 'UTC' CheckDate_UTC
        , cast(left(cu.Details,charindex('%',cu.Details)-1) as int) [CPU Utilization Pct]
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
left join PercentageOfRunnableQueries porq     on porq.CheckDate=cu.CheckDate   and porq.ServerName=cu.ServerName  
join      WaitTimePerCorePerSec       wtpcps   on wtpcps.CheckDate=cu.CheckDate and wtpcps.ServerName=cu.ServerName    
join      BatchRequestsPerSec         brps     on brps.CheckDate=cu.CheckDate   and brps.ServerName=cu.ServerName  
join      SqlCompilationsPerSec       scps     on scps.CheckDate=cu.CheckDate   and scps.ServerName=cu.ServerName  
join      SqlReCompilationsPerSec     srcps    on srcps.CheckDate=cu.CheckDate  and srcps.ServerName=cu.ServerName   
join      ForwardedRecordsPerSec      frps     on frps.CheckDate=cu.CheckDate   and frps.ServerName=cu.ServerName;