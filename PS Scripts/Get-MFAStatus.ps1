Write-Host "Finding Azure Active Directory Accounts..." -ForegroundColor Green
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
$folder = [Microsoft.VisualBasic.Interaction]::InputBox("Choose Report Folder", "Report Folder", "c:\temp")

$Users = Get-MsolUser -All | Where-Object {($_.UserType -ne "Guest") -and ($_.IsLicensed -eq "True")}
$Report = [System.Collections.Generic.List[Object]]::new() # Create output file
Write-Host "Processing" -ForegroundColor Blue -NoNewline; write-host " $($Users.Count) " -ForegroundColor Green -NoNewline; write-host "accounts..." -ForegroundColor Blue
ForEach ($User in $Users) {

    $MFADefaultMethod = ($User.StrongAuthenticationMethods | Where-Object { $_.IsDefault -eq "True" }).MethodType
    $MFAPhoneNumber = $User.StrongAuthenticationUserDetails.PhoneNumber
    $PrimarySMTP = $User.ProxyAddresses | Where-Object { $_ -clike "SMTP*" } | ForEach-Object { $_ -replace "SMTP:", "" }
    $Aliases = $User.ProxyAddresses | Where-Object { $_ -clike "smtp*" } | ForEach-Object { $_ -replace "smtp:", "" }

    If ([bool]$User.StrongAuthenticationRequirements) {
        $MFAState = ($User.StrongAuthenticationRequirements).State
    }
    Else {
        $MFAState = 'Disabled'
    }

    If ($MFADefaultMethod) {
        Switch ($MFADefaultMethod) {
            "OneWaySMS" { $MFADefaultMethod = "Text code authentication phone" }
            "TwoWayVoiceMobile" { $MFADefaultMethod = "Call authentication phone" }
            "TwoWayVoiceOffice" { $MFADefaultMethod = "Call office phone" }
            "PhoneAppOTP" { $MFADefaultMethod = "Authenticator app or hardware token" }
            "PhoneAppNotification" { $MFADefaultMethod = "Microsoft authenticator app" }
        }
    }
    Else {
        $MFADefaultMethod = "Not enabled"
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

Write-Host "Report located: " -ForegroundColor Blue -NoNewline; write-host "$($folder)\MFAUsers.csv" -ForegroundColor Green
$Report | Select-Object UserPrincipalName, DisplayName, MFAState, MFADefaultMethod, MFAPhoneNumber, PrimarySMTP, Aliases | Sort-Object UserPrincipalName | Out-GridView
$Report | Sort-Object UserPrincipalName | Export-CSV -Encoding UTF8 -NoTypeInformation -path "$($folder)\MFAUsers.csv"