# Open a connection to the SQL Server
$SqlConnection_CoDb042 = New-Object System.Data.SqlClient.SqlConnection;
$SqlConnection_CoDb042.ConnectionString = "Server=co-db-042;Database=CentralAdmin;Integrated Security=True";
$SqlConnection_CoDb042.Open();

# Get the list of servers to check
$SqlCmd_GetServers = New-Object System.Data.SqlClient.SqlCommand;
$SqlCmd_GetServers.CommandText = "
SELECT DISTINCT
    CASE
        WHEN CHARINDEX('\',[rs].[server_name]) != 0 THEN LEFT([rs].[server_name],CHARINDEX('\',[rs].[server_name])-1)
        WHEN CHARINDEX(',',[rs].[server_name]) != 0 THEN LEFT([rs].[server_name],CHARINDEX(',',[rs].[server_name])-1)
        ELSE [rs].[server_name]
    END AS [server_name]
FROM
    [msdb].[dbo].[sysmanagement_shared_server_groups_internal] AS [sg]      
LEFT JOIN 
    [msdb].[dbo].[sysmanagement_shared_registered_servers_internal] AS [rs] ON [sg].[server_group_id] = [rs].[server_group_id]      
WHERE
    [sg].[server_type] = 0 --only the Database Engine Server Group      
    AND [rs].[server_name] IS NOT NULL          
    AND [sg].[name] IN ('AMER - PROD', 'AMER - QA', 'AMER - DEV', 'AMER - POC', 'AMER - TEST', 'AMER - PRODFIX', 'AMER - TRAIN')   
UNION   
SELECT
    'co-db-042' AS [server_name]   
UNION   
SELECT
    'neen-db-010' AS [server_name];";
$SqlCmd_GetServers.Connection = $SqlConnection_CoDb042;
$result = $SqlCmd_GetServers.ExecuteReader();
$tblServers = New-Object System.Data.DataTable;
$tblServers.Load($result);

$ServerNames = $tblServers.Select();

$SqlInsert = "USE [CentralAdmin];`r`n`r`n" +
             "UPDATE [CentralAdmin].[dbo].[ServerTestConnection]`r`n" +
             "SET    [Category] = 3`r`n" +
             "WHERE  [Category] = 2;`r`n`r`n" +
             "UPDATE [CentralAdmin].[dbo].[ServerTestConnection]`r`n" +
             "SET    [Category] = 2`r`n" +
             "WHERE  [Category] = 1;`r`n`r`n" +
             "INSERT INTO [CentralAdmin].[dbo].[ServerTestConnection] ([ServerName],[Result],[TestTime],[Category]) VALUES `r`n";

ForEach($Server in $ServerNames)
{
	$ServerName = $Server.server_name;

	$test = Test-Connection -ComputerName $ServerName -Count 1 -Quiet;
	
	if ($test)
	{
		# test succeeded
		$TestResult = 1;
	}
	else  # if the first test failed, check again with parameters for account for slower/busy network
	{
		$testAgain = Test-Connection -ComputerName $ServerName -Count 3 -Delay 2 -Quiet;
		
		if ($testAgain)
		{
			# test succeeded
			$TestResult = 1;
		}
		else  # if the second test also failed, record the result as fail for this server
		{
			# test failed
			$TestResult = 0;
		}
	}

	$SqlInsert += "    ('" + $ServerName + "'," + $TestResult + ",'" + (Get-Date -format s) + "',1),`r`n";
}

$SqlInsert = $SqlInsert.Substring(0,$SqlInsert.Length - 3) + ";`r`n`r`n";
$SqlInsert += "EXECUTE [CentralAdmin].[dbo].[usp_ServerTestConnections];"

$SqlCmd_InsertReults = New-Object System.Data.SqlClient.SqlCommand;
$SqlCmd_InsertReults.Connection = $SqlConnection_CoDb042;
$SqlCmd_InsertReults.CommandText = $SqlInsert;
$result = $SqlCmd_InsertReults.ExecuteNonQuery();

# Close the connection.
if ($sqlConnection.State -eq [Data.ConnectionState]::Open) 
{
    $SqlConnection_CoDb042.Close();
}
