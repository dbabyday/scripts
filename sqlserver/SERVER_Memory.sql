DECLARE 
	@ver		varchar(350),
	@index		int,
	@WinVer		varchar(20),
	@Available	bigint,
	@Installed	bigint,
	@PercentUsed decimal(3,2),
	@DisplayAvailable	decimal(10,2),
	@DisplayInstalled	decimal(10,2);

SELECT @ver = @@VERSION;
SELECT @index = CHARINDEX('Windows NT', @ver) + 11;

SELECT @WinVer = CASE SUBSTRING(@ver, @index, 3)
	WHEN 5.2 THEN '2003 or 2003 R2'
	WHEN 6.0 THEN '2008'
	WHEN 6.1 THEN '2008 R2'
	WHEN 6.2 THEN '2012'
	WHEN 6.3 THEN '2012 R2'
	ELSE 'OTHER'
	END;
	
SELECT @Available = available_physical_memory_kb
FROM sys.dm_os_sys_memory


SELECT @Installed = total_physical_memory_kb
FROM sys.dm_os_sys_memory

SELECT @DisplayAvailable = CONVERT(decimal(22,0),@Available) / 1024 / 1024;
SELECT @DisplayInstalled = CONVERT(decimal(22,0),@Installed) / 1024 / 1024;
SELECT @PercentUsed = ( CONVERT(decimal(20,0),@Installed) - CONVERT(decimal(20,0), @Available) ) / CONVERT(decimal(20,0),@Installed);


select 
	@WinVer AS [ServerVersion], 
	@DisplayAvailable AS [Available(GB)],
	@DisplayInstalled AS [Installed(GB)],
	@PercentUsed AS [PercentUsed];