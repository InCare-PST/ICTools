$users = Get-ADUser -Filter * -Properties *
$userlist = foreach($user in $users){
    $immid = [system.convert]::ToBase64String(([GUID]($user.objectguid)).tobytearray())
    $props = @{
        samaccountname = $user.samaccountname
        name = $user.Name
        immuteID = $immid
    }
    $object = New-Object psobject -Property $props

    $object | Select-Object name,samaccountname,immuteID
}