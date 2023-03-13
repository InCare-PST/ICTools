$users = Import-Csv -Path 'C:\Users\bbris\OneDrive - Thrive\thrive\Clients\Voigt\Client Updates\upvoigtusers.csv'
$exportme = foreach ($u in $users) {
    $props = @{
        Name        = $u.'Display name'
        Email       = $u.'User principal name'
        MobilePhone = $u.'Mobile Phone'
        OfficePhone = $u.'Phone number'
        Enabled     = "True"
    }
    $tempobject = New-Object -TypeName psobject -Property $props
    $tempobject | Select-Object name, Email, MobilePhone, OfficePhone, Enabled
}
$exportme | Export-Csv -Path 'C:\Users\bbris\OneDrive - Thrive\Thrive\Clients\Voigt\Client Updates\clientupdate.csv'