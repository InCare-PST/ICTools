function update-client {
    [CmdletBinding()]
        Param (

            [string]$path = "c:\temp\",

            [string]$filename = "clientupdate.csv",

            [switch]$disable = $false
            
        )
    Begin{

        $userinfo = Import-Csv -Path $path\$filename

        $adusers = Get-ADUser -Filter *

        $date = Get-Date -Format MM-dd-yyyy    
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
                    #if(([bool]$user.Mobilephone) -and ($user.Mobilephone -notmatch $adaccount.MobilePhone)){
                        if(([bool]$user.Mobilephone) -and !($user.Mobilephone -notmatch $adaccount.MobilePhone)){
                            #$adaccount | Set-ADUser -MobilePhone $user.Mobilephone
                            $tempmobile = $user.mobilephone -replace "\D+"
                            $newmobile = "{0:(###) ###-####}" -f [int64]$tempmobile
                            $adaccount | Select-Object name
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