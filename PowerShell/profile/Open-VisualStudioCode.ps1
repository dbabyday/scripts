Function Open-VisualStudioCode {
	[CmdletBinding()]

	Param (
		[String] $filePath
	)

	Process {
		if ($PSBoundParameters.ContainsKey('filePath')) {
			$fullPath = (Get-ChildItem -Path $filePath).FullName
			code $fullPath
		}
		else {
			code -n
		}
	}
}