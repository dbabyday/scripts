select * from sys.traces


/* stop/close a trace

EXEC sp_trace_setstatus <TraceID>, 0	--<< stop
EXEC sp_trace_setstatus <TraceID>, 2	--<< close

-- get results
SELECT [id],'SELECT * FROM ::fn_trace_gettable(''' + [path] + ''', default);' FROM sys.traces;

*/


