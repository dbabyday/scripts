
# user input
$account = Read-Host "Account (no domain leding letters)"
$group   = Read-Host "Group (no domain leding letters)"
$server   = Read-Host "Server/Domain (ap.plexus.com, eu.plexus.com, na.plexus.com)"

$member  = "No --> $account is NOT a member of $group"

Get-ADGroupMember -Identity $group -Server $server | ForEach-Object {
	if ($_.SamAccountName -eq $account) {
	    $member = "Yes --> $account IS a member of $group"
	}
}

Write-Host $member


