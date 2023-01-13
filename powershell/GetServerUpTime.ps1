#Function Get-Uptime {
<# .SYNOPSIS
Determine the uptime of a server or group of servers.

.PARAMETER $computername
the name of a server or servers separated by commas that is being targetted
.PARAMETER $inputfile
the filename of a group of servers you are targetting, c:\temp\my-server-list.txt
.EXAMPLES
Get-ServerUptime co-ap-001,co-db-001,co-web-999
Get-ServerUptime c:\temp\my-server-list.txt

#>

Param(
   [Parameter(Mandatory=$False,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,position=0)]
	[array]$computername,
	[Parameter(Mandatory=$False,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,position=1)]
	[string]$inputfile
	)

	if($inputfile) {$computername = GC $inputfile}
	elseif (!$computername ) { Write-host "Please supply a server or list of servers. This can be done via the command line individually or via a text file."
								break
	}
	
#PROCESS {
foreach ($c in $computername) {
$Now=Get-Date
    if (Test-Connection -Computername $c -count 1 -quiet){
        #write-host -ForegroundColor green $_.Name
        #$_.name | get-uptime
        $LastBoot=[System.Management.ManagementDateTimeConverter]::ToDateTime((Get-WmiObject win32_operatingsystem -ComputerName $($c)).lastbootuptime)
        $Result=@{ “Server”=$($c);
        “Last Reboot”=$LastBoot;
        “Time Since Reboot”=”{0} Days {1} Hours {2} Minutes {3} Seconds” -f ($Now – $LastBoot).days, `
        ($Now – $LastBoot).hours,($Now – $LastBoot).minutes,($Now – $LastBoot).seconds}
        Write-Output (New-Object psobject -Property $Result|select Server, “Last Reboot”, “Time Since Reboot”) #|out-host #|Export-Csv -Append c:\temp\results.csv 
    }
    else { 
        $Result=@{ “Server”=$($c);
        “Last Reboot”="Down";
        “Time Since Reboot”=”{0} Days {1} Hours {2} Minutes {3} Seconds” -f (0).days, (0).hours,(0).minutes,(0).seconds}
        Write-Output (New-Object psobject -Property $Result|select Server, “Last Reboot”, “Time Since Reboot”) #|out-host #|Export-Csv -Append c:\temp\results.csv
    }

}