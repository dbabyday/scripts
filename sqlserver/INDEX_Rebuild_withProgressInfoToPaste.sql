-- Paste the rebuild command into @sql
-- selects the info to paste into INDEX_RebuildProgress AND executes the command


DECLARE 
	-- USER INPUT
	@sql NVARCHAR(MAX) = '',
	
	-- other variables
	@progress NVARCHAR(MAX);

IF OBJECT_ID('tempdb..#Command') IS NOT NULL 
	DROP TABLE #Command;
CREATE TABLE #Command
(
	[sql] NVARCHAR(MAX)
);

INSERT INTO #Command ([sql]) VALUES (@sql);

SELECT @progress = N'
USE ' + SUBSTRING(@sql,CHARINDEX('[',@sql,CHARINDEX('ON [',@sql)),CHARINDEX(']',@sql,CHARINDEX('ON [',@sql))-CHARINDEX('[',@sql,CHARINDEX('ON [',@sql))+1) + N';

SET @indexName = ''' + SUBSTRING(@sql,CHARINDEX('[',@sql)+1,CHARINDEX(']',@sql)-CHARINDEX('[',@sql)-1) + ''';
SET @startTime = ''' + CONVERT(VARCHAR(30),GETDATE(),120) + ''';';

SELECT @progress;
GO

DECLARE @sql NVARCHAR(MAX);
SELECT @sql = [sql] FROM #Command;
EXECUTE(@sql);

-- clean up
IF OBJECT_ID('tempdb..#Command') IS NOT NULL 
	DROP TABLE #Command;