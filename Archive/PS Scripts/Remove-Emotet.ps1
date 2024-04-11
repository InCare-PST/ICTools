Function Remove-Emotet {
<#
Synopsis
#>
    [cmdletbinding(SupportsShouldProcess = $True)]
        param(
            $RunTime = "24",

            [switch]$LogOnly,

            [switch]$RunOnce,

            [string]$LogDir = "C:\Temp",

            [int32]$LastLogon = "60",

            [switch]$UseList
        )
    Begin{
        $RunTimeLoop = (Get-Date).AddHours($RunTime)
        if(!(Test-Path $LogDir)){
            New-Item -Path $LogDir -ItemType Directory
        }
    }
    Process{
        if ($UseList){
                $WRMComp = Import-Clixml -Path $LogDir\WRMComp.xml
                $NWRM = Import-Clixml -Path $LogDir\NOWRM.xml
            }
        else {
                Start-Job -Name Verify -ArgumentList $RunTime,$LastLogon,$Logdir,$RunOnce{
                    Param($RunTime,$LastLogon,$Logdir,$RunOnce)
                    if($RunOnce){
                        Get-OnlineADComps -RunTime $RunTime -LastLogon $LastLogon -LogDir $LogDir -RunOnce
                    }
                    else {
                        Get-OnlineADComps -RunTime $RunTime -LastLogon $LastLogon -LogDir $LogDir
                    }
                }
                $noFiles = $true
                while($noFiles){
                    if ((Test-Path $logdir\WRMComp.xml)-and (Test-Path $logdir\NOWRM.xml)){
                        $noFiles = $false
                        $WRMComp = Import-Clixml -Path $LogDir\WRMComp.xml
                        $NWRM = Import-Clixml -Path $LogDir\NOWRM.xml
                    }
                    else {
                        Start-Sleep -Seconds 10
                    }
                }
            }
        #Start-Job -Name LegacyJob -ScriptBlock {Remove-EmotetLegacy -ComputerName ($NWRM.name) -LogDir $LogDir -Logonly $LogOnly}
        $looptime = (Get-Date).AddHours($RunTime)
        while ((Get-Date) -le $looptime){
                if($LogOnly -or $RunOnce){
                    $looptime = (Get-Date)
                }
                $WRMComp = Import-Clixml -Path $LogDir\WRMComp.xml
                #$ScanTime = (Get-Date).ToString('yyyy-MM-dd')
                if (Test-Path "$LogDir\exclude32.txt") {
                    $exclude32 = Get-Content -Path $LogDir\exclude32.txt
                }
                if (Test-Path "$LogDir\exclude64.txt") {
                    $exclude64 = Get-Content -Path $LogDir\exclude64.txt
                }
                if (Test-Path "$LogDir\excludewindows.txt") {
                    $excludewin = Get-Content -Path $LogDir\excludewindows.txt
                }
                Invoke-Command -ComputerName $WRMComp.name -ArgumentList $LogOnly,$exclude32,$exclude64,$excludewin -ErrorAction SilentlyContinue -ErrorVariable NoConnect {
                    param($LogOnly,$exclude32,$exclude64,$excludewin)
                    $deletedfiles = @()
                    $ComputerName = $env:COMPUTERNAME
                    if (Test-Path -Path "C:\windows\SysWOW64") {
                        $file = Get-ChildItem -Path C:\windows\syswow64 *.exe | Where-Object {$_.creationtime -ge (get-date).AddDays(-3) -and $_.name -ne $_.originalname -and $_.name -notmatch $exclude64}
                            if([bool]$file){
                                foreach ($bfile in $file){
                                if ([bool]$bfile){
                                    $filedeleted = $false
                                    $filepath = $bfile.fullname
                                    if (!($LogOnly)){
                                        try {
                                            Stop-Process -Name $bfile.basename -Force -ErrorAction SilentlyContinue
                                        }
                                        catch{

                                        }
                                        #Start-Sleep -Seconds 3
                                        try {
                                            Remove-Item $bfile.fullname -ErrorAction Stop
                                            $filedeleted = $true
                                        }
                                        catch{
                                            $filedeleted = $false
                                        }
                                    }
                                    if ($filedeleted){
                                        $delstatus = "Yes"
                                        write-host "$filepath was detected on $ComputerName and was deleted" -ForegroundColor Yellow
                                    }
                                    else {
                                        $delstatus = "No"
                                        write-host "$filepath was detected on $ComputerName but was not deleted" -ForegroundColor Red
                                    }
                                    $tempobj = @{
                                        Name = $bfile.name
                                        Directory = $bfile.fullname
                                        CreationDate = $bfile.creationtime
                                        Deleted = $delstatus
                                        Command = $Task
                                        Type = "Dropper"
                                        ComputerName = $ComputerName
                                        TimeStamp = (Get-Date -Format "dd-MM-yyyy HH:mm:ss")
                                    }
                                    $FileObj = New-Object -TypeName psobject -Property $tempobj
                                    $deletedfiles += $FileObj
                                }else{
                                write-host "$ComputerName 64 Bit System Did not detect Dropper" -ForegroundColor Green
                                }
                        }
                            }else{
                                write-host "$ComputerName 64 Bit System Did not detect Dropper" -ForegroundColor Green
                            }
                    }
                    if (!(Test-Path -Path "C:\windows\SysWOW64")) {
                        $file = Get-ChildItem -Path C:\windows\system32 *.exe | Where-Object {$_.creationtime -ge (get-date).AddDays(-1.5) -and $_.name -ne $_.originalname -and $_.name -notmatch $exclude32}
                            if([bool]$file){
                                foreach ($bfile in $file){
                                if ([bool]$bfile){
                                    $filedeleted = $false
                                    $filepath = $bfile.fullname
                                    if (!($LogOnly)){
                                        try {
                                            Stop-Process -Name $bfile.basename -Force -ErrorAction SilentlyContinue
                                        }
                                        catch{

                                        }
                                    }
                                        #Start-Sleep -Seconds 3
                                        try {
                                            Remove-Item $bfile.fullname -ErrorAction Stop
                                            $filedeleted = $true
                                        }
                                        catch{
                                            $filedeleted = $false
                                        }
                                    if ($filedeleted){
                                        $delstatus = "Yes"
                                        write-host "$filepath was detected on $ComputerName and was deleted" -ForegroundColor Yellow
                                    }
                                    else {
                                        $delstatus = "No"
                                        write-host "$filepath was detected on $ComputerName but was not deleted" -ForegroundColor Red
                                    }
                                    $tempobj = @{
                                        Name = $bfile.name
                                        Directory = $bfile.fullname
                                        CreationDate = $bfile.creationtime
                                        Deleted = $delstatus
                                        Command = $Task
                                        Type = "Dropper"
                                        ComputerName = $ComputerName
                                        TimeStamp = (Get-Date -Format "dd-MM-yyyy HH:mm:ss")
                                    }
                                    $FileObj = New-Object -TypeName psobject -Property $tempobj
                                    $deletedfiles += $FileObj
                                }else{
                                write-host "$ComputerName 32 Bit System Did not detect Dropper" -ForegroundColor Green
                                }
                        }
                            }else{
                                write-host "$ComputerName 32 Bit System Did not detect Dropper" -ForegroundColor Green
                            }
                    }
                    $file = get-childitem -Path C:\Windows*.exe,c:\windows\temp\*.exe | Where-Object {$_.creationtime -ge (get-date).AddDays(-2) -and $_.Name -match "(?i)(\w{8}\.exe)" -and $_.name -notmatch $excludewin}
                            if([bool]$file){
                                foreach ($bfile in $file){
                                if ([bool]$bfile){
                                    $filedeleted = $false
                                    $filepath = $bfile.fullname
                                    if (!($LogOnly)){
                                        try {
                                            Stop-Process -Name $bfile.basename -Force -ErrorAction SilentlyContinue
                                        }
                                        catch{

                                        }
                                        #Start-Sleep -Seconds 3
                                        try {
                                            Remove-Item $bfile.fullname -ErrorAction Stop
                                            $filedeleted = $true
                                        }
                                        catch{
                                            $filedeleted = $false
                                        }
                                    }
                                    if ($filedeleted){
                                        $delstatus = "Yes"
                                        write-host "$filepath was detected on $ComputerName and was deleted" -ForegroundColor Yellow
                                    }
                                    else {
                                        $delstatus = "No"
                                        write-host "$filepath was detected on $ComputerName but was not deleted" -ForegroundColor Red
                                    }
                                    $tempobj = @{
                                        Name = $bfile.name
                                        Directory = $bfile.fullname
                                        CreationDate = $bfile.creationtime
                                        Deleted = $delstatus
                                        Command = $Task
                                        Type = "Emotet"
                                        ComputerName = $ComputerName
                                        TimeStamp = (Get-Date -Format "dd-MM-yyyy HH:mm:ss")
                                    }
                                    $FileObj = New-Object -TypeName psobject -Property $tempobj
                                    $deletedfiles += $FileObj
                                    #$deletedfiles += ($bfile | select name,directory,creationtime)
                                }else{
                                write-host "$ComputerName Windows Directory does not have any emotet files" -ForegroundColor Green
                                }
                            }
                            }else{
                                write-host "$ComputerName Windows Directory does not have any emotet files" -ForegroundColor Green
                            }
                    $file = get-childitem -path C:\Users\*\AppData\Roaming,c:\windows\ * -Recurse -Force -ErrorAction SilentlyContinue | Where-Object {$_.name -match "^44\w{62}\.exe$|^m\w\wvca\.exe$|^tetup\.exe|^wbM\w+\.exe|^mtwvc\.exe" -or $_.FullName -match "(?i)(appdata\\.*\\aim\w$)|(appdata\\.*\\WSOG$)|(appdata\\.*\\AMNI$)|(appdata\\.*\\WSIGE$)"}
                            if([bool]$file){
                                foreach ($bfile in $file){
                                if ([bool]$bfile){
                                    $filedeleted = $false
                                    $filepath = $bfile.fullname
                                    if (!($LogOnly)){
                                        try {
                                            Stop-Process -Name $bfile.basename -Force -ErrorAction SilentlyContinue
                                        }
                                        catch{

                                        }
                                        #Start-Sleep -Seconds 3
                                        try {
                                            Remove-Item $bfile.fullname -Recurse -Force -ErrorAction Stop
                                            $filedeleted = $true
                                        }
                                        catch{
                                            $filedeleted = $false
                                        }
                                    }
                                    if ($filedeleted){
                                        $delstatus = "Yes"
                                        write-host "$filepath was detected on $ComputerName and was deleted" -ForegroundColor Yellow
                                    }
                                    else {
                                        $delstatus = "No"
                                        write-host "$filepath was detected on $ComputerName but was not deleted" -ForegroundColor Red
                                    }
                                    $tempobj = @{
                                        Name = $bfile.name
                                        Directory = $bfile.FullName
                                        CreationDate = $bfile.creationtime
                                        Deleted = $delstatus
                                        Command = $Task
                                        Type = "44Trojan"
                                        ComputerName = $ComputerName
                                        TimeStamp = (Get-Date -Format "dd-MM-yyyy HH:mm:ss")
                                    }
                                    $FileObj = New-Object -TypeName psobject -Property $tempobj
                                    $deletedfiles += $FileObj
                                    #$deletedfiles += ($bfile | select name,directory,creationtime)
                                }else{
                                Write-Host "$ComputerName C:\Users\Username\Appdata and C:\Windows does not have 44 Trickbot files" -ForegroundColor Green
                                }
                            }
                            }else{
                                Write-Host "$ComputerName C:\Users\Username\Appdata and C:\Windows does not have 44 Trickbot files" -ForegroundColor Green
                            }
                    $file = get-childitem -path C:\  *.exe | Where-Object {$_.name -match "^44\w{62}\.exe$|^m\w\wvca\.exe$|^mtwvc\.exe"}
                            if([bool]$file){
                                foreach ($bfile in $file){
                                if ([bool]$bfile){
                                    $filedeleted = $false
                                    $filepath = $bfile.fullname
                                    if (!($LogOnly)){
                                        try {
                                            Stop-Process -Name $bfile.basename -Force -ErrorAction SilentlyContinue
                                        }
                                        catch{

                                        }
                                        #Start-Sleep -Seconds 3
                                        try {
                                            Remove-Item $bfile.fullname -ErrorAction Stop
                                            $filedeleted = $true
                                        }
                                        catch{
                                            $filedeleted = $false
                                        }
                                    }
                                    if ($filedeleted){
                                        $delstatus = "Yes"
                                        write-host "$filepath was detected on $ComputerName and was deleted" -ForegroundColor Yellow
                                    }
                                    else {
                                        $delstatus = "No"
                                        write-host "$filepath was detected on $ComputerName but was not deleted" -ForegroundColor Red
                                    }
                                    $tempobj = @{
                                        Name = $bfile.name
                                        Directory = $bfile.FullName
                                        CreationDate = $bfile.creationtime
                                        Deleted = $delstatus
                                        Command = $Task
                                        Type = "44Trojan"
                                        ComputerName = $ComputerName
                                        TimeStamp = (Get-Date -Format "dd-MM-yyyy HH:mm:ss")
                                    }
                                    $FileObj = New-Object -TypeName psobject -Property $tempobj
                                    $deletedfiles += $FileObj
                                    #$deletedfiles += ($bfile | select name,directory,creationtime)
                                }else{
                                write-host "$ComputerName C:\ Directory does not have 44 Trickbot files" -ForegroundColor Green
                                }
                            }
                            }else{
                                write-host "$ComputerName C:\ Directory does not have 44 Trickbot files" -ForegroundColor Green
                            }
                    $file = get-childitem -path C:\Windows\System32\Tasks  * | Where-Object {$_.name -match "Msne?tcs|Sysnetsf"}
                            if([bool]$file){
                                foreach ($bfile in $file){
                                if ([bool]$bfile){
                                    $filedeleted = $false
                                    $filepath = $bfile.fullname
                                    [xml]$xmltemp = get-content $filepath
                                    $Task = $xmltemp.task.actions.exec.command
                                    if (!($LogOnly)){
                                        <#try {
                                            Stop-Process -Name $bfile.basename -Force -ErrorAction SilentlyContinue
                                        }
                                        catch{

                                        }#>
                                        #Start-Sleep -Seconds 3
                                        try {
                                            Remove-Item $bfile.fullname -ErrorAction Stop
                                            $filedeleted = $true
                                        }
                                        catch{
                                            $filedeleted = $false
                                        }
                                    }
                                    if ($filedeleted){
                                        $delstatus = "Yes"
                                        write-host "$filepath was detected on $ComputerName and was deleted" -ForegroundColor Red
                                    }
                                    else {
                                        $delstatus = "No"
                                        write-host "$filepath was detected on $ComputerName but was not deleted" -ForegroundColor Red
                                    }
                                    $tempobj = @{
                                        Name = $bfile.name
                                        Directory = $bfile.FullName
                                        CreationDate = $bfile.creationtime
                                        Deleted = $delstatus
                                        Command = $Task
                                        Type = "TrickBot Task"
                                        ComputerName = $ComputerName
                                        TimeStamp = (Get-Date -Format "dd-MM-yyyy HH:mm:ss")
                                    }
                                    $FileObj = New-Object -TypeName psobject -Property $tempobj
                                    $deletedfiles += $FileObj
                                    #$deletedfiles += ($bfile | select name,directory,creationtime)
                                }else{
                                write-host "$ComputerName C:\windows\system32\tasks Directory does not have trickbot files" -ForegroundColor Green
                                }
                            }
                            }else{
                                write-host "$ComputerName C:\windows\system32\tasks Directory does not have trickbot files" -ForegroundColor Green
                            }
                $deletedfiles
                } | Select-Object Name,Directory,CreationDate,Deleted,Command,Type,ComputerName,TimeStamp | Export-Csv -Path $LogDir\Deleted-Emotet-Files.csv -Append -Force -NoTypeInformation
                if ([bool]$Noconnect){
                    $Noconnect | Export-Clixml "$LogDir\CantConnect $(Get-Date -Format 'dd-MM-yyyy HH-mm-ss').xml"
                }
            #Start-Sleep -Seconds 30
            }
    }
    End{
        $RunningJobs = Get-Job
        foreach ($job in $RunningJobs){
            if ($job.name -eq "Verify" -and $job.State -eq "Running"){
                Stop-Job -Name Verify -ErrorAction SilentlyContinue
                Remove-Job -Name Verify -ErrorAction SilentlyContinue
            }
            if ($job.name -eq "LegacyJob" -and $job.State -eq "Running"){
                Stop-Job -Name LegacyJob -ErrorAction SilentlyContinue
                Remove-Job -Name LegacyJob -ErrorAction SilentlyContinue
            }
        }
        $FTimeStamp = (Get-Date -Format "dd-MM-yyyy HH-mm-ss")
        Rename-Item -Path $LogDir\Deleted-Emotet-Files.csv -NewName Deleted-Emotet-Files-RuntimeEnded-$FTimeStamp.csv
    }

}
