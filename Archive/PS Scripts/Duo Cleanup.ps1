$groupName = 'DuoMFA Users'
$Members   = (Get-ADGroup $groupName -Properties members).members
foreach($member in $members){
    write-verbose "Checking on '$member'..." -verbose
    $userstatus = Get-aduser $member
    if(-not($userstatus.enabled)){
        Remove-ADGroupMember $groupName -Members $member -Confirm:$false -Verbose
    }
}