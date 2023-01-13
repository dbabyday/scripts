/********************************************************************
* 
* CONFIGURATION_MaxMemory.sql
* Date: 2017-02-09
* 
* Purpose: Get the max memory recommendation and the command to set it
* 
* Based on Jonathan Kehayias' blog post:
* https://www.sqlskills.com/blogs/jonathan/how-much-memory-does-my-sql-server-actually-need/
* 
* Leaves memory available for OS:
*     1 GB +
*     1 GB for every 4 GB between 4 - 16 GB server memory +
*     1 GB for every 8 GB over 16 GB server memory
* 
* NOTE: @option = 1 will NOT change the configuration. It will only show the 
*       current and reccomended configuration, and create the command to change it.
* 
************************************************************************/

DECLARE @option BIT, 
        @sql NVARCHAR(MAX);

SET @option = 1; -- 0 = select query, 1 = execute query (does not change configuration, only shows current and reccomeneded)

SET @sql = N'SET NOCOUNT ON;

DECLARE  @serverMemory    DECIMAL(25,5),
         @maxSqlMemory    DECIMAL(25,5),
         @osBase          INT,
         @os4_16          DECIMAL(25,5),
         @osOver16        DECIMAL(25,5),
         @osTotal         DECIMAL(25,5),
         @sqlRecommended  DECIMAL(25,5);

-- get current values
SELECT @serverMemory = ';

IF CAST(LEFT(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(25)),4) AS DECIMAL(5,1)) >= 11.0 -- 2012+
    SET @sql = @sql + 'os.physical_memory_kb/1024.0/1024';
ELSE -- 2005, 2008, 2008R2
    SET @sql = @sql + 'os.physical_memory_in_bytes/1024.0/1024/1024';

SET @sql = @sql + ' FROM sys.dm_os_sys_info AS os;
SELECT @maxSqlMemory = CAST([value_in_use] AS INT) / 1024.0 FROM [sys].[configurations] WHERE [name] = ''max server memory (MB)'';

-- calculate recommended value
SET @osBase = 1;

SET @os4_16 =   CASE
                    WHEN @serverMemory < 4              THEN 0
                    WHEN @serverMemory BETWEEN 4 AND 16 THEN (@serverMemory - 4) / 4
                    WHEN @serverMemory > 16             THEN 4
                END;

SET @osOver16 = CASE
                    WHEN @serverMemory <  16 THEN 0
                    WHEN @serverMemory >= 16 THEN (@serverMemory - 16) / 8
                END;

SET @osTotal        = @osBase + @os4_16 + @osOver16;
SET @sqlRecommended = ROUND(@serverMemory - @osTotal,0);

-- display results
SELECT
    @@SERVERNAME AS [server],
    CAST(@serverMemory AS DECIMAL(21,1))   AS [ServerMemory_GB],
    CAST(@MaxSqlMemory AS DECIMAL(21,1))   AS [MaxSqlMemory_GB],
    CAST(@sqlRecommended AS DECIMAL(21,1)) AS [Recommended SQL Memory],
    CAST(@osTotal AS DECIMAL(21,1))        AS [Recommended OS Memory],
    N''EXECUTE master.sys.sp_configure @configname = ''''max server memory (MB)'''', @configvalue = '' + CAST(CAST(@sqlRecommended AS INT) * 1024 AS NVARCHAR(20)) + N''; RECONFIGURE;'';';

IF @option = 0
    SELECT @sql;
ELSE IF @option = 1
    EXECUTE(@sql); 

