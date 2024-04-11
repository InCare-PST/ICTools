$srinew = Import-Csv -Path 'C:\Users\bbris\OneDrive - Thrive\Thrive\Clients\SRI Management\Aquisitions\ESLtochange.csv'
#$newsheet = New-Object -TypeName psobject
$newsheet = foreach($user in $srinew){
    $upn = $user.'user principal name'
    $nupn = $upn -replace '((?<=@).*)', 'srimgt.com'
    $user.'user principal name' = $nupn
    $user
}
$newsheet