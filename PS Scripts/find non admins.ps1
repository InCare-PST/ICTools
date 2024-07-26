$domainAdminsGroup = "CN=Domain Admins,CN=Users,DC=kittyhawkinc,DC=local"
$enterpriseAdminsGroup = "CN=Enterprise Admins,CN=Users,DC=kittyhawkinc,DC=local"


$adminUsers = Get-ADUser -Filter * -Properties MemberOf | Where-Object { 
    ($_.MemberOf -contains $domainAdminsGroup) -or ($_.MemberOf -contains $enterpriseAdminsGroup)
}

# Get all users
$allUsers = Get-ADUser -Filter * -Properties MemberOf

# Filter out admin users from all users
$nonAdminUsers = $allUsers | Where-Object { 
    ($adminUsers -notcontains $_)
}



# Reset the password for each non-admin user
foreach ($user in $nonAdminUsers) {
    try {
        Set-ADAccountPassword -Identity $user.SamAccountName -NewPassword (ConvertTo-SecureString -AsPlainText $newPassword -Force) -Reset
        Write-Host "Password reset for user: $($user.SamAccountName)"
    } catch {
        Write-Host "Failed to reset password for user: $($user.SamAccountName). Error: $_"
    }
}
