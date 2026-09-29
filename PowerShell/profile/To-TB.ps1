Function To-TB {
	[CmdletBinding()]

	Param (
		[Parameter(ValueFromPipeline)]
		$Item
	)

	Process {
		Select-Object -InputObject $Item Mode, LastWriteTime, @{Name="Length TB";Expression={ "{0,15:N1}" -f ($_.Length / 1TB) }}, Name
	}
}