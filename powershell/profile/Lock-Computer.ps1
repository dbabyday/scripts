$xCmdString = {rundll32.exe user32.dll,LockWorkStation}
Invoke-Command $xCmdString
Remove-Variable -Name xCmdString