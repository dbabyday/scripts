Function Start-SsmsAsAdmin {
	<#
		.NOTES
			Name: Start-SsmsAsAdmin.ps1
		.SYNOPSIS
			Start SSMS as .admin account
		.DESCRIPTION
			Start SSMS as .admin account
		.PARAMETER $AccountName
			Name of the account to run the program as
		.EXAMPLE
			PS> Start-SsmsAsAdmin -AccountName NA\james.lutsey.admin
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

		C:\Windows\system32\RUNAS.exe /user:$AccountName "C:\Program Files (x86)\Microsoft SQL Server Management Studio 19\Common7\IDE\Ssms.exe"
	}
	End {
		# nothing to do here
	}
}