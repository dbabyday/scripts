
# Define the path to your input file
$filePath = '\\neen-dsk-011\it$\database\users\James\JamesProjects\PlanCache\RedundantQueries\GSF\usp_UnitSearch_Select\usp_UnitSearch_Select - Examples.sql' # **Change this to your actual file path**

# Regular expression patterns for extraction
# (.*?) is the non-greedy capture group for the value
$regexString1 = '@p_DateCode=(.*?),@'
#$regexString2 = '@p_ItemNumberInternal=(.*?),@'

# Array to store the results from all lines
$results = @()

Write-Host "Processing file: $filePath"
Write-Host "---"

# get the row number for reference
$rownum = 0

# Use Get-Content to read the file line by line
    Get-Content -Path $filePath | ForEach-Object {
        $rownum++
        $line = $_
        
        # Initialize values for the current line
        $string1Value = "N/A"
#        $internalValue = "N/A"
        
        # 1. Extract @p_ItemNumberCustomer
        if ($line -match $regexString1) {
            $string1Value = $Matches[1]
        }
        
#        # 2. Extract @p_ItemNumberInternal
#        if ($line -match $regexInternal) {
#            $internalValue = $Matches[1]
#        }
        
        # Create an object with the results for the current line
        if ($string1Value -ne "N''") {
            $results += [PSCustomObject]@{
                RowNumber               = $rownum
                #LineContent             = $line.Substring(0, [System.Math]::Min(80, $line.Length)) + "..." # Truncate for display
                string1Value      = $string1Value
                #ItemNumberInternal      = $internalValue
            }
        }
    }
    
    # --- Output Results ---
    Write-Host "Processing complete for $regexString1"
    $results | Format-Table -AutoSize
    
    # Optional: Export the results to a CSV file
    # $results | Export-Csv -Path "C:\Scripts\extracted_values.csv" -NoTypeInformation
