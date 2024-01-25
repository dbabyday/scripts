Function Start-Ssms18AsAdmin {
	<#
		.NOTES
			Name: Start-Ssms18AsAdmin.ps1
		.SYNOPSIS
			Start SSMS 18 as .admin account
		.DESCRIPTION
			Start SSMS 18 as .admin account
		.PARAMETER $AccountName
			Name of the account to run the program as
		.EXAMPLE
			PS> Start-Ssms18AsAdmin -AccountName NA\james.lutsey.admin
	#>

	[CmdletBinding()]

	Param (
		[Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
		[ValidateNotNullorEmpty()]
		[String] $AccountName = "NA\james.lutsey.admin"
	)#Param

	Begin {
		# nothing to do here
	}

	Process {
		$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($yeti)
		$yeti2 = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
		Set-Clipboard -Value $yeti2
		Remove-Variable -Name yeti2

		C:\Windows\system32\RUNAS.exe /user:$AccountName "C:\Program Files (x86)\Microsoft SQL Server Management Studio 18\Common7\IDE\Ssms.exe"
	}
	End {
		# nothing to do here
	}
}