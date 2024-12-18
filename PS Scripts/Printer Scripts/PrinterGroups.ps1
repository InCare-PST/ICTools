$printers = Get-ChildItem "D:\deployment\*.csv" | ForEach-Object { import-csv $_ } 
$groups = $printers -split {$_ -eq " " -or $_ -eq ")" -or $_ -eq "\" -or $_ -eq ";"} | Select-String "LCIPR","Bear" | Sort-Object
$grp = $groups | Select-Object -Unique

foreach($var1 in $grp){



if(![bool](Get-ADGroup -filter * | Where-Object Name -eq $var1 )){
New-ADGroup -Name $var1 -GroupScope Global -GroupCategory Security -Path "OU=Groups,OU=LCI,DC=lci,DC=local"
}
$printers | Where-Object Printer -match $var1 | ForEach-Object {Add-ADGroupMember -Identity "$var1" -Members $_.User 
}
}
