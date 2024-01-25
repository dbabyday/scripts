Function Get-Services {
	<#
		.NOTES
			Name: Get-Services
		.SYNOPSIS
			Get the services for a given computer name and filter on a provided value.
		.DESCRIPTION
			List services for a provided servername. Match the name of the service with a given string value.
		.PARAMETER $ComputerName
			Name fo the computer you to check for services
		.PARAMETER $ServiceNameLike
			String to filter service name like
		.EXAMPLE
			PS> Get-Services -ComputerName dcc-sql-dv-021 -ServiceNameLike SQL
	#>

	[CmdletBinding()]

	Param (
		[Parameter(Mandatory = $true)]
		[String] $ComputerName
		,
		[String] $ServiceNameLike
	)#Param

	Begin {
		# nothing to do here
	}

	Process {
		Get-WmiObject Win32_Service -ComputerName $ComputerName -Filter "name Like '%$ServiceNameLike%' " | 
			select-object State,DisplayName,Name,StartMode,StartName,__Server | 
			Sort-Object DisplayName | 
			Format-Table -AutoSize

		Write-Host '-------------------------------------------'
		Write-Host 'Commands to interact with the service'
		Write-Host '-------------------------------------------'
		Write-Host '        Name :  $sn=''<service_name>'''
		Write-Host '        View :  Get-WmiObject Win32_Service -ComputerName $ComputerName | Where-Object Name -eq $sn'
		Write-Host '        Stop :  Set-Service -ComputerName $ComputerName -Name $sn -Status Stopped -PassThru'
		Write-Host '        Start:  Set-Service -ComputerName $ComputerName -Name $sn -Status Running -PassThru'
		Write-Host
	}
	End {
		# nothing to do here
	}
}