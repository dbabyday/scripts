/* Run at the distributor on the distribution database 
	gcc-sql-pd-007
	acc-sql-pd-007
	xia-sql-pd-007
*/

--USE distribution;
USE Gsfdistribution_PROD;



/* summary */
select	  p.name publisher
	, da.publisher_db
	, da.publication
	, s.name subscriber
	, da.subscriber_db
	, re.error_code
	, count(1) qty_errors
	, min(re.time) first_time
	, max(re.time) last_time
from 	  MSdistribution_history dh
join	  MSdistribution_agents  da ON dh.agent_id = da.id
join	  MSrepl_errors          re ON dh.error_id = re.id
join	  master.sys.servers     p  ON da.publisher_id = p.server_id
join	  master.sys.servers     s  ON da.subscriber_id = s.server_id
--where	  re.time >= '2021-10-25 00:00:00'
	  -- and re.time <= '2021-10-26 00:00:00'
	  -- dh.error_id <> 0
group by  p.name
	, da.publisher_db
	, da.publication
	, s.name
	, da.subscriber_db
	, re.error_code
order by  min(re.time);



/* individual errors */
select	  re.time
	, p.name publisher
	, da.publisher_db
	, da.publication
	, s.name subscriber
	, da.subscriber_db
	, re.error_code
	, re.error_text
	--, re.xact_seqno
	--, re.command_id
	--, da.publisher_id
	, 'execute dbo.sp_browsereplcmds @xact_seqno_start='''+convert(varchar(100),re.xact_seqno,1)+''', @xact_seqno_end='''+convert(varchar(100),re.xact_seqno,1)+''', @publisher_database_id='+cast(da.publisher_id as varchar(10))+', @command_id='+cast(re.command_id as varchar(10))+';' browsereplcmds
from 	  MSdistribution_history dh
join	  MSdistribution_agents  da ON dh.agent_id = da.id
join	  MSrepl_errors          re ON dh.error_id = re.id
join	  master.sys.servers     p  ON da.publisher_id = p.server_id
join	  master.sys.servers     s  ON da.subscriber_id = s.server_id
--where	  re.time >= '2021-10-25 00:00:00'
	  -- and re.time <= '2021-10-26 00:00:00'
	  -- dh.error_id <> 0
order by  re.time;


