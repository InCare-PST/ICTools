$date = (get-date).AddDays(-25)
$TimeStamp = (Get-Date).ToString('yyyy-MM-dd hh:mm')
$pathname = "C:\temp\InDelete-Loader.txt"
"------------------ VERIFY AT $TimeStamp --------------------------" | Out-File $pathname -Append
$computers = Get-ADComputer -Filter * -Properties LastLogonDate | where lastlogondate -GE $date
$verified = @()
ForEach ($comp in $computers) {
#    if (Test-Connection -ComputerName $comp.name -Count 1 -Quiet) {
    if (Invoke-Command -ComputerName $comp.name -ScriptBlock {Test-Path -Path "C:\windows"} -ErrorAction SilentlyContinue) {
        Write-Host $comp.name
        #Add-Member -InputObject $comp -MemberType NoteProperty -Name ComputerName -Value $comp.name -Force
        $verified += ($comp | select -ExpandProperty name)
    }
}


& \WindowsPowerShell\LoaderDeLInvo-Looped_.ps1

