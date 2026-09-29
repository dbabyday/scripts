<#

wms-apac-prod-mssql.db.ap.plexus.com
wms-amer-prod-mssql.db.na.plexus.com
wms-emea-prod-mssql.db.na.plexus.com
wms-xia-prod-mssql.db.ap.plexus.com
wms-hgz-prod-mssql.db.ap.plexus.com
wms-apac-qa-mssql.db.ap.plexus.com
wms-amer-qa-mssql.db.na.plexus.com
wms-emea-qa-mssql.db.na.plexus.com
wms-xiam-qa-mssql.db.ap.plexus.com
wms-hgz-qa-mssql.db.ap.plexus.com

#>


# List of CNAME aliases to query
$aliases = @(
    "wms-apac-prod-mssql.db.ap.plexus.com",
    "wms-amer-prod-mssql.db.na.plexus.com",
    "wms-emea-prod-mssql.db.na.plexus.com",
    "wms-xia-prod-mssql.db.ap.plexus.com",
    "wms-hgz-prod-mssql.db.ap.plexus.com",
    "wms-apac-qa-mssql.db.ap.plexus.com",
    "wms-amer-qa-mssql.db.na.plexus.com",
    "wms-emea-qa-mssql.db.na.plexus.com",
    "wms-xiam-qa-mssql.db.ap.plexus.com",
    "wms-hgz-qa-mssql.db.ap.plexus.com"
)

# Process each alias and retrieve CNAME records
$results = foreach ($alias in $aliases) {
    try {
        # Query for CNAME records specifically
        $dnsResult = Resolve-DnsName -Name $alias -Type CNAME -ErrorAction Stop | 
                     Where-Object { $_.Type -eq 'CNAME' }

        [PSCustomObject]@{
            Alias    = $alias
            NameHost = $dnsResult.NameHost -join ', '
        }
    }
    catch {
        [PSCustomObject]@{
            Alias    = $alias
            NameHost = "Resolution Failed / Not Found"
        }
    }
}

# Display results formatted as a table
$results | Format-Table -AutoSize