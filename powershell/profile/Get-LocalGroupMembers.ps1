Function Get-LocalGroupMembers {
	<#
	.NOTES
		Name: Get-LocalGroupMembers.ps1
		Author: Jeff Hicks
		Version History:
		1.0 - 20220119 - Adapted from https://gist.github.com/jdhitsolutions/2b3f8761db581726802e

	.SYNOPSIS
		Get local group membership using ADSI.

	.DESCRIPTION
		This command uses ADSI to connect to a server and enumerate the members of a local group. By default it will retrieve members of the local Administrators group.
		The command uses legacy protocols to connect and enumerate group memberships. You may find it more efficient to wrap this function in an Invoke-Command expression. See examples.

	.PARAMETER ComputerList
		The name of a computer to query. For multiple computers, use a comma separated list.

	.PARAMETER GroupName
		The name of a local group. The default value is Administrators.

	.EXAMPLE
		PS C:\> Get-LocalGroupMembers -ComputerList dcc-sql-qa-021

		Computer       LocalGroup     AccountName                               Class Domain     IsLocal
		--------       ----------     -----------                               ----- ------     -------
		DCC-SQL-QA-021 Administrators Domain Admins                             Group NA           False
		DCC-SQL-QA-021 Administrators earl.andrews                              User  NA            True
		DCC-SQL-QA-021 Administrators Enterprise Admins                         Group PLEXUSCORP   False
		DCC-SQL-QA-021 Administrators Neenah-US Site Administrators             Group NA           False
		DCC-SQL-QA-021 Administrators Neenah-US Site MSSQL Administrators in NA Group NA           False
		DCC-SQL-QA-021 Administrators Neenah-US Site Service Accounts           Group NA           False
		DCC-SQL-QA-021 Administrators Penang-MY Site MSSQL Administrators in AP Group AP           False
		DCC-SQL-QA-021 Administrators srvcCyberArkLAP.na                        User  NA           False

	.EXAMPLE
		PS C:\> Get-LocalGroupMembers -ComputerList dcc-sql-qa-021 -GroupName Users

		Computer       LocalGroup AccountName         Class Domain       IsLocal
		--------       ---------- -----------         ----- ------       -------
		DCC-SQL-QA-021 Users      Authenticated Users Group NT AUTHORITY   False
		DCC-SQL-QA-021 Users      Domain Users        Group NA             False
		DCC-SQL-QA-021 Users      INTERACTIVE         Group NT AUTHORITY   False

	.EXAMPLE
		PS C:\> Get-LocalGroupMembers -ComputerList dcc-sql-dv-028,dcc-sql-qa-021

		Computer       LocalGroup     AccountName                               Class Domain     IsLocal
		--------       ----------     -----------                               ----- ------     -------
		DCC-SQL-DV-028 Administrators casey.ratliff.admin                       User  EXT          False
		DCC-SQL-DV-028 Administrators Domain Admins                             Group NA           False
		DCC-SQL-DV-028 Administrators earl.andrews                              User  NA            True
		DCC-SQL-DV-028 Administrators Enterprise Admins                         Group PLEXUSCORP   False
		DCC-SQL-DV-028 Administrators liz.valenta.admin                         User  NA           False
		DCC-SQL-DV-028 Administrators Neenah-US Site Administrators             Group NA           False
		DCC-SQL-DV-028 Administrators Neenah-US Site MSSQL Administrators       Group NA           False
		DCC-SQL-DV-028 Administrators Neenah-US Site Service Accounts           Group NA           False
		DCC-SQL-DV-028 Administrators srvccognos.dev                            User  NA           False
		DCC-SQL-DV-028 Administrators srvcCyberArkLAP.na                        User  NA           False
		DCC-SQL-DV-028 Administrators srvcvrasqlbuild.na                        User  NA           False
		DCC-SQL-QA-021 Administrators Domain Admins                             Group NA           False
		DCC-SQL-QA-021 Administrators earl.andrews                              User  NA            True
		DCC-SQL-QA-021 Administrators Enterprise Admins                         Group PLEXUSCORP   False
		DCC-SQL-QA-021 Administrators Neenah-US Site Administrators             Group NA           False
		DCC-SQL-QA-021 Administrators Neenah-US Site MSSQL Administrators in NA Group NA           False
		DCC-SQL-QA-021 Administrators Neenah-US Site Service Accounts           Group NA           False
		DCC-SQL-QA-021 Administrators Penang-MY Site MSSQL Administrators in AP Group AP           False
		DCC-SQL-QA-021 Administrators srvcCyberArkLAP.na                        User  NA           False

	#>

	[CmdletBinding()]

	Param (
		[Parameter(Mandatory = $true)]
		[ValidateNotNullorEmpty()]
		[String[]] $ComputerList
		,
		[Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
		[ValidateNotNullorEmpty()]
		[String] $GroupName = "Administrators"
	)#Param

	Begin {
		# nothing to do here
	}#Begin

	Process {
		$membersArray = @()

		ForEach ($computer in $ComputerList) {
			#the WinNT moniker is case-sensitive
			[ADSI]$group = "WinNT://$computer/$GroupName,group"

			$members = $group.invoke("Members") 

			if (-Not $script:NotFound) {
				$found = ($members | measure).count

				if ($found -gt 0 ) {
					$members | foreach {

						#define an ordered hashtable which will hold properties
						#for a custom object
						$Hash = [ordered]@{Computer = $computer.toUpper()}

						#include the group name
						$hash.Add("LocalGroup",$GroupName)

						#Get the name property
						$hash.Add("AccountName",$_[0].GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null))
						
						#get ADS Path of member
						$ADSPath = $_[0].GetType().InvokeMember("ADSPath", 'GetProperty', $null, $_, $null)
						$hash.Add("ADSPath",$ADSPath)

						#get the member class, ie user or group
						$hash.Add("Class",$_[0].GetType().InvokeMember("Class", 'GetProperty', $null, $_, $null))  

						<#
						Domain members will have an ADSPath like WinNT://MYDomain/Domain Users.  
						Local accounts will be like WinNT://MYDomain/Computername/Administrator
						#>

						$hash.Add("Domain",$ADSPath.Split("/")[2])

						#if computer name is found between two /, then assume
						#the ADSPath reflects a local object
						if ($ADSPath -match "/$computer/") {
							$local = $True
							}
						else {
							$local = $False
							}
						$hash.Add("IsLocal",$local)

						#turn the hashtable into an object
						$member = New-Object -TypeName PSObject -Property $hash
						$membersArray += $member
					} #foreach member
				} 
				else {
					Write-Warning "No members found in $GroupName on $Computer."
				}
			} #if no errors
		} #foreach $computer

		$membersArray | Sort-Object Computer,AccountName | Select-Object Computer,LocalGroup,AccountName,Class,Domain,IsLocal  | Format-Table -AutoSize
	}#Process

	End {
		# nothing to do here
	}#End
}#Function