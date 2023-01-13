Function Get-DriveSpace {
	<#
		.NOTES
			Name: Get-DriveSpace.ps1
			Author: James Lutsey
			Version History:
			1.0 - 20221212 - Initial Release.
		.SYNOPSIS
			Report the drive space for a server
		.DESCRIPTION
			Displays a report of all drives' size and freespace for a server.
		.PARAMETER $ComputerName
			Name of the server to report on.
		.EXAMPLE
			PS> Get-DriveSpace -ComputerName gcc-sql-pd-041
	#>

	[CmdletBinding()]

	Param (
		[Parameter(Mandatory = $true)]
		[String] $ComputerName
	)

	Begin {
		# nothing to do here
	}

	Process {
		Get-WmiObject win32_volume -ComputerName $ComputerName | 
			Where-Object  { $_.Name -NotLike "\\?\Volume*" } | 
			Select-Object PSComputerName,Name,Freespace,Capacity | 
			Sort-Object   Name | 
			Format-Table  -AutoSize PSComputerName,
				Name,
				@{Name="size_GB"; Expression={"{0:N1}" -f (($_.Capacity)/1GB)}; align="right"},
				@{Name="free_GB"; Expression={"{0:N1}" -f (($_.Freespace)/1GB)}; align="right"},
				@{Name="pct_free";Expression={"{0:N0}" -f (($_.Freespace)/($_.Capacity)*100)};align="right"}
	}
	
	End {
		# nothing to do here
	}
}