function Set-Immutid {
    [CmdletBinding()]
    param (
        [switch]$report
    )
    
    begin {
        if (Get-Module -ListAvailable -Name Az.Accounts){}
        else{
            Return "Azure module not installed."
        }
        if (Get-Module -ListAvailable -Name ActiveDirectory){}
        else{
            Return "Active diretory module not installed."
        }
        Connect-AzAccount
        $azureUsers = Get-AzADUser
        $adUsers = Get-ADUser -Filter * -Properties *
    }
    
    process {
        foreach($azuser in $azureUsers){
            $adUser = $adUsers | Where-Object {$_.givenname -eq $azuser.GivenName -and $_.surname -eq $azuser.Surname}
            if ($adUser.count -eq 1) {
                $immid = [system.convert]::ToBase64String(([GUID]($user.objectguid)).tobytearray())
                $props = @{
                    name = $adUser.Name
                    samaccountname = $adUser.samaccountname
                    objectguid = $adUser.objectguid
                    mail = $azuser.mail
                    immuteID = $immid
                }
            }
        }

        foreach($user in $adUsers) {
            $immid = [system.convert]::ToBase64String(([GUID]($user.objectguid)).tobytearray())
            $props = @{
                samaccountname = $user.samaccountname
                name = $user.Name
                immuteID = $immid
            }
            $object = New-Object psobject -Property $props
        
            $object | Select-Object name,samaccountname,immuteID
            }

    }
    
    end {
        
    }
}