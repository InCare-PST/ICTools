$outfile = "C:\WindowsPowershell\quicklog.txt"
"=======================================================
Verify Loop
" | Out-File $outfile -Append
Get-Date | Out-File $outfile -Append
"
=======================================================
" | Out-File $outfile -Append

$date = (get-date).AddDays(-25)
$computers = Get-ADComputer -Filter * -Properties LastLogonDate | where lastlogondate -GE $date
$verified = @()
ForEach ($comp in $computers) {
    if ([bool](Test-WSMan -ComputerName $comp.Name -ErrorAction SilentlyContinue)) {
        Write-Host $comp.name
        #Add-Member -InputObject $comp -MemberType NoteProperty -Name ComputerName -Value $comp.name -Force
        $verified += ($comp | select -ExpandProperty name)
    }
}


& \WindowsPowerShell\Kill-Trickbot.ps1