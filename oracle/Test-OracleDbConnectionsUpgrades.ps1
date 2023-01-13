
# script you want to execute
#$sqlFile = Read-Host "SQL file"
#$sqlFile = "OracleMultiScript.sql"
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
# upgrades
$databases = @(  "jdepd01"
               , "jdepd03"
               , "bir"
               , "bchpd01"
               , "knxpd01"
              )
<#

# patching
$databases = @(  "mwspd01"
               , "plx"
              )


               , "oemprd01"

aglav01
aglprd01
aglqa01
aglro01

cdbdv01
dbadv01


#>


#while ($true) {
    # run the sql script in each database
    ForEach ($db in $databases) {
        Write-Host (Get-Date -Format "yyyy-MM-dd HH:mm:ss")" - Connecting to $db"
        sqlplus -s $username/$pw@$db "@$sqlFile"
    }
    Start-Sleep -S 1
#}


# clean up
Remove-Variable -Name bstr
Remove-Variable -Name databases
Remove-Variable -Name db
Remove-Variable -Name pw
Remove-Variable -Name securedValue
Remove-Variable -Name sqlFile
Remove-Variable -Name username