$securedValue = Read-Host -Prompt "Password" -AsSecureString
$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securedValue)
$pw = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)

#Remove-Variable -Name pw