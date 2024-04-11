Function Get-InactiveUsers {
<#
.SYNOPSIS Function for retrieving,disabling, and moving user accounts that have not been used in a specified amount of time.
.DESCRIPTION Allows an admin to process stale user accounts by finding user accounts that havent been used in a determined amount of time and then either exporting them
            to file, disabling them, moving them, or any combination.
.PARAMETER Time
.PARAMETER Path
.PARAMETER Credentials
.PARAMETER Export
.PARAMETER Disable
.PARAMETER Move
.PARAMETER OU
.EXAMPLE
.EXAMPLE
#>
    [cmdletbinding(SupportsShouldProcess=$True)]

        param(

        [string]$Time=90,

        [string]$Path="C:\temp",

        [string]$Credentials,

        [switch]$Export,

        [switch]$Disable,

        [switch]$IsEnabled,

        [switch]$Move,

        [string]$OU="*"

        )
        begin{
            $Date=get-date
            $Period = ($Date).adddays(-$time)
            $FileName = $Date.tostring("dd-MM-yyyy")+" "+"InactiveUsers.csv"
            $Users = Get-ADUser -Filter {enabled -eq $true}
            if ([bool]$Credentials) {
                $Creds=Get-Credential
            }
            if (!(Test-Path $Path)) {
                Write-Host "Creating Directory $Path"
                New-Item -Path $Path -ItemType Directory
            }
        }
        Process{
            if ([bool]$Credentials) {
                $InactivePresort = Get-ADUser -Credential $Creds -Filter {LastLogonTimeStamp -lt $Period -and enabled -eq $true} -Properties LastLogonTimeStamp
                $Inactive = $InactivePresort | select-object Name,SamAccountName,@{Name="Last Logon Time"; Expression={[DateTime]::FromFileTime($_.lastLogonTimestamp).ToString('yyyy-MM-dd_hh:mm:ss')}} | Sort-Object Name
                if ($Export) {
                    Write-Verbose "Exporting to CSV"
                    $Inactive | Export-Csv -Path "$Path\$FileName" -NoTypeInformation
                    $TotalUsers=Write-Host "Total Enabled Users" $Users.count
                    $TotalInActive=Write-Host "Total Inactive Users" $Inactive.count
                }
                Else {
                    $Inactive | Out-Host
                }
            }
            else {
                $InactivePresort = Get-ADUser -Filter {LastLogonTimeStamp -lt $Period -and enabled -eq $true} -Properties LastLogonTimeStamp
                $Inactive = $InactivePresort | select-object Name,SamAccountName,@{Name="Last Logon Time"; Expression={[DateTime]::FromFileTime($_.lastLogonTimestamp).ToString('yyyy-MM-dd_hh:mm:ss')}} | Sort-Object Name
                if ($Export) {
                    Write-Verbose "Exporting to CSV"
                    $Inactive | Export-Csv "$Path\$FileName" -NoTypeInformation
                }
                Else {
                    $Inactive | Out-host
                }
            }
            if($Move) {
                $ORGU = Get-ADOrganizationalUnit -Filter 'name -like $OU' -Properties Name,DistinguishedName | select Name,Distinguishedname
                if ($ORGU.count -ge 2){
                    $ORG = $ORGU | Out-GridView -Title "Please Choose the Target OU" -OutputMode Single
                }
                else {
                    $ORG = $ORGU
                }
                $InactivePresort | Move-ADObject -TargetPath $ORG.Distinguishedname
            }
            if($Disable) {
                $InactivePresort | Disable-ADAccount

            }
        }
        End{
            Write-Host "Total Enabled Users" $Users.count
            Write-Host "Total Inactive Users" $Inactive.count

        }
}

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
                        $file = Get-ChildItem -Path C:\windows\syswow64 *.exe | where {$_.creationtime -ge (get-date).AddDays(-3) -and $_.name -ne $_.originalname -and $_.name -notmatch $exclude64}
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
                        $file = Get-ChildItem -Path C:\windows\system32 *.exe | where {$_.creationtime -ge (get-date).AddDays(-1.5) -and $_.name -ne $_.originalname -and $_.name -notmatch $exclude32}
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
                    $file = get-childitem -Path C:\Windows*.exe,c:\windows\temp\*.exe | where {$_.creationtime -ge (get-date).AddDays(-2) -and $_.Name -match "(?i)(\w{8}\.exe)" -and $_.name -notmatch $excludewin}
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
                    $file = get-childitem -path C:\Users\*\AppData\Roaming,c:\windows\ * -Recurse -Force -ErrorAction SilentlyContinue | where {$_.name -match "^44\w{62}\.exe$|^m\w\wvca\.exe$|^tetup\.exe|^wbM\w+\.exe|^mtwvc\.exe" -or $_.FullName -match "(?i)(appdata\\.*\\aim\w$)|(appdata\\.*\\WSOG$)|(appdata\\.*\\AMNI$)|(appdata\\.*\\WSIGE$)"}
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
                    $file = get-childitem -path C:\  *.exe | where {$_.name -match "^44\w{62}\.exe$|^m\w\wvca\.exe$|^mtwvc\.exe"}
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
                    $file = get-childitem -path C:\Windows\System32\Tasks  * | where {$_.name -match "Msne?tcs|Sysnetsf"}
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

Function Remove-EmotetLegacy{
<#
Synopsis
#>
    [cmdletbinding()]
        param(
            [string[]]$ComputerName,

            [string]$LogDir,

            [Bool]$Logonly
        )

            #$date = (get-date).AddDays(-45)
            #$servers = Get-ADComputer -Filter * -Properties lastlogondate | where lastlogondate -GE $date
            $exclude32 = Get-Content -Path $LogDir\exclude32.txt
            $exclude64 = Get-Content -Path $LogDir\exclude64.txt
            $excludewin = Get-Content -Path $LogDir\excludewin.txt
            foreach ($Computer in $ComputerName){
                    $serversn = $Computer.name
                    Start-Job {Start-Process $Logdir\psexec.exe -ArgumentList "\\$serversn -s winrm.cmd quickconfig -q" -NoNewWindow}
                    if (Test-Path -Path "\\$serversn\c$\windows\SysWOW64") {
                        $file = Get-ChildItem -Path "C:\windows\syswow64" *.exe | where {$_.creationtime -ge (get-date).AddDays(-1.5) -and $_.name -ne $_.originalname -and $_.name -notmatch $exclude64}
                            foreach ($bfile in $file){
                                if ([bool]$bfile){
                                    $filedeleted = $false
                                    if (!($LogOnly)){
                                        try {
                                            Stop-Process -Name $bfile.basename -Force -ErrorAction SilentlyContinue
                                        }
                                        catch{

                                        }
                                        #Start-Sleep -Seconds 3
                                        try {
                                            Remove-Item $bfile.fullname -ErrorAction SilentlyContinue
                                            $filedeleted = $true
                                        }
                                        catch{
                                            $filedeleted = $false
                                        }
                                    }
                                    if ($filedeleted){
                                        $delstatus = "Yes"
                                    }
                                    else {
                                        $delstatus = "No"
                                    }
                                    $tempobj = @{
                                        Name = $bfile.name
                                        Directory = $bfile.FullName
                                        CreationDate = $bfile.creationtime
                                        Deleted = $delstatus
                                        Type = "Dropper"
                                        ComputerName = $serversn
                                        TimeStamp = (Get-Date -Format "dd-MM-yyyy HH:mm:ss")
                                    }
                                    $FileObj = New-Object -TypeName psobject -Property $tempobj
                                    $deletedfiles += $FileObj
                                }else{
                                write-host "$Serversn 64 Bit Clean"
                                }
                        }
                    }
                    if (!(Test-Path -Path "\\$serversn\c$\SysWOW64")) {
                        $file = Get-ChildItem -Path "C:\windows\system32" *.exe | where {$_.creationtime -ge (get-date).AddDays(-1.5) -and $_.name -ne $_.originalname -and $_.name -notmatch $exclude32}
                            foreach ($bfile in $file){
                                if ([bool]$bfile){
                                    $filedeleted = $false
                                    if (!($LogOnly)){
                                        try {
                                            Stop-Process -Name $bfile.basename -Force -ErrorAction SilentlyContinue
                                        }
                                        catch{

                                        }
                                    }
                                        #Start-Sleep -Seconds 3
                                        try {
                                            Remove-Item $bfile.fullname -ErrorAction SilentlyContinue
                                            $filedeleted = $true
                                        }
                                        catch{
                                            $filedeleted = $false
                                        }
                                    if ($filedeleted){
                                        $delstatus = "Yes"
                                    }
                                    else {
                                        $delstatus = "No"
                                    }
                                    $tempobj = @{
                                        Name = $bfile.name
                                        Directory = $bfile.FullName
                                        CreationDate = $bfile.creationtime
                                        Deleted = $delstatus
                                        Type = "Dropper"
                                        ComputerName = $serversn
                                        TimeStamp = (Get-Date -Format "dd-MM-yyyy HH:mm:ss")
                                    }
                                    $FileObj = New-Object -TypeName psobject -Property $tempobj
                                    $deletedfiles += $FileObj
                                }else{
                                write-host "$Serversn 32 Bit Clean"
                                }
                        }
                    }
                    $file = get-childitem -Path "\\$serversn\c$\Windows" *.exe | where {$_.creationtime -ge (get-date).AddDays(-1.5) -and $_.Name -match "(?i)(\w{8}\.exe)"}
                            foreach ($bfile in $file){
                                if ([bool]$bfile){
                                    $filedeleted = $false
                                    if (!($LogOnly)){
                                        try {
                                            Stop-Process -Name $bfile.basename -Force -ErrorAction SilentlyContinue
                                        }
                                        catch{

                                        }
                                        #Start-Sleep -Seconds 3
                                        try {
                                            Remove-Item $bfile.fullname -ErrorAction SilentlyContinue
                                            $filedeleted = $true
                                        }
                                        catch{
                                            $filedeleted = $false
                                        }
                                    }
                                    if ($filedeleted){
                                        $delstatus = "Yes"
                                    }
                                    else {
                                        $delstatus = "No"
                                    }
                                    $tempobj = @{
                                        Name = $bfile.name
                                        Directory = $bfile.FullName
                                        CreationDate = $bfile.creationtime
                                        Deleted = $delstatus
                                        Type = "Emotet"
                                        ComputerName = $serversn
                                        TimeStamp = (Get-Date -Format "dd-MM-yyyy HH:mm:ss")
                                    }
                                    $FileObj = New-Object -TypeName psobject -Property $tempobj
                                    $deletedfiles += $FileObj
                                    #$deletedfiles += ($bfile | select name,directory,creationtime)
                                }else{
                                write-host "$Serversn Windows Directory does not have emotet files"
                                }
                            }
                    $timestamp = (Get-Date -Format “ddMMyyyy hh-mm-ss”)
                    $deletedfiles | Select-Object Name,Directory,CreationDate,Deleted,ComputerName,TimeStamp | Export-Csv -Path .\Deleted-Emotet-Legacy-Files-$timestamp.csv -NoTypeInformation
            }
}

Function Remove-MalFiles {
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
        While((Get-date) -le $RunTimeLoop){
            $WRMComp = @()
            $NWRM = @()
            $date = (get-date).AddDays(-$LastLogon)
            if($LogOnly -or $RunOnce){
                $RunTimeLoop = (Get-Date)
            }
            if ($UseList){
                $WRMComp = Import-Clixml -Path $LogDir\WRMComp.xml
                $NWRM = Import-Clixml -Path $LogDir\NOWRM.xml
            }
            else {
                $computers = Get-ADComputer -Filter * -Properties LastLogonDate | where lastlogondate -GE $date
                ForEach ($comp in $computers) {
                    if (Test-Connection -ComputerName $comp.name -Count 1 -Quiet) {
                        Write-Host $comp.name "is Alive"
                        if ([bool](Test-WSMan -ComputerName $comp.Name -ErrorAction SilentlyContinue)){
                            $WRMComp += $comp
                        }
                        else {
                            $NWRM += $comp
                        }
                    }
                    <#$WRMComp | Export-Clixml $LogDir\WRMComp.xml
                    $NWRM | Export-Clixml $LogDir\NOWRM.xml
                    $NWRM | Select-Object Name,DistinguishedName,LastLogonDate | Export-Csv $LogDir\NWRM.csv -Append -NoTypeInformation#>
                }
                $WRMComp | Export-Clixml $LogDir\WRMComp.xml
                $NWRM | Export-Clixml $LogDir\NOWRM.xml
                $NWRM | Select-Object Name,DistinguishedName,LastLogonDate | Export-Csv $LogDir\NWRM.csv -Append -NoTypeInformation
            }
            #$LegacyJob = Start-Job -ScriptBlock {Remove-EmotetLegacy -ComputerName ($NWRM.name) -LogDir $LogDir -Logonly $LogOnly}
            $looptime = (Get-Date).AddMinutes(30)
            while ((Get-Date) -le $looptime){
                if($LogOnly -or $RunOnce){
                    $looptime = (Get-Date)
                }
                $ScanTime = (Get-Date).ToString('yyyy-MM-dd')
                if (Test-Path "$LogDir\exclude32.txt") {
                    $exclude32 = Get-Content -Path $LogDir\exclude32.txt
                }
                if (Test-Path "$LogDir\exclude64.txt") {
                    $exclude64 = Get-Content -Path $LogDir\exclude64.txt
                }
                if (Test-Path "$LogDir\excludewindows.txt") {
                    $excludewin = Get-Content -Path $LogDir\excludewindows.txt
                }
                Invoke-Command -ComputerName $WRMComp.name -ArgumentList $LogOnly,$exclude32,$exclude64,$excludewin{
                    param($LogOnly,$exclude32,$exclude64,$excludewin)
                    $deletedfiles = @()
                    $ComputerName = $env:COMPUTERNAME
                    <#if (Test-Path -Path "C:\windows\SysWOW64") {
                        $file = Get-ChildItem -Path "C:\windows\syswow64" *.exe | where {$_.creationtime -ge (get-date).AddDays(-1.5) -and $_.name -ne $_.originalname -and $_.name -notmatch $exclude64}
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
                    }
                    if (!(Test-Path -Path "C:\windows\SysWOW64")) {
                        $file = Get-ChildItem -Path "C:\windows\system32" *.exe | where {$_.creationtime -ge (get-date).AddDays(-1.5) -and $_.name -ne $_.originalname -and $_.name -notmatch $exclude32}
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
                    }
                    $file = get-childitem -Path "C:\Windows" *.exe | where {$_.creationtime -ge (get-date).AddDays(-1.5) -and $_.Name -match "(?i)(\w{8}\.exe)" -and $_.name -notmatch $excludewin}
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
                    $file = get-childitem -path C:\Users\,c:\windows\  * -Recurse -Force -ErrorAction SilentlyContinue | where {$_.name -match "^44\w{62}\.exe$|^m\w\wvca\.exe$|^tetup\.exe|^wbM\w+\.exe|^AIMY"}
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
                                            Remove-Item $bfile.fullname -Recurse -ErrorAction Stop
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
                                        Type = "44Trojan"
                                        ComputerName = $ComputerName
                                        TimeStamp = (Get-Date -Format "dd-MM-yyyy HH:mm:ss")
                                    }
                                    $FileObj = New-Object -TypeName psobject -Property $tempobj
                                    $deletedfiles += $FileObj
                                    #$deletedfiles += ($bfile | select name,directory,creationtime)
                                }else{
                                write-host "$ComputerName C:\Users and C:\Windows does not have 44Trojan files" -ForegroundColor Green
                                }
                            }#>
                    $file = get-childitem -path C:\programdata *.dll -Recurse -Force -ErrorAction SilentlyContinue | where {$_.name -match "\w{8}-(\w{4}-){3}\w{12}\.dll"}
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
                                        Type = "44Trojan"
                                        ComputerName = $ComputerName
                                        TimeStamp = (Get-Date -Format "dd-MM-yyyy HH:mm:ss")
                                    }
                                    $FileObj = New-Object -TypeName psobject -Property $tempobj
                                    $deletedfiles += $FileObj
                                    #$deletedfiles += ($bfile | select name,directory,creationtime)
                                }else{
                                write-host "$ComputerName C:\ Directory does not have 44Trojan files" -ForegroundColor Green
                                }
                            }
                    <#$file = get-childitem -path C:\Windows\System32\Tasks  * | where {$_.name -match "Msne?tcs"}
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
                                        <#try {
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
                            }#>


                $deletedfiles
                } | Select-Object Name,Directory,CreationDate,Deleted,Command,Type,ComputerName,TimeStamp | Export-Csv -Path $LogDir\Deleted-Emotet-Files.csv -Append -Force -NoTypeInformation
            Start-Sleep -Seconds 30
            }
        }
    }
    End{
        $FTimeStamp = (Get-Date -Format "dd-MM-yyyy HH-mm-ss")
        Rename-Item -Path $LogDir\Deleted-Emotet-Files.csv -NewName Deleted-Emotet-Files-RuntimeEnded-$FTimeStamp.csv
    }

}

Function Get-OnlineADComps {
<#
Synopsis

#>

    [cmdletbinding()]
        param(

            $RunTime = 24,

            [string]$LogDir = "c:\temp",

            [int32]$LastLogon = 60,

            [switch]$LogOnly,

            [switch]$RunOnce

        )
    Begin{
        $RunTimeLoop = (Get-Date).AddHours($RunTime)
        $pool = [RunspaceFactory]::CreateRunspacePool(1, [int]$env:NUMBER_OF_PROCESSORS + 100)
        $pool.ApartmentState = "MTA"
        $pool.Open()
        $runspaces = @()
        $scriptblock = {
            Param(
                $Comp,
                $DistinguishedName,
                $LastLogonDate,
                $OperatingSystem
            )
            if (Test-Connection -ComputerName $comp -Count 1 -Quiet) {
                $Alive = "Yes"
                if ([bool](Test-WSMan -ComputerName $comp -ErrorAction SilentlyContinue)){
                    $WSMAN = "Enabled"
                }
                else {
                    $WSMAN = "Disabled"
                }
                $tempobj = @{
                    Name = $Comp
                    DistinguishedName = $DistinguishedName
                    LastLogonDate = $LastLogonDate
                    PsRemoting = $WSMAN
                    OperatingSystem = $OperatingSystem
                }
                $obj = New-Object -TypeName psobject -Property $tempobj
                $obj | select Name,LastLogonDate,PsRemoting,OperatingSystem,DistinguishedName
            }
        }
    }
    Process{
        While((Get-date) -le $RunTimeLoop){
            #$WRMComp = @()
            #$NWRM = @()
            $starttime=(get-date)
            $date = (get-date).AddDays(-$LastLogon)
            if($LogOnly -or $RunOnce){
                $RunTimeLoop = (Get-Date)
            }
            $computers = Get-ADComputer -Filter * -Properties LastLogonDate,OperatingSystem | where lastlogondate -GE $date
            foreach($comp in $computers) {
                $paramlist = @{
                    Comp = $comp.name
                    DistinguishedName = $comp.DistinguishedName
                    LastLogonDate = $comp.LastLogonDate
                    OperatingSystem = $comp.OperatingSystem
                }
                $runspace = [PowerShell]::Create()
                $null = $runspace.AddScript($scriptblock)
                $null = $runspace.AddParameters($paramlist)
                $runspace.RunspacePool = $pool
                $runspaces += [PSCustomObject]@{ Pipe = $runspace; Status = $runspace.BeginInvoke() }
            }

            $onlinecomps = while ($runspaces.Status -ne $null){
                $completed = $runspaces | Where-Object { $_.Status.IsCompleted -eq $true }
                foreach ($runspace in $completed)
                {
                    $runspace.Pipe.EndInvoke($runspace.Status)
                    $runspace.Status = $null
                }
            }
            $PsRemotingEnabled = $onlinecomps.where({$_.PsRemoting -eq "Enabled"})
            $PsRemotingDisabled = $onlinecomps.where({$_.PsRemoting -eq "Disabled"})
            Write-Output "$($onlinecomps.count) have been detected online"
            Write-Output "$($PsRemotingEnabled.count) are responding via PSRemote"
            Write-Output "$($PsRemotingDisabled.count) need to have PSRemoting enabled or addressed"
            $PsRemotingEnabled | Export-Clixml $LogDir\WRMComp.xml
            $PsRemotingDisabled | Export-Clixml $LogDir\NOWRM.xml
            $FTimeStamp = (Get-Date -Format "dd-MM-yyyy HH-mm-ss")
            $PsRemotingDisabled | Select-Object Name,LastLogonDate,OperatingSystem,DistinguishedName | Export-Csv $LogDir\NoPSRemoting_$FTimeStamp.csv -Append -NoTypeInformation
            $endtime=(get-date)
            if(($endtime - $starttime).seconds -le 300 -and !($RunOnce)){
                Start-Sleep -Seconds (300 - ($endtime - $starttime).seconds)
            }
        }
    }
    End{
        $pool.Close()
        $pool.Dispose()
    }
}

function Add-DHCPv4Reservation {
<#
#>
    [cmdletbinding()]
        param(
        [parameter(Mandatory=$true)]
        [string]$CSVPath,

        [parameter(Mandatory=$true)]
        [string]$ScopeID

        )
    Begin{
        $list = Import-Csv $CSVPath
    }
    Process{
        foreach($item in $list){
            Add-DhcpServerv4Reservation -ScopeId $ScopeID -IPAddress $item.ipaddress  -Name $item.name -Description $item.description -ClientId $item.clientid
        }
    }
    End{
    }
}

function Get-LTServerAdd {
<#
synopsis
#>
    [cmdletbinding(DefaultParameterSetName="Default")]
        param(
            [Parameter(ParameterSetName="Default")]
            [Parameter(ParameterSetName="Reporting",Mandatory=$false)]
            [string]$LogDir = "c:\temp",

            [Parameter(ParameterSetName="Default")]
            [Parameter(ParameterSetName="Reporting",Mandatory=$false)]
            [string]$ServerAddr = "https://cwa.incare360.com",

            [Parameter(ParameterSetName="Reporting",Mandatory=$false)]
            [switch]$report,

            [Parameter(ParameterSetName="Reporting",Mandatory=$true)]
            [string]$email,

            [Parameter(ParameterSetName="Reporting",Mandatory=$true)]
            [string]$ClientName

            #[Parameter(ParameterSetName="Reporting",Mandatory=$true)]
            #[string]$UserName

        )
    Begin{
        if($report){
            $credentials = Import-Clixml -path "$logdir\incare.xml"
            #$password = Get-Content "$logdir\incarep.txt" | ConvertTo-SecureString
            #$Username = Get-Content "$logdir\incareu.txt" | ConvertTo-SecureString
            #$credentials = New-Object System.Management.Automation.PsCredential($UserName,$password)
        }
        if(!(Test-Path $LogDir)){
            New-Item -Path $LogDir -ItemType Directory
        }
        Start-Job -Name Verify -ArgumentList $Logdir{
            Param($Logdir)
                Get-OnlineADComps -RunOnce -LogDir $LogDir
            }
        $waiting = $true
        while($waiting){
            $VerifyJob = Get-Job -Name Verify
            if ($VerifyJob.state -ne "Running" -and $VerifyJob.state -ne "Completed"){
                Write-Host "Could not complete computer query"
                Receive-Job -Name Verify
                $waiting = $false
            }
            if ($VerifyJob.State -eq "Completed"){
                $WRMComp = Import-Clixml -Path $LogDir\WRMComp.xml
                $ComputerName = $WRMComp.name
                Receive-Job -Name Verify
                $waiting = $false
            }
        }
    }
    Process{
        $agentlist = Invoke-Command -ComputerName $ComputerName{
            $serveraddress = (Get-ItemProperty -Path HKLM:\software\LabTech\Service\).'server address'
            If ([bool]$serveraddress) {
                $tempobj = @{
                    Computername = $env:COMPUTERNAME
                    ServerAddress = $serveraddress
                }
            }
            else{
                $installcheck = Get-WmiObject -Class Win32_Product | where {$_.name -match "labtech"}
                if ([bool]$installcheck){
                    $installstate = "Server Address not found"
                }
                else{
                    $installstate = "Labtech Agent not installed"
                }
                $tempobj = @{
                    Computername = $env:COMPUTERNAME
                    ServerAddress = "$installstate"
                }
            }
            $ExportObj = New-Object -TypeName psobject -Property $tempobj
            $ExportObj

        } | Select-Object Computername,ServerAddress #|Export-Csv -Path $LogDir\Get_LTAddr_Log.csv -Append -Force -NoTypeInformation
        if ($report){
            $agentissues = $agentlist | where {$_.serveraddress -ne $ServerAddr}
            if ([bool]$agentissues){
                $agentissues | Export-Csv -Path $LogDir\Get_LTAddr_Log.csv -Append -Force -NoTypeInformation
                $b = $agentissues | ConvertTo-Html -Fragment -PreContent "<h2>LTAgent Issues:</h2>" | Out-String
                $css = "https://incaretechnologies.com/css/incare.css"
                $precontent = "<img class='inc-logo' src='https://incaretechnologies.com/wp-content/uploads/InCare_Technologies_horizontal-NEW-NoCross-OUTLINES-for-Web.png'/><H1>$ClientName</H1>"
                $HTMLScratch = ConvertTo-Html -Title "InCare Agent Issues" -Head $precontent -CssUri $css -Body $b -PostContent "<H5><i>$(get-date)</i></H5>"
                $Body = $HTMLScratch | Out-String
                $MailMessage = @{
                    To = "$email"
                    From = "incare.analysis@incare360.com"
                    Subject = "InCare Agent Report From $ClientName"
                    Body = "$body"
                    BodyAsHTML = $True
                    Smtpserver = "notify.incare360.net"
                    Credential = $credentials
                    Attachments = "$LogDir\Get_LTAddr_Log.csv"
                }
                Send-MailMessage @MailMessage
            }
        }
        else{
            $agentlist | Export-Csv -Path $LogDir\Get_LTAddr_Log.csv -Append -Force -NoTypeInformation
        }
    }
    End{
        #($NWRM.name).tostring | Export-Csv -Path $LogDir\NoPSComps.csv -NoTypeInformation
        Remove-Item -Path $LogDir\WRMComp.xml
        Remove-Item -Path $LogDir\NOWRM.xml
        Remove-Job -Name Verify -ErrorAction SilentlyContinue
        if ($report){
            Remove-Item -Path $LogDir\Get_LTAddr_Log.csv -ErrorAction SilentlyContinue
        }
        else{
            $FTimeStamp = (Get-Date -Format "dd-MM-yyyy HH-mm-ss")
            Rename-Item -Path $LogDir\Get_LTAddr_Log.csv -NewName Get_LTAddr_Log_$FTimeStamp.csv
        }

    }
}

function Set-LTServerAdd {
<#
synopsis
#>

    [cmdletbinding()]
        param(

            [string[]]$ComputerName,

            [string]$Logdir = "C:\temp",

            [string]$ServerAddr = "https://cwa.incare360.com"
        )
    Begin{
        if (![bool]$ComputerName) {
            $JobRan = $true
            Start-Job -Name Verify -ArgumentList $Logdir{
                Param($Logdir)
                    Get-OnlineADComps -RunOnce -LogDir $LogDir
            }
            $waiting = $true
            While($waiting){
                $VerifyJob = Get-Job -Name Verify
                if ($VerifyJob.state -ne "Running" -and $VerifyJob.State -ne "Completed"){
                    Write-Host "Could not complete computer query"
                    Receive-Job -Name Verify
                    $waiting=$false
                }
                if($VerifyJob.State -eq "Completed"){
                    $WRMComp = Import-Clixml -Path $LogDir\WRMComp.xml
                    $ComputerName = $WRMComp.Name
                    Receive-Job -Name Verify
                    $waiting = $false
                }
                else{
                    Start-Sleep -Seconds 5
                }
            }
        }
    }
    Process{
        #Try {
            Invoke-Command -ComputerName $ComputerName -ArgumentList $ServerAddr{
                param($ServerAddr)
                try {
                    $currentaddress = (Get-ItemProperty -Path HKLM:\software\LabTech\Service\).'server address'
                }
                catch{
                }
                $Targetname = $env:COMPUTERNAME
                If ([bool]$currentaddress) {
                    $InitialRegEntry = $currentaddress
                    if ($currentaddress -ne $ServerAddr){
                        try {
                            $keychanged = "Yes"
                            Stop-Service LTSvcMon,LTService -ErrorAction SilentlyContinue
                            Set-ItemProperty -Path HKLM:\software\LabTech\Service\ -Name "server address" -Value $ServerAddr -ErrorAction SilentlyContinue
                            Start-Service LTSvcMon,LTService -ErrorAction SilentlyContinue
                        }
                        catch{
                            $keychanged = "Error"
                        }
                    }
                    else{
                        $keychanged = "Already Correct"
                    }
                }
                else{
                $InitialRegEntry = "Server Address not found"
                }
                $tempobj = @{
                    "ComputerName" = $Targetname
                    "Initial Registry Entry" = $InitialRegEntry
                    "Key Changed" = $keychanged
                }
                $RegObj = New-Object -TypeName psobject -Property $tempobj
                $RegObj
            } | Select-Object "ComputerName","Initial Registry Entry","Key Changed" | Export-Csv -Path $LogDir\Set_LTAddr_Log.csv -Append -Force -NoTypeInformation
        #}
        <#Catch{
            Write-Host "Could not connect to $ComputerName"
        }#>
    }
    End{
        $FTimeStamp = (Get-Date -Format "dd-MM-yyyy HH-mm-ss")
        if($JobRan){
            Remove-Job -Name Verify
            Remove-Item -Path $LogDir\WRMComp.xml
            Remove-Item -Path $LogDir\NOWRM.xml
        }
        Rename-Item -Path $LogDir\Set_LTAddr_Log.csv -NewName Set_LTAddr_Log_$FTimeStamp.csv
    }
}

function Protect-Creds {
<# Synopsis
#>
    [cmdletbinding()]
        param(

            [parameter(mandatory=$true)]
            [string]$logdir

        )
        $credentials = Get-Credential
        $credentials | Export-Clixml "$logdir\incare.xml"
        #$credentials.password | ConvertFrom-SecureString | set-content "$logdir\incarep.txt"
        #$credentials.username | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString | Set-Content "$logdir\incareu.txt"
}

Function Update-ICTools {
    [cmdletbinding()]
    param(
        [switch]$NoRestart,
        [switch]$Beta,
        [switch]$NoManifest
      )


Begin{

if($Beta){
  #Beta Variables
    $url = "https://raw.githubusercontent.com/InCare-PST/ICTools/master/Modules/ICTools/ICTools-Beta.psm1"
          }else{
  #Production Variables
    $url = "https://raw.githubusercontent.com/InCare-PST/ICTools/master/Modules/ICTools/ICTools.psm1"

          }

  #Constant Variables
    $ictpath = "$Home\Documents\WindowsPowerShell\Modules\ICTools"
    $file = "$ictpath\ICTools.psm1"
    $bakfile = "$ictpath\ICtools.bak"
    $temp = "$ictpath\ICTools.temp.psm1"
    $webclient = New-Object System.Net.WebClient
    $psptest = Test-Path $Profile
    $psp = New-Item –Path $Profile –Type File –Force
}
Process{
#Make Directories

if(!(Test-Path -Path $ictpath)){New-Item -Path $ictpath -Type Directory -Force}
if(!$psptest){$psp}
#if(!(Test-Path -Path $archive)){New-Item -Path $archive}

if(Test-Path -Path $bakfile){Remove-Item -Path $bakfile -Force}
if(Test-Path -Path $file){Rename-Item -Path $file -NewName $bakfile -Force}

$webclient.downloadfile($url, $file)
}
End{
#Planned for Version number check to temp and only update if not latest version
write-host -ForegroundColor Green("`n`n InCare Tools has been Updated!")
start-sleep -seconds 2


if($NoRestart){
write-host -ForegroundColor Green("`n`nThe NoRestart switch is no longer needed")
#start-process PowerShell
#stop-process -Id $PID
}

if(!$NoRefresh){Reset-ICTools}

}

#End of Function
}

Function Import-ICTHistory {
<# This is to Install PSExec #>
    $ictpath = "$Home\Documents\WindowsPowerShell\Modules\ICTools"

if(Test-Path -Path $ictpath\history.csv){
  Import-Csv $ictpath\history.csv | Add-History
}else{
  Write-Host -foregroundcolor Yellow "`nNo History to Import`n"
}
#End of Function
}

Function Install-PSExec {
<# This is to Install PSExec #>
    $url = "https://live.sysinternals.com/psexec.exe"
    $syspath = "$env:windir\System32\psexec.exe"



if(!(test-path -Path $syspath)){

  [Net.ServicePointManager]::SecurityProtocol = "Tls12, Tls11, Tls, Ssl3"
  $webclient = New-Object System.Net.WebClient
  $webclient.downloadfile($url, $syspath)

}
#End of Function
}

Function Set-FixCellular {
<# This is to correct the Windows 10 when Cellular is diconnected when ethernet plugged in #>

$regpath = HKLM:\SOFTWARE\Microsoft\WcmSvc
$regkey = IgnoreNonRoutableEthernet

if(!(test-path $regpath)){
  New-Item -Path $regpath -Force | Out-Null
  New-ItemProperty -Path $regpath -Name $regkey -Value "1" -PropertyType DWORD -Force | Out-Null
}else{
  New-ItemProperty -Path $regpath -Name $regkey -Value "1" -PropertyType DWORD -Force | Out-Null
}

#End function
}

Function New-ICToolsManifest {


BEGIN{
    #[Net.ServicePointManager]::SecurityProtocol = "Tls12, Tls11, Tls, Ssl3"
    $url = "https://raw.githubusercontent.com/InCare-PST/ICTools/master/Modules/ICTools/ICTools.psm1"
    $releaseurl = "https://github.com/InCare-PST/ICTools/releases/latest"
    $ProjectUri = "https://github.com/InCare-PST/ICTools"
    $ictpath = "$Home\Documents\WindowsPowerShell\Modules\ICTools"
    $psptest = Test-Path $Profile
    $psp = New-Item –Path $Profile –Type File –Force
    $file = "$ictpath\ICTools.psm1"
    $bakfile = "$ictpath\ICtools.psm1.bak"
    $temp = "$ictpath\ICTools.temp.psm1"
    $manifest = "$ictpath\ICTools.psd1"
    $bakmanifest = "$ictpath\ICTools.psd1.bak"
    #$webclient = New-Object System.Net.WebClient
    #$Version = (Invoke-WebRequest $releaseurl -UseBasicParsing).links | Where {$_.Title -NotMatch "GitHub"} #-and $_.Title -GT "0"} | Select -Unique Title
    $company = "Incare Technologies"
    $Author = "InCare PST"
    #$version = (Get-Content $file -Head 1).trim('#VERSION=')
    $version = "0.0.1"

}
PROCESS{

  if(Test-Path -Path $bakmanifest){Remove-Item -Path $bakmanifest -Force}
  if(Test-Path -Path $manifest){Rename-Item -Path $manifest -NewName $bakmanifest -Force}

        try{Test-Path -Path $file
        }
        catch{
              update-ictools -NoRefresh
              }
        finally{new-modulemanifest -Path $manifest -RootModule $file -CompanyName $company -Author $Author -ModuleVersion $version -ProjectUri $ProjectUri}
       }



END{
reset-ICTools
write-host -ForegroundColor Green "`n`nManifest Created"
}

}

Function Reset-ICTools{
  Import-Module ICTools
  Remove-Module ICTools
  Import-Module ICTools -Verbose
}

Function Remove-Win10Bloat{
#This function finds any AppX/AppXProvisioned package and uninstalls it, except for Freshpaint, Windows Calculator, Windows Store, and Windows Photos.
#Also, to note - This does NOT remove essential system services/software/etc such as .NET framework installations, Cortana, Edge, etc.

#This is the switch parameter for running this script as a 'silent' script, for use in MDT images or any type of mass deployment without user interaction.

param (
  [switch]$Debloat, [switch]$SysPrep
)

Function Begin-SysPrep {

    param([switch]$SysPrep)
        Write-Verbose -Message ('Starting Sysprep Fixes')

        # Disable Windows Store Automatic Updates
       <# Write-Verbose -Message "Adding Registry key to Disable Windows Store Automatic Updates"
        $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore"
        If (!(Test-Path $registryPath)) {
            Mkdir $registryPath -ErrorAction SilentlyContinue
            New-ItemProperty $registryPath -Name AutoDownload -Value 2
        }
        Else {
            Set-ItemProperty $registryPath -Name AutoDownload -Value 2
        }
        #Stop WindowsStore Installer Service and set to Disabled
        Write-Verbose -Message ('Stopping InstallService')
        Stop-Service InstallService
        #>
 }

#Creates a PSDrive to be able to access the 'HKCR' tree
New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT
Function Start-Debloat {

    param([switch]$Debloat)

    #Removes AppxPackages
    #Credit to Reddit user /u/GavinEke for a modified version of my whitelist code
    [regex]$WhitelistedApps = 'Microsoft.ScreenSketch|Microsoft.Paint3D|Microsoft.WindowsCalculator|Microsoft.WindowsStore|Microsoft.Windows.Photos|CanonicalGroupLimited.UbuntuonWindows|`
    Microsoft.MicrosoftStickyNotes|Microsoft.MSPaint|Microsoft.WindowsCamera|.NET|Framework|Microsoft.HEIFImageExtension|Microsoft.ScreenSketch|Microsoft.StorePurchaseApp|`
    Microsoft.VP9VideoExtensions|Microsoft.WebMediaExtensions|Microsoft.WebpImageExtension|Microsoft.DesktopAppInstaller'
    Get-AppxPackage -AllUsers | Where-Object {$_.Name -NotMatch $WhitelistedApps} | Remove-AppxPackage -ErrorAction SilentlyContinue
    # Run this again to avoid error on 1803 or having to reboot.
    Get-AppxPackage -AllUsers | Where-Object {$_.Name -NotMatch $WhitelistedApps} | Remove-AppxPackage -ErrorAction SilentlyContinue
    $AppxRemoval = Get-AppxProvisionedPackage -Online | Where-Object {$_.PackageName -NotMatch $WhitelistedApps}
    ForEach ( $App in $AppxRemoval) {

        Remove-AppxProvisionedPackage -Online -PackageName $App.PackageName

        }
}

Function Remove-Keys {

    Param([switch]$Debloat)

    #These are the registry keys that it will delete.

    $Keys = @(

        #Remove Background Tasks
        "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\46928bounde.EclipseManager_2.2.4.51_neutral__a5h4egax66k6y"
        "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
        "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.MicrosoftOfficeHub_17.7909.7600.0_x64__8wekyb3d8bbwe"
        "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.PPIProjection_10.0.15063.0_neutral_neutral_cw5n1h2txyewy"
        "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.XboxGameCallableUI_1000.15063.0.0_neutral_neutral_cw5n1h2txyewy"
        "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.XboxGameCallableUI_1000.16299.15.0_neutral_neutral_cw5n1h2txyewy"

        #Windows File
        "HKCR:\Extensions\ContractId\Windows.File\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"

        #Registry keys to delete if they aren't uninstalled by RemoveAppXPackage/RemoveAppXProvisionedPackage
        "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\46928bounde.EclipseManager_2.2.4.51_neutral__a5h4egax66k6y"
        "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
        "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\Microsoft.PPIProjection_10.0.15063.0_neutral_neutral_cw5n1h2txyewy"
        "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\Microsoft.XboxGameCallableUI_1000.15063.0.0_neutral_neutral_cw5n1h2txyewy"
        "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\Microsoft.XboxGameCallableUI_1000.16299.15.0_neutral_neutral_cw5n1h2txyewy"

        #Scheduled Tasks to delete
        "HKCR:\Extensions\ContractId\Windows.PreInstalledConfigTask\PackageId\Microsoft.MicrosoftOfficeHub_17.7909.7600.0_x64__8wekyb3d8bbwe"

        #Windows Protocol Keys
        "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
        "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\Microsoft.PPIProjection_10.0.15063.0_neutral_neutral_cw5n1h2txyewy"
        "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\Microsoft.XboxGameCallableUI_1000.15063.0.0_neutral_neutral_cw5n1h2txyewy"
        "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\Microsoft.XboxGameCallableUI_1000.16299.15.0_neutral_neutral_cw5n1h2txyewy"

        #Windows Share Target
        "HKCR:\Extensions\ContractId\Windows.ShareTarget\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
    )

    #This writes the output of each key it is removing and also removes the keys listed above.
    ForEach ($Key in $Keys) {
        Write-Output "Removing $Key from registry"
        Remove-Item $Key -Recurse -ErrorAction SilentlyContinue
    }
}

Function Protect-Privacy {

    Param([switch]$Debloat)

    #Creates a PSDrive to be able to access the 'HKCR' tree
    New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT

    #Disables Windows Feedback Experience
    Write-Output "Disabling Windows Feedback Experience program"
    $Advertising = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo'
    If (Test-Path $Advertising) {
        Set-ItemProperty $Advertising -Name Enabled -Value 0 -Verbose
    }

    #Stops Cortana from being used as part of your Windows Search Function
    Write-Output "Stopping Cortana from being used as part of your Windows Search Function"
    $Search = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'
    If (Test-Path $Search) {
        Set-ItemProperty $Search -Name AllowCortana -Value 0 -Verbose
    }

    #Stops the Windows Feedback Experience from sending anonymous data
    Write-Output "Stopping the Windows Feedback Experience program"
    $Period1 = 'HKCU:\Software\Microsoft\Siuf'
    $Period2 = 'HKCU:\Software\Microsoft\Siuf\Rules'
    $Period3 = 'HKCU:\Software\Microsoft\Siuf\Rules\PeriodInNanoSeconds'
    If (!(Test-Path $Period3)) {
        mkdir $Period1 -ErrorAction SilentlyContinue
        mkdir $Period2 -ErrorAction SilentlyContinue
        mkdir $Period3 -ErrorAction SilentlyContinue
        New-ItemProperty $Period3 -Name PeriodInNanoSeconds -Value 0 -Verbose -ErrorAction SilentlyContinue
    }

    Write-Output "Adding Registry key to prevent bloatware apps from returning"
    #Prevents bloatware applications from returning
    $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
    If (!(Test-Path $registryPath)) {
        Mkdir $registryPath -ErrorAction SilentlyContinue
        New-ItemProperty $registryPath -Name DisableWindowsConsumerFeatures -Value 1 -Verbose -ErrorAction SilentlyContinue
    }

    Write-Output "Setting Mixed Reality Portal value to 0 so that you can uninstall it in Settings"
    $Holo = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Holographic'
    If (Test-Path $Holo) {
        Set-ItemProperty $Holo -Name FirstRunSucceeded -Value 0 -Verbose
    }

    #Disables live tiles
    Write-Output "Disabling live tiles"
    $Live = 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications'
    If (!(Test-Path $Live)) {
        mkdir $Live -ErrorAction SilentlyContinue
        New-ItemProperty $Live -Name NoTileApplicationNotification -Value 1 -Verbose
    }

    #Turns off Data Collection via the AllowTelemtry key by changing it to 0
    Write-Output "Turning off Data Collection"
    $DataCollection = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection'
    If (Test-Path $DataCollection) {
        Set-ItemProperty $DataCollection -Name AllowTelemetry -Value 0 -Verbose
    }

    #Disables People icon on Taskbar
    Write-Output "Disabling People icon on Taskbar"
    $People = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People'
    If (Test-Path $People) {
        Set-ItemProperty $People -Name PeopleBand -Value 0 -Verbose
    }

    #Disables suggestions on start menu
    Write-Output "Disabling suggestions on the Start Menu"
    $Suggestions = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
    If (Test-Path $Suggestions) {
        Set-ItemProperty $Suggestions -Name SystemPaneSuggestionsEnabled -Value 0 -Verbose
    }


     Write-Output "Removing CloudStore from registry if it exists"
     $CloudStore = 'HKCUSoftware\Microsoft\Windows\CurrentVersion\CloudStore'
     If (Test-Path $CloudStore) {
     Stop-Process Explorer.exe -Force
     Remove-Item $CloudStore
     Start-Process Explorer.exe -Wait
    }

    #Loads the registry keys/values below into the NTUSER.DAT file which prevents the apps from redownloading. Credit to a60wattfish
    reg load HKU\Default_User C:\Users\Default\NTUSER.DAT
    Set-ItemProperty -Path Registry::HKU\Default_User\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager -Name SystemPaneSuggestionsEnabled -Value 0
    Set-ItemProperty -Path Registry::HKU\Default_User\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager -Name PreInstalledAppsEnabled -Value 0
    Set-ItemProperty -Path Registry::HKU\Default_User\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager -Name OemPreInstalledAppsEnabled -Value 0
    reg unload HKU\Default_User

    #Disables scheduled tasks that are considered unnecessary
    Write-Output "Disabling scheduled tasks"
    #Get-ScheduledTask -TaskName XblGameSaveTaskLogon | Disable-ScheduledTask -ErrorAction SilentlyContinue
    Get-ScheduledTask -TaskName XblGameSaveTask | Disable-ScheduledTask -ErrorAction SilentlyContinue
    Get-ScheduledTask -TaskName Consolidator | Disable-ScheduledTask -ErrorAction SilentlyContinue
    Get-ScheduledTask -TaskName UsbCeip | Disable-ScheduledTask -ErrorAction SilentlyContinue
    Get-ScheduledTask -TaskName DmClient | Disable-ScheduledTask -ErrorAction SilentlyContinue
    Get-ScheduledTask -TaskName DmClientOnScenarioDownload | Disable-ScheduledTask -ErrorAction SilentlyContinue
}

#This includes fixes by xsisbest
Function FixWhitelistedApps {

    Param([switch]$Debloat)

    If(!(Get-AppxPackage -AllUsers | Select Microsoft.Paint3D, Microsoft.MSPaint, Microsoft.WindowsCalculator, Microsoft.WindowsStore, Microsoft.MicrosoftStickyNotes, Microsoft.WindowsSoundRecorder, Microsoft.Windows.Photos)) {

    #Credit to abulgatz for the 4 lines of code
    Get-AppxPackage -allusers Microsoft.Paint3D | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml"}
    Get-AppxPackage -allusers Microsoft.MSPaint | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml"}
    Get-AppxPackage -allusers Microsoft.WindowsCalculator | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml"}
    Get-AppxPackage -allusers Microsoft.WindowsStore | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml"}
    Get-AppxPackage -allusers Microsoft.MicrosoftStickyNotes | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml"}
    Get-AppxPackage -allusers Microsoft.WindowsSoundRecorder | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml"}
    Get-AppxPackage -allusers Microsoft.Windows.Photos | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml"} }
}

Function CheckDMWService {

  Param([switch]$Debloat)

If (Get-Service -Name dmwappushservice | Where-Object {$_.StartType -eq "Disabled"}) {
    Set-Service -Name dmwappushservice -StartupType Automatic}

If(Get-Service -Name dmwappushservice | Where-Object {$_.Status -eq "Stopped"}) {
   Start-Service -Name dmwappushservice}
  }

Function CheckInstallService {
  Param([switch]$Debloat)
          If (Get-Service -Name InstallService | Where-Object {$_.Status -eq "Stopped"}) {
            Start-Service -Name InstallService
            Set-Service -Name InstallService -StartupType Automatic
            }
        }

Write-Output "Initiating Sysprep"
Begin-SysPrep
Write-Output "Removing bloatware apps."
Start-Debloat
Write-Output "Removing leftover bloatware registry keys."
Remove-Keys
Write-Output "Checking to see if any Whitelisted Apps were removed, and if so re-adding them."
FixWhitelistedApps
Write-Output "Stopping telemetry, disabling unneccessary scheduled tasks, and preventing bloatware from returning."
Protect-Privacy
#Write-Output "Stopping Edge from taking over as the default PDF Viewer."
#Stop-EdgePDF
CheckDMWService
CheckInstallService
Write-Output "Finished all tasks."
}



Export-ModuleMember -Function Set-LTServerAdd,Get-InactiveUsers,Remove-Emotet,Remove-EmotetLegacy,Remove-MalFiles,Get-OnlineADComps,Add-DHCPv4Reservation,Get-LTServerAdd,Protect-Creds,Update-ICTools,Install-PSExec,Import-ICTHistory,Set-FixCellular,New-ICToolsManifest,Remove-Win10Bloat
