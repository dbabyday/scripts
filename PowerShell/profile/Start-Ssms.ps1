Function Start-Ssms {
	<#
		.NOTES
			Name: Start-Ssms.ps1
		.SYNOPSIS
			Start SSMS as .admin account when on VM and regular account on laptop
		.DESCRIPTION
			Start SSMS as .admin account when on VM and regular account on laptop
		.EXAMPLE
			PS> Start-SsmsAsAdmin
	#>

	Process {
		# Use admin account on my vm
		if ($env:computername -eq "WDCCVM0221") {
			$AdminAccount = "NA\james.lutsey.admin"
			
			$cred = New-Object System.Management.Automation.PSCredential ($AdminAccount, $yeti)
			Start-Process -FilePath "C:\Program Files\Microsoft SQL Server Management Studio 22\Release\Common7\IDE\SSMS.exe" -Credential $cred

			Remove-Variable -Name cred
		}
		# use regular account on laptop
		else {
			Start-Process "C:\Program Files\Microsoft SQL Server Management Studio 22\Release\Common7\IDE\SSMS.exe"
		}
	}
}


