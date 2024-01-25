$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($yeti)
$yeti2 = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
Set-Clipboard -Value $yeti2
Remove-Variable -Name yeti2

Start-Process -FilePath "C:\Program Files\Internet Explorer\iexplore.exe" -ArgumentList "https://vault.plexus.com/PasswordVault/v10/logon/ldap"