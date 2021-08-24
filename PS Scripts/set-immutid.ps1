function Set-Immutid {
    [CmdletBinding()]
    param (
        [switch]$apply
    )
    
    begin {
        if (Get-Module -ListAvailable -Name azuread){}
        else{
            Return "AzureAD module not installed."
        }
        if (Get-Module -ListAvailable -Name ActiveDirectory){}
        else{
            Return "Active diretory module not installed."
        }
        Connect-AzureAD
        $azureUsers = Get-AzureADUser
        $adUsers = Get-ADUser -Filter * -Properties *
    }
    
    process {
        $userlist = foreach($azuser in $azureUsers){
            $adUser = $adUsers | Where-Object {$_.givenname -eq $azuser.GivenName -and $_.surname -eq $azuser.Surname}
            if (@($adUser).count -eq 1) {
                $immid = [system.convert]::ToBase64String(([GUID]($adUser.objectguid)).tobytearray())
                $props = @{
                    name = $adUser.Name
                    samaccountname = $adUser.samaccountname
                    objectguid = $adUser.objectguid
                    mail = $azuser.Mail
                    immuteID = $immid
                    lastlogondate = $adUser.lastlogondate
                }
                $tempobject = New-Object psobject -Property $props
                $tempobject | Select-Object name,samaccountname,mail,lastlogondate,objectguid,immuteID
            }
            if (@($adUser).count -lt 1) {
                $props = @{
                    name = $azuser.DisplayName
                    mail = $azuser.Mail
                }
                $tempobject = New-Object psobject -Property $props
                $tempobject | Select-Object name,mail
            }
        }
        $userlist.count
        if($apply){
            foreach ($cuser in $userlist) {
                if ($cuser.immuteID) {
                    $cuser.immuteID
                }
            }
        }
        elseif ($export) {
            
        }
        #$userlist | Select-Object name,samaccountname,mail,lastlogondate,objectguid,immuteID
    }
    
    end {
        
    }
}
Set-Immutid -apply