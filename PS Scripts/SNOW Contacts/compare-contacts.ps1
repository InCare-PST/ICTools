$clientsnow = Import-Csv -Path c:\temp\clientsnow.csv
$adusers = Get-ADUser -Filter * -Properties enabled,mail
$approved = $clientsnow | Where-Object {$_.u_approval_status -eq "Approved"}
foreach($user in $approved){
    $useraccount = $adusers | Where-Object {$_.mail -match $user.email}
    $props = @{
        Name = $useraccount.Name
        SNOWName = $user.name
        Enabled = $useraccount.enabled
        Approved = $user.u_approval_status
    }
    $tempobject = New-Object -TypeName psobject -Property $props
    $tempobject | Where-Object {$_.enabled -eq $false -and $_.Approved -eq "Approved"} |Select-Object Name,SNOWName,Enabled,Approved | Export-Csv -Path C:\Temp\SnowCompare02.csv -NoTypeInformation -Append
}