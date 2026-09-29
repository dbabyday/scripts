Function Convert-WordToNumbers {
	<#
		.NOTES
			Name: Convert-WordToNumbers.ps1
			Author: dbabyday
			Version History:
			1.0 - 20240503 - Initial Release.
		.SYNOPSIS
			Convert the letters of a word to the numbers from a phone keypad
		.DESCRIPTION
			Convert the letters of a word to the numbers from a phone keypad
		.PARAMETER $Word
			The word to convert to numbers
		.EXAMPLE
			PS> Get-DriveSpace -Word cold
	#>

	[CmdletBinding()]

	Param (
		[Parameter(Mandatory = $true)]
		[String] $Word
	)

	Begin {
		# nothing to do here
	}

	Process {
		$NumberOutput = ""

		foreach ($Char in $Word.ToCharArray()) {
			switch ($Char) {
				" " { $NumberOutput = $NumberOutput + "1" }
				"A" { $NumberOutput = $NumberOutput + "2" }
				"B" { $NumberOutput = $NumberOutput + "2" }
				"C" { $NumberOutput = $NumberOutput + "2" }
				"D" { $NumberOutput = $NumberOutput + "3" }
				"E" { $NumberOutput = $NumberOutput + "3" }
				"F" { $NumberOutput = $NumberOutput + "3" }
				"G" { $NumberOutput = $NumberOutput + "4" }
				"H" { $NumberOutput = $NumberOutput + "4" }
				"I" { $NumberOutput = $NumberOutput + "4" }
				"J" { $NumberOutput = $NumberOutput + "5" }
				"K" { $NumberOutput = $NumberOutput + "5" }
				"L" { $NumberOutput = $NumberOutput + "5" }
				"M" { $NumberOutput = $NumberOutput + "6" }
				"N" { $NumberOutput = $NumberOutput + "6" }
				"O" { $NumberOutput = $NumberOutput + "6" }
				"P" { $NumberOutput = $NumberOutput + "7" }
				"Q" { $NumberOutput = $NumberOutput + "7" }
				"R" { $NumberOutput = $NumberOutput + "7" }
				"S" { $NumberOutput = $NumberOutput + "7" }
				"T" { $NumberOutput = $NumberOutput + "8" }
				"U" { $NumberOutput = $NumberOutput + "8" }
				"V" { $NumberOutput = $NumberOutput + "8" }
				"W" { $NumberOutput = $NumberOutput + "9" }
				"X" { $NumberOutput = $NumberOutput + "9" }
				"Y" { $NumberOutput = $NumberOutput + "9" }
				"Z" { $NumberOutput = $NumberOutput + "9" }
				Default { $NumberOutput = $NumberOutput + "0" }
			}
		}

		$NumberOutput
	}
	
	End {
		# nothing to do here
	}
}