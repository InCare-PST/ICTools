
# Connect to Microsoft Graph
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
$scope = [Microsoft.VisualBasic.Interaction]::InputBox("Enter Scope Requested", "Scope", "User.Read.All,Organization.Read.All,AuditLog.Read.All,Directory.Read.All,UserAuthenticationMethod.Read.All")
#$scope = "User.Read.All,Organization.Read.All,AuditLog.Read.All,Directory.Read.All"
Connect-MgGraph -Scopes $scope


$Users = Get-MgUser  -All

$Report = [System.Collections.Generic.List[Object]]::new() # Create output file

ForEach ($User in $Users) {
    try {
        # Retrieve the user's authentication methods
        $AuthMethods = Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/v1.0/users/$($User.Id)/authentication/methods"

        $MFADefaultMethod = $null
        $MFAPhoneNumber = $null

        ForEach ($Method in $AuthMethods.value) {
            Switch ($Method["@odata.type"]) {
                "#microsoft.graph.phoneAuthenticationMethod" {
                    $MFADefaultMethod = "Phone"
                    $MFAPhoneNumber = $Method.phoneNumber
                }
                "#microsoft.graph.softwareOathAuthenticationMethod" {
                    $MFADefaultMethod = "Software OATH"
                }
                "#microsoft.graph.fido2AuthenticationMethod" {
                    $MFADefaultMethod = "FIDO2"
                }
                "#microsoft.graph.microsoftAuthenticatorAuthenticationMethod" {
                    $MFADefaultMethod = "Microsoft Authenticator"
                }
            }
        }

        $PrimarySMTP = $User.ProxyAddresses | Where-Object { $_ -clike "SMTP:*" } | ForEach-Object { $_ -replace "SMTP:", "" }
        $Aliases = $User.ProxyAddresses | Where-Object { $_ -clike "smtp:*" } | ForEach-Object { $_ -replace "smtp:", "" }

        $MFAState = if ($MFADefaultMethod) { 'Enabled' } else { 'Disabled' }

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
    } catch {
        Write-Host "Failed to retrieve authentication methods for user: $($User.UserPrincipalName)" -ForegroundColor Red
    }
}

Write-Host "Report is in c:\temp\MFAUsers.csv"
$Report | Select-Object UserPrincipalName, DisplayName, MFAState, MFADefaultMethod, MFAPhoneNumber, PrimarySMTP, Aliases | Sort-Object UserPrincipalName | Out-GridView
$Report | Sort-Object UserPrincipalName | Export-CSV -Encoding UTF8 -NoTypeInformation c:\temp\MFAUsers.csv
