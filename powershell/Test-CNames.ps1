$fqdnAndCnames = Get-Content -Path C:\JamesScripts\PowerShell\Test-CNames_InputList.txt
$dnsRecords = @()

$fqdnAndCnames | ForEach-Object {
    $fqdnAndCname = $_ -split ','
	$fqdn = $fqdnAndCname[0]
	$cname = $fqdnAndCname[1]

    $testFqdn = Test-Connection $fqdn -ErrorAction SilentlyContinue -Count 1 | Select-Object IPV4Address
    If ($testFqdn -eq $null) {
    	$result = 'FAIL - FQDN failed Test-Connection'
    	$ipFqdn = ''
    }
    Else {
	    $ipFqdn = (([string]$testFqdn).Replace('@{IPV4Address=','')).Replace('}','')

	    $testCname = Test-Connection $cname -ErrorAction SilentlyContinue -Count 1 | Select-Object IPV4Address
	    If ($testCname -eq $null) {
	        $result = 'FAIL - CNAME not created'
	        $ipCname = ''
	    }
	    Else {
	        $ipCname = (([string]$testCname).Replace('@{IPV4Address=','')).Replace('}','')
	        
	        If ( $ipFqdn -eq $ipCname ) {
	            $result = 'PASS - IP Addresses match'
	        }
	        Else {
	            $result = 'FAIL - IP Addresses do not match'
	        }
	    }    
    }

	$record = New-Object -TypeName PSObject
	$record | Add-Member -Name 'fqdn'    -MemberType NoteProperty -Value $fqdn
	$record | Add-Member -Name 'cname'   -MemberType NoteProperty -Value $cname
	$record | Add-Member -Name 'ipFqdn'  -MemberType NoteProperty -Value $ipFqdn
	$record | Add-Member -Name 'ipCname' -MemberType NoteProperty -Value $ipCname
	$record | Add-Member -Name 'result'  -MemberType NoteProperty -Value $result
	$dnsRecords += $record
}

$dnsRecords | Format-Table -AutoSize
#$dnsRecords | Out-GridView




