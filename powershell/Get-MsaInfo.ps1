$account = Read-Host "Account"
$groups = @()

Get-ADServiceAccount -Identity $account -Properties MemberOf | select -ExpandProperty MemberOf | foreach {
	$domain        = $null
	$name          = $null
	$fullname      = $null
	$groupcategory = $null

	$domain = (($_).Substring(($_).IndexOf("DC=")+3,2)).ToUpper()
	$name = ($_).Substring(3,($_).IndexOf(",")-3)
	$fullname = $domain + "\" + $name

	Get-ADGroup $name | ForEach-Object { $groupcategory = $_.GroupCategory }
	
	$group = New-Object -TypeName PSObject
	$group | Add-Member -Name "group_name" -MemberType Noteproperty -Value $fullname
	$group | Add-Member -Name "group_category" -MemberType Noteproperty -Value $groupcategory
	$groups += $group
}

$groups | Sort-Object group_name

Get-ADServiceAccount $account -properties * | Select-Object Name, SamAccountName, TrustedForDelegation | Format-Table -AutoSize
