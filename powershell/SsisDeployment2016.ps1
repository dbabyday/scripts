<#************************************************************************************************************************
* 
* Script: SsisDeployment2016.ps1
*     
* Purpose: Deploy the SSIS Deployment package(s) (ispac files) that are in the indicated folder
* 
* Instructions: 1. Enter the SQL Instance
*               2. Enter the SSISDB Folder
*               3. Enter the folder path of the package(s) to deploy 
*                  (or use the use the commented command to select the current folder)
*               4. Enter the path for the IS deployment wizzard .exe file (2016 default location is entered)
* 
************************************************************************************************************************#>

Clear-Host

# USER INPUT
$SQLInstance        = "co-db-779"
$SsisdbFolderName   = "Integrations"
$PackageLocation    = ""   # split-path -parent $MyInvocation.MyCommand.Definition
$ISDeploymentWizard = "C:\Program Files (x86)\Microsoft SQL Server\130\DTS\Binn\ISDeploymentWizard.exe" # SQL Server 2016 default location

# Installs each ispac file found in the folder where the powershell script is located.
Get-ChildItem $PackageLocation -Filter *.ispac | 
Foreach-Object {

    $ProjectName = $_.BaseName
    Write-Host "Deploying project $ProjectName ...";

    & $ISDeploymentWizard /Silent /ModelType:Project /SourcePath:"$PackageLocation\$ProjectName.ispac" /DestinationServer:"$SQLInstance" /DestinationPath:"/SSISDB/$SsisdbFolderName/$ProjectName" | Out-Null

    Write-Host "Deployment of project $ProjectName complete";

}
