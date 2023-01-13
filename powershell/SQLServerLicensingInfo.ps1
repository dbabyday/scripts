param([string]$SQLServerList=$(Throw `
"Paramater missing: -SQLServerList ConfigGroup"))


Function Get-CPUInfo
{
    [CmdletBinding()]
    Param ( [parameter(Mandatory = $TRUE,ValueFromPipeline = $TRUE)] [String] $ComputerName )

    Process
    {
        # Get Default SQL Server instance's Edition
        $sqlconn = new-object System.Data.SqlClient.SqlConnection(`
                    "server=$ComputerName;Trusted_Connection=true");
        $query = "SELECT SERVERPROPERTY('Edition') AS Edition;"

        $sqlconn.Open()
        $sqlcmd = new-object System.Data.SqlClient.SqlCommand ($query, $sqlconn);
        $sqlcmd.CommandTimeout = 0;
        $dr = $sqlcmd.ExecuteReader();

        while ($dr.Read()) 
        { 
        	$SQLEdition = $dr.GetValue(0);
        }

        $dr.Close()
        $sqlconn.Close()

        #Get processors information            
        $CPU=Get-WmiObject -ComputerName $ComputerName -class Win32_Processor
        #Get Computer model information
        $OS_Info=Get-WmiObject -ComputerName $ComputerName -class Win32_ComputerSystem
        
        #Reset number of cores
        $Cores = 0
       
        foreach($Processor in $CPU)
        {
            #count the total number of cores         
       		$Cores = $Cores+$Processor.NumberOfCores
        } 
       
        $InfoRecord = New-Object -TypeName PSObject -Property @{
            Server = $ComputerName;
            Model = $OS_Info.Model;
            Cores = $Cores;
            Edition = $SQLEdition;
		}

	   Write-Output $InfoRecord
    }
}

#loop through the server list and get information about CPUs, Cores and Default instance edition
Get-Content $SQLServerList | Foreach-Object {Get-CPUInfo $_ }|Format-Table -AutoSize Server, Model, Edition, Cores