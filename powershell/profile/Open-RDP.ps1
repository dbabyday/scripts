$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($yeti)
$yeti2 = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
Set-Clipboard -Value $yeti2
Remove-Variable -Name yeti2

Start-Process -FilePath "C:\Windows\system32\mstsc.exe"