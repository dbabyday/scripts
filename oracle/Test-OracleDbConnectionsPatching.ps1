
# script you want to execute
#$sqlFile = Read-Host "SQL file"
$sqlFile = "cstatus_exit.sql"

# check if sqlFile exists
if (-Not (Test-Path -Path $sqlFile)) {
	Write-Warning -Message "The SQL file, $sqlFile, does not exist"
	return
}

# get the db username
$username = Read-Host -Prompt "Username"

# get the db password
$securedValue = Read-Host -Prompt "Password" -AsSecureString
$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securedValue)
$pw = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)

# databases against which you want to execute the script
# patching
$databases = @(
	  "jdepd01"
	, "jdepd03"
	, "ampd01"
	, "ebsupkpd"
	, "winpd02"
	, "plx"
	, "bir"
	, "bchpd01"
	, "knxpd01"
	, "arcpd01"
	, "hz1s"
	, "iccm"
	, "iccn"
	, "iccx"
	, "pg2s"
	, "pg3s"
	, "jsprpd"
	, "rmnpd01"
	, "jabpd02"
	, "oemprd01"
	, "bonpd01"
	, "psfpd01"
)



# run the sql script in each database
ForEach ($db in $databases) {
	Write-Host (Get-Date -Format "yyyy-MM-dd HH:mm:ss")" - Connecting to $db"
	sqlplus -s $username/$pw@$db "@$sqlFile"
}
Start-Sleep -S 1


# clean up
Remove-Variable -Name bstr
Remove-Variable -Name databases
Remove-Variable -Name db
Remove-Variable -Name pw
Remove-Variable -Name securedValue
Remove-Variable -Name sqlFile
Remove-Variable -Name username