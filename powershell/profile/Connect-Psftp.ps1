Function Connect-Psftp {
	<#
		.NOTES
			Name: Connect-Sqlplus.ps1
			Author: James Lutsey
			Version History:
			1.0 - 20230111 - Initial Release.
		.SYNOPSIS
			Start sqlplus with db username jlutsey and provided db name
		.DESCRIPTION
			Start sqlplus with db username jlutsey and provided db name
		.PARAMETER $DatabaseName
			Name of the database to connect to
		.PARAMETER $Username
			Database username to connect with
			Default value is JLUTSEY
		.EXAMPLE
			PS> Connect-Sqlplus -DatabaseName jdedv01
	#>

	[CmdletBinding()]

	Param (
		[Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
		[ValidateNotNullorEmpty()]
		[String] $ServerName = "gcc-ora-pd-005"
	)#Param

	Begin {
		# nothing to do here
	}

	Process {
		$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($yeti)
		$yeti2 = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
		Set-Clipboard -Value $yeti2
		Remove-Variable -Name yeti2

		Write-Output "cd /orahome/admin/jdepd03/adhoc/james"

		psftp james.lutsey.admin@$ServerName
	}
	End {
		# nothing to do here
	}
}