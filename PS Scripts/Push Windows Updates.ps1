#$computerlist = Get-Content -Path C:\temp\servers.txt

#$computerlist = Get-ADComputer -Filter * -Properties OperatingSystem | Where-Object OperatingSystem -notlike "*server*" | Select-Object Name
$options = read-host -prompt "Enter 1 for Servers, Enter 2 for Workstations, Enter 3 for All, or Q to Quit"

if($options -eq "1"){$computerlist = Get-ADComputer -Filter * -Properties OperatingSystem | Where-Object OperatingSystem -like "*server*" | Select-Object Name}
elseif($options -eq "2"){$computerlist = Get-ADComputer -Filter * -Properties OperatingSystem | Where-Object OperatingSystem -notlike "*server*" | Select-Object Name}
elseif($options -eq "3"){$computerlist = Get-ADComputer -Filter * -Properties OperatingSystem | Select-Object Name}
elseif($options -eq "Q"){Write-Host -ForegroundColor Yellow "Exiting Script"; $computerlist = $null;Exit}

$i = 1200
$updatedlist = @()
$failedlist = @()
foreach($c in $computerlist){if([bool](test-connection $c.name -count 1 -quiet)){write-host -ForegroundColor Green $c.name "is up!"; $updatedlist += $c.name}else{write-host -ForegroundColor Red $c.name "is down"; $failedlist += $c.name}}

Get-CimInstance -ClassName win32_operatingsystem -ComputerName $updatedlist -ErrorAction SilentlyContinue | Select-Object csname, buildnumber, lastbootuptime | Sort-Object -Property lastbootuptime

start-sleep 2

Invoke-WUInstall -ComputerName $updatedlist -Script {Import-Module PSWindowsUpdate; Get-WUInstall -MicrosoftUpdate -AcceptAll | out-file c:\PSWindowsUpdate.log } -Confirm:$False -Verbose
For ($i -gt 1; $i--) {  
    Write-Progress -Activity "Servers Updating" -SecondsRemaining $i
    Start-Sleep 1
}

start-sleep 2

Get-CimInstance -ClassName win32_operatingsystem -ComputerName $updatedlist -ErrorAction SilentlyContinue | Select-Object csname, buildnumber, lastbootuptime | Sort-Object -Property lastbootuptime
Start-Sleep 2
write-host -ForegroundColor Red "Could not update:" $failedlist