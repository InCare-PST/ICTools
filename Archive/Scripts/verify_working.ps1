#$date = (get-date).AddDays(-25)
$computers = Get-ADComputer -Filter * -Properties * | where enabled -eq $true
$verified = @()
ForEach ($comp in $computers) {
    if (Test-Connection -ComputerName $comp.name -Count 1 -Quiet) {
        Write-Host $comp.name
        #Add-Member -InputObject $comp -MemberType NoteProperty -Name ComputerName -Value $comp.name -Force
        $verified += ($comp | select -ExpandProperty name)
    }
}


& \WindowsPowerShell\LoaderDeLInvo-Looped.ps1