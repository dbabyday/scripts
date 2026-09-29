$bstr9 = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($yeti9)
$yeti29 = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr9)
Set-Clipboard -Value $yeti29
Remove-Variable -Name yeti29

