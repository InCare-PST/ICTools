#Update TrendMicro for Terminal Server Instances - JTGallups
#
#
#


#System Info
Add-Type -AssemblyName PresentationCore,PresentationFramework


#Script Variables 
    $tmisc="HKLM:\SOFTWARE\Wow6432Node\TrendMicro\PC-cillinNTCorp\CurrentVersion\Misc."
    $unloadpass=Read-Host -Prompt "Unload Password" -AsSecureString
    $trend="C:\Program Files (x86)\Trend Micro\Client Server Security Agent"
    $cpmconfig="C:\Program Files (x86)\Trend Micro\Client Server Security Agent\HostedAgent\CPM\CpmConfig.ini"
    $cpmbak="C:\Program Files (x86)\Trend Micro\Client Server Security Agent\HostedAgent\CPM"
    $bakdate="CpmConfig-$(get-date -f yyy-MM-dd).bak"
    $TmPreFilter="HKLM:\SYSTEM\CurrentControlSet\Services\TmPreFilter\Parameters"
    $TMFilter="HKLM:\SYSTEM\CurrentControlSet\Services\TmFilter\Parameters"
    $RTScan="HKLM:\SOFTWARE\WOW6432Node\TrendMicro\PC-cillinNTCorp\CurrentVersion\Real Time Scan Configuration"
    $MemoryManagement="HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
    $osversion=(Get-CimInstance CIM_OperatingSystem).buildnumber


#Unload TrendMicro
    Start-Process "$trend\PccNtMon.exe" -ArgumentList "-n $(ConvertFrom-SecureString -SecureString $unloadpass -AsPlainText)"


#Unload Wait for it to finish unloading
    write-host "Sleeping 3 Minutes..." -ForegroundColor Green
    start-sleep -Seconds 60
    write-host "Two more minutes..." -ForegroundColor Green
    start-sleep -Seconds 60
    write-host "One more minute..." -ForegroundColor Green
    start-sleep -Seconds 60


#Update MISC.
    IF(!(Test-Path $tmisc)){new-item -Path $tmisc -Force}
    New-ItemProperty -Path $tmisc -Name "RCS" -Value 202 -PropertyType DWORD -Force
    New-ItemProperty -Path $tmisc -Name "EnableProcessScanForStartUp" -Value 0 -PropertyType DWORD -Force
    New-ItemProperty -Path $tmisc -Name "EnableProcessScanWhenScan" -Value 0 -PropertyType DWORD -Force


#Update Real Time Scan Configuration
    IF(!(Test-Path $RTScan)){new-item -path $RTScan -Force}
    New-ItemProperty -Path $RTScan -Name "NTRtScanInitSleep" -Value 18000 -PropertyType DWORD -Force


#Update CPM Config
    Copy-Item $cpmconfig $cpmbak\$bakdate -Force
    ((get-content -path $cpmconfig -raw) -replace 'RCS =0','RCS =1') | Set-Content -Path $cpmconfig


#Update TmPreFilter
    IF(!(Test-Path $TmPreFilter)){new-item -Path $TmPreFilter -Force}
    New-ItemProperty -Path $TmPreFilter -Name "EnableMiniFilter" -Value 1 -PropertyType DWORD -Force


#Update TMFilter
    IF(!(Test-Path $TmFilter)){new-item -Path $TmFilter -Force}
    New-ItemProperty -Path $TmFilter -Name "DisableCtProcCheck" -Value 1 -PropertyType DWORD -Force


#Update PagedPoolSize Windows 2k8 Version and below (Build 9200 is Server 2012 RTM)
    IF([int]$osversion -lt "9200"){
    IF(!(Test-Path $MemoryManagement)){new-item -Path $MemoryManagement -Force}
    New-ItemProperty -Path $MemoryManagement -Name "PagedPoolSize" -Value "FFFFFFFF" -PropertyType DWORD -Force
    }

#Display warning message about addtional hosted console changes required
#Message Box Variables
    $ButtonType =[System.Windows.MessageBoxButton]::ok
    $MessageboxTitle=“Hosted console actions required!”
    $Messageboxbody=“
    1) Restart the server, memory management will then be set.

    2) Exclude the following file extensions from scanning on the RDS Farm:
    • .LOG
    • .DAT
    • .TMP
    • .POL
    • .PF

    3) Exclude the roaming profiles & redirected folders from the real-time scan on the fileserver.

    4)Create a daily/weekly scheduled scan of the roaming profiles in off-peak hours on the fileserver.
    ”
    $MessageIcon=[System.Windows.MessageBoxImage]::Warning

    [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)


