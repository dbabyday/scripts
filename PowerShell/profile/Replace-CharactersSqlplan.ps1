#param([String]$filePath)
#
#
#$content = Get-Content $filePath
#$content = $content -replace '&amp;#xd;&amp;#xa;',"`n"
#$content = $content -replace '&amp;#xd;',"`n"
#$content = $content -replace '&amp;#x9;',"`t"
#$content = $content -replace '&lt;',"<"
#$content = $content -replace '&gt;',">"
#$content = $content -replace '&amp;apos;',"'"
#$content = $content -replace '&amp;lt;',"&lt;"
#$content = $content -replace '&amp;gt;',"&gt;"
#$content | Set-Content $filePath





Function Replace-CharactersSqlplan {
	<#
		.NOTES
			Name: Replace-CharactersSqlplan
			Author: dbabyday
			Version History:
			1.0 - 20241031 - Initial Release.
		.SYNOPSIS
			Replace unicode hex character codes with their characters, for the query_plan xml from sys.query_store_plan.
		.DESCRIPTION
			Replace unicode hex character codes with their characters, for the query_plan xml from sys.query_store_plan.
		.PARAMETER $filePath
			Name of the file to replace the characters in
		.EXAMPLE
			PS> Replace-CharactersSqlplan -filePath C:\Users\dbabyday\Documents\plan1.sqlplan
	#>	

	[CmdletBinding()]

	Param (
		[Parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
		[ValidateNotNullorEmpty()]
		[String] $filePath
	)

	Process {
		$content = Get-Content $filePath
		$content = $content -replace '&amp;#xd;&amp;#xa;',"`n"
		$content = $content -replace '&amp;#xd;',"`n"
		$content = $content -replace '&amp;#x9;',"`t"
		$content = $content -replace '&lt;',"<"
		$content = $content -replace '&gt;',">"
		$content = $content -replace '&amp;apos;',"'"
		$content = $content -replace '&amp;lt;',"&lt;"
		$content = $content -replace '&amp;gt;',"&gt;"
		$content | Set-Content $filePath
	}
}