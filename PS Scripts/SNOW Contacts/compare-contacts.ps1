$gastrosnow = Import-Csv -Path c:\temp\gastrosnow.csv
$approved = $gastrosnow | Where-Object {$_.u_approval_status -eq "Approved"}
foreach($user in $approved){
    $useraccount = Get-ADUser -Filter * -Properties enabled| Where-Object {$_.UserPrincipalName -match $user.email}
    $props = @{
        Name = $useraccount.Name
        SNOWName = $user.name
        Enabled = $useraccount.enabled
        Approved = $user.u_approval_status
    }
    $tempobject = New-Object -TypeName psobject -Property $props
    $tempobject | Where-Object {$_.enabled -eq $false -and $_.Approved -eq "Approved"} |Select-Object Name,SNOWName,Enabled,Approved | Export-Csv -Path C:\Temp\SnowCompare02.csv -NoTypeInformation -Append
}