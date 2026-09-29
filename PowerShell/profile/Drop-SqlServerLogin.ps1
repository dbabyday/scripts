Function Drop-SqlServerLogin {
	<#
		.NOTES
			Name: Drop-SqlServerLogin.ps1
			Author: James Lutsey
			Version History:
			1.0 - 20260310 - Initial Release.
		.SYNOPSIS
			Drop a login in SQL Server with sysadmin privilege
		.DESCRIPTION
			Drop a login in SQL Server with sysadmin privilege
		.PARAMETER $SqlServer
			Name of the sql server instance to connect to
		.PARAMETER $LoginName
			Name of the login to drop
		.EXAMPLE
			PS> Drop-SqlServerLogin -SqlServer dcc-sql-dv-014
	#>

	[CmdletBinding()]

	Param (
		[Parameter(Mandatory = $true)]
		[String] $SqlServer
		,
		[String] $Username = "NA\james.lutsey"
	)

	Begin {
		# nothing to do here
	}

	Process {
		$query = "DROP LOGIN [$Username];"
		Invoke-Sqlcmd -ServerInstance $SqlServer -Database master -Query $query
	}
	
	End {
		# nothing to do here
	}
}









