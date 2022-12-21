function update-clientinfo {
    [CmdletBinding()]
        Param (

            [string]$path = "c:\temp\",

            [string]$filename = "clientupdate.csv",

            [switch]$disable = $false,

            [switch]$apply = $false
            
        )
    Begin{

        $userinfo = Import-Csv -Path $path\$filename

        $adusers = Get-ADUser -Filter *

        $date = Get-Date -Format MM-dd-yyyy  
        
        if (Test-Path -Path $path\accountstodisable$date.csv) {
            Remove-Item -Path $path\accountstodisable$date.csv
        }
    }
    Process{
        foreach($user in $userinfo){
            $adaccount = $adusers | Where-Object {$_.UserPrincipalName -match $user.userid}
            if([bool]$adaccount){
                if($user.enabled -eq "N"){
                    if(($adaccount.enabled -eq $true) -and ($disable -eq $false)){
                        $adaccount | Select-Object name,userid,enabled | Export-Csv -Path $path\accountstodisable$date.csv -NoTypeInformation -Append
                    }
                    elseif(($adaccount.enabled -eq $true) -and ($disable -eq $true)){
                        $adaccount | Set-ADUser -Enabled $false
                    }
                }
                else{
                    if(([bool]$user.Mobilephone) -and !($user.Mobilephone -notmatch $adaccount.MobilePhone)){
                        $tempmobile = $user.mobilephone -replace "\D+"
                        foreach($user in $userinfo){
                            $tempmobile = $user.mobilephone -replace "\D+"
                            if($tempmobile.length -eq 10){
                                $newmobile = "{0:+1 (###) ###-####}" -f [int64]$tempmobile
                            }
                            elseif ($tempmobile.length -eq 11) {
                                $newmobile = "{0:+# (###) ###-####}" -f [int64]$tempmobile
                            }
                            else {
                                Write-Host "$($user.name) with mobile number $($user.Mobilephone) does not match required formatting."
                            }
                        }
                        $adaccount | Select-Object name
                        if ($apply -eq $false) {
                            $props = @{
                                username = $adaccount.name
                                snowname = $user.name
                                enabled = $adaccount.enabled
                                currentmobile = $adaccount.mobilephone
                                newmobile = $newmobile
                            }
                            $tempobject = New-Object psobject -Property $props
                            $tempobject | Export-Csv -Path $path\mobileupdate$date.csv -NoTypeInformation -Append
                        }
                        else {
                            $adaccount | Set-ADUser -MobilePhone $newmobile
                        }
                    }
                }
            }
            else{

                Write-Host "Cannot find AD account for $($user.name) with user id $($user.userid)" -ForegroundColor Red

                $user | Export-Csv -Path $path\noaccount$date.csv -NoTypeInformation -Append

            }
        }
    }
    End{}
}