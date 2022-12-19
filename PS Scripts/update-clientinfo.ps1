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
            if($user.enabled -eq "N"){
                if($adaccount.enabled -eq $true){
                   #$adaccount | Set-ADUser -Enabled $false
                }
            }
            else{
                if($user.Mobilephone -notmatch $adaccount.MobilePhone){
                    #$adaccount | Set-ADUser -MobilePhone $user.Mobilephone
                }
            }
        }
    }
    End{}
}