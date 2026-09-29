Function To-MB {
	[CmdletBinding()]

	Param (
		[Parameter(ValueFromPipeline)]
		$Item
	)

	Process {
		Select-Object -InputObject $Item Mode, LastWriteTime, @{Name="Length MB";Expression={ "{0,15:N1}" -f ($_.Length / 1MB) }}, Name
	}
}