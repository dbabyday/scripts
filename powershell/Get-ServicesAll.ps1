# All Services
Get-WmiObject Win32_Service -ComputerName $cn  | 
select-object State,DisplayName,Name,StartMode,StartName,__Server | 
Sort-Object DisplayName | 
Format-Table -AutoSize
