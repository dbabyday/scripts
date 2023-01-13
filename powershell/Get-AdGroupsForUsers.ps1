#Clear-Host

#----------------------------------------------------
#--// GET GROUPS FOR USERS                       //--
#----------------------------------------------------

$users = Read-Host "user"

$groups = @()

$users | ForEach-Object {
    $user = $_
    Get-ADUser -Identity $user -Properties MemberOf | Select-Object -ExpandProperty MemberOf | ForEach-Object {
        $name = ($_).Substring(($_).IndexOf("DC=")+3,2) + "\" + ($_).Substring(3,($_).IndexOf(",")-3)

        $group = New-Object -TypeName PSObject
        $group | Add-Member -Name "user_name" -MemberType NoteProperty -Value $user
        $group | Add-Member -Name "group_name" -MemberType Noteproperty -Value $name
        $groups += $group
    }	
}

$groups | Sort-Object user_name, group_name | Format-Table -Autosize



