Function Publish-SSIS2016IsPac {
    <#
    .NOTES
        Name: Publish-SSIS2016IsPac.ps1
        Author: Drew Wilson
        Version History:
        1.0 - 20170628 - Initial Release.
        1.1 - 20180526 - Rename function, added functionality
        1.2 - 20180726 - Removed {switch} and replaced Environment parameter with Destination
    .SYNOPSIS
        SSIS 2016 IsPac Project Deployment
    .DESCRIPTION
        Deploys one or more SSIS Deployment projects (ispac files).
    .PARAMETER $SourceDirectory
        Service Now Ticket number where the ispac file resides on the fileshare.
    .PARAMETER $DestinationServer
        Servername where the project will be deployed. $SSISDBFolder must already exist
    .PARAMETER $SSISDBFolder
        Destination project folder where the project will be deployed.
    .EXAMPLE
        [PS] D:\xfr\>.\Publish-SSIS2016Ispac -SourceDirectory CTASK12345 -DestinationServer CO-DB-079 -SSISDBFolder GDL
        Deploys SSIS projects from CTASK12345 directory to "CO-DB-079" under the "SSISDB\GDL" folder
    .EXAMPLE
        [PS] D:\xfr\>.\Publish-SSIS2016Ispac -SourceDirectory CTASK12345 -DestinationServer XIA-SQL-PD-005 -SSISDBFolder BI
        Deploys SSIS projects from CTASK12345 directory to "XIA-SQL-PD-005" under the "SSISDB\BI" project
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)] [String]$SourceDirectory,
        [Parameter(Mandatory = $true)] [String]$DestinationServer,
        [Parameter(Mandatory = $true)] [String]$SSISDBFolder [ValidateSet("BI", "BI_Restricted", "GDL", "GSF2_APP", "Integrations")]
    )#Param
    Begin {
        Write-Host " ";
        Write-Host (Get-Date -Format "yyyy-MM-dd HH:mm:ss")"- Start";
        Write-Host " ";
        $ScriptPath = "\\neen-dsk-011\SSIS$\$SSISDBFolder\$SourceDirectory"
        $ISDeploymentWizard = "C:\Program Files (x86)\Microsoft SQL Server\130\DTS\Binn\ISDeploymentWizard.exe"
    }#Begin
    Process {
        Get-ChildItem -Path $ScriptPath -Filter *.ispac
        Write-Host " "
        $continue = Read-Host -Prompt "Do you want to deploy all of these IsPacs to $DestinationServer ? (y/n)"
        if (($continue -ne "y") -and ($continue -ne "Y")) {
            Write-Warning "Exiting without deploying."
            Write-Host " "
            break
        }
        Write-Host " "

        Get-ChildItem -Path $ScriptPath -Filter *.ispac |
            Foreach-Object { 
            $ProjectName = $_.BaseName
            Write-Host (Get-Date -Format "yyyy-MM-dd HH:mm:ss")"- Deploying project $ProjectName ...";
            & $ISDeploymentWizard /Silent /ModelType:Project /SourcePath:"$ScriptPath\$ProjectName.ispac" /DestinationServer:"$DestinationServer" /DestinationPath:"/SSISDB/$SSISDBFolder/$ProjectName" | Out-Null
            Write-Host (Get-Date -Format "yyyy-MM-dd HH:mm:ss")"- Deployment of project $ProjectName to $DestinationServer completed";
            Write-Host " ";
        }
    }#Process
    End {
        Write-Host (Get-Date -Format "yyyy-MM-dd HH:mm:ss")"- End";
        Write-Host " ";
    }#End
}#Function

Set-Location -Path C:\