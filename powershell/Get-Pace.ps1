$miles   = [double](Read-Host -Prompt 'Miles')
$hours   = [double](Read-Host -Prompt 'Hours')
$minutes = [double](Read-Host -Prompt 'Minutes')
$seconds = [double](Read-Host -Prompt 'Seconds')

$totalSeconds = ($hours * 3600) + ($minutes * 60) + $seconds

$paceAllSeconds = $totalSeconds / $miles

$minutesPerMile = [math]::Truncate($paceAllSeconds / 60)

$remainingSeconds = [math]::Round($paceAllSeconds - ($minutesPerMile * 60))

$paceMinutes = "00" + $minutesPerMile
$paceMinutes = $paceMinutes.Substring($paceMinutes.Length - 2,2)

$paceSeconds = "00" + $remainingSeconds
$paceSeconds = $paceSeconds.Substring($paceSeconds.Length -2,2)

$pace = $paceMinutes + ":" + $paceSeconds
"Pace: $pace"

