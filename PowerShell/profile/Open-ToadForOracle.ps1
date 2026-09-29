$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($yeti)
$yeti2 = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
Set-Clipboard -Value $yeti2
Remove-Variable -Name yeti2

Start-Process -FilePath "C:\Program Files\Quest Software\Toad for Oracle 2026 R1 Edition\Toad for Oracle 26.1\Toad.exe"