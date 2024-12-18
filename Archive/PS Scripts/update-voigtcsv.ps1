$vexport = Import-Csv -Path 'C:\Users\bbris\OneDrive - Thrive\Thrive\Clients\Voigt\Client Updates\voigt.csv'
$365export = Import-Csv -Path 'C:\Users\bbris\OneDrive - Thrive\Thrive\Clients\Voigt\Client Updates\clientupdate.csv'
$count = 0
$newlist = @()
foreach($line in $vexport){
    $365line = $365export | Where-Object {$_.Name -match $line.name}
        if ($line.name -eq $365line.Name) {
            $line.mobilephone = $365line.mobilephone
            $line.OfficePhone = $365line.OfficePhone
            $line.enabled = $365line.enabled
            $newlist = $newlist + $line
            $count = $count + 1
        }
        else {
            Write-Host "$($line.Name) does not have a match" -ForegroundColor Red
            $line | Export-Csv -Path 'C:\Users\bbris\OneDrive - Thrive\Thrive\Clients\Voigt\Client Updates\missingusers.csv' -NoTypeInformation -Append
        }
}
$count
$newlist | Export-Csv -Path 'C:\Users\bbris\OneDrive - Thrive\Thrive\Clients\Voigt\Client Updates\clienupdate3.csv' -NoTypeInformation