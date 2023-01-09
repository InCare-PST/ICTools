#Update TrendMicro for Terminal Server Instances

$tmisc="HKLM:\SOFTWARE\Wow6432Node\TrendMicro\PC-cillinNTCorp\CurrentVersion\Misc."
$unloadpass=Read-Host -Prompt "Unload Password" #-MaskInput
$trend="C:\Program Files (x86)\Trend Micro\Client Server Security Agent"
$cpmconfig="C:\Program Files (x86)\Trend Micro\Client Server Security Agent\HostedAgent\CPM\CpmConfig.ini"
$cpmbak="C:\Program Files (x86)\Trend Micro\Client Server Security Agent\HostedAgent\CPM"
$bakdate="CpmConfig-$(get-date -f yyy-MM-dd).bak"
$TmPreFilter="HKLM:\SYSTEM\CurrentControlSet\Services\TmPreFilter\Parameters"
#$MemoryManagement="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"

#Unload TrendMicro
Start-Process "$trend\PccNtMon.exe" -ArgumentList "-n $unloadpass"
#Unload Wait for it to finish unloading
write-host "Sleeping 3 Minutes..." -ForegroundColor Green
start-sleep -Seconds 60
write-host "Two more minutes..." -ForegroundColor Green
start-sleep -Seconds 60
write-host "One more minute..." -ForegroundColor Green
start-sleep -Seconds 60


#Update RCS
IF(!(Test-Path $tmisc)){new-item -Path $tmisc -Force}
New-ItemProperty -Path $tmisc -Name "RCS" -Value 202 -PropertyType DWORD -Force

#Update CPM Config
Copy-Item $cpmconfig $cpmbak\$bakdate -Force
((get-content -path $cpmconfig -raw) -replace 'RCS =0','RCS =1') | Set-Content -Path $cpmconfig

#Update TmPreFilter
IF(!(Test-Path $TmPreFilter)){new-item -Path $TmPreFilter -Force}
New-ItemProperty -Path $TmPreFilter -Name "EnableMiniFilter" -Value 1 -PropertyType DWORD -Force

#Update PagedPoolSize Windows 2k8 Version and below
#IF(!(Test-Path $MemoryManagement)){new-item -Path $MemoryManagement -Force}
#New-ItemProperty -Path $MemoryManagement -Name "PagedPoolSize" -Value "FFFFFFFF" -PropertyType DWORD -Force


Write-Host "

Restart the computer, memory management will then be set.
Exclude the following file extensions from scanning on a Citrix and Terminal Server:
• .LOG
• .DAT
• .TMP
• .POL
• .PF
Exclude the roaming profiles from the RealTime scan on the fileserver.
Create a daily/weekly scheduled scan of the roaming profiles in off-peak hours on the fileserver.
" -ForegroundColor DarkGreen -BackgroundColor White