function get-clientinfo {
    [CmdletBinding()]
    param (

        [string]$ClientName,

        [string]$path = "C:\temp"

    )
    Begin {
        if (![bool]$ClientName) {
            $ClientName = Read-Host -Prompt "Please enter Client Name"
        }
        $userlist = Get-ADUser -Filter * -Properties MobilePhone, OfficePhone, Enabled, displayname
    }
    Process {
        $EnabledUsers = $userlist | Where-Object { $_.enabled -eq $true -and [bool]($_.surname) -eq $true -and $_.name -notmatch "360" } 
        $EnabledUsers | Select-Object @{N = 'Name'; E = { $_.displayname } }, @{N = 'Email'; E = { $_.userprincipalname } }, MobilePhone, OfficePhone, Enabled | Export-Csv -Path $path\$ClientName.csv -NoTypeInformation
    }
    End {
        
    }
}
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

        $adusers = Get-ADUser -Filter * -Properties MobilePhone, OfficePhone

        $date = Get-Date -UFormat %e-%m-%G-%H.%M

        $workingpath = "$path\ClientUpdate$date"

        New-Item -Path $workingpath -Type Directory
        
    }
    Process {
        foreach ($user in $userinfo) {
            $adaccount = $adusers | Where-Object { $_.UserPrincipalName -match $user.email }
            if ([bool]$adaccount) {
                if ($user.enabled -eq "FALSE") {
                    if (($adaccount.enabled -eq $true) -and ($disable -eq $false)) {
                        $adaccount | Select-Object name, UserPrincipalName, enabled | Export-Csv -Path $workingpath\accountstodisable.csv -NoTypeInformation -Append
                    }
                    elseif (($adaccount.enabled -eq $true) -and ($disable -eq $true)) {
                        $adaccount | Set-ADUser -Enabled $false
                        $disabledaccount = Get-ADUser -Filter * -Properties enabled | Where-Object { $_.name -match $adaccount.name }
                        $disabledaccount | Select-Object name, UserPrincipalName, enabled | Export-Csv -Path $workingpath\accountsdisable.csv -NoTypeInformation -Append
                    }
                }
                else {
                    if (([bool]$user.Mobilephone) -or ([bool]$user.OfficePhone)) {
                        $addcommand = @{}
                        $newmobile = ""
                        $newoffice = ""
                        if ([bool]$user.Mobilephone) {
                            $tempmobile = $user.mobilephone -replace "\D+"
                            if ($tempmobile.length -eq 10) {
                                $newmobile = "{0:+1##########}" -f [int64]$tempmobile
                                $addcommand['MobilePhone'] = $newmobile
                            }
                            elseif ($tempmobile.length -eq 11) {
                                $newmobile = "{0:+###########}" -f [int64]$tempmobile
                                $addcommand['MobilePhone'] = $newmobile
                            }
                            else {
                                Write-Host "$($user.name) with mobile number $($user.Mobilephone) does not match required formatting."
                            }
                        }
                        if ([bool]$user.OfficePhone) {
                            $tempoffice = $user.OfficePhone -replace "\D+"
                            if ($tempoffice.length -eq 10) {
                                $newoffice = "{0:+1##########}" -f [int64]$tempoffice
                                $addcommand['OfficePhone'] = $newoffice
                            }
                            elseif ($tempoffice.length -eq 11) {
                                $newoffice = "{0:+###########}" -f [int64]$tempoffice
                                $addcommand['OfficePhone'] = $newoffice
                            }
                            else {
                                Write-Host "$($user.name) with Office number $($user.Businessphone) does not match required formatting."
                            }
                        }
                        #$adaccount | Select-Object name
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
                            $tempobject | Select-Object username, snowname, enabled, currentmobile, newmobile, currentoffice, newoffice | Export-Csv -Path $workingpath\proposed-mobile-update.csv -NoTypeInformation -Append
                        }
                        elseif ($apply -eq $true) {
                            if (([bool]$newmobile) -and ([bool]$newoffice)) {
                                Set-ADUser -Identity $adaccount.SamAccountName -OfficePhone $newoffice -MobilePhone $newmobile
                            }
                            elseif (([bool]$newmobile) -and (![bool]$newoffice)) {
                                Set-ADUser -Identity $adaccount.SamAccountName -MobilePhone $newmobile
                            }
                            elseif ((![bool]$newmobile) -and ([bool]$newoffice)) {
                                Set-ADUser -Identity $adaccount.SamAccountName -OfficePhone $newoffice
                            }
                            #Set-ADUser -Identity $adaccount.SamAccountName $addcommand
                            $tempobject | Select-Object username, snowname, enabled, currentmobile, newmobile, currentoffice, newoffice | Export-Csv -Path $workingpath\mobile-update.csv -NoTypeInformation -Append
                        }
                    }
                }
            }
            else {

                Write-Host "Cannot find AD account for $($user.name) with user id $($user.userid)" -ForegroundColor Red

                $user | Export-Csv -Path $workingpath\noaccount.csv -NoTypeInformation -Append

            }
        }
    }
    End {
        Compress-Archive -LiteralPath $workingpath -DestinationPath $path\ClientUpdate$date.zip
        if (Test-Path -Path $path\ClientUpdate$date.zip) {
            Remove-Item -LiteralPath $workingpath -Force
        }
    }
}