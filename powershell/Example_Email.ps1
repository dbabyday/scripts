$smpt    = 'intranet-smtp.plexus.com'
$from    = 'james.lutsey@plexus.com'
$to      = 'james.lutsey@plexus.com'
#$bcc     = 'james.lutsey@yahoo.com'
$subject = 'Testing Email with PowerShell'
$body    = 'Just <a href="https://www.packers.com/">a test</a> message.'

$emailParams = @{
    SmtpServer = $smpt 
    From       = $from 
    To         = $to 
    #Bcc        = $bcc
    Subject    = $subject 
    Body       = $body 
    BodyAsHtml = $True
}

Send-MailMessage @emailParams