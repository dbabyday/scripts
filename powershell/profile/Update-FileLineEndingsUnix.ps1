Function Update-FileLineEndingsUnix {
	<#
	.NOTES
		Name: Update-FileLineEndingsUnix
		Author: James Lutsey
		Version History:
		1.0 - 2021-10-08 - Initial Release.
	.SYNOPSIS
		Update a file to UNIX line endings.
	.DESCRIPTION
		Replaces line endings in a file to UNIX line endings ("`r`n", "`n")
	.PARAMETER $FileFullName
		Full path of file name in which to change line endings
	.EXAMPLE
		[PS] C:\> Update-FileLineEndingsUnix -FileFullName \\neen-dsk-011\it$\database\users\James\JamesDownloads\PDU012345678_20210101_1.sql
		Updates file \\neen-dsk-011\it$\database\users\James\JamesDownloads\PDU012345678_20210101_1.sql to change line endings to UNIX line endings
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true)]
		[String] $FileFullName
	)#Param
	Begin {
		$tmpFile='\\neen-dsk-011\it$\database\users\James\JamesDownloads\tmp.txt'
	}#Begin
	Process {
		if (Test-Path -Path $FileFullName) {
			# write the file with unix line endings
			[IO.File]::WriteAllText("$tmpFile", ([IO.File]::ReadAllText("$FileFullName") -replace "`r`n", "`n"))

			# replace the original file
			Remove-Item -Path $FileFullName
			Rename-Item -Path $tmpFile -NewName $FileFullName
		}
		else {
			Write-Warning -Message "File does not exist: $FileFullName"
		}
			}#Process
	End {
		# nothing to end with this time
	}#End
}#Function