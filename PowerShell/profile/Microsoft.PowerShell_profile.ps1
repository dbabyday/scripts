



#-------------------------------------
# DISPLAY
#-------------------------------------

# directory
Set-Location -Path \\neen-dsk-011\it$\database\users\James\JamesScripts

# window title
$Shell = $Host.UI.RawUI
if ( $env:USERNAME -eq "james.lutsey" ) {
	$Shell.WindowTitle="james"
}
elseif ( $env:USERNAME -eq "james.lutsey.admin" ) {
	$Shell.WindowTitle=".admin"
}

# display prompt
function prompt { 
	if ($PWD.Path -match "\\\\neen-dsk-011\\it\$\\database\\users\\James") {
		if ( $env:USERNAME -eq "james.lutsey.admin" ) {
			"(.admin)PS ~" + $PWD.Path.Substring($PWD.Path.IndexOf("\James") + 6, $PWD.Path.Length - $PWD.Path.IndexOf("\James") - 6) + "> " 
		}
		else {
			"PS ~" + $PWD.Path.Substring($PWD.Path.IndexOf("\James") + 6, $PWD.Path.Length - $PWD.Path.IndexOf("\James") - 6) + "> " 
		}
	}
	else {
		if ( $env:USERNAME -eq "james.lutsey.admin" ) {
			"(.admin)PS " + $PWD.Path + "> ";
		}
		else {
			"PS " + $PWD.Path + "> ";
		}
		
	}
}




#-------------------------------------
# PREP
#-------------------------------------

# directory for files used to create functions and aliases
$profileDir="\\neen-dsk-011\it$\database\users\James\JamesScripts\PowerShell\profile"




#-------------------------------------
# VARIABLES FOR QUICK REFERENCE
#-------------------------------------

. $profileDir\Set-VariableYeti.ps1


#-------------------------------------
# CNAMEs
#-------------------------------------
$gsfCnames = @(
    [PSCustomObject]@{ Environment = 'PROD';    Region = 'APAC'; Workload = 'OLTP';      CNAME = 'gsf2-pd.db.ap.plexus.com' }
    [PSCustomObject]@{ Environment = 'PROD';    Region = 'APAC'; Workload = 'Reporting'; CNAME = 'sql01-pd.db.ap.plexus.com' }
    [PSCustomObject]@{ Environment = 'PROD';    Region = 'APAC'; Workload = 'SSIS';      CNAME = 'ssis-apac-prod-mssql.db.ap.plexus.com' }
    [PSCustomObject]@{ Environment = 'PROD';    Region = 'AMER'; Workload = 'OLTP';      CNAME = 'gsf2-pd-mssql.db.na.plexus.com' }
    [PSCustomObject]@{ Environment = 'PROD';    Region = 'AMER'; Workload = 'Reporting'; CNAME = 'gsf2-rpt-amer.db.na.plexus.com' }
    [PSCustomObject]@{ Environment = 'PROD';    Region = 'AMER'; Workload = 'SSIS';      CNAME = 'ssis-amer-prod-mssql.db.na.plexus.com' }
    [PSCustomObject]@{ Environment = 'PROD';    Region = 'XIAM'; Workload = 'OLTP';      CNAME = 'gsf2-pd.db.xiamen.ap.plexus.com' }
    [PSCustomObject]@{ Environment = 'PROD';    Region = 'XIAM'; Workload = 'Reporting'; CNAME = 'gsf2-rpt.db.xiamen.ap.plexus.com' }
    [PSCustomObject]@{ Environment = 'PROD';    Region = 'XIAM'; Workload = 'SSIS';      CNAME = 'ssis-xiam-prod-mssql.db.ap.plexus.com' }
    [PSCustomObject]@{ Environment = 'QA';      Region = 'APAC'; Workload = 'OLTP';      CNAME = 'gsf-apac-qa-mssql.db.ap.plexus.com' }
    [PSCustomObject]@{ Environment = 'QA';      Region = 'APAC'; Workload = 'Reporting'; CNAME = 'gsf-reporting-apac-qa-mssql.db.ap.plexus.com' }
    [PSCustomObject]@{ Environment = 'QA';      Region = 'APAC'; Workload = 'SSIS';      CNAME = 'ssis-apac-qa-mssql.db.ap.plexus.com' }
    [PSCustomObject]@{ Environment = 'QA';      Region = 'AMER'; Workload = 'OLTP';      CNAME = 'gsf-amer-qa-mssql.db.na.plexus.com' }
    [PSCustomObject]@{ Environment = 'QA';      Region = 'AMER'; Workload = 'Reporting'; CNAME = 'gsf-reporting-amer-qa-mssql.db.na.plexus.com' }
    [PSCustomObject]@{ Environment = 'QA';      Region = 'AMER'; Workload = 'SSIS';      CNAME = 'ssis-amer-qa-mssql.db.na.plexus.com' }
    [PSCustomObject]@{ Environment = 'QA';      Region = 'XIAM'; Workload = 'OLTP';      CNAME = 'gsf-xiam-qa-mssql.db.ap.plexus.com' }
    [PSCustomObject]@{ Environment = 'QA';      Region = 'XIAM'; Workload = 'Reporting'; CNAME = 'gsf-reporting-xiam-qa-mssql.db.ap.plexus.com' }
    [PSCustomObject]@{ Environment = 'QA';      Region = 'XIAM'; Workload = 'SSIS';      CNAME = 'ssis-xiam-qa-mssql.db.ap.plexus.com' }
    [PSCustomObject]@{ Environment = 'TEST';    Region = 'APAC'; Workload = 'OLTP';      CNAME = 'gsf-apac-test-mssql.db.ap.plexus.com' }
    [PSCustomObject]@{ Environment = 'TEST';    Region = 'APAC'; Workload = 'Reporting'; CNAME = 'gsf-apac-test-mssql.db.ap.plexus.com' }
    [PSCustomObject]@{ Environment = 'TEST';    Region = 'APAC'; Workload = 'SSIS';      CNAME = 'ssis-apac-tst-mssql.db.ap.plexus.com' }
    [PSCustomObject]@{ Environment = 'TEST';    Region = 'AMER'; Workload = 'OLTP';      CNAME = 'gsf-amer-test-mssql.db.na.plexus.com' }
    [PSCustomObject]@{ Environment = 'TEST';    Region = 'AMER'; Workload = 'Reporting'; CNAME = 'gsf-amer-test-mssql.db.na.plexus.com' }
    [PSCustomObject]@{ Environment = 'TEST';    Region = 'AMER'; Workload = 'SSIS';      CNAME = 'ssis-amer-tst-mssql.db.na.plexus.com' }
    [PSCustomObject]@{ Environment = 'DEV';     Region = 'APAC'; Workload = '';          CNAME = 'sql-dev.db.ap.plexus.com' }
    [PSCustomObject]@{ Environment = 'DEV';     Region = 'AMER'; Workload = '';          CNAME = 'gsf-amer-dev-mssql.db.na.plexus.com' }
    [PSCustomObject]@{ Environment = 'PRODFIX'; Region = 'APAC'; Workload = '';          CNAME = 'gsf2-apac-prodfix-mssql.db.ap.plexus.com' }
    [PSCustomObject]@{ Environment = 'PRODFIX'; Region = 'AMER'; Workload = '';          CNAME = 'gapps-prodfix-mssql.db.na.plexus.com' }
)

$wmsCnames = @(
    [PSCustomObject]@{ Environment = 'PROD'; Region = 'APAC'; Workload = ''; CNAME = 'wms-apac-prod-mssql.db.ap.plexus.com' }
    [PSCustomObject]@{ Environment = 'PROD'; Region = 'AMER'; Workload = ''; CNAME = 'wms-amer-prod-mssql.db.na.plexus.com' }
    [PSCustomObject]@{ Environment = 'PROD'; Region = 'EMEA'; Workload = ''; CNAME = 'wms-emea-prod-mssql.db.na.plexus.com' }
    [PSCustomObject]@{ Environment = 'PROD'; Region = 'HGZ';  Workload = ''; CNAME = 'wms-hgz-prod-mssql.db.ap.plexus.com' }
    [PSCustomObject]@{ Environment = 'PROD'; Region = 'XIAM'; Workload = ''; CNAME = 'wms-xia-prod-mssql.db.ap.plexus.com' }
    [PSCustomObject]@{ Environment = 'QA';   Region = 'APAC'; Workload = ''; CNAME = 'wms-apac-qa-mssql.db.ap.plexus.com' }
    [PSCustomObject]@{ Environment = 'QA';   Region = 'AMER'; Workload = ''; CNAME = 'wms-amer-qa-mssql.db.na.plexus.com' }
    [PSCustomObject]@{ Environment = 'QA';   Region = 'EMEA'; Workload = ''; CNAME = 'wms-emea-qa-mssql.db.na.plexus.com' }
    [PSCustomObject]@{ Environment = 'QA';   Region = 'HGZ';  Workload = ''; CNAME = 'wms-hgz-qa-mssql.db.ap.plexus.com' }
    [PSCustomObject]@{ Environment = 'QA';   Region = 'XIAM'; Workload = ''; CNAME = 'wms-xiam-qa-mssql.db.ap.plexus.com' }
)



#-------------------------------------
# FUNCTIONS
#-------------------------------------

#. $profileDir\Get-PathEnvironmentVariable.ps1
. $profileDir\Connect-Psftp.ps1
. $profileDir\Connect-Sqlplus.ps1
. $profileDir\Convert-WordToNumbers.ps1
. $profileDir\Create-SqlServerLoginSysadmin.ps1
. $profileDir\Get-DriveSpace.ps1
. $profileDir\Drop-SqlServerLogin.ps1
. $profileDir\Get-LocalGroupMembers.ps1
. $profileDir\Get-Services.ps1
. $profileDir\Make-Directory.ps1
. $profileDir\Open-VisualStudioCode.ps1
. $profileDir\Publish-SsisIsPac.ps1
. $profileDir\Replace-CharactersSqlplan.ps1
. $profileDir\Resolve-CNameHost.ps1
. $profileDir\Start-ChromeAsRegularAccount.ps1
. $profileDir\Start-PowerShellAsAdmin.ps1
. $profileDir\Start-Ssms.ps1
. $profileDir\To-GB.ps1
. $profileDir\To-KB.ps1
. $profileDir\To-MB.ps1
. $profileDir\To-TB.ps1
. $profileDir\Update-FileLineEndingsUnix.ps1

#-------------------------------------
# ALIASES
#-------------------------------------

# change directories
if (-Not (Get-Alias -Name home -ErrorAction SilentlyContinue)) { Set-Alias -Name home -Value "$profileDir\Set-LocationHome.ps1" }
if (-Not (Get-Alias -Name doc  -ErrorAction SilentlyContinue)) { Set-Alias -Name doc  -Value "$profileDir\Set-LocationDocumentation.ps1" }
if (-Not (Get-Alias -Name dl   -ErrorAction SilentlyContinue)) { Set-Alias -Name dl   -Value "$profileDir\Set-LocationDownloads.ps1" }
if (-Not (Get-Alias -Name p    -ErrorAction SilentlyContinue)) { Set-Alias -Name p    -Value "$profileDir\Set-LocationProjects.ps1" }
if (-Not (Get-Alias -Name q    -ErrorAction SilentlyContinue)) { Set-Alias -Name q    -Value "$profileDir\Set-LocationQueryTuning.ps1" }
if (-Not (Get-Alias -Name s    -ErrorAction SilentlyContinue)) { Set-Alias -Name s    -Value "$profileDir\Set-LocationScripts.ps1" }
if (-Not (Get-Alias -Name swap -ErrorAction SilentlyContinue)) { Set-Alias -Name swap -Value "$profileDir\Set-LocationSwap.ps1" }
if (-Not (Get-Alias -Name t    -ErrorAction SilentlyContinue)) { Set-Alias -Name t    -Value "$profileDir\Set-LocationJamesTools.ps1" }

# directory/file/drive info
if (-Not (Get-Alias -Name dirs     -ErrorAction SilentlyContinue)) { Set-Alias -Name dirs     -Value "$profileDir\Get-Directories.ps1" }
if (-Not (Get-Alias -Name dirsize  -ErrorAction SilentlyContinue)) { Set-Alias -Name dirsize  -Value "$profileDir\Get-DirectorySize.ps1" }
if (-Not (Get-Alias -Name fn       -ErrorAction SilentlyContinue)) { Set-Alias -Name fn       -Value "$profileDir\Get-ChildItemFullName.ps1" }
if (-Not (Get-Alias -Name gds      -ErrorAction SilentlyContinue)) { Set-Alias -Name gds      -Value "Get-DriveSpace" }
if (-Not (Get-Alias -Name ll       -ErrorAction SilentlyContinue)) { Set-Alias -Name ll       -Value "$profileDir\Get-ChildItemSortName.ps1" }
if (-Not (Get-Alias -Name lt       -ErrorAction SilentlyContinue)) { Set-Alias -Name lt       -Value "$profileDir\Get-ChildItemSortLastWriteTime.ps1" }
if (-Not (Get-Alias -Name glogin   -ErrorAction SilentlyContinue)) { Set-Alias -Name glogin   -Value "$profileDir\Get-glogin.ps1" }
if (-Not (Get-Alias -Name mkdir    -ErrorAction SilentlyContinue)) { Set-Alias -Name mkdir    -Value "Make-Directory" }
if (-Not (Get-Alias -Name tnsnames -ErrorAction SilentlyContinue)) { Set-Alias -Name tnsnames -Value "$profileDir\Get-tnsnames.ps1" }
if (-Not (Get-Alias -Name ule      -ErrorAction SilentlyContinue)) { Set-Alias -Name ule      -Value "Update-FileLineEndingsUnix" }

# open applicaitons
if (-Not (Get-Alias -Name ca     -ErrorAction SilentlyContinue)) { Set-Alias -Name ca     -Value "$profileDir\Open-CyberArk.ps1" }
if (-Not (Get-Alias -Name chrome -ErrorAction SilentlyContinue)) { Set-Alias -Name chrome -Value "Start-ChromeAsRegularAccount" }
if (-Not (Get-Alias -Name citrix -ErrorAction SilentlyContinue)) { Set-Alias -Name citrix -Value "C:\Program Files (x86)\Citrix\ICA Client\SelfServicePlugin\SelfService.exe" }
if (-Not (Get-Alias -Name cv     -ErrorAction SilentlyContinue)) { Set-Alias -Name cv     -Value "$profileDir\Start-CommVault.ps1" }
if (-Not (Get-Alias -Name np     -ErrorAction SilentlyContinue)) { Set-Alias -Name np     -Value "C:\Program Files\Notepad++\notepad++.exe" }
if (-Not (Get-Alias -Name psa    -ErrorAction SilentlyContinue)) { Set-Alias -Name psa    -Value "Start-PowerShellAsAdmin" }
if (-Not (Get-Alias -Name rdp    -ErrorAction SilentlyContinue)) { Set-Alias -Name rdp    -Value "$profileDir\Open-RDP.ps1" }
if (-Not (Get-Alias -Name ssms   -ErrorAction SilentlyContinue)) { Set-Alias -Name ssms   -Value "Start-Ssms" }
if (-Not (Get-Alias -Name subl   -ErrorAction SilentlyContinue)) { Set-Alias -Name subl   -Value "C:\Program Files\Sublime Text\sublime_text.exe" }
if (-Not (Get-Alias -Name toad   -ErrorAction SilentlyContinue)) { Set-Alias -Name toad   -Value "$profileDir\Open-ToadForOracle.ps1" }
if (-Not (Get-Alias -Name vsc    -ErrorAction SilentlyContinue)) { Set-Alias -Name vsc    -Value "Open-VisualStudioCode" }
if (-Not (Get-Alias -Name vscp   -ErrorAction SilentlyContinue)) { Set-Alias -Name vscp   -Value "$profileDir\Open-VisualStudioCode_PowerShellProfile.ps1" }

# other
if (-Not (Get-Alias -Name c    -ErrorAction SilentlyContinue)) { Set-Alias -Name c    -Value "$profileDir\Clear-Clipboard.ps1" }
if (-Not (Get-Alias -Name cm   -ErrorAction SilentlyContinue)) { Set-Alias -Name cm   -Value "$profileDir\Get-cmMesServers.ps1" }
if (-Not (Get-Alias -Name cwn  -ErrorAction SilentlyContinue)) { Set-Alias -Name cwn  -Value "Convert-WordToNumbers" }
if (-Not (Get-Alias -Name de   -ErrorAction SilentlyContinue)) { Set-Alias -Name de   -Value "$profileDir\Get-DbaEmails.ps1" }
if (-Not (Get-Alias -Name gs   -ErrorAction SilentlyContinue)) { Set-Alias -Name gs   -Value "Get-Services" }
if (-Not (Get-Alias -Name gsa  -ErrorAction SilentlyContinue)) { Set-Alias -Name gsa  -Value "$profileDir\Get-Sysadmin.ps1" }
if (-Not (Get-Alias -Name gsf  -ErrorAction SilentlyContinue)) { Set-Alias -Name gsf  -Value "$profileDir\Get-GsfServers.ps1" }
if (-Not (Get-Alias -Name lock -ErrorAction SilentlyContinue)) { Set-Alias -Name lock -Value "$profileDir\Lock-Computer.ps1" }
if (-Not (Get-Alias -Name lgm  -ErrorAction SilentlyContinue)) { Set-Alias -Name lgm  -Value "Get-LocalGroupMembers" }
if (-Not (Get-Alias -Name lms  -ErrorAction SilentlyContinue)) { Set-Alias -Name lms  -Value "$profileDir\Set-ClipboardLms.ps1" }
if (-Not (Get-Alias -Name psf  -ErrorAction SilentlyContinue)) { Set-Alias -Name psf  -Value "Connect-Psftp" }
if (-Not (Get-Alias -Name qs   -ErrorAction SilentlyContinue)) { Set-Alias -Name qs   -Value "$profileDir\Get-SsmsQueryShortcuts.ps1" }
if (-Not (Get-Alias -Name rcsp -ErrorAction SilentlyContinue)) { Set-Alias -Name rcsp -Value "Replace-CharactersSqlplan" }
if (-Not (Get-Alias -Name sa   -ErrorAction SilentlyContinue)) { Set-Alias -Name sa   -Value "Create-SqlServerLoginSysadmin" }
if (-Not (Get-Alias -Name sad  -ErrorAction SilentlyContinue)) { Set-Alias -Name sad  -Value "Drop-SqlServerLogin" }
if (-Not (Get-Alias -Name sj   -ErrorAction SilentlyContinue)) { Set-Alias -Name sj   -Value "Connect-Sqlplus" }
if (-Not (Get-Alias -Name tc   -ErrorAction SilentlyContinue)) { Set-Alias -Name tc   -Value "Convert-FahrenheitToCelsius" }
if (-Not (Get-Alias -Name tf   -ErrorAction SilentlyContinue)) { Set-Alias -Name tf   -Value "Convert-CelsiusToFahrenheit" }
if (-Not (Get-Alias -Name usb  -ErrorAction SilentlyContinue)) { Set-Alias -Name usb  -Value "$profileDir\Set-ClipboardUsb" }
if (-Not (Get-Alias -Name wms  -ErrorAction SilentlyContinue)) { Set-Alias -Name wms  -Value "$profileDir\Get-WmsServers.ps1" }
if (-Not (Get-Alias -Name y    -ErrorAction SilentlyContinue)) { Set-Alias -Name y    -Value "$profileDir\Set-ClipboardYeti" }





#-------------------------------------
# CLEAN UP
#-------------------------------------

#Clear-Host