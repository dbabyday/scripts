# Prompt the user for the source and target directories
$SourceDir = Read-Host "Enter the path to the SOURCE folder"
$TargetDir = Read-Host "Enter the path to the TARGET folder"

# Validate that the source directory actually exists before proceeding
if (!(Test-Path -Path $SourceDir -PathType Container)) {
    Write-Error "The source folder '$SourceDir' does not exist or is not a directory. Exiting script."
    exit
}

# Ensure the target directory exists, create it if it doesn't
if (!(Test-Path -Path $TargetDir -PathType Container)) {
    Write-Host "Target folder does not exist. Creating: $TargetDir" -ForegroundColor Yellow
    New-Item -Path $TargetDir -ItemType Directory | Out-Null
}

# --- STEP 1: Copy new/updated items from Source to Target ---
Get-ChildItem -Path $SourceDir -Recurse | ForEach-Object {
    $RelativePath = $_.FullName.Substring($SourceDir.Length)
    $DestinationPath = Join-Path $TargetDir $RelativePath

    if ($_.PSIsContainer) {
        if (!(Test-Path -Path $DestinationPath)) {
            New-Item -Path $DestinationPath -ItemType Directory | Out-Null
        }
    }
    else {
        $DestinationFile = Get-Item -Path $DestinationPath -ErrorAction SilentlyContinue
        if (-not $DestinationFile -or $_.LastWriteTime -gt $DestinationFile.LastWriteTime) {
            $ParentDir = Split-Path -Parent $DestinationPath
            if (!(Test-Path -Path $ParentDir)) {
                New-Item -Path $ParentDir -ItemType Directory | Out-Null
            }
            Copy-Item -Path $_.FullName -Destination $DestinationPath -Force
            Write-Host "Updated: $RelativePath"
        }
    }
}

# --- STEP 2: Delete items from Target that no longer exist in Source ---
Get-ChildItem -Path $TargetDir -Recurse | Sort-Object FullName -Descending | ForEach-Object {
    $RelativePath = $_.FullName.Substring($TargetDir.Length)
    $SourcePath = Join-Path $SourceDir $RelativePath

    if (!(Test-Path -Path $SourcePath)) {
        Remove-Item -Path $_.FullName -Recurse -Force
        Write-Host "Deleted: $RelativePath" -ForegroundColor Red
    }
}

Write-Host "Sync complete!" -ForegroundColor Green
