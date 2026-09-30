$SqlServers = @()

<#

	# GSF
	[PSCustomObject]@{SqlServer = 'acc-sql-ts-009'; Db = 'master';}
	[PSCustomObject]@{SqlServer = 'dcc-sql-pf-001'; Db = 'master';}
	[PSCustomObject]@{SqlServer = 'acc-sql-dv-001'; Db = 'master';}
	[PSCustomObject]@{SqlServer = 'dcc-sql-dv-017'; Db = 'master';}
	[PSCustomObject]@{SqlServer = 'acc-sql-ts-006'; Db = 'master';}
	[PSCustomObject]@{SqlServer = 'dcc-sql-ts-003'; Db = 'master';}
	[PSCustomObject]@{SqlServer = 'acc-sql-qa-004'; Db = 'master';}
	[PSCustomObject]@{SqlServer = 'dcc-sql-qa-010'; Db = 'master';}
	[PSCustomObject]@{SqlServer = 'xia-sql-qa-008'; Db = 'master';}
	[PSCustomObject]@{SqlServer = 'acc-sql-qa-003'; Db = 'master';}
	[PSCustomObject]@{SqlServer = 'dcc-sql-qa-009'; Db = 'master';}
	[PSCustomObject]@{SqlServer = 'xia-sql-qa-007'; Db = 'master';}
	[PSCustomObject]@{SqlServer = 'acc-sql-pd-001'; Db = 'master';}
	[PSCustomObject]@{SqlServer = 'gcc-sql-pd-023'; Db = 'master';}
	[PSCustomObject]@{SqlServer = 'xia-sql-pd-011'; Db = 'master';}
	[PSCustomObject]@{SqlServer = 'acc-sql-pd-008'; Db = 'master';}
	[PSCustomObject]@{SqlServer = 'gcc-sql-pd-019'; Db = 'master';}
	[PSCustomObject]@{SqlServer = 'xia-sql-pd-010'; Db = 'master';}

	# WMS
	[PSCustomObject]@{SqlServer = 'acc-sql-pd-015'; Db = 'master';}
	[PSCustomObject]@{SqlServer = 'adr-sql-qa-003'; Db = 'master';}
	[PSCustomObject]@{SqlServer = 'gcc-sql-pd-014'; Db = 'master';}
	[PSCustomObject]@{SqlServer = 'dcc-sql-qa-014'; Db = 'master';}
	[PSCustomObject]@{SqlServer = 'xia-sql-pd-019'; Db = 'master';}
	[PSCustomObject]@{SqlServer = 'xia-sql-qa-010'; Db = 'master';}

	#cmMES
	[PSCustomObject]@{SqlServer = 'dcc-sql-sb-002'; Db = 'master';}
	[PSCustomObject]@{SqlServer = 'dcc-sql-dv-041'; Db = 'master';}
	[PSCustomObject]@{SqlServer = 'dcc-sql-tn-002'; Db = 'master';}
	[PSCustomObject]@{SqlServer = 'dcc-sql-tn-003'; Db = 'master';}
	[PSCustomObject]@{SqlServer = 'dcc-sqlst01n01'; Db = 'master';}
	[PSCustomObject]@{SqlServer = 'dcc-sqlst01n02'; Db = 'master';}
	[PSCustomObject]@{SqlServer = 'gcc-sqlpd07n01'; Db = 'master';}
	[PSCustomObject]@{SqlServer = 'gcc-sqlpd07n02'; Db = 'master';}
	[PSCustomObject]@{SqlServer = 'azt-sql-dv-001'; Db = 'master';}
	[PSCustomObject]@{SqlServer = 'azt-sql-st-001'; Db = 'master';}
	[PSCustomObject]@{SqlServer = 'azt-sql-st-002'; Db = 'master';}
	[PSCustomObject]@{SqlServer = 'adr-sql-sb-001'; Db = 'master';}
	[PSCustomObject]@{SqlServer = 'adr-sql-dv-003'; Db = 'master';}
	[PSCustomObject]@{SqlServer = 'adr-sql-tn-001'; Db = 'master';}
	[PSCustomObject]@{SqlServer = 'adr-sqlst01n01'; Db = 'master';}
	[PSCustomObject]@{SqlServer = 'adr-sqlst01n02'; Db = 'master';}
	[PSCustomObject]@{SqlServer = 'acc-sqlpd01n01'; Db = 'master';}
	[PSCustomObject]@{SqlServer = 'acc-sqlpd01n02'; Db = 'master';}
	[PSCustomObject]@{SqlServer = 'dcc-sqlst04n01'; Db = 'master';}
	[PSCustomObject]@{SqlServer = 'dcc-sqlst04n02'; Db = 'master';}

	# others
	[PSCustomObject]@{SqlServer = 'gcc-sql-pd-063'; Db = 'master';}
	[PSCustomObject]@{SqlServer = 'gcc-sql-pd-041'; Db = 'master';}
#>




$Databases = @(
	[PSCustomObject]@{SqlServer = 'wms-amer-prod-mssql.db.na.plexus.com'; Db = 'master';}
	[PSCustomObject]@{SqlServer = 'wms-apac-prod-mssql.db.ap.plexus.com'; Db = 'master';}
	[PSCustomObject]@{SqlServer = 'wms-xia-prod-mssql.db.ap.plexus.com'; Db = 'master';}
)


$Directory = "\\neen-dsk-011\it$\database\users\James\JamesTools\SqlServerMasterProcs\"
$SqlFiles = @()
$SqlFiles += $Directory + "FirstResponderKit_v8_25.sql"
$SqlFiles += $Directory + "sp_BlitzLock_CustomizedForError_SQLAgent_v8_25.sql"
$SqlFiles += $Directory + "sp_cColumns.sql"
$SqlFiles += $Directory + "sp_cObject.sql"
$SqlFiles += $Directory + "sp_cParams.sql"
$SqlFiles += $Directory + "sp_HumanEvents_v6_6.sql"
$SqlFiles += $Directory + "sp_RaiserrorTime.sql"
$SqlFiles += $Directory + "sp_WhoIsActive_v12_00.sql"



# verify the files exist
$Go_NoGo = "Go"
ForEach ($SqlFile in $SqlFiles) {
	if (-Not (Test-Path -Path $SqlFile)) {
		$Go_NoGo = "NoGo"
		Write-Warning -Message "File does not exist - $SqlFile"
	}
}



# execute the files on the sql servers
if ($Go_NoGo -eq "Go") {
	ForEach ($Database in $Databases) {
		ForEach ($SqlFile in $SqlFiles) {
			$now = Get-Date
			$msg = "$now - " + $Database.SqlServer + " - " + $Database.Db + " - " + $SqlFile
			Write-Host -Object $msg

			Invoke-Sqlcmd -ServerInstance $Database.SqlServer -Database $Database.Db -InputFile $SqlFile
		}
	}
}
else {
	Write-Warning -Message "Skipping execution. Verify and update files before trying again."
}