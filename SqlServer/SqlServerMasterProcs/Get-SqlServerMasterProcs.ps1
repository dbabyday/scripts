$SqlServers = @()

<#

	# GSF
	$SqlServers += "acc-sql-ts-009"
	$SqlServers += "dcc-sql-pf-001"
	$SqlServers += "acc-sql-dv-001"
	$SqlServers += "dcc-sql-dv-017"
	$SqlServers += "acc-sql-ts-006"
	$SqlServers += "dcc-sql-ts-003"
	$SqlServers += "acc-sql-qa-004"
	$SqlServers += "dcc-sql-qa-010"
	$SqlServers += "xia-sql-qa-008"
	$SqlServers += "acc-sql-qa-003"
	$SqlServers += "dcc-sql-qa-009"
	$SqlServers += "xia-sql-qa-007"
	$SqlServers += "acc-sql-pd-001"
	$SqlServers += "gcc-sql-pd-023"
	$SqlServers += "xia-sql-pd-011"
	$SqlServers += "acc-sql-pd-008"
	$SqlServers += "gcc-sql-pd-019"
	$SqlServers += "xia-sql-pd-010"

	# WMS
	$SqlServers += "acc-sql-pd-015"
	$SqlServers += "adr-sql-qa-003"
	$SqlServers += "gcc-sql-pd-014"
	$SqlServers += "dcc-sql-qa-014"
	$SqlServers += "xia-sql-pd-019"
	$SqlServers += "xia-sql-qa-010"

	#cmMES
	$SqlServers += "dcc-sql-sb-002"
	$SqlServers += "dcc-sql-dv-041"
	$SqlServers += "dcc-sql-tn-002"
	$SqlServers += "dcc-sql-tn-003"
	$SqlServers += "dcc-sqlst01n01"
	$SqlServers += "dcc-sqlst01n02"
	$SqlServers += "gcc-sqlpd07n01"
	$SqlServers += "gcc-sqlpd07n02"
	$SqlServers += "azt-sql-dv-001"
	$SqlServers += "azt-sql-st-001"
	$SqlServers += "azt-sql-st-002"
	$SqlServers += "adr-sql-sb-001"
	$SqlServers += "adr-sql-dv-003"
	$SqlServers += "adr-sql-tn-001"
	$SqlServers += "adr-sqlst01n01"
	$SqlServers += "adr-sqlst01n02"
	$SqlServers += "acc-sqlpd01n01"
	$SqlServers += "acc-sqlpd01n02"
	$SqlServers += "dcc-sqlst04n01"
	$SqlServers += "dcc-sqlst04n02"

	# just a single sql server
	$SqlServers += "gcc-sql-pd-063"
#>



	$SqlServers += "gcc-sql-pd-023"



$MyQuery = "
WITH MyMasterProcs AS (
	          SELECT N'dbo' AS SchemaName, N'sp_Blitz' AS ProcName
	UNION ALL SELECT N'dbo' AS SchemaName, N'sp_BlitzAnalysis' AS ProcName
	UNION ALL SELECT N'dbo' AS SchemaName, N'sp_BlitzBackups' AS ProcName
	UNION ALL SELECT N'dbo' AS SchemaName, N'sp_BlitzCache' AS ProcName
	UNION ALL SELECT N'dbo' AS SchemaName, N'sp_BlitzIndex' AS ProcName
	UNION ALL SELECT N'dbo' AS SchemaName, N'sp_BlitzWho' AS ProcName
	UNION ALL SELECT N'dbo' AS SchemaName, N'sp_DatabaseRestore' AS ProcName
	UNION ALL SELECT N'dbo' AS SchemaName, N'sp_ineachdb' AS ProcName
	UNION ALL SELECT N'dbo' AS SchemaName, N'sp_BlitzFirst' AS ProcName
	UNION ALL SELECT N'dbo' AS SchemaName, N'sp_cColumns' AS ProcName
	UNION ALL SELECT N'dbo' AS SchemaName, N'sp_cObject' AS ProcName
	UNION ALL SELECT N'dbo' AS SchemaName, N'sp_cParams' AS ProcName
	UNION ALL SELECT N'dbo' AS SchemaName, N'sp_HumanEvents' AS ProcName
	UNION ALL SELECT N'dbo' AS SchemaName, N'sp_RaiserrorTime' AS ProcName
	UNION ALL SELECT N'dbo' AS SchemaName, N'sp_WhoIsActive' AS ProcName
)
SELECT
	  @@SERVERNAME SqlServer
	, mmp.SchemaName + N'.' + mmp.ProcName AS MyList
	, SCHEMA_NAME(p.schema_id) + N'.' + name AS Existing
	, p.modify_date
FROM
	MyMasterProcs AS mmp
LEFT OUTER JOIN
	sys.procedures AS p ON p.schema_id = SCHEMA_ID(mmp.SchemaName) AND p.name = mmp.ProcName
ORDER BY
	  mmp.SchemaName
	, mmp.ProcName;
"


$dataTables = @()
$SqlServers | ForEach-Object {
	$SqlServer = $_
	$now = Get-Date
	Write-Host "$now - $SqlServer"

	$dataTable = Invoke-Sqlcmd -ServerInstance $SqlServer -Database master -Query $MyQuery -OutputAs DataSet
	$dataTables += $dataTable
}


$dataTables | ForEach-Object {
    $dataSet = $_
    $dataSet.Tables | ForEach-Object {
        $dataTable = $_
        $dataTable | Format-Table -AutoSize
    }
}