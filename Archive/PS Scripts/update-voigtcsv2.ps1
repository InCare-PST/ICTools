$vexport = Import-Csv -Path 'C:\Users\bbris\OneDrive - Thrive\Thrive\Clients\Voigt\Client Updates\voigt.csv'
$365export = Import-Csv -Path 'C:\Users\bbris\OneDrive - Thrive\Thrive\Clients\Voigt\Client Updates\clientupdate.csv'
$count = 0
$newlist = @()
foreach ($line in $365export) {
    $vline = $vexport | Where-Object { $_.Name -match $line.name }
    if ($line.name -eq $vline.Name) {
        $props = @{
            Name        = $line.Name
            Email       = $vline.Email
            MobilePhone = $line.MobilePhone
            OfficePhone = $line.OfficePhone
            Enabled     = $line.Enabled
        }
        $nline = New-Object -TypeName psobject -Property $props
        #$line.mobilephone = $365line.mobilephone
        #$line.OfficePhone = $365line.OfficePhone
        #$line.enabled = $365line.enabled
        #$line.email = $vline.email
        $newlist = $newlist + $nline
        $count = $count + 1
    }
    else {
        Write-Host "$($line.Name) does not have a match" -ForegroundColor Red
        $line | Export-Csv -Path 'C:\Users\bbris\OneDrive - Thrive\Thrive\Clients\Voigt\Client Updates\missingusers5.csv' -NoTypeInformation -Append
    }
}
$count
$newlist | Select-Object Name,Email,MobilePhone,OfficePhone,Enabled | Export-Csv -Path 'C:\Users\bbris\OneDrive - Thrive\Thrive\Clients\Voigt\Client Updates\clienupdate5.csv' -NoTypeInformation