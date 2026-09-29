$SqlServers = @(
	# GSF
	'acc-sql-pd-001'
	, 'acc-sql-pd-004'
	, 'acc-sql-pd-008'
	, 'acc-sql-pd-025'
	, 'acc-sql-qa-003'
	, 'acc-sql-qa-004'
	, 'acc-sql-ts-001'
	#, 'acc-sql-ts-005'
	, 'adr-sql-dv-004'
	, 'adr-sql-qa-002'
	, 'adr-sql-ts-001'
	, 'adr-sql-ts-009'
	, 'adr-sql-ts-010'
	, 'dcc-sql-dv-032'
	, 'dcc-sql-dv-048'
	, 'dcc-sql-pf-002'
	, 'dcc-sql-qa-009'
	, 'dcc-sql-qa-010'
	, 'dcc-sql-qa-020'
	#, 'dcc-sql-ts-001'
	, 'dcc-sql-ts-010'
	#, 'gcc-sql-pd-007'
	, 'gcc-sql-pd-019'
	, 'gcc-sql-pd-023'
	, 'gcc-sql-pd-034'
	#, 'xia-sql-pd-005'
	, 'xia-sql-pd-010'
	, 'xia-sql-pd-011'
	, 'xia-sql-pd-018'
	#, 'xia-sql-qa-005'
	, 'xia-sql-qa-007'
	, 'xia-sql-qa-008'
	, 'xia-sql-qa-011'

	# WMS
	, 'acc-sql-pd-015'
	, 'adr-sql-qa-003'
	, 'gcc-sql-pd-014'
	, 'dcc-sql-qa-014'
	, 'xia-sql-pd-019'
	, 'xia-sql-qa-010'

	#cmMES
	, 'dcc-sql-sb-002'
	, 'dcc-sql-dv-041'
	, 'dcc-sql-tn-002'
	, 'dcc-sql-tn-003'
	, 'dcc-sqlst01n01'
	, 'dcc-sqlst01n02'
	, 'gcc-sqlpd07n01'
	, 'gcc-sqlpd07n02'
	, 'azt-sql-dv-001'
	, 'azt-sql-st-001'
	, 'azt-sql-st-002'
	, 'adr-sql-sb-001'
	, 'adr-sql-dv-003'
	, 'adr-sql-tn-001'
	, 'adr-sqlst01n01'
	, 'adr-sqlst01n02'
	, 'acc-sqlpd01n01'
	, 'acc-sqlpd01n02'
	, 'dcc-sqlst04n01'
	, 'dcc-sqlst04n02'

	# others
	, 'dcc-sql-dv-031'
	, 'gcc-sql-pd-041'
	, 'gcc-sql-pd-063'
	, 'gcc-sql-pd-325'
)


ForEach ($SqlServer in $SqlServers) {
	$query = "
SELECT @@SERVERNAME AS sql_server, l.name AS LoginName, r.name AS ServerRole
FROM sys.server_principals l
JOIN sys.server_role_members m ON l.principal_id = m.member_principal_id
JOIN sys.server_principals r ON r.principal_id = m.role_principal_id
WHERE l.name = 'NA\james.lutsey' AND r.name = 'sysadmin';
"
	#Write-Host "Checking SQL Server: $SqlServer"
	Invoke-Sqlcmd -ServerInstance $SqlServer -Database master -Query $query
}