-- https://blog.sqlauthority.com/2015/09/12/sql-server-who-dropped-table-or-database/

-- read all available traces.
DECLARE @current VARCHAR(500);
DECLARE @start VARCHAR(500);
DECLARE @indx INT;

SELECT @current = path
FROM sys.traces
WHERE is_default = 1;

SET @current = REVERSE(@current);
SELECT @indx = PATINDEX('%\%', @current);
SET @current = REVERSE(@current);
SET @start = LEFT(@current, LEN(@current) - @indx) + '\log.trc';

-- CHANGE FILER AS NEEDED
SELECT   te.name as event_name
       , tr.DatabaseName
       , tr.ObjectName
       , tr.HostName
       , tr.ApplicationName
       , tr.LoginName
       , tr.StartTime
FROM     sys.fn_trace_gettable(@start, DEFAULT) tr
JOIN     sys.trace_events                       te on tr.EventClass=te.trace_event_id
WHERE    tr.EventClass IN (46,47,164) -- Object:Created, Object:Deleted, Object:Altered
         AND tr.EventSubclass = 0 
         AND tr.DatabaseID <> 2
ORDER BY tr.StartTime DESC;