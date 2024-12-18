#Force Password Changes

import-module ActiveDirectory

#Script to unset Password never expires
$usersnever = Get-ADUser -Filter {PasswordNeverExpires -eq $true}
$usersnever = $usersnever | Where-Object SamAccountName -notlike "Thrive*"
$usersnever = $usersnever | Where-Object SamAccountName -notlike "TDServ*"
$usersnever = $usersnever | Where-Object SamAccountName -notlike "ADSyncMSA7f3b3$"

#verify no thrive!
$usersnever | Sort-Object SamAccountName 

#Script to do the work
foreach($u in $usersnever){try{
    get-aduser $u.samaccountname | Set-ADUser -PasswordNeverExpires $false
} catch {
    Write-Host "Failed unset password never expires for user: $($user.SamAccountName). Error: $_"
}
}



#Force Expire Passwords
$users = Get-ADUser -Filter {Enabled -eq $true}
$users = $users | Where-Object SamAccountName -notlike "Thrive*"
$users = $users | Where-Object SamAccountName -notlike "TDServ*"
#$users = $users | Where-Object SamAccountName -notlike "ADSyncMSA7f3b3$"
$users = $users | Where-object  {($_.DistinguishedName -notlike "*OU=Services*") -and ($_.Enabled -eq $True)}

#verify users before forcing password change at login
$users | Select-Object SamAccountName

#script to force password change at next login
foreach($u in $users){try {
    #get-aduser $u.samaccountname | Set-ADUser -ChangePasswordAtLogon $true
    get-aduser $u.samaccountname -Properties * | Select SamAccountName,PasswordNeverExpires,PasswordExpired
} catch {
    Write-Host "Failed to expire password for user: $($user.SamAccountName). Error: $_"
}
}



#Disable Domain Admin accounts not thrive
$domainadmins = Get-ADGroupMember -Identity "Domain Admins" -Recursive | Get-ADUser -Property SamAccountName
$entadmins = Get-ADGroupMember -Identity "Enterprise Admins" -Recursive | Get-ADUser -Property SamAccountName
$admins = Get-ADGroupMember -Identity "Administrators" -Recursive | Get-ADUser -Property SamAccountName
$schadmins = Get-ADGroupMember -Identity "Schema Admins" -Recursive | Get-ADUser -Property SamAccountName
$adminsall = @()
$adminsall += $domainadmins
$adminsall += $entadmins
$adminsall += $admins
$adminsall += $schadmins
$adminsall = $adminsall | Select-Object -Unique
$adminsall = $adminsall | Where-Object SamAccountName -notlike "Thrive*"
$adminsall = $adminsall | Where-Object SamAccountName -notlike "TDServ*"

$adminsall | Sort-Object SamAccountName

#Verify you are not going to lock yourself out!
foreach($a in $adminsall){try {
    get-aduser $a.samaccountname | set-aduser -Enabled $false
}
catch {
    write-host "Failed to disable Admin user: $($user.SamAccountName). Error: $_"
}
}

