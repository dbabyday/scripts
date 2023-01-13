/* -- set up table to store errors

use CentralAdmin;
go
create schema error;
go

use centraladmin;
drop table error.message;
create table error.message (
	  EntryTime datetime2(0)
	, Msg           int
	, Level         int
	, State         int
	, ProcedureName nvarchar(128)
	, Line          int
	, Text          nvarchar(max)
);

*/


begin try
	-- try your stuff here
	select 1;
end try
begin catch
	-- record the error
	insert into CentralAdmin.error.message (EntryTime, Msg, Level, State, ProcedureName, Line, Text)
	select getdate(), error_number(), error_severity(), error_state(), error_procedure(), error_line(), error_message();
	-- rollback transaction
	while @@trancount>0
	begin
		print convert(varchar(19),getdate(),120) + ' - TRANCOUNT: ' + CAST(@@trancount as varchar) + ' - ROLLBACK TRANSACTION;';
		rollback transaction;
	end;
end catch;


-- view errors
select top(10) 
         EntryTime
       , Msg
       , Level
       , State
       , ProcedureName
       , Line
       , Text
from     CentralAdmin.error.message
order by EntryTime desc;