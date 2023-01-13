use CentralAdmin;


-- create temp table to hold combined sessions
if object_id(N'tempdb..#blocking',N'U') is not null drop table #blocking;
create table #blocking (
	  Entry_Date            datetime
	, a_Session_ID          smallint
	, a_Blocking_Session    smallint
	, a_Wait_Type           nvarchar(60)
	, a_Wait_Time           int
	, a_Status              nvarchar(30)
	, a_Database_Name       nvarchar(128)
	, a_Login_Name          nvarchar(128)
	, a_Host_Name           nvarchar(128)
	, a_Program_Name        nvarchar(128)
	, a_Command             nvarchar(32)
	, a_Executing_Statement nvarchar(max)
	, b_Session_ID          smallint
	, b_Blocking_Session    smallint
	, b_Wait_Type           nvarchar(60)
	, b_Wait_Time           int
	, b_Status              nvarchar(30)
	, b_Database_Name       nvarchar(128)
	, b_Login_Name          nvarchar(128)
	, b_Host_Name           nvarchar(128)
	, b_Program_Name        nvarchar(128)
	, b_Command             nvarchar(32)
	, b_Executing_Statement nvarchar(max)
);


insert into #blocking (
	  Entry_Date
	, a_Session_ID
	, a_Blocking_Session
	, a_Wait_Type
	, a_Wait_Time
	, a_Status
	, a_Database_Name
	, a_Login_Name
	, a_Host_Name
	, a_Program_Name
	, a_Command
	, a_Executing_Statement
	, b_Session_ID
	, b_Blocking_Session
	, b_Wait_Type
	, b_Wait_Time
	, b_Status
	, b_Database_Name
	, b_Login_Name
	, b_Host_Name
	, b_Program_Name
	, b_Command
	, b_Executing_Statement
)
select    a.[EntryDate]
	, a.[SessionID]
	, a.[Blocking Session]
	, a.[Wait Type]
	, a.[Wait Time]
	, a.[Status]
	, a.[Database Name]
	, a.[Login Name]
	, a.[Host Name]
	, a.[Program Name]
	, a.[Command]
	, a.[Executing Statement]
	, b.[SessionID]
	, b.[Blocking Session]
	, b.[Wait Type]
	, b.[Wait Time]
	, b.[Status]
	, b.[Database Name]
	, b.[Login Name]
	, b.[Host Name]
	, b.[Program Name]
	, b.[Command]
	, b.[Executing Statement]
from	  dbo.ActiveSessions a
join	  dbo.ActiveSessions b on b.[Blocking Session]=a.SessionID and b.EntryDate=a.EntryDate
where	  a.[Blocking Session]=0
	  and b.[Database Name] = 'TipQA_PRD';


-- cursor to loop through each entry
DECLARE	  @entry_date         datetime
	, @b_session_id       smallint
	, @b_blocking_session smallint;

DECLARE cur_blocking CURSOR LOCAL FAST_FORWARD FOR
	select	  Entry_Date
		, b_Session_ID
		, b_Blocking_Session
	from	  #blocking
	order by  Entry_Date
		, b_Session_ID
		, b_Blocking_Session;

-- delete record if the blocked sessionID and Blocking Session are the same in the next 3 minutes
OPEN cur_blocking;
	FETCH NEXT FROM cur_blocking INTO @entry_date, @b_session_id, @b_blocking_session;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF EXISTS (  select 1
		             from   #blocking 
			     where  Entry_Date > @entry_date
			            and Entry_Date < dateadd(minute,3,@entry_date)
				    and b_Session_ID = @b_session_id
				    and b_Blocking_Session = @b_blocking_session
		          )
		BEGIN
			delete from #blocking
			where Entry_Date = @entry_date
			      and b_Session_ID = @b_session_id
			      and b_Blocking_Session = @b_blocking_session;
		END;

		FETCH NEXT FROM cur_blocking INTO @entry_date, @b_session_id, @b_blocking_session;
	END;
CLOSE cur_blocking;
DEALLOCATE cur_blocking;




-- display results
select	  Entry_Date
	, a_Session_ID
	, a_Blocking_Session
	, a_Wait_Type
	, cast(cast(a_Wait_Time as decimal)/1000/60 as decimal(10,1)) a_wait_minutes
	, a_Status
	, a_Database_Name
	, a_Login_Name
	, a_Host_Name
	, a_Program_Name
	, a_Command
	, a_Executing_Statement
	, b_Session_ID
	, b_Blocking_Session
	, b_Wait_Type
	, cast(cast(b_Wait_Time as decimal)/1000/60 as decimal(10,1)) b_wait_minutes
	, b_Status
	, b_Database_Name
	, b_Login_Name
	, b_Host_Name
	, b_Program_Name
	, b_Command
	, b_Executing_Statement
from	  #blocking
order by  Entry_Date
	, a_Session_ID
	, b_Session_ID;

-- clean up
if object_id(N'tempdb..#blocking',N'U') is not null drop table #blocking;


