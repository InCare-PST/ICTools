function update-client {
    [CmdletBinding()]
        Param (

            [string]$path = "c:\temp\clientupdate.csv"
            
        )
    Begin{
        $userinfo = Import-Csv -Path $path
        #$olduserinfo = Get-ADUser -Properties * -Filter *
    }
    Process{
        foreach($user in $userinfo){
            $adaccount = Get-ADUser -Filter *  | Where-Object {$_.UserPrincipalName -match $user.userid}
            if([bool]$adaccount){
                if($user.enabled -eq "N"){
                    if($adaccount.enabled -eq $true){
                    #$adaccount | Set-ADUser -Enabled $false
                    }
                    else{}
                }
                else{
                    #if(([bool]$user.Mobilephone) -and ($user.Mobilephone -notmatch $adaccount.MobilePhone)){
                        if([bool]$user.Mobilephone){
                            #$adaccount | Set-ADUser -MobilePhone $user.Mobilephone
                            $adaccount | Select-Object name
                            $props = @{
                                username = $adaccount.name
                                snowname = $user.name
                                enabled = $adaccount.enabled
                                currentmobile = $adaccount.mobilephone
                                newmobile = $user.Mobilephone
                            }
                            $tempobject = New-Object psobject -Property $props
                            $tempobject | Export-Csv -Path c:\temp\mobileupdate.csv -NoTypeInformation -Append
                        }
                }
            }
            else{
                Write-Host "Cannot find AD account for $($user.name)" -ForegroundColor Red
            }
        }
    }
    End{}
}