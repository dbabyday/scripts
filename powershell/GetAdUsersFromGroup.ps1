#$accounts = null

$myGroup = 'AP\Penang-MY Site MSSQL Administrators in AP'
$members = Get-QADGroupMember $myGroup
foreach ($member in $members) 
{ 
    # check if it is a group or user




    $member.DN.Substring($member.DN.IndexOf(',DC=')+4,2) + "\" + $member.SamAccountName 
}


