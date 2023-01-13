$miles       = [double](Read-Host -Prompt 'Miles')
$paceMinutes = [double](Read-Host -Prompt 'Pace Minutes')
$paceSeconds = [double](Read-Host -Prompt 'Pace Seconds')

# convert the pace into total seconds per mile
$paceTotalSeconds = $paceMinutes * 60 + $paceSeconds

# calculate the total seconds to run the distance
$timeTotalSeconds = $paceTotalSeconds * $miles

# get the whole hours
$iTimeHours = [math]::Truncate($timeTotalSeconds / 3600)

# get the whole minutes
$timeSecondsRemainingAfterHours = $timeTotalSeconds - ($iTimeHours * 3600)
$iTimeMinutes = [math]::Truncate($timeSecondsRemainingAfterHours / 60)

# get the seconds
$iTimeSeconds = $timeSecondsRemainingAfterHours - ($iTimeMinutes * 60)

# convert the time parts to string and concatenate
$sTimeHours = "00" + [string]$iTimeHours
$sTimeHours = $sTimeHours.Substring($sTimeHours.Length - 2,2)

$sTimeMinutes = "00" + [string]$iTimeMinutes
$sTimeMinutes = $sTimeMinutes.Substring($sTimeMinutes.Length - 2,2)

$sTimeSeconds = "00" + [string]$iTimeSeconds
$sTimeSeconds = $sTimeSeconds.Substring($sTimeSeconds.Length - 2,2)

$time = $sTimeHours + ":" + $sTimeMinutes + ":" + $sTimeSeconds

# display the result
"Time: $time"

