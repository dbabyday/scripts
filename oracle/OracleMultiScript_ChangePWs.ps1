# get the db username
$username = Read-Host -Prompt "Username"

# get the db password
$securedValue = Read-Host -Prompt "Current Password" -AsSecureString
$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securedValue)
$pw = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)

# get the new password
$securedValue = Read-Host -Prompt "New Password" -AsSecureString
$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securedValue)
$npw = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
$sqlCmd = 'alter user ' + $username + ' identified by "' + $npw + '";'

# databases against which you want to execute the script
$databases = @(
          "agldev01"
        , "agltrn01"
        , "ampd01"
        , "amts01"
        , "arcdv01"
        , "arcpd01"
        , "bchpd01"
        , "bir"
        , "bondv01"
        , "bonpd01"
        , "bonqa01"
        , "ebsappd1"
        , "ebsaput1"
        , "ebsdv01"
        , "ebspd01"
        , "ebssb01"
        , "ebsts01"
        , "ebsupkpd"
        , "ggpy01"
        , "hz1s"
        , "iccm"
        , "iccn"
        , "iccx"
        , "jabprd01"
        , "jdecv01"
        , "jdedv01"
        , "jdepd01"
        , "jdepd03"
        , "jdepr01"
        , "jdepy01"
        , "jdetr01"
        , "jsprpd"
        , "jsprpy"
        , "knxpd01"
        , "oemdv01"
        , "oemprd01"
        , "olmdv01"
        , "pg2s"
        , "pg3s"
        , "plx"
        , "plxdv01"
        , "psfpd01"
        , "rmnpd01"
        , "uc4np01"
        , "windv02"
        , "winpc02"
        , "winpd02"
        , "winqa02"
        , "wintmp02"
              )
<#



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
        $sqlCmd | sqlplus -s $username/$pw@$db
    }
    Start-Sleep -S 1
#}


# clean up
Remove-Variable -Name bstr
Remove-Variable -Name databases
Remove-Variable -Name db
Remove-Variable -Name pw
Remove-Variable -Name securedValue
Remove-Variable -Name sqlCmd
Remove-Variable -Name username