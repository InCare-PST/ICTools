

$NewHostName = Read-Host -Prompt 'Input your computer name'
$DomainToJoin = "contoso.com"
$OU = "OU=TestOU,DC=contoso,DC=com"

workflow {
  Add-Computer -DomainName $DomainToJoin -OUPath $OU -NewName $NewHostName
  restart-computer -wait


}
