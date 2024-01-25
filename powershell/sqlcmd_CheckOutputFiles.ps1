param([Parameter(Mandatory=$true)][string]$dir)


write-host " "
write-host " "
gci -recurse -path $dir | foreach-object {
	if ($_.Length -gt 3) {
		write-host "-------------------------------------------------------------"
		write-host $_.Name
		write-host "-------------------------------------------------------------"
		gc $_.FullName
		write-host " "
		write-host " "
	}
}
write-host " "
write-host " "

