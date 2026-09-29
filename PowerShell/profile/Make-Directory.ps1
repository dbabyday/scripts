Function Make-Directory {
	<#
		.NOTES
			Name: Make-Directory.ps1
			Author: dbabyday
			Version History:
			1.0 - 20250912 - Initial Release.
		.SYNOPSIS
			Make a new direcotry
		.DESCRIPTION
			Make a new directory
		.PARAMETER $Name
			The name for the new directory
		.PARAMETER $Path
			The location for the new directory - default is the current location
		.EXAMPLE
			PS> Get-DriveSpace -Word cold
	#>

	[CmdletBinding()]

	Param (
		[Parameter(Mandatory = $true)]
		[String] $Name
		,
		[String] $Path = (Get-Location).Path
	)

	Begin {
		# nothing to do here
	}

	Process {
		New-Item -Path $Path -Name $Name -ItemType Directory
	}
	
	End {
		# nothing to do here
	}
}