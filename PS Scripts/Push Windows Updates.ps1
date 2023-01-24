$computerlist = Get-Content -Path C:\scripts\servers.txt
$i = 1200

Get-CimInstance -ClassName win32_operatingsystem -ComputerName $computerlist | select csname, buildnumber, lastbootuptime | Sort-Object -Property lastbootuptime
Invoke-WUInstall -ComputerName $computerlist -Script {ipmo PSWindowsUpdate; Get-WUInstall –MicrosoftUpdate -AcceptAll -autoreboot | out-file c:\PSWindowsUpdate.log } -Confirm:$False -Verbose
For ($i -gt 1; $i–-) {  
    Write-Progress -Activity "Servers Updating" -SecondsRemaining $i
    Start-Sleep 1
}
Get-CimInstance -ClassName win32_operatingsystem -ComputerName $computerlist | select csname, buildnumber, lastbootuptime | Sort-Object -Property lastbootuptime