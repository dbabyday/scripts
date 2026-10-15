
$Databases = @(
	[PSCustomObject]@{ SqlServer = 'gapps-prodfix-mssql.db.na.plexus.com'; Db = 'master'; }
	[PSCustomObject]@{ SqlServer = 'gsf2-apac-prodfix-mssql.db.ap.plexus.com'; Db = 'master'; }
	[PSCustomObject]@{ SqlServer = 'gsf2-pd.db.ap.plexus.com'; Db = 'master'; }
	[PSCustomObject]@{ SqlServer = 'gsf2-pd.db.xiamen.ap.plexus.com'; Db = 'master'; }
	[PSCustomObject]@{ SqlServer = 'gsf2-pd-mssql.db.na.plexus.com'; Db = 'master'; }
	[PSCustomObject]@{ SqlServer = 'gsf2-rpt.db.xiamen.ap.plexus.com'; Db = 'master'; }
	[PSCustomObject]@{ SqlServer = 'gsf2-rpt-amer.db.na.plexus.com'; Db = 'master'; }
	[PSCustomObject]@{ SqlServer = 'gsf-amer-dev-mssql.db.na.plexus.com'; Db = 'master'; }
	[PSCustomObject]@{ SqlServer = 'gsf-amer-qa-mssql.db.na.plexus.com'; Db = 'master'; }
	[PSCustomObject]@{ SqlServer = 'gsf-amer-test-mssql.db.na.plexus.com'; Db = 'master'; }
	[PSCustomObject]@{ SqlServer = 'gsf-apac-qa-mssql.db.ap.plexus.com'; Db = 'master'; }
	[PSCustomObject]@{ SqlServer = 'gsf-apac-test-mssql.db.ap.plexus.com'; Db = 'master'; }
	[PSCustomObject]@{ SqlServer = 'gsf-reporting-amer-qa-mssql.db.na.plexus.com'; Db = 'master'; }
	[PSCustomObject]@{ SqlServer = 'gsf-reporting-apac-qa-mssql.db.ap.plexus.com'; Db = 'master'; }
	[PSCustomObject]@{ SqlServer = 'gsf-reporting-xiam-qa-mssql.db.ap.plexus.com'; Db = 'master'; }
	[PSCustomObject]@{ SqlServer = 'gsf-xiam-qa-mssql.db.ap.plexus.com'; Db = 'master'; }
	[PSCustomObject]@{ SqlServer = 'sql01-pd.db.ap.plexus.com'; Db = 'master'; }
	[PSCustomObject]@{ SqlServer = 'sql-dev.db.ap.plexus.com'; Db = 'master'; }
	[PSCustomObject]@{ SqlServer = 'ssis-amer-prod-mssql.db.na.plexus.com'; Db = 'master'; }
	[PSCustomObject]@{ SqlServer = 'ssis-amer-qa-mssql.db.na.plexus.com'; Db = 'master'; }
	[PSCustomObject]@{ SqlServer = 'ssis-amer-tst-mssql.db.na.plexus.com'; Db = 'master'; }
	[PSCustomObject]@{ SqlServer = 'ssis-apac-prod-mssql.db.ap.plexus.com'; Db = 'master'; }
	[PSCustomObject]@{ SqlServer = 'ssis-apac-qa-mssql.db.ap.plexus.com'; Db = 'master'; }
	[PSCustomObject]@{ SqlServer = 'ssis-apac-tst-mssql.db.ap.plexus.com'; Db = 'master'; }
	[PSCustomObject]@{ SqlServer = 'ssis-xiam-prod-mssql.db.ap.plexus.com'; Db = 'master'; }
	[PSCustomObject]@{ SqlServer = 'ssis-xiam-qa-mssql.db.ap.plexus.com'; Db = 'master'; }
	[PSCustomObject]@{ SqlServer = 'wms-amer-prod-mssql.db.na.plexus.com'; Db = 'master'; }
	[PSCustomObject]@{ SqlServer = 'wms-amer-qa-mssql.db.na.plexus.com'; Db = 'master'; }
	[PSCustomObject]@{ SqlServer = 'wms-apac-prod-mssql.db.ap.plexus.com'; Db = 'master'; }
	[PSCustomObject]@{ SqlServer = 'wms-apac-qa-mssql.db.ap.plexus.com'; Db = 'master'; }
	[PSCustomObject]@{ SqlServer = 'wms-emea-prod-mssql.db.na.plexus.com'; Db = 'master'; }
	[PSCustomObject]@{ SqlServer = 'wms-emea-qa-mssql.db.na.plexus.com'; Db = 'master'; }
	[PSCustomObject]@{ SqlServer = 'wms-hgz-prod-mssql.db.ap.plexus.com'; Db = 'master'; }
	[PSCustomObject]@{ SqlServer = 'wms-hgz-qa-mssql.db.ap.plexus.com'; Db = 'master'; }
	[PSCustomObject]@{ SqlServer = 'wms-xiam-qa-mssql.db.ap.plexus.com'; Db = 'master'; }
	[PSCustomObject]@{ SqlServer = 'wms-xia-prod-mssql.db.ap.plexus.com'; Db = 'master'; }
)



$SqlFiles = @()

#$Directory = "\\neen-dsk-011\it$\database\users\James\JamesScripts\SqlServer\"
$Directory = "\\neen-dsk-011\it$\database\users\James\"

# $SqlFiles += $Directory + "sp_JamesLock.sql"
# $SqlFiles += $Directory + "cQueryPerformanceHist_ByObjectId.sql"
# $SqlFiles += $Directory + "cIndexColumns.sql"
$SqlFiles += $Directory + "a.sql"



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

			Invoke-Sqlcmd -ServerInstance $Database.SqlServer -Database $Database.Db -InputFile $SqlFile | Format-Table -AutoSize
		}
	}
}
else {
	Write-Warning -Message "Skipping execution. Verify and update files before trying again."
}