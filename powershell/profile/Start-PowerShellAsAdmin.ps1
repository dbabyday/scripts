Function Start-PowerShellAsAdmin {
	<#
		.NOTES
			Name: Start-PowerShellAsAdmin.ps1
		.SYNOPSIS
			Start PowerShell as .admin account
		.DESCRIPTION
			Start PowerShell as .admin account
		.PARAMETER $AccountName
			Name of the account to run the program as
		.EXAMPLE
			PS> Start-PowerShellAsAdmin -AccountName NA\james.lutsey.admin
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

		C:\Windows\system32\RUNAS.exe /user:$AccountName "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
	}
	End {
		# nothing to do here
	}
}