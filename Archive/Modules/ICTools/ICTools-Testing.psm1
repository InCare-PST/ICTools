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
        While((Get-date) -le $RunTimeLoop){
            <#$WRMComp = @()
            $NWRM = @()
            $date = (get-date).AddDays(-$LastLogon)#>
            if($LogOnly -or $RunOnce){
                $RunTimeLoop = (Get-Date)
            }
            if ($UseList){
                $WRMComp = Import-Clixml -Path $LogDir\WRMComp.xml
                $NWRM = Import-Clixml -Path $LogDir\NOWRM.xml
            }
            else {
                Start-Job -Name Verify {
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
               <#$computers = Get-ADComputer -Filter * -Properties LastLogonDate | where lastlogondate -GE $date
                ForEach ($comp in $computers) {
                    if (Test-Connection -ComputerName $comp.name -Count 1 -Quiet) {
                        Write-Host $comp.name "is Alive"
                        if ([bool](Test-WSMan -ComputerName $comp.Name -ErrorAction SilentlyContinue)){
                            $WRMComp += $comp
                        }
                        else {
                            $NWRM += $comp
                        }
                    }#>
                    <#$WRMComp | Export-Clixml $LogDir\WRMComp.xml
                    $NWRM | Export-Clixml $LogDir\NOWRM.xml
                    $NWRM | Select-Object Name,DistinguishedName,LastLogonDate | Export-Csv $LogDir\NWRM.csv -Append -NoTypeInformation#>
                <#}
                $WRMComp | Export-Clixml $LogDir\WRMComp.xml
                $NWRM | Export-Clixml $LogDir\NOWRM.xml
                $NWRM | Select-Object Name,DistinguishedName,LastLogonDate | Export-Csv $LogDir\NWRM.csv -Append -NoTypeInformation
            }#>
            }
            Start-Job -Name LegacyJob -ScriptBlock {Remove-EmotetLegacy -ComputerName ($NWRM.name) -LogDir $LogDir -Logonly $LogOnly}
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
                    if (Test-Path -Path "C:\windows\SysWOW64") {
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
                    $file = get-childitem -path C:\Users\*\AppData,c:\windows\ * -Recurse -Force -ErrorAction SilentlyContinue | where {$_.fullname -match "^44\w{62}\.exe$|^m\w\wvca\.exe$|^tetup\.exe|^wbM\w+\.exe|(?i)(appdata\\.*\\aim\w$)"}
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
                                Write-Host "$ComputerName C:\Users\Username\Appdata and C:\Windows does not have 44Trojan files" -ForegroundColor Yellow
                                }
                            }
                    $file = get-childitem -path C:\  *.exe | where {$_.name -match "^44\w{62}\.exe$|^m\w\wvca\.exe$"}
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
                    $file = get-childitem -path C:\Windows\System32\Tasks  * | where {$_.name -match "Msne?tcs"}
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
                                write-host "$ComputerName C:\windows\system32\tasks Directory does not have tickbot files" -ForegroundColor Green
                                }
                            }
                $deletedfiles
                } | Select-Object Name,Directory,CreationDate,Deleted,Command,Type,ComputerName,TimeStamp | Export-Csv -Path $LogDir\Deleted-Emotet-Files.csv -Append -Force -NoTypeInformation
            #Start-Sleep -Seconds 30
            }
        }
    }
    End{
        Stop-Job -Name Verify -ErrorAction SilentlyContinue
        Stop-Job -Name LegacyJob -ErrorAction SilentlyContinue
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
                                write-host "$ComputerName C:\windows\system32\tasks Directory does not have tickbot files" -ForegroundColor Green
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
    }
    Process{
        While((Get-date) -le $RunTimeLoop){
            $WRMComp = @()
            $NWRM = @()
            $date = (get-date).AddDays(-$LastLogon)
            if($LogOnly -or $RunOnce){
                $RunTimeLoop = (Get-Date)
            }
            $computers = Get-ADComputer -Filter * -Properties LastLogonDate | where lastlogondate -GE $date
            ForEach ($comp in $computers) {
                if (Test-Connection -ComputerName $comp.name -Count 1 -Quiet) {
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
        Write-Output "$($computers.count)% have been detected online"
        Write-Output "$($WRMComp.count)% are responding via PSRemote"
        Write-Output "$($NWRM.count) need to have PSRemoting enabled or addressed"
        $WRMComp | Export-Clixml $LogDir\WRMComp.xml
        $NWRM | Export-Clixml $LogDir\NOWRM.xml
        $NWRM | Select-Object Name,DistinguishedName,LastLogonDate | Export-Csv $LogDir\NWRM.csv -Append -NoTypeInformation
        }
    }
    End{
    }
}

Export-ModuleMember -Function Get-InactiveUsers,Remove-Emotet,Remove-EmotetLegacy,Remove-MalFiles,Get-OnlineADComps
