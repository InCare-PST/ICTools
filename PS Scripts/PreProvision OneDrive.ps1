#Script to PreProvision OneDrive for all users
[Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')

$title = 'SharePoint Site'
$msg   = 'Enter your SharepointSite:'
$defaultvalue = 'https://contoso-admin.sharepoint.com'

$SharepointURL = [Microsoft.VisualBasic.Interaction]::InputBox($msg, $title,$defaultvalue)
#$Credential = (Get-Credential)

#Connect-MsolService -Credential $Credential
Connect-AzureAD -Confirm
Connect-SPOService -Url $SharepointURL

$list = @()
#Counterspre
$i = 0


#Get licensed users
$users = Get-AzureADUser | Where-Object AssignedLicenses -ne $NULL
#total licensed users
$count = $users.count

foreach ($u in $users) {
    $i++
    Write-Host "$i/$count"

    $upn = $u.userprincipalname
    $list += $upn

    if ($i -eq 199) {
        #We reached the limit
        Request-SPOPersonalSite -UserEmails $list -NoWait
        Start-Sleep -Milliseconds 655
        $list = @()
        $i = 0
    }
}

if ($i -gt 0) {
    Request-SPOPersonalSite -UserEmails $list -NoWait
}