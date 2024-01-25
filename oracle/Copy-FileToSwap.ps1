

# user input
$file    = Read-Host -Prompt "File name (full path)"
$dirName = Read-Host -Prompt "Directory name on swap drive"

# create directory
$dirSwap = "\\na\neendata\Swap\"
$dir     = $dirSwap + $dirName + "\"
if ( !(Test-Path -Path $dir) ) {
    New-Item -Path $dirSwap -Name $dirName -ItemType Directory
}

# copy the file
Copy-Item -Path $file -Destination $dir

# display the file path
Get-ChildItem -Path $dir | Select-Object Mode, LastWriteTime, Length, FullName | Format-Table -AutoSize


