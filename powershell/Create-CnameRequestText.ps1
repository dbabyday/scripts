<######################################################################################################################
# 
# Create-CnameRequestText.ps1
# 
# Author: James Lutsey
# Date:   2018-10-26
# 
# Purpose: Create the text for the "Additional Comments" section of a cname request for an Oracle database server.
# 
# Date        Name                  Description of change
# ----------  --------------------  ---------------------------------------------------------------------------------
# 
# 
######################################################################################################################>

$target   = $null
$dbName   = $null
$ip       = $null
$comments = $null


# user input
Write-Host ""
$target = Read-Host 'Target server name'
$dbName = Read-Host 'Database name'

# get the ip address
$ip = (Test-Connection -ComputerName $target -Count 1).IPV4Address.IPAddressToString

# get the fqdn
nslookup $ip | ForEach-Object {
    If ($_ -match "Name:") {
        $fqdn = ($_).Substring(9,($_).Length - 9)
    }
}

# create the additional comments text
$comments = 'Please create an alias [' + $dbName + '-db.na.plexus.com] that points to [' + $fqdn + ']'

# display results
Write-Host " "
'FQDN       = ' + $fqdn
'IP Address = ' + $ip
'Comments   = ' + $comments
Write-Host " "



# clean up
$target   = $null
$dbName   = $null
$ip       = $null
$comments = $null

