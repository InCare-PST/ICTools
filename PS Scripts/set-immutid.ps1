function Set-Immutid {
    [CmdletBinding()]
    param (
        
    )
    
    begin {
        if (Get-Module -ListAvailable -Name Az.Accounts){}
        else{}
        $users = Get-ADUser -Filter * -Properties *
    }
    
    process {
        foreach($user in $users) {
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