Function Create-SqlServerLoginSysadmin {
	<#
		.NOTES
			Name: Create-SqlServerLoginSysadmin.ps1
			Author: James Lutsey
			Version History:
			1.0 - 20260310 - Initial Release.
		.SYNOPSIS
			Create a login in SQL Server with sysadmin privilege
		.DESCRIPTION
			Create a login in SQL Server with sysadmin privilege
		.PARAMETER $SqlServer
			Name of the sql server instance to connect to
		.PARAMETER $LoginName
			Name of the login to create
		.EXAMPLE
			PS> Create-SqlServerLoginSysadmin -SqlServer dcc-sql-dv-014
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
		$query = "CREATE LOGIN [$Username] FROM WINDOWS; ALTER SERVER ROLE sysadmin ADD MEMBER [$Username];"
		Invoke-Sqlcmd -ServerInstance $SqlServer -Database master -Query $query
	}
	
	End {
		# nothing to do here
	}
}









