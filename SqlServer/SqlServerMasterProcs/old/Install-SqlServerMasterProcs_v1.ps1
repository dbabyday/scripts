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

	$SqlServers += "gcc-sql-pd-041"




$Directory = "\\neen-dsk-011\it$\database\users\James\JamesTools\SqlServerMasterProcs\"
$SqlFiles = @()
$SqlFiles += "FirstResponderKit_v8_25.sql"
$SqlFiles += "sp_BlitzLock_CustomizedForError_SQLAgent_v8_25.sql"
$SqlFiles += "sp_cColumns.sql"
$SqlFiles += "sp_cObject.sql"
$SqlFiles += "sp_cParams.sql"
$SqlFiles += "sp_HumanEvents_v6_6.sql"
$SqlFiles += "sp_RaiserrorTime.sql"
$SqlFiles += "sp_WhoIsActive_v12_00.sql"



# verify the files exist
$Go_NoGo = "Go"
$SqlFiles | ForEach-Object {
	$SqlFile = $Directory + $_

	if (-Not (Test-Path -Path $SqlFile)) {
		$Go_NoGo = "NoGo"
		Write-Warning -Message "File does not exist - $SqlFile"
	}
}



# execute the files on the sql servers
if ($Go_NoGo -eq "Go") {
	$SqlServers | ForEach-Object {
		$SqlServer = $_

		$SqlFiles | ForEach-Object {
			$SqlFile = $Directory + $_

			$now = Get-Date
			"$now - $SqlServer - $SqlFile"
			Invoke-Sqlcmd -ServerInstance $SqlServer -Database master -InputFile $SqlFile
		}
	}
}
else {
	Write-Warning -Message "Skipping execution. Verify and update files before trying again."
}