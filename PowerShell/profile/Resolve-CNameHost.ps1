function Resolve-CNameHost {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject[]]$CNames,

        [Parameter(Mandatory = $false)]
        [string[]]$Environment,

        [Parameter(Mandatory = $false)]
        [string[]]$Workload,

        [Parameter(Mandatory = $false)]
        [string[]]$Region,

        [Parameter(Mandatory = $false)]
        [string[]]$SortBy
    )

    begin {
        $allResults = [System.Collections.Generic.List[PSObject]]::new()
    }

    process {
        foreach ($item in $CNames) {
            # Apply Filters (skip processing if item does not match specified criteria)
            if ($Environment -and ($item.Environment -notmatch ($Environment -join '|'))) { continue }
            if ($Workload    -and ($item.Workload    -notmatch ($Workload -join '|')))    { continue }
            if ($Region      -and ($item.Region      -notmatch ($Region -join '|')))      { continue }

            $cname = $item.CNAME
            $hostName = "Resolution Failed / Not a CNAME"

            if (-not [string]::IsNullOrWhiteSpace($cname)) {
                try {
                    $dnsRecord = Resolve-DnsName -Name $cname -Type CNAME -ErrorAction Stop
                    $hostName = ($dnsRecord.NameHost | Select-Object -First 1)
                }
                catch {
                    # Keeps default failure string if resolution fails
                }
            }

            $allResults.Add([PSCustomObject]@{
                Environment = $item.Environment
                Region      = $item.Region
                Workload    = $item.Workload
                CNAME       = $cname
                HostName    = $hostName
            })
        }
    }

    end {
        # Sort results if -SortBy is specified, otherwise return as-is
        if ($SortBy) {
            $allResults | Sort-Object -Property $SortBy
        } else {
            $allResults
        }
    }
}