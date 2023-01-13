<######################################################################################################################
# 
# Get-ServiceNowRequestFields.ps1
# 
# Author: James Lutsey
# Date: 2018-08-09
# 
# Purpose: Generate the fields for ServiceNow requests needed for new SQL Server installations
#              - CNAME
#              - Mananged Service Accounts
#              - SSL Certificate
# 
# Date        Name                  Description of change
# ----------  --------------------  ---------------------------------------------------------------------------------
# 
# 
######################################################################################################################>

$serverName  = Read-Host "Server Name"
$environment = Read-Host "Environment (PROD, QA, TEST, TRAIN, DEV)"
$appName     = Read-Host "App Name"
$region      = Read-Host "Region (optional)"



#################################################################
# VERIFY INPUT                                                  #
#################################################################

# test connection
if ( -not (Test-Connection -ComputerName $serverName -Count 1 -Quiet) ) {
    if ( -not (Test-Connection -ComputerName $ServerName -Count 3 -Delay 2 -Quiet) ) {
        Write-Warning "Unable to connect to $serverName"
        Write-Host ""
        Exit
    }
}

# get the ip address
$ip = (Test-Connection -ComputerName $serverName -Count 1).IPV4Address.IPAddressToString

# get the fully qualified domain name
nslookup $ip | ForEach-Object {
    if ($_ -match "Name:") {
        $fqdn = ($_).Substring(9,1).ToUpper() + ($_).Substring(10,($_).Length - 10).ToLower()
    }
}



#################################################################
# CNAME                                                         #
#################################################################

# create the output strings
$displayFqdn = $fqdn + " " * (169 - $fqdn.Length) + "|"

$displayIp   = $ip + " " * (169 - $ip.Length) + "|"

$comments = 'Please create an alias [' + $appName
if ($region -ne '') { 
    $comments += '-' + $region.ToLower()
}
$comments += '-' + $environment.ToLower() + '-mssql.db' + $fqdn.Substring($fqdn.IndexOf('.'),$fqdn.Length - $fqdn.IndexOf('.')) + '] that points to [' + $fqdn + ']'
$displayComments = $comments + " " * (169 - $comments.Length) + "|"

#display
Write-Host ""
Write-Host ""
Write-Host "  ** CNAME (DNS Request) **"
Write-Host "  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
Write-Host "  | FQDN                    | $displayFqdn"
Write-Host "  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
Write-Host "  | IP Address              | $displayIp"
Write-Host "  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
Write-Host "  | Additional Comments     | $displayComments"
Write-Host "  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
Write-Host ""
Write-Host ""



#################################################################
# MANAGED SERVICE ACCOUNTS                                      #
#################################################################

# create the output strings
$srvcAcctName = "Managed Service Accounts | $fqdn"
$displaySrvcAcctName = $srvcAcctName + " " * (169 - $srvcAcctName.Length) + "|"

$appEnv = 'SQL Server - ' + $environment.ToUpper()
$displayAppEnv = $appEnv + " " * (169 - $appEnv.Length) + "|"

$pwSecured1 = "Login entered in SQL Server Configuration Manager."
$pwSecured2 = "Password is not entered."
$displayPwSecured1 = $pwSecured1 + " " * (169 - $pwSecured1.Length) + "|"
$displayPwSecured2 = $pwSecured2 + " " * (169 - $pwSecured2.Length) + "|"

$functionPerf = "Running the services for SQL Server"
$displayFunctionPerf = $functionPerf + " " * (169 - $functionPerf.Length) + "|"

if ($environment -eq 'PROD') {
    $elevPriv1 = "Please add the managed service account for SQL Server service to the following groups. This will give permissions to folders used for SQL Server maintenance activities."
    $elevPriv2 = ""
    $elevPriv3 = "NA\Neenah-US Neen SQL Backups Edit Users in NA"
    $elevPriv4 = "NA\Neenah-US Databackup DEV-SQL-Backups View Users in NA"
}
else {
    $elevPriv1 = "Please add the managed service account for SQL Server service to the following groups. This will give permissions to folders used for SQL Server maintenance activities."
    $elevPriv2 = ""
    $elevPriv3 = "NA\Neenah-US Databackup DEV-SQL-Backups Edit Users in NA"
    $elevPriv4 = "NA\Neenah-US Neen SQL Backups View Users in NA"
}
$dispalayElevPriv1 = $elevPriv1 + " " * (169 - $elevPriv1.Length) + "|"
$dispalayElevPriv2 = $elevPriv2 + " " * (169 - $elevPriv2.Length) + "|"
$dispalayElevPriv3 = $elevPriv3 + " " * (169 - $elevPriv3.Length) + "|"
$dispalayElevPriv4 = $elevPriv4 + " " * (169 - $elevPriv4.Length) + "|"


$comments1 = "Please create managed service accounts for the following services on Dcc-sql-qa-001.na.plexus.com"
$comments2 = ""
$comments3 = "SQL Server service"
$comments4 = "SQL Server Agent service"
$dispalayComments1 = $comments1 + " " * (169 - $comments1.Length) + "|"
$dispalayComments2 = $comments2 + " " * (169 - $comments2.Length) + "|"
$dispalayComments3 = $comments3 + " " * (169 - $comments3.Length) + "|"
$dispalayComments4 = $comments4 + " " * (169 - $comments4.Length) + "|"


#display
Write-Host "  ** Managed Service Accounts (Service Account) **"
Write-Host "  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
Write-Host "  | Service Account Name    | $displaySrvcAcctName"
Write-Host "  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
Write-Host "  | Application Environment | $displayAppEnv"
Write-Host "  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
Write-Host "  | Login Password Secured  | $displayPwSecured1"
Write-Host "  |                         | $displayPwSecured2"
Write-Host "  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
Write-Host "  | Function Performing     | $displayFunctionPerf"
Write-Host "  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
Write-Host "  | Elevated Permissions    | $dispalayElevPriv1"
Write-Host "  |                         | $dispalayElevPriv2"
Write-Host "  |                         | $dispalayElevPriv3"
Write-Host "  |                         | $dispalayElevPriv4"
Write-Host "  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
Write-Host "  | Additional Comments     | $dispalayComments1"
Write-Host "  |                         | $dispalayComments2"
Write-Host "  |                         | $dispalayComments3"
Write-Host "  |                         | $dispalayComments4"
Write-Host "  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
Write-Host ""
Write-Host ""






#################################################################
# SSL CERTIFICATE                                               #
#################################################################

$primaryHost = $fqdn.Substring(0,$fqdn.IndexOf(".")).ToUpper()
$displayPrimaryHost = $primaryHost + " " * (169 - $primaryHost.Length) + "|"

$comments    = "This certificate will be used by SQL Server on $fqdn"
$displayComments = $comments + " " * (169 - $comments.Length) + "|"

#display
Write-Host "  ** SSL Certificate Request **"
Write-Host "  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
Write-Host "  | Common Name             | $displayFqdn"
Write-Host "  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
Write-Host "  | Primary Host            | $displayPrimaryHost"
Write-Host "  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
Write-Host "  | Additional Comments     | $displayComments"
Write-Host "  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
Write-Host ""
Write-Host ""




