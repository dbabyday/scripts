function Convert-FahrenheitToCelsius {
    <#
    .SYNOPSIS
        Converts Fahrenheit to Celsius and formats the output string.
    #>
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [double]$Fahrenheit
    )

    process {
        # Perform the calculation
        $celsius = ($Fahrenheit - 32) * (5 / 9)

        # Round to the tenths place
        $roundedF = [Math]::Round($Fahrenheit, 1)
        $roundedC = [Math]::Round($celsius, 1)

        # Return as a formatted string: "N.N F = N.N C"
        # The "{0:N1}" syntax forces 1 decimal place
        return "{0:N1} F = {1:N1} C" -f $roundedF, $roundedC
    }
}