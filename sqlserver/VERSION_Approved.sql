SELECT 
	@@SERVERNAME, 
	SERVERPROPERTY('ProductVersion') AS [Version],
	CASE CAST(SERVERPROPERTY('ProductVersion') AS NVARCHAR(128))
		WHEN '8.00.2039'		THEN 'YES'
		WHEN '9.00.5000.00'		THEN 'YES'
		WHEN '9.0.5000.00'		THEN 'YES'
		WHEN '10.00.6000.29'	THEN 'YES'
		WHEN '10.0.6000.29'		THEN 'YES'
		WHEN '10.50.6000.34'	THEN 'YES'
		WHEN '11.0.5058.0'		THEN 'YES'
		WHEN '12.0.4100.1'		THEN 'YES'
		ELSE 'NO'
	END AS [Approved]