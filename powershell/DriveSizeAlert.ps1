$start = Get-Date
$start

$PSEmailServer = "intranet-smtp.plexus.com"
$to            = "james.lutsey@plexus.com"
$from          = "$env:computername <$env:computername@plexus.com>"
$subject       = "WARNING: Low Server Volume Free Space"



#------------------------------------------------------------------------------
#--// OPEN A CONNECTION TO THE SQL SERVER                                  //--
#------------------------------------------------------------------------------

$SqlConnection_CoDb042 = New-Object System.Data.SqlClient.SqlConnection;
$SqlConnection_CoDb042.ConnectionString = "Server=co-db-042;Database=CentralAdmin;Integrated Security=True";
$SqlConnection_CoDb042.Open();


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

$SqlCmd_GetServers.Connection = $SqlConnection_CoDb042
$result = $SqlCmd_GetServers.ExecuteReader()
$tblServers = New-Object System.Data.DataTable
$tblServers.Load($result)

$ServerNames = $tblServers.Select()


#------------------------------------------------------------------------------
#--// START THE HTML BODY                                                  //--
#------------------------------------------------------------------------------

$body  = "<html>`r`n"
$body += "<head>`r`n"
$body += "    <style type=`"text/css`">`r`n"
$body += "        H3`r`n"
$body += "        {`r`n"
$body += "            font-family: verdana,arial,sans-serif;`r`n"
$body += "        }`r`n"
$body += "        table.gridtable`r`n"
$body += "        {`r`n"
$body += "            font-family: verdana,arial,sans-serif;`r`n"
$body += "            font-size:11px;`r`n"
$body += "            color:#333333;`r`n"
$body += "            border-width: 1px;`r`n"
$body += "            border-color: #666666;`r`n"
$body += "            border-collapse: collapse`r`n"
$body += "        }`r`n"
$body += "        table.gridtable th`r`n"
$body += "        {`r`n"
$body += "            border-width: 1px;`r`n"
$body += "            padding: 8px;`r`n"
$body += "            border-style: solid;`r`n"
$body += "            border-color: #666666;`r`n"
$body += "            background-color: #dedede;`r`n"
$body += "        }`r`n"
$body += "        table.gridtable td`r`n"
$body += "        {`r`n"
$body += "            border-width: 1px;`r`n"
$body += "            padding: 8px;`r`n"
$body += "            border-style: solid;`r`n"
$body += "            border-color: #666666;`r`n"
$body += "            background-color: #ffffff;`r`n"
$body += "        }`r`n"
$body += "        table.gridtable .red`r`n"
$body += "        {`r`n"
$body += "            background-color:#ff0000`r`n"
$body += "        }`r`n"
$body += "        table.gridtable .yellow`r`n"
$body += "        {`r`n"
$body += "            background-color:#ffff00`r`n"
$body += "        }`r`n"
$body += "    </style>`r`n"
$body += "</head>`r`n"
$body += "`r`n"
$body += "<body>`r`n"
$body += "    <H3>Low Volume Free Space:</H3>`r`n"
$body += "    <table border=`"1`" class=`"gridtable`">`r`n"
$body += "        <tr>`r`n"
$body += "            <th>Server Name</th>`r`n"
$body += "            <th>Volume Name</th>`r`n"
$body += "            <th>Free Space</th>`r`n"
$body += "            <th>Total Size</th>`r`n"
$body += "            <th>Percent Free</th>`r`n"
$body += "        </tr>`r`n"

# start the html for errors
$errorHtml  = "    <H3>Errors:</H3>`r`n"
$errorHtml += "    <table border=`"1`" class=`"gridtable`">`r`n"
$errorHtml += "        <tr>`r`n"
$errorHtml += "            <th>Server Name</th>`r`n"
$errorHtml += "            <th>Error</th>`r`n"
$errorHtml += "        </tr>`r`n"

#------------------------------------------------------------------------------
#--// GET THE VOLUMES WITH LOW FREE SPACE                                  //--
#------------------------------------------------------------------------------

foreach ( $Server in $ServerNames ) {
	$cn = $Server.server_name
	$cn

	try {
		Get-WmiObject win32_volume -ComputerName $cn | 
			Where-Object  { ( $_.Name -NotLike "\\?\Volume*" ) -and ( $_.Name -ne "D:\" ) -and ( $_.DriveType -ne 5 ) -and ( $_.Freespace -lt 2147483648 ) } | 
			Sort-Object Name |
			foreach {
				$name   = $_.Name
				$free   = ($_.Freespace) / 1GB
				$size   = ($_.Capacity) / 1GB
				$pct    = ($_.Freespace) / ($_.Capacity) * 100

				# enter the volume info into the html table 
				$body += "        <tr>`r`n"
				$body += "            <td align=`"left`">$cn</td>`r`n"
				$body += "            <td align=`"left`">$name</td>`r`n"

				if ( $_.Freespace -lt 1073741824 ) { 
					$body += "            <td align=`"right`" class=`"Yellow`">" + "{0:N2}" -f $free + " GB</td>`r`n"
				}
				else {
					$body += "            <td align=`"right`">" + "{0:N2}" -f $free + " GB</td>`r`n"
				}
				
				$body += "            <td align=`"right`">" + "{0:N2}" -f $size + " GB</td>`r`n"
				$body += "            <td align=`"right`">" + "{0:N0}" -f $pct + "%</td>`r`n"
				$body += "        </tr>`r`n"
			} # foreach win32_volume
	} # try
	catch {
		$ErrorMsg = $_.Exception

		$errorHtml += "        <tr>`r`n"
		$errorHtml += "            <td align=`"left`">$cn</td>`r`n"
		$errorHtml += "            <td align=`"left`">$ErrorMsg</td>`r`n"
		$errorHtml += "        </tr>`r`n"
	} # catch
} # foreach ( $cn in $ServerNames )

$body += "    </table>`r`n"

if ( $errorHtml -match '<td ') {
	$body += "`r`n$errorHtml"
}


#------------------------------------------------------------------------------
#--// END THE HTML BODY                                                    //--
#------------------------------------------------------------------------------

$body += "</body>`r`n"
$body += "</html>"

$body


#------------------------------------------------------------------------------
#--// SEND THE ALERT                                                       //--
#------------------------------------------------------------------------------

Send-MailMessage -To $to -From $from -Subject $subject -Body $body -BodyAsHtml -Priority High







$end = Get-Date
$end

$ts = New-TimeSpan -Start $start -End $end
$ts.Minutes
$ts.Seconds
$ts.Milliseconds




#------------------------------------------------------------------------------
#--// CLOSE THE CONNECTION - gcc-sql-pd-001                                //--
#------------------------------------------------------------------------------

if ($sqlConnection.State -eq [Data.ConnectionState]::Open) 
{
    $SqlConnection_GccSqlPd001.Close();
}


