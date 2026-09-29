Function Start-ChromeAsRegularAccount {
	<#
		.NOTES
			Name: Start-ChromeAsRegularAccount.ps1
		.SYNOPSIS
			Start Chrome as regular account
		.DESCRIPTION
			Start Chrome as regular account
		.EXAMPLE
			PS> Start-ChromeAsRegularAccount
	#>

	Process {
		$RegularAccount = "NA\james.lutsey"
		
		#C:\Windows\system32\RUNAS.exe /user:$RegularAccount "C:\Program Files\Google\Chrome\Application\chrome.exe"
		$cred = New-Object System.Management.Automation.PSCredential ($RegularAccount, $yeti)
		Start-Process -FilePath "C:\Program Files\Google\Chrome\Application\chrome.exe" -Credential $cred

		Remove-Variable -Name cred
	}
}
