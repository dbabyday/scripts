function Convert-CelsiusToFahrenheit {
    <#
    .SYNOPSIS
        Converts Celsius to Fahrenheit and formats the output string.
    #>
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [double]$Celsius
    )

    process {
        # Perform the calculation
        $fahrenheit = ($Celsius * (9 / 5)) + 32

        # Round to the tenths place
        $roundedC = [Math]::Round($Celsius, 1)
        $roundedF = [Math]::Round($fahrenheit, 1)

        # Return as a formatted string: "N.N C = N.N F"
        return "{0:N1} C = {1:N1} F" -f $roundedC, $roundedF
    }
}