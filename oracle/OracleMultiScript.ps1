# set the sql script you want to execute
$sqlScript="OracleMultiScript.sql"
#$sqlScript="OracleMultiScript_cstatus.sql"
#$sqlScript="pw.sql"
#$sqlScript="dmq.sql"

# get the db username
$username = "JLUTSEY"
# ---------------------------------------------------------------------------------------
#$username = Read-Host -Prompt "Username"
# ---------------------------------------------------------------------------------------

# get the db password
$securedValue = $yeti
$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securedValue)
$pw = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
# ---------------------------------------------------------------------------------------
#$securedValue = Read-Host -Prompt "Password" -AsSecureString
#$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securedValue)
#$pw = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
# ---------------------------------------------------------------------------------------



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
		, "cdbdv01"
		, "dbadv01"
		, "ebsappd1"
		, "ebspd01"
		, "ebspvoid"
		, "ebsupkpd"
		, "ggpy01"
		, "hz1s"
		, "iccm"
		, "iccn"
		, "iccx"
		, "jabpd02"
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
		, "winpd02"
		, "winqa02"
			  )
<#



aglav01
aglprd01
aglqa01
aglro01

jdrf01
jdrf02

#>


#while ($true) {

	# run the sql script in each database
	ForEach ($db in $databases) {
		if ($db -in "cdbdv01","dbadv01") {
			$thisUsername="c##$username"
		}
		else {
			$thisUsername=$username
		}
		Write-Host (Get-Date -Format "yyyy-MM-dd HH:mm:ss")" - Connecting to $db"
		sqlplus -s $thisUsername/$pw@$db @$sqlScript
	}

	#Start-Sleep -S 1
#}


# clean up
Remove-Variable -Name bstr
Remove-Variable -Name databases
Remove-Variable -Name db
Remove-Variable -Name pw
Remove-Variable -Name securedValue
Remove-Variable -Name username