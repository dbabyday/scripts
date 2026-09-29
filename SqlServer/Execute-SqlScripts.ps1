
$Databases = @(
	[PSCustomObject]@{SqlServer = 'wms-amer-qa-mssql.db.na.plexus.com'; Db = 'Wms_Boi_QA'; }
	[PSCustomObject]@{SqlServer = 'wms-amer-qa-mssql.db.na.plexus.com'; Db = 'Wms_Chi_QA'; }
	[PSCustomObject]@{SqlServer = 'wms-amer-qa-mssql.db.na.plexus.com'; Db = 'Wms_Gdl_QA'; }
	[PSCustomObject]@{SqlServer = 'wms-amer-qa-mssql.db.na.plexus.com'; Db = 'Wms_Kel_QA'; }
	[PSCustomObject]@{SqlServer = 'wms-amer-qa-mssql.db.na.plexus.com'; Db = 'Wms_Mya_QA'; }
	[PSCustomObject]@{SqlServer = 'wms-amer-qa-mssql.db.na.plexus.com'; Db = 'Wms_Nee_QA'; }
	[PSCustomObject]@{SqlServer = 'wms-amer-qa-mssql.db.na.plexus.com'; Db = 'Wms_Nee_TEST'; }
	[PSCustomObject]@{SqlServer = 'wms-amer-qa-mssql.db.na.plexus.com'; Db = 'Wms_Ora_QA'; }
	[PSCustomObject]@{SqlServer = 'wms-amer-qa-mssql.db.na.plexus.com'; Db = 'Wms_PBoi_QA'; }
	[PSCustomObject]@{SqlServer = 'wms-amer-qa-mssql.db.na.plexus.com'; Db = 'Wms_SrvApp_QA'; }
	[PSCustomObject]@{SqlServer = 'wms-amer-qa-mssql.db.na.plexus.com'; Db = 'Wms_SrvChi_QA'; }
	[PSCustomObject]@{SqlServer = 'wms-amer-qa-mssql.db.na.plexus.com'; Db = 'Wms_SrvChi_TEST'; }
	[PSCustomObject]@{SqlServer = 'wms-amer-qa-mssql.db.na.plexus.com'; Db = 'Wms_SrvGdl_QA'; }
	[PSCustomObject]@{SqlServer = 'wms-amer-qa-mssql.db.na.plexus.com'; Db = 'Wms_SrvNee_QA'; }
	[PSCustomObject]@{SqlServer = 'wms-amer-qa-mssql.db.na.plexus.com'; Db = 'Wms_SrvOra_QA'; }

	[PSCustomObject]@{SqlServer = 'wms-apac-qa-mssql.db.ap.plexus.com'; Db = 'Wms_Bgk1_QA'; }
	[PSCustomObject]@{SqlServer = 'wms-apac-qa-mssql.db.ap.plexus.com'; Db = 'Wms_Brg_QA'; }
	[PSCustomObject]@{SqlServer = 'wms-apac-qa-mssql.db.ap.plexus.com'; Db = 'Wms_Hil_QA'; }
	[PSCustomObject]@{SqlServer = 'wms-apac-qa-mssql.db.ap.plexus.com'; Db = 'WMS_Isl_QA'; }
	[PSCustomObject]@{SqlServer = 'wms-apac-qa-mssql.db.ap.plexus.com'; Db = 'WMS_Riv_QA'; }
	[PSCustomObject]@{SqlServer = 'wms-apac-qa-mssql.db.ap.plexus.com'; Db = 'Wms_RVE_QA'; }
	[PSCustomObject]@{SqlServer = 'wms-apac-qa-mssql.db.ap.plexus.com'; Db = 'Wms_Sea_PRODFIX'; }
	[PSCustomObject]@{SqlServer = 'wms-apac-qa-mssql.db.ap.plexus.com'; Db = 'Wms_Sea_QA'; }
	[PSCustomObject]@{SqlServer = 'wms-apac-qa-mssql.db.ap.plexus.com'; Db = 'WMS_Sng_QA'; }

	[PSCustomObject]@{SqlServer = 'wms-xiam-qa-mssql.db.ap.plexus.com'; Db = 'Wms_Hgz_QA'; }
	[PSCustomObject]@{SqlServer = 'wms-xiam-qa-mssql.db.ap.plexus.com'; Db = 'Wms_Hng_QA'; }
	[PSCustomObject]@{SqlServer = 'wms-xiam-qa-mssql.db.ap.plexus.com'; Db = 'Wms_SrvXia_QA'; }
	[PSCustomObject]@{SqlServer = 'wms-xiam-qa-mssql.db.ap.plexus.com'; Db = 'Wms_Xia1_QA'; }
	[PSCustomObject]@{SqlServer = 'wms-xiam-qa-mssql.db.ap.plexus.com'; Db = 'Wms_Xia2_QA'; }
)



$Directory = "\\neen-dsk-011\it$\database\users\James\JamesScripts\SqlServer\"
$SqlFiles = @()
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