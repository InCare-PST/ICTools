#Printer Log for Migration

$var="Shared Folder Location" #Example "\\msft.local\shares\deployment"
$printers = get-printer | Where-Object Type -eq "Connection"
$comp = "$env:computername"
$user = "$env:username"
$export = "$var\$user.csv"



foreach ($p in $printers) {
$tempobj = @{
Computer = $comp
User = $user
Printer = $p.name
SharedLocation = $p.computername

}
$FileObj = New-Object -TypeName psobject -Property $tempobj
$fileobj | export-csv $export -NoTypeInformation -Append
}

