$targetDirectory = "C:\JamesDownloads\"

if ( (Get-ChildItem -Path $targetDirectory -Filter "*.zip").Count -eq 0 ) {
    Write-Warning -Message "There are no .zip files in $targetDirectory"
}

if ( (Get-ChildItem -Path $targetDirectory -Filter "*.zip").Count -gt 1 ) {
    Write-Warning -Message "There are multiple .zip files in $targetDirectory"
}    

if ( (Get-ChildItem -Path $targetDirectory -Filter "*.zip").Count -eq 1 ) {
    $extract = "y"
    
    if ((Get-ChildItem -Path $targetDirectory | Where-Object { ($_.Mode -eq '-a----') -and (($_.Name).Substring(($_.Name).Length - 4,4) -ne '.zip') }).Count -ne 0) {
        $msg = "There are other files in $targetDirectory `r`n"
        $msg += "------------------------------------------------------------------------------------------`r`n"
        Get-ChildItem -Path $targetDirectory | Where-Object { ($_.Mode -eq '-a----') -and (($_.Name).Substring(($_.Name).Length - 4,4) -ne '.zip') } | ForEach-Object {
            $msg += $_.Name + "`r`n"
        }
        Write-Warning -Message $msg
        Write-Host ""
        $extract = Read-Host "Continue with the extract? [y] yes, [n] no"
        $extract = $extract.ToLower()
    }

    if ( ($extract -ne 'y') -and ($extract -ne 'n') ) {
        Write-Warning "You did not enter y, n. Please start over."
    }

    if ( $extract -eq "n") {
        Write-Host "Canceled | No action taken"
    }

    if ( $extract -eq "y" ) {
        $source      = (Get-ChildItem -Path $targetDirectory -Filter "*.zip").FullName
        $destination = $targetDirectory
        [io.compression.zipfile]::ExtractToDirectory($source, $destination)

        Write-Host ""
        $msg = "The files have been extracted from $source `r`n"
        $msg += "`r`n"
        $msg += "The following are files currently in $targetDirectory `r`n"
        $msg += "------------------------------------------------------------------------------------------`r`n"
        Get-ChildItem -Path $targetDirectory | Where-Object { ($_.Mode -eq '-a----') -and (($_.Name).Substring(($_.Name).Length - 4,4) -ne '.zip') } | ForEach-Object {
            $msg += $_.Name + "`r`n"
        }
        Write-Host $msg
        Write-Host ""

        $deleteZip = Read-Host "Delete the .zip file? [y] yes, [n] no"
        $deleteZip = $deleteZip.ToLower()
        if ($deleteZip -eq 'y') {
            Remove-Item -Path $source
            Write-Host "DELETED | $source"
        }
    }
}




