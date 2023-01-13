# user iput
$computerName = Read-Host "Computer Name"
$driveLetter  = Read-Host "Drive Letter (ex: F)"
$email        = Read-Host "Email Address"
$threshold    = Read-Host "Threshold to notify when greater than (GB)"

# other variables
$driveName     = $driveLetter + ":\"

# check the drive capacity
do {
    Start-Sleep -Seconds 60
    $drive = Get-WmiObject win32_volume -ComputerName $computerName | Where-Object {$_.Name -eq $driveName}
}
until ( ($drive.Capacity / 1GB) -gt $threshold )

# send the notification
$PSEmailServer = "intranet-smtp.plexus.com"
$subject       = "Expanded | " + $computerName + " " + $driveName
$body          = [string]([int]($drive.Capacity / 1GB)) + " GB"

Send-MailMessage -To $to -From $from -Subject $subject -Body $body -BodyAsHtml

