Function Publish-SsisIsPac {
	<#
	.NOTES
		Name: Publish-SsisIsPac.ps1
		Author: Drew Wilson
		Version History:
		1.0 - 20170628 - Initial Release.
		1.1 - 20180526 - Rename function, added functionality
		1.2 - 20180726 - Removed {switch} and replaced Environment parameter with Destination
		1.3 - 20220110 - James Lutsey: Added option for 2019

	.SYNOPSIS
		SSIS IsPac Project Deployment (2016 or 2019)

	.DESCRIPTION
		Deploys one or more SSIS Deployment projects (ispac files).

	.PARAMETER $IspacDirectory
		Directory where the ispac file resides. (Standard directory is in \\neen-dsk-011\ssis$)

	.PARAMETER $DestinationServer
		Servername where the project will be deployed. $ProjectFolder must already exist.

	.PARAMETER $ProjectFolder
		Destination project folder where the project will be deployed.

	.EXAMPLE
		PS C:\> Publish-SsisIsPac -IspacDirectory \\neen-dsk-011\ssis$\bi\test2016 -DestinationServer co-db-779 -ProjectFolder BI

		2022-01-20 07:02:01 - Start



		    Directory: \\neen-dsk-011\ssis$\bi\test2016


		Mode                LastWriteTime         Length Name
		----                -------------         ------ ----
		-a----        1/11/2022   9:06 AM         105924 BI_STG_ITGlobalMetrics_2016_Testing.ispac

		Do you want to deploy all of these IsPacs to co-db-779 BI ? (y/n): y

		2022-01-20 07:02:05 - Deploying project BI_STG_ITGlobalMetrics_2016_Testing ...
		2022-01-20 07:02:10 - Deployment of project BI_STG_ITGlobalMetrics_2016_Testing to co-db-779 BI completed

		2022-01-20 07:02:10 - End

	.EXAMPLE
		PS C:\> Publish-SsisIsPac -IspacDirectory \\neen-dsk-011\ssis$\bi\test2019 -DestinationServer dcc-sql-qa-019 -ProjectFolder BI

		2022-01-20 07:05:58 - Start



		    Directory: \\neen-dsk-011\ssis$\bi\test2019


		Mode                LastWriteTime         Length Name
		----                -------------         ------ ----
		-a----        1/11/2022   8:44 AM          96973 BI_STG_APM_2019_Testing.ispac

		Do you want to deploy all of these IsPacs to dcc-sql-qa-019 BI ? (y/n): y

		2022-01-20 07:06:01 - Deploying project BI_STG_APM_2019_Testing ...
		2022-01-20 07:06:09 - Deployment of project BI_STG_APM_2019_Testing to dcc-sql-qa-019 BI completed

		2022-01-20 07:06:09 - End

	#>

	[CmdletBinding()]

	Param (
		[Parameter(Mandatory = $true)]
		[String] $IspacDirectory
		,
		[Parameter(Mandatory = $true)]
		[ValidateSet("co-db-992","co-db-779","co-db-079","dcc-sql-dv-029","dcc-sql-qa-019","gcc-sql-pd-051","acc-sql-dv-001","acc-sql-ts-002","acc-sql-qa-001","acc-sql-pd-002","xia-sql-qa-004","xia-sql-pd-005")]
		[String] $DestinationServer
		,
		[Parameter(Mandatory = $true)]
		[ValidateSet("BI", "BI_Restricted", "GDL", "GSF2_APP", "Integrations")]
		[String] $ProjectFolder
	)

	Begin {
		Write-Host " ";
		Write-Host (Get-Date -Format "yyyy-MM-dd HH:mm:ss")"- Start";
		Write-Host " ";

		# Set the locations for the deployment wizards
		Set-Variable -Name ISDeploymentWizard2016 -Option Constant -Value "C:\Program Files (x86)\Microsoft SQL Server\130\DTS\Binn\ISDeploymentWizard.exe"
		Set-Variable -Name ISDeploymentWizard2019 -Option Constant -Value "C:\Program Files (x86)\Microsoft SQL Server\150\DTS\Binn\ISDeploymentWizard.exe"
	}

	Process {
		# choose which deployment wizard to use based on the ssis version of the destination server
		if (($DestinationServer -eq "co-db-992") -or ($DestinationServer -eq "co-db-779") -or ($DestinationServer -eq "co-db-079") -or ($DestinationServer -eq "acc-sql-dv-001") -or ($DestinationServer -eq "acc-sql-ts-002") -or ($DestinationServer -eq "acc-sql-qa-001") -or ($DestinationServer -eq "acc-sql-pd-002") -or ($DestinationServer -eq "xia-sql-qa-004") -or ($DestinationServer -eq "xia-sql-pd-005")) {
			$ISDeploymentWizard = $ISDeploymentWizard2016
		}
		elseif (($DestinationServer -eq "dcc-sql-dv-029") -or ($DestinationServer -eq "dcc-sql-qa-019") -or ($DestinationServer -eq "gcc-sql-pd-051")) {
			$ISDeploymentWizard = $ISDeploymentWizard2019
		}
		else {
			Write-Warning -Message "Unaccounted for destination server, $DestinationServer , when choosing which deployment wizard to use. (check the code of this function to find the logical error."
			Write-Warning -Message "Exiting without deploying."
			break
		}

		# show the user which ispac files are in the directory and have them comfirm that they should all be deployed
		Get-ChildItem -Path $IspacDirectory -Filter *.ispac
		Write-Host " "
		$continue = Read-Host -Prompt "Do you want to deploy all of these IsPacs to $DestinationServer $ProjectFolder ? (y/n)"
		if (($continue -ne "y") -and ($continue -ne "Y")) {
			Write-Warning -Message "Exiting without deploying."
			Write-Host " "
			break
		}
		Write-Host " "

		# deploy the projects
		Get-ChildItem -Path $IspacDirectory -Filter *.ispac |
			Foreach-Object { 
			$ProjectName = $_.BaseName
			Write-Host (Get-Date -Format "yyyy-MM-dd HH:mm:ss")"- Deploying project $ProjectName ...";
			& $ISDeploymentWizard /Silent /ModelType:Project /SourcePath:"$IspacDirectory\$ProjectName.ispac" /DestinationServer:"$DestinationServer" /DestinationPath:"/SSISDB/$ProjectFolder/$ProjectName" | Out-Null
			Write-Host (Get-Date -Format "yyyy-MM-dd HH:mm:ss")"- Deployment of project $ProjectName to $DestinationServer $ProjectFolder completed";
			Write-Host " ";
		}
	}

	End {
		Write-Host (Get-Date -Format "yyyy-MM-dd HH:mm:ss")"- End";
		Write-Host " ";
	}

}#Function