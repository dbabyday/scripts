



Write-Host ""
$sourceloc = Read-Host -Prompt "Source location"
if ($sourceloc.Substring($sourceloc.Length - 1,1) -ne "\") { $sourceloc = $sourceloc + "\"}
Write-Host "Directories at source location...choose one to deploy."
Get-ChildItem -Path $sourceloc
Write-Host ""
$sourcedir  = Read-Host -Prompt "Directory to deploy"
$sourcepath = $sourceloc + $sourcedir + "\"
$destdir    = "QuoteWinAccellion_Debug"
$bakname    = "$destdir" + (Get-Date -format _yyyyMMdd)
$dv         = "co-db-992"
$qa         = "co-db-779"
$pd         = "co-db-079"

# choose environment
$environment = "n/a"
while ( ($environment -ne "dv") -and ($environment -ne "qa") -and ($environment -ne "pd") ) {
    $environment = Read-Host -Prompt "Environment (dv, qa, pd)"
} 
if ($environment -eq "dv") { 
    $server = $dv
    $continue = "n/a"
    while ( ($continue -ne "y") -and ($continue -ne "n") ) {
        $continue = Read-Host -Prompt "You have selected $environment $server . Is this correct? (y/n)"
    }
}
if ($environment -eq "qa") { 
    $server = $qa
    $continue = "n/a"
    while ( ($continue -ne "y") -and ($continue -ne "n") ) {
        $continue = Read-Host -Prompt "You have selected $environment $server . Is this correct? (y/n)"
    }
}
if ($environment -eq "pd") { 
    $server = $pd
    $continue = "n/a"
    while ( ($continue -ne "y") -and ($continue -ne "n") ) {
        $continue = Read-Host -Prompt "You have selected $environment $server . Is this correct? (y/n)"
    }
}
if ($continue -eq "n") {
    Write-Warning -Message "You chose to not continue based on environment information. EXITING WITHOUT DEPLOYING."

    exit
}

# destination path
$destpath = "\\" + $server + "\c$\Support\"

# remove old backups
Get-ChildItem -Path $destpath | Where-Object { ($_.Name -match $destdir) -and ($_.Name -ne $destdir) } | ForEach-Object {
    Remove-Item -Path $_.FullName -Recurse -Confirm
}

# check if backup directory name exists
$testpath = $destpath + $bakname + "\"
if (Test-Path -Path $testpath) {
	$overwrite = Read-Host -Prompt "Do want to overwrite $testpath with the backup of the current directory? (y/n)"
	if ($overwrite -eq "n") {
	    Write-Warning -Message "A directory with the backup name already exists, and you chose to not overwrite it...we are EXITING WITHOUT DEPLOYING."
        
        Remove-Variable -Name overwrite

	    exit
	}
}

# backup current directory
$currentdir = $destpath + $destdir + "\"
Rename-Item -Path $currentdir -NewName $bakname
Write-Host ""
Write-Host "-----------------------------------------------------------------------------------------------------------------------"
Write-Host ""
Write-Host $currentdir "has been backed up to" $destpath $bakname
Write-Host ""


# deploy new directory
Copy-Item -Path $sourcepath -Destination $destpath -Recurse
$pathbefore = $destpath + $sourcedir + "\"
Rename-Item -Path $pathbefore -NewName $destdir

# display results
Write-Host "Folder $sourcepath has been deployed to $currentdir"
Write-Host ""
Get-ChildItem -Path $currentdir | Sort-Object Name
Write-Host ""
Write-Host "-----------------------------------------------------------------------------------------------------------------------"
Write-Host ""

# clean up
Remove-Variable -Name sourceloc
Remove-Variable -Name sourcedir
Remove-Variable -Name sourcepath
Remove-Variable -Name destdir
Remove-Variable -Name bakname
Remove-Variable -Name dv
Remove-Variable -Name qa
Remove-Variable -Name pd
Remove-Variable -Name environment
Remove-Variable -Name server
Remove-Variable -Name destpath
Remove-Variable -Name testpath
Remove-Variable -Name currentdir
Remove-Variable -Name pathbefore

