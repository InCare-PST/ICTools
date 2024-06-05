Write-Host "Finding Azure Active Directory Accounts..."

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.Read.All"

# Get all users excluding guest users
$Users = Get-MgUser -Filter "userType ne 'Guest' and accountEnabled eq true" -Property "id, displayName, userPrincipalName, strongAuthenticationMethods, proxyAddresses, strongAuthenticationUserDetails, strongAuthenticationRequirements" -All

$Report = [System.Collections.Generic.List[Object]]::new() # Create output file
Write-Host "Processing" $Users.Count "accounts..."

ForEach ($User in $Users) {
    $MFADefaultMethod = ($User.StrongAuthenticationMethods | Where-Object { $_.IsDefault -eq "True" }).MethodType
    $MFAPhoneNumber = $User.StrongAuthenticationUserDetails.PhoneNumber
    $PrimarySMTP = $User.ProxyAddresses | Where-Object { $_ -clike "SMTP:*" } | ForEach-Object { $_ -replace "SMTP:", "" }
    $Aliases = $User.ProxyAddresses | Where-Object { $_ -clike "smtp:*" } | ForEach-Object { $_ -replace "smtp:", "" }

    $MFAState = if ($User.StrongAuthenticationRequirements) {
        $User.StrongAuthenticationRequirements.State
    } else {
        'Disabled'
    }

    $MFADefaultMethod = switch ($MFADefaultMethod) {
        "OneWaySMS" { "Text code authentication phone" }
        "TwoWayVoiceMobile" { "Call authentication phone" }
        "TwoWayVoiceOffice" { "Call office phone" }
        "PhoneAppOTP" { "Authenticator app or hardware token" }
        "PhoneAppNotification" { "Microsoft authenticator app" }
        default { "Not enabled" }
    }
  
    $ReportLine = [PSCustomObject] @{
        UserPrincipalName = $User.UserPrincipalName
        DisplayName       = $User.DisplayName
        MFAState          = $MFAState
        MFADefaultMethod  = $MFADefaultMethod
        MFAPhoneNumber    = $MFAPhoneNumber
        PrimarySMTP       = ($PrimarySMTP -join ',')
        Aliases           = ($Aliases -join ',')
    }
                 
    $Report.Add($ReportLine)
}

Write-Host "Report is in c:\temp\MFAUsers.csv"
$Report | Select-Object UserPrincipalName, DisplayName, MFAState, MFADefaultMethod, MFAPhoneNumber, PrimarySMTP, Aliases | Sort-Object UserPrincipalName | Out-GridView
$Report | Sort-Object UserPrincipalName | Export-CSV -Encoding UTF8 -NoTypeInformation c:\temp\MFAUsers.csv
