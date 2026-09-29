Function To-KB {
	[CmdletBinding()]

	Param (
		[Parameter(ValueFromPipeline)]
		$Item
	)

	Process {
		Select-Object -InputObject $Item Mode, LastWriteTime, @{Name="Length KB";Expression={ "{0,15:N1}" -f ($_.Length / 1KB) }}, Name
	}
}