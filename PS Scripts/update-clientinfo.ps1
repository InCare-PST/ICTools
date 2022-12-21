function update-clientinfo {
    [CmdletBinding()]
    Param (

        [string]$path = "c:\temp\",

        [string]$filename = "clientupdate.csv",

        [switch]$disable = $false,

        [switch]$apply = $false
            
    )
    Begin {

        $userinfo = Import-Csv -Path $path\$filename

        $adusers = Get-ADUser -Filter *

        $date = Get-Date -UFormat %e-%m-%G-%H.%M

        $workingpath = "$path\ClientUpdate$date"

        New-Item -Path $workingpath -Type Directory
        
    }
    Process {
        foreach ($user in $userinfo) {
            $adaccount = $adusers | Where-Object { $_.UserPrincipalName -match $user.userid }
            if ([bool]$adaccount) {
                if ($user.enabled -eq "N") {
                    if (($adaccount.enabled -eq $true) -and ($disable -eq $false)) {
                        $adaccount | Select-Object name, userid, enabled | Export-Csv -Path $workingpath\accountstodisable$date.csv -NoTypeInformation -Append
                    }
                    elseif (($adaccount.enabled -eq $true) -and ($disable -eq $true)) {
                        $adaccount | Set-ADUser -Enabled $false
                        $disabledaccount = Get-ADUser -Filter * -Properties enabled| Where-Object {$_.name -match $adaccount.name}
                        $disabledaccount | Select-Object name, userid, enabled | Export-Csv -Path $workingpath\accountsdisable$date.csv -NoTypeInformation -Append
                    }
                }
                else {
                    if (([bool]$user.Mobilephone) -or ([bool]$user.Businessphone)) {
                        if ([bool]$user.Mobilephone) {
                            $tempmobile = $user.mobilephone -replace "\D+"
                            $addcommand = "-MobilePhone $newmobile"
                            if ($tempmobile.length -eq 10) {
                                $newmobile = "{0:+1##########}" -f [int64]$tempmobile
                            }
                            elseif ($tempmobile.length -eq 11) {
                                $newmobile = "{0:+###########}" -f [int64]$tempmobile
                            }
                            else {
                                Write-Host "$($user.name) with mobile number $($user.Mobilephone) does not match required formatting."
                            }
                        }
                        if ([bool]$user.Businessphone) {
                            $tempoffice = $user.Businessphone -replace "\D+"
                            $addcommand = $addcommand + " -officephone $newoffice"
                            if ($tempoffice.length -eq 10) {
                                $newoffice = "{0:+1##########}" -f [int64]$tempoffice
                            }
                            elseif ($tempoffice.length -eq 11) {
                                $newoffice = "{0:+###########}" -f [int64]$tempoffice
                            }
                            else {
                                Write-Host "$($user.name) with Office number $($user.Businessphone) does not match required formatting."
                            }
                        }
                        $adaccount | Select-Object name
                        $props = @{
                            username      = $adaccount.name
                            snowname      = $user.name
                            enabled       = $adaccount.enabled
                            currentmobile = $adaccount.mobilephone
                            newmobile     = $newmobile
                            currentoffice = $adaccount.OfficePhone
                            newoffice     = $newoffice
                        }
                        $tempobject = New-Object psobject -Property $props
                        if ($apply -eq $false) {
                            $tempobject | Select-Object username, snowname, enabled, currentmobile, newmobile, currentoffice, newoffice | Export-Csv -Path $workingpath\proposed-mobile-update$date.csv -NoTypeInformation -Append
                        }
                        elseif ($apply -eq $true) {
                            $adaccount | Set-ADUser $addcommand
                            $tempobject | Select-Object username, snowname, enabled, currentmobile, newmobile, currentoffice, newoffice | Export-Csv -Path $workingpath\mobile-update$date.csv -NoTypeInformation -Append
                        }
                    }
                }
            }
            else {

                Write-Host "Cannot find AD account for $($user.name) with user id $($user.userid)" -ForegroundColor Red

                $user | Export-Csv -Path $workingpath\noaccount$date.csv -NoTypeInformation -Append

            }
        }
    }
    End {}
}