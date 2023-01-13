$array = @()

$object = New-Object -TypeName PSObject

$object | Add-Member -Name 'Name' -MemberType Noteproperty -Value 'Joe'
$object | Add-Member -Name 'Age' -MemberType Noteproperty -Value 32
$object | Add-Member -Name 'Info' -MemberType Noteproperty -Value 'something about him'

$array += $object

$array | Format-Table