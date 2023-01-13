SELECT 
	*,
	'(Get-EventLog -ComputerName "' + [SqlServer] + '" -LogName "System" -Source "Service Control Manager" -EntryType "Information" -Message "*' + [DisplayName] + '*running*" -Newest 1).TimeGenerated;' AS [PowerShell_GetLastStartTime]
FROM
	[CentralAdmin].[dbo].[SqlServerServices]
WHERE
	[ConfirmedDateUTC] > (SELECT CAST(CAST(MAX(ConfirmedDateUTC) AS DATE) AS DATETIME2(0)) FROM [CentralAdmin].[dbo].[SqlServerServices])
	AND [SqlServer] IN ('co-db-070','co-db-043','co-db-967','co-ap-960')
	AND [Name] IN ('MSSQLSERVER','SQLSERVERAGENT')
	AND [State] = 'Running'
ORDER BY
	[SqlServer],
	[Name];

