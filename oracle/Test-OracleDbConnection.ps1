
# script you want to execute
#$sqlFile = Read-Host "SQL file"
$sqlFile = "Test-OracleDbConnection.sql"

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
$db="jdepd03"



while ($true) {
	# run the sql script in each database
	#Write-Host (Get-Date -Format "yyyy-MM-dd HH:mm:ss")" - Connecting to $db"
	sqlplus -s $username/$pw@$db "@$sqlFile"

	Start-Sleep -S 60
}


# clean up
Remove-Variable -Name bstr
Remove-Variable -Name db
Remove-Variable -Name pw
Remove-Variable -Name securedValue
Remove-Variable -Name sqlFile
Remove-Variable -Name username