#Specific User
Get-ADUser cvaughan -Properties * | Select-Object pwdlastset
 get-aduser cvaughan | Set-ADUser -Replace @{pwdlastset = -1}

#Specific list of users
$list = Import-csv "C:\temp\users.csv"
$list | ForEach-Object {get-aduser -filter * | Set-ADUser -Replace @{pwdlastset = -1}}

#All Users
get-aduser -filter * | Set-ADUser -Replace @{pwdlastset = -1}
