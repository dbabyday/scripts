# SQL Server Services
Get-WmiObject Win32_Service -ComputerName $cn -Filter "name Like '%SQL%' or DisplayName Like '%SQL%'" | 
select-object State,DisplayName,Name,StartMode,StartName,__Server | 
Sort-Object DisplayName | 
Format-Table -AutoSize
