Clear-Host


$PSEmailServer = "intranet-smtp.plexus.com"
$to            = "james.lutsey@plexus.com"
$from          = "$env:computername <$env:computername@plexus.com>"
$subject       = "WARNING: Low Free Space - Transaction Log Drive"



#------------------------------------------------------------------------------
#--// OPEN A CONNECTION TO THE SQL SERVER                                  //--
#------------------------------------------------------------------------------

# get the instance name; specify named instnaces (co-db-955 & neen-db-011: logs for named instances are on same drives as default instnaces )
If ( $env:computername -eq "CO-DB-051" ) {
	$instance = "CO-DB-051\OLTP01"
}
ElseIf ( $env:computername -eq "CO-DB-161" ) {
	$instance = "CO-DB-161\DG"
}
ElseIf ( $env:computername -eq "CO-DB-919" ) {
	$instance = "CO-DB-919\DG"
}
Else {
	$instance = $env:computername
}

$SqlConnection_ThisServer = New-Object System.Data.SqlClient.SqlConnection;
$SqlConnection_ThisServer.ConnectionString = "Server=$instance;Database=master;Integrated Security=True";
$SqlConnection_ThisServer.Open();


#------------------------------------------------------------------------------
#--// GET THE DRIVES CONTAINING LOG FILES                                  //--
#------------------------------------------------------------------------------

$SqlCmd_GetLogFiles = New-Object System.Data.SqlClient.SqlCommand

$SqlCmd_GetLogFiles.CommandText  = "SELECT [physical_name]`r`n"
$SqlCmd_GetLogFiles.CommandText += "FROM   [sys].[master_files]`r`n"
$SqlCmd_GetLogFiles.CommandText += "WHERE  [type] = 1`r`n"
$SqlCmd_GetLogFiles.CommandText += "       AND DB_NAME([database_id]) NOT IN ('master','model','msdb','tempdb');"

$SqlCmd_GetLogFiles.Connection = $SqlConnection_ThisServer
$result = $SqlCmd_GetLogFiles.ExecuteReader()
$tblLogFiles = New-Object System.Data.DataTable
$tblLogFiles.Load($result)

$LogFiles = $tblLogFiles.Select()



#------------------------------------------------------------------------------
#--// CLOSE THE CONNECTION - This Server                                   //--
#------------------------------------------------------------------------------

if ($SqlConnection_ThisServer.State -eq [Data.ConnectionState]::Open) 
{
    $SqlConnection_ThisServer.Close();
}



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



try {
	Get-WmiObject win32_volume | 
		Where-Object  { ( $_.Name -NotLike "\\?\Volume*" ) -and ( $_.DriveType -ne 5 ) -and ( ( $_.Freespace -lt 2147483648 ) -or ( ( ($_.Freespace) / ($_.Capacity) ) -lt 0.10 ) ) } | 
		Sort-Object Name |
		foreach {
			$include = 0
			foreach ( $LogFile in $LogFiles ) {
				$physicalName = $LogFile.physical_name

				if ( $physicalName.StartsWith($_.Name) ) {
					$include = 1
				}
			} # foreach ( $LogFile in $LogFiles )

			if ($include -eq 1) {
				$name   = $_.Name
				$free   = ($_.Freespace) / 1GB
				$size   = ($_.Capacity) / 1GB
				$pct    = ($_.Freespace) / ($_.Capacity) * 100

				# enter the volume info into the html table 
				$body += "        <tr>`r`n"
				$body += "            <td align=`"left`">$instance</td>`r`n"
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
			} # if (include -eq 1)
		} # foreach win32_volume
} # try
catch {
	$ErrorMsg = $_.Exception

	$errorHtml += "        <tr>`r`n"
	$errorHtml += "            <td align=`"left`">$instance</td>`r`n"
	$errorHtml += "            <td align=`"left`">$ErrorMsg</td>`r`n"
	$errorHtml += "        </tr>`r`n"
} # catch

$body += "    </table>`r`n"

If ( $body -match '<td ') {
	$priority = "High"	
}
Else {
	$priority = "Normal"
	$subject  = "Powershell Error in Job: DBA - Transaction Log Drive Low Free Space Alert"
}

if ( $errorHtml -match '<td ') {
	$body += "`r`n$errorHtml"
}


#------------------------------------------------------------------------------
#--// END THE HTML BODY                                                    //--
#------------------------------------------------------------------------------

$body += "</body>`r`n"
$body += "</html>"


#------------------------------------------------------------------------------
#--// SEND THE ALERT                                                       //--
#------------------------------------------------------------------------------

If ( $body -match '<td ') {
	Send-MailMessage -To $to -From $from -Subject $subject -Body $body -BodyAsHtml -Priority $priority	
}



