use CentralAdmin;


/*===========================*/
/*== SET UP                ==*/
/*===========================*/

declare
	  @who_is_active_results_database sysname     = 'CentralAdmin'
	, @who_is_active_results_schema   sysname     = 'blocking'
	, @who_is_active_results_table    varchar(50) = 'who_is_active'
	, @schema                         varchar(max);

set @who_is_active_results_table = @who_is_active_results_database + '.' + @who_is_active_results_schema + '.' + @who_is_active_results_table;

/* make sure we have the sp_WhoIsActive procedure */
if object_id(N'master.dbo.sp_WhoIsActive') is null
begin
	print 'This script uses Adam Machanic''s open source sp_WhoIsActive procedure.';
	print 'Go get it from https://github.com/amachanic/sp_whoisactive/releases and create it in master.';
	return;
end;

/* make sure we have the blocking schema */
if schema_id(N'blocking') is null 
	execute (N'create schema blocking');

/* make sure we have the who_is_active results table */
if object_id(@who_is_active_results_table) is null
begin;
	execute sp_WhoIsActive
		  @get_transaction_info = 1
		, @get_outer_command = 1
		, @get_plans = 1
		, @get_task_info=2
		, @get_additional_info=1
		, @return_schema = 1
		, @schema = @schema OUTPUT;
	set @schema = REPLACE(@schema, '<table_name>', @who_is_active_results_table);
	execute ( @schema );
end;

/* make sure we have the blocking chain table */
if object_id(N'blocking.blocking_chain') is null
begin
	select *
	into   blocking.blocking_chain
	from   blocking.who_is_active
	where  1=0;

	alter table blocking.blocking_chain add order_id int;
	alter table blocking.blocking_chain add level_id int;
end;





/*===========================*/
/*== DO THE WORK           ==*/
/*===========================*/

declare
	  @session_id          smallint
	, @blocking_session_id smallint
	, @order_id            int = 1
	, @level_id            int = 0
	, @qty                 int;

/* cursor for lead blockers */
declare cur_leadBlockers cursor local fast_forward for
	select   distinct blocker.session_id
	from     blocking.who_is_active blocked
	join     blocking.who_is_active blocker on blocker.session_id = blocked.blocking_session_id
	where    blocker.blocking_session_id is null
	order by blocker.session_id;

/* make sure our tables do not have any old results */
truncate table blocking.who_is_active;
truncate table blocking.blocking_chain;

/* get the sessions */
execute sp_WhoIsActive
	  @get_transaction_info = 1
	, @get_outer_command = 1
	, @get_plans = 1
	, @get_task_info = 2
	, @get_additional_info = 1
	, @destination_table = @who_is_active_results_table;

/* loop through the lead blockers */
open cur_leadBlockers;
	fetch next from cur_leadBlockers into @session_id;

	while @@fetch_status = 0
	begin
		/* insert the lead blocker */
		insert into blocking.blocking_chain ( order_id,  level_id, [dd hh:mm:ss.mss],session_id,sql_text,sql_command,login_name,wait_info,tasks,tran_log_writes,CPU,tempdb_allocations,tempdb_current,blocking_session_id,reads,writes,context_switches,physical_io,physical_reads,query_plan,used_memory,status,tran_start_time,open_tran_count,percent_complete,host_name,database_name,program_name,additional_info,start_time,login_time,request_id,collection_time)
		select                               @order_id, @level_id, [dd hh:mm:ss.mss],session_id,sql_text,sql_command,login_name,wait_info,tasks,tran_log_writes,CPU,tempdb_allocations,tempdb_current,blocking_session_id,reads,writes,context_switches,physical_io,physical_reads,query_plan,used_memory,status,tran_start_time,open_tran_count,percent_complete,host_name,database_name,program_name,additional_info,start_time,login_time,request_id,collection_time
		from   blocking.who_is_active
		where  session_id = @session_id;
		/* always increment the order_id value so we keep the blocking chain results organized */
		set @order_id = @order_id + 1;
		/* increment the level so we look next for sessions blocked by this session...keeping the blocking chain results in order_id */
		set @level_id = @level_id + 1;

		/* drill down and up the blocking levels under this lead blocker */
		while @level_id > 0
		begin
			/* grab the blocking session_id one level up */
			select @blocking_session_id = session_id
			from   blocking.blocking_chain
			where  order_id = (select max(b.order_id) from blocking.blocking_chain b where b.level_id = @level_id - 1);

			/* check how many sessions are blocked by it that we ahve not yet logged */
			select @qty = count(1)
			from   blocking.who_is_active
			where  blocking_session_id = @blocking_session_id
			       and session_id not in (select session_id from blocking.blocking_chain);

			if @qty > 0
			begin
				/* get the next session blocked by it that we have not yet logged */
				select   top(1) @session_id = session_id
				from     blocking.who_is_active
				where    blocking_session_id = @blocking_session_id
				         and session_id not in (select session_id from blocking.blocking_chain)
				order by session_id;

				/* insert the session into our blocking chain results table */
				insert into blocking.blocking_chain ( order_id,  level_id, [dd hh:mm:ss.mss],session_id,sql_text,sql_command,login_name,wait_info,tasks,tran_log_writes,CPU,tempdb_allocations,tempdb_current,blocking_session_id,reads,writes,context_switches,physical_io,physical_reads,query_plan,used_memory,status,tran_start_time,open_tran_count,percent_complete,host_name,database_name,program_name,additional_info,start_time,login_time,request_id,collection_time)
				select                               @order_id, @level_id, [dd hh:mm:ss.mss],session_id,sql_text,sql_command,login_name,wait_info,tasks,tran_log_writes,CPU,tempdb_allocations,tempdb_current,blocking_session_id,reads,writes,context_switches,physical_io,physical_reads,query_plan,used_memory,status,tran_start_time,open_tran_count,percent_complete,host_name,database_name,program_name,additional_info,start_time,login_time,request_id,collection_time
				from   blocking.who_is_active
				where  session_id = @session_id;
				/* always increment the order_id value so we keep the blocking chain results organized */
				set @order_id = @order_id + 1;
				/* increment the level so we look next for sessions blocked by this session...keeping the blocking chain results in order_id */
				set @level_id = @level_id + 1;
			end
			else
			begin
				/* no more session blocked from this blocking session, so go up a level and check for more there */
				set @level_id = @level_id - 1;
			end;
		end;

	        fetch next from cur_leadBlockers into @session_id;
	end;
close cur_leadblockers;
deallocate cur_leadblockers;





/*===========================*/
/*== DISPLAY THE RESULTS   ==*/
/*===========================*/

select	  case
		when level_id = 0 then cast(session_id as varchar(10))
		else replicate('....',level_id) + cast(session_id as varchar(10))
	  end session_id
	, blocking_session_id
	, database_name
	, login_name
	, host_name
	, program_name
	, login_time
	, start_time
	, tran_start_time
	, [dd hh:mm:ss.mss]
	, wait_info
	, status
	, open_tran_count
	, sql_text
	, sql_command
	, query_plan
	, additional_info
	, tasks
	, tran_log_writes
	, CPU
	, tempdb_allocations
	, tempdb_current
	, reads
	, writes
	, context_switches
	, physical_io
	, physical_reads
	, used_memory
	, percent_complete
	, request_id
	, collection_time
from	  blocking.blocking_chain
order by  order_id;