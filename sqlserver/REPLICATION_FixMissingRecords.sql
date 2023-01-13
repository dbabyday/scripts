

/* PROBLEM: Replicated database is missing records */




/*********************************************************************************************************************/
    RAISERROR('Caught you! You don''t really want to run this whole script...setting NOEXEC ON',16,1) WITH NOWAIT;
    SET NOEXEC ON; -- SET NOEXEC OFF;
/*********************************************************************************************************************/




/* 1. Check pending commands in the distribution database
If pending commands is growing, there is probably an error that is stopping replication.
If pending commands is zero, or low and dropping, then replication is probably running okay, and we likely skipped some errors that explain the missing records.
*/



/* 2. Look for errors
An error like "Procedure or function sp_MSins_TestReviewDefectFixLog has too many arguments specified."
	indicates that the insert for a record failed.

Run at the distributor on the distribution database 
	gcc-sql-pd-007
	acc-sql-pd-007
	xia-sql-pd-007
*/
USE Gsfdistribution_PROD
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
go



/* 3. Create a linked server between the subsciber and publisher, or if one exists make sure data transfer is set to true */



/* 4. Use the primary key field to find the range of records that are missing 
You can use a loop like I have here, or just run separate queries on the publication and subsciption databases to compare record counts.
Either way, as you find recourd count differences, keep narrowing the range until it is at a managable size.
*/
use GSF2_APAC_PROD;
-- get the range of ids
select min(reviewdefectfixlogid), max(reviewdefectfixlogid) from test.ReviewDefectFixLog;
-- 
declare @lower_value bigint = 0   /* bottom of the range you want to compare record counts */
      , @upper_value bigint
      , @batch_size  bigint = 1000000000  /* how many ids you want to check record counts at a time */
      , @rows_different bigint;
while @lower_value < 2000000035327411   /* top of range you want to compare record counts */
begin
	set @upper_value = @lower_value + @batch_size;
	select @rows_different = (select count(1) from [ACC-SQL-PD-001].GSF2_APAC_PROD.Test.ReviewDefectFixLog where ReviewDefectFixLogId >= @lower_value and ReviewDefectFixLogId < @upper_value) - 
	                         (select count(1) from                                 Test.ReviewDefectFixLog where ReviewDefectFixLogId >= @lower_value and ReviewDefectFixLogId < @upper_value);
	if @rows_different <> 0
		print 'Lower value: '+cast(@lower_value as varchar(30))+' - Upper value: '+cast(@upper_value as varchar(30))+' - Rows different: ' + cast(@rows_different as varchar(30));
	set @lower_value = @upper_value;
end;
go


/* 5. Insert the missing records in the range you found 
Unless the range is very small, you will probably want to do this in batches to reduce blocking time.
	If the publisher and subscriber are in different regions, you will probably want to do it in smaller batches.
If there is an identity column, you need to set identity_insert on before you can insert a value.
*/
use GSF2_APAC_PROD;
set identity_insert Test.ReviewDefectFixLog on;

declare @lower_value bigint = 63584180000  /* bottom of the range of missing ids*/
      , @upper_value bigint
      , @batch_size  bigint = 1000;  /* how many records you want to join/insert in each batch */
while @lower_value < 63584270000  /* top of your range of missing ids */
begin
	set @upper_value = @lower_value + @batch_size;

	insert into Test.ReviewDefectFixLog (ReviewDefectFixLogId,TimeElapsed,ReferenceIdUnitLocation,SiteId,FocusedFactoryId,Note,UserAccountIdCreatedBy,DateCreated,StationCreatedAt,EquipmentId)
	select    p.ReviewDefectFixLogId,p.TimeElapsed,p.ReferenceIdUnitLocation,p.SiteId,p.FocusedFactoryId,p.Note,p.UserAccountIdCreatedBy,p.DateCreated,p.StationCreatedAt,p.EquipmentId
	from      (  select ReviewDefectFixLogId,TimeElapsed,ReferenceIdUnitLocation,SiteId,FocusedFactoryId,Note,UserAccountIdCreatedBy,DateCreated,StationCreatedAt,EquipmentId
		     from   [ACC-SQL-PD-001].GSF2_APAC_PROD.Test.ReviewDefectFixLog
		     where  ReviewDefectFixLogId >= @lower_value
			    and ReviewDefectFixLogId < @upper_value
		  ) p
	left join (  select ReviewDefectFixLogId
		     from   Test.ReviewDefectFixLog
		     where  ReviewDefectFixLogId >= @lower_value
			    and ReviewDefectFixLogId < @upper_value
		  ) s on s.ReviewDefectFixLogId = p.ReviewDefectFixLogId
	where     s.ReviewDefectFixLogId is null;

	set @lower_value = @upper_value;
end;

set identity_insert Test.ReviewDefectFixLog off;
go


