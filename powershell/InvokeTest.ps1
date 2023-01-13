Clear-Host
#------------------------------------------------------------------------------
#--// OPEN A CONNECTION TO THE SQL SERVER                                  //--
#------------------------------------------------------------------------------

$SqlConnection_GccSqlPd001 = New-Object System.Data.SqlClient.SqlConnection;
$SqlConnection_GccSqlPd001.ConnectionString = "Server=gcc-sql-pd-001;Database=CentralAdmin;Integrated Security=True";
$SqlConnection_GccSqlPd001.Open();


#------------------------------------------------------------------------------
#--// GET THE LIST OF SERVERS TO CHECK                                     //--
#------------------------------------------------------------------------------

$SqlCmd_GetServers = New-Object System.Data.SqlClient.SqlCommand

$SqlCmd_GetServers.CommandText = "
SELECT DISTINCT 
          CASE
               WHEN CHARINDEX('\',[rs].[server_name]) != 0 THEN LEFT([rs].[server_name],CHARINDEX('\',[rs].[server_name])-1)
               WHEN CHARINDEX(',',[rs].[server_name]) != 0 THEN LEFT([rs].[server_name],CHARINDEX(',',[rs].[server_name])-1)
               ELSE [rs].[server_name]
          END AS [server_name]
FROM      [msdb].[dbo].[sysmanagement_shared_server_groups_internal] AS [sg]      
LEFT JOIN [msdb].[dbo].[sysmanagement_shared_registered_servers_internal] AS [rs] ON [sg].[server_group_id] = [rs].[server_group_id]      
WHERE     [sg].[server_type] = 0 --only the Database Engine Server Group      
          AND [rs].[server_name] IS NOT NULL
          /*AND LOWER([rs].[server_name]) NOT LIKE 'bois%'
          AND LOWER([rs].[server_name]) NOT LIKE 'buff%'
          AND LOWER([rs].[server_name]) NOT LIKE 'gdl%'
          AND LOWER([rs].[server_name]) NOT LIKE 'guad%'
          AND LOWER([rs].[server_name]) NOT LIKE 'kels%'
          AND LOWER([rs].[server_name]) NOT LIKE 'namp%'
          AND LOWER([rs].[server_name]) NOT LIKE 'orad%'*/
          AND LOWER([rs].[server_name]) NOT IN ('neen-web-980','wneevm0002','wneevm0003','neen-db-010')
          AND [sg].[name] IN ('AMER - PROD', 'AMER - QA', 'AMER - DEV', 'AMER - POC', 'AMER - TEST', 'AMER - PRODFIX', 'AMER - TRAIN')   
UNION   
SELECT    @@SERVERNAME AS [server_name]   
ORDER BY  1;"

$SqlCmd_GetServers.Connection = $SqlConnection_GccSqlPd001
$result = $SqlCmd_GetServers.ExecuteReader()
$tblServers = New-Object System.Data.DataTable
$tblServers.Load($result)

$ServerNames = $tblServers.Select()
$computerNames = $ServerNames.server_name

foreach ($cn in $computerNames) {

'Invoke-Command -ComputerName "' + $cn + '" -ScriptBlock { Get-WmiObject win32_volume | 
     Where-Object  { ( $_.Name -NotLike "\\?\Volume*" ) -and ( $_.Name -ne "D:\" ) -and ( $_.DriveType -ne 5 ) } | 
	 select        SystemName,Name,Freespace,Capacity } |
	 Sort-Object   SystemName, Name | 
	 Format-Table  SystemName,
	               Name,
	               @{Name="free_GB"; Expression={"{0:N1}" -f (($_.Freespace)/1GB)};              align="right"},
	               @{Name="size_GB"; Expression={"{0:N1}" -f (($_.Capacity)/1GB)};               align="right"},
	               @{Name="pct_free";Expression={"{0:N0}" -f (($_.Freespace)/($_.Capacity)*100)};align="right"}'
}

#
#
#
#$x = Invoke-Command -ComputerName $computerNames -ScriptBlock { Get-WmiObject win32_volume | 
#     Where-Object  { ( $_.Name -NotLike "\\?\Volume*" ) -and ( $_.Name -ne "D:\" ) -and ( $_.DriveType -ne 5 ) } | 
#	 select        SystemName,Name,Freespace,Capacity }
#
#
#
#
#$x | Sort-Object   SystemName, Name | 
#	 Format-Table  SystemName,
#	               Name,
#	               @{Name="free_GB"; Expression={"{0:N1}" -f (($_.Freespace)/1GB)};              align="right"},
#	               @{Name="size_GB"; Expression={"{0:N1}" -f (($_.Capacity)/1GB)};               align="right"},
#	               @{Name="pct_free";Expression={"{0:N0}" -f (($_.Freespace)/($_.Capacity)*100)};align="right"} 
# 
#
#
#





#------------------------------------------------------------------------------
#--// CLOSE THE CONNECTION - gcc-sql-pd-001                                //--
#------------------------------------------------------------------------------

if ($sqlConnection.State -eq [Data.ConnectionState]::Open) 
{
    $SqlConnection_GccSqlPd001.Close();
}


