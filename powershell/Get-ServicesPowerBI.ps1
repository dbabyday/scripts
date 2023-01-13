# CommVault Services
Get-WmiObject Win32_Service -ComputerName $cn -Filter "DisplayName Like '%Power BI%'" | 
select-object State,DisplayName,Name,StartMode,StartName,__Server | 
Sort-Object DisplayName | 
Format-Table -AutoSize
