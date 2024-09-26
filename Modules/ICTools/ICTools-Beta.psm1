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
    [cmdletbinding(SupportsShouldProcess = $True)]

    param(

        [string]$Time = 90,

        [string]$Path = "C:\temp",

        [switch]$Credentials,

        [switch]$Export,

        [switch]$Disable,

        [switch]$IsEnabled,

        [switch]$Move,

        [string]$OU = "*"

    )
    begin {
        $Date = get-date
        $Period = ($Date).adddays(-$time)
        $FileName = $Date.tostring("dd-MM-yyyy") + " " + "InactiveUsers.csv"
        $Users = Get-ADUser -Filter { enabled -eq $true }
        if ([bool]$Credentials) {
            $Creds = Get-Credential
        }
        if (!(Test-Path $Path)) {
            Write-Host "Creating Directory $Path"
            New-Item -Path $Path -ItemType Directory
        }
    }
    Process {
        if ([bool]$Credentials) {
            $InactivePresort = Get-ADUser -Credential $Creds -Filter { LastLogonTimeStamp -lt $Period -and enabled -eq $true } -Properties LastLogonTimeStamp
            $Inactive = $InactivePresort | select-object Name, SamAccountName, @{Name = "Last Logon Time"; Expression = { [DateTime]::FromFileTime($_.lastLogonTimestamp).ToString('yyyy-MM-dd_hh:mm:ss') } } | Sort-Object Name
            if ($Export) {
                Write-Verbose "Exporting to CSV"
                $Inactive | Export-Csv -Path "$Path\$FileName" -NoTypeInformation
                Write-Host "Total Enabled Users" $Users.count
                Write-Host "Total Inactive Users" $Inactive.count
            }
            Else {
                $Inactive | Out-Host
            }
        }
        else {
            $InactivePresort = Get-ADUser -Filter { LastLogonTimeStamp -lt $Period -and enabled -eq $true } -Properties LastLogonTimeStamp
            $Inactive = $InactivePresort | select-object Name, SamAccountName, @{Name = "Last Logon Time"; Expression = { [DateTime]::FromFileTime($_.lastLogonTimestamp).ToString('yyyy-MM-dd_hh:mm:ss') } } | Sort-Object Name
            if ($Export) {
                Write-Verbose "Exporting to CSV"
                $Inactive | Export-Csv "$Path\$FileName" -NoTypeInformation
            }
            Else {
                $Inactive | Out-host
            }
        }
        if ($Move) {
            $ORGU = Get-ADOrganizationalUnit -Filter 'name -like $OU' -Properties Name, DistinguishedName | Select-Object Name, Distinguishedname
            if ($ORGU.count -ge 2) {
                $ORG = $ORGU | Out-GridView -Title "Please Choose the Target OU" -OutputMode Single
            }
            else {
                $ORG = $ORGU
            }
            $InactivePresort | Move-ADObject -TargetPath $ORG.Distinguishedname
        }
        if ($Disable) {
            $InactivePresort | Disable-ADAccount

        }
    }
    End {
        Write-Host "Total Enabled Users" $Users.count
        Write-Host "Total Inactive Users" $Inactive.count

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
    Begin {
        $RunTimeLoop = (Get-Date).AddHours($RunTime)
        if (!(Test-Path $LogDir)) {
            New-Item -Path $LogDir -ItemType Directory
        }
    }
    Process {
        While ((Get-date) -le $RunTimeLoop) {
            $WRMComp = @()
            $NWRM = @()
            $date = (get-date).AddDays(-$LastLogon)
            if ($LogOnly -or $RunOnce) {
                $RunTimeLoop = (Get-Date)
            }
            if ($UseList) {
                $WRMComp = Import-Clixml -Path $LogDir\WRMComp.xml
                $NWRM = Import-Clixml -Path $LogDir\NOWRM.xml
            }
            else {
                $computers = Get-ADComputer -Filter * -Properties LastLogonDate | Where-Object { $_.lastlogondate -GE $date }
                ForEach ($comp in $computers) {
                    if (Test-Connection -ComputerName $comp.name -Count 1 -Quiet) {
                        Write-Host $comp.name "is Alive"
                        if ([bool](Test-WSMan -ComputerName $comp.Name -ErrorAction SilentlyContinue)) {
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
                $NWRM | Select-Object Name, DistinguishedName, LastLogonDate | Export-Csv $LogDir\NWRM.csv -Append -NoTypeInformation
            }
            #$LegacyJob = Start-Job -ScriptBlock {Remove-EmotetLegacy -ComputerName ($NWRM.name) -LogDir $LogDir -Logonly $LogOnly}
            $looptime = (Get-Date).AddMinutes(30)
            while ((Get-Date) -le $looptime) {
                if ($LogOnly -or $RunOnce) {
                    $looptime = (Get-Date)
                }
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
                Invoke-Command -ComputerName $WRMComp.name -ArgumentList $LogOnly, $exclude32, $exclude64, $excludewin {
                    param($LogOnly, $exclude32, $exclude64, $excludewin)
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
                    $file = get-childitem -path C:\programdata *.dll -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { $_.name -match "\w{8}-(\w{4}-){3}\w{12}\.dll" }
                    foreach ($bfile in $file) {
                        if ([bool]$bfile) {
                            $filedeleted = $false
                            $filepath = $bfile.fullname
                            if (!($LogOnly)) {
                                try {
                                    Stop-Process -Name $bfile.basename -Force -ErrorAction SilentlyContinue
                                }
                                catch {

                                }
                                #Start-Sleep -Seconds 3
                                try {
                                    Remove-Item $bfile.fullname -ErrorAction Stop
                                    $filedeleted = $true
                                }
                                catch {
                                    $filedeleted = $false
                                }
                            }
                            if ($filedeleted) {
                                $delstatus = "Yes"
                                write-host "$filepath was detected on $ComputerName and was deleted" -ForegroundColor Red
                            }
                            else {
                                $delstatus = "No"
                                write-host "$filepath was detected on $ComputerName but was not deleted" -ForegroundColor Red
                            }
                            $tempobj = @{
                                Name         = $bfile.name
                                Directory    = $bfile.FullName
                                CreationDate = $bfile.creationtime
                                Deleted      = $delstatus
                                Command      = $Task
                                Type         = "44Trojan"
                                ComputerName = $ComputerName
                                TimeStamp    = (Get-Date -Format "dd-MM-yyyy HH:mm:ss")
                            }
                            $FileObj = New-Object -TypeName psobject -Property $tempobj
                            $deletedfiles += $FileObj
                            #$deletedfiles += ($bfile | select name,directory,creationtime)
                        }
                        else {
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
                } | Select-Object Name, Directory, CreationDate, Deleted, Command, Type, ComputerName, TimeStamp | Export-Csv -Path $LogDir\Deleted-Emotet-Files.csv -Append -Force -NoTypeInformation
                Start-Sleep -Seconds 30
            }
        }
    }
    End {
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
    Begin {
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
                #$Alive = "Yes"
                if ([bool](Test-WSMan -ComputerName $comp -ErrorAction SilentlyContinue)) {
                    $WSMAN = "Enabled"
                }
                else {
                    $WSMAN = "Disabled"
                }
                $tempobj = @{
                    Name              = $Comp
                    DistinguishedName = $DistinguishedName
                    LastLogonDate     = $LastLogonDate
                    PsRemoting        = $WSMAN
                    OperatingSystem   = $OperatingSystem
                }
                $obj = New-Object -TypeName psobject -Property $tempobj
                $obj | Select-Object Name, LastLogonDate, PsRemoting, OperatingSystem, DistinguishedName
            }
        }
    }
    Process {
        While ((Get-date) -le $RunTimeLoop) {
            #$WRMComp = @()
            #$NWRM = @()
            $starttime = (get-date)
            $date = (get-date).AddDays(-$LastLogon)
            if ($LogOnly -or $RunOnce) {
                $RunTimeLoop = (Get-Date)
            }
            $computers = Get-ADComputer -Filter * -Properties LastLogonDate, OperatingSystem | Where-Object { $_.lastlogondate -GE $date }
            foreach ($comp in $computers) {
                $paramlist = @{
                    Comp              = $comp.name
                    DistinguishedName = $comp.DistinguishedName
                    LastLogonDate     = $comp.LastLogonDate
                    OperatingSystem   = $comp.OperatingSystem
                }
                $runspace = [PowerShell]::Create()
                $null = $runspace.AddScript($scriptblock)
                $null = $runspace.AddParameters($paramlist)
                $runspace.RunspacePool = $pool
                $runspaces += [PSCustomObject]@{ Pipe = $runspace; Status = $runspace.BeginInvoke() }
            }

            $onlinecomps = while ($runspaces.Status -ne $null) {
                $completed = $runspaces | Where-Object { $_.Status.IsCompleted -eq $true }
                foreach ($runspace in $completed) {
                    $runspace.Pipe.EndInvoke($runspace.Status)
                    $runspace.Status = $null
                }
            }
            $PsRemotingEnabled = $onlinecomps | Where-Object { $_.PsRemoting -eq "Enabled" }
            $PsRemotingDisabled = $onlinecomps | Where-Object { $_.PsRemoting -eq "Disabled" }
            Write-Output "$($onlinecomps.count) have been detected online"
            Write-Output "$($PsRemotingEnabled.count) are responding via PSRemote"
            Write-Output "$($PsRemotingDisabled.count) need to have PSRemoting enabled or addressed"
            $PsRemotingEnabled | Export-Clixml $LogDir\WRMComp.xml
            $PsRemotingDisabled | Export-Clixml $LogDir\NOWRM.xml
            $FTimeStamp = (Get-Date -Format "dd-MM-yyyy HH-mm-ss")
            $PsRemotingDisabled | Select-Object Name, LastLogonDate, OperatingSystem, DistinguishedName | Export-Csv $LogDir\NoPSRemoting_$FTimeStamp.csv -Append -NoTypeInformation
            $endtime = (get-date)
            if (($endtime - $starttime).seconds -le 300 -and !($RunOnce)) {
                Start-Sleep -Seconds (300 - ($endtime - $starttime).seconds)
            }
        }
    }
    End {
        $pool.Close()
        $pool.Dispose()
    }
}

function Add-DHCPv4Reservation {
    <#
#>
    [cmdletbinding()]
    param(
        [parameter(Mandatory = $true)]
        [string]$CSVPath,

        [parameter(Mandatory = $true)]
        [string]$ScopeID

    )
    Begin {
        $list = Import-Csv $CSVPath
    }
    Process {
        foreach ($item in $list) {
            Add-DhcpServerv4Reservation -ScopeId $ScopeID -IPAddress $item.ipaddress  -Name $item.name -Description $item.description -ClientId $item.clientid
        }
    }
    End {
    }
}

function Get-LTServerAdd {
    <#
.SYNOPSIS
This command is for checking online domain computers for the proper labtech reporting server setting and returning that information.
.DESCRIPTION
Checks a registry key in the labtech hive to see if the server has been properly configured for the Labtech agent. It reports back
on the setting and if labtech was actually installed. It can also be set to email reports
.PARAMETER LogDir
This parameter sets the working dirctory for the command. The default is C:\temp
.PARAMETER ServerAddr
This parameter specifies the correct server address for the Labtech reporting server. Currently set to "https://cwa.incare360.com" by default
.PARAMETER Exclude
Specifies if certain computers should be excluded from the scan. The options are Servers, Workstations, or a list in a csv file called exclude.csv. The file should
have only one column called name
.PARAMETER Report
This specifies if the command should send a report through email. It only emails a report if there are machines misconfigured or without the InCare agent.
If this Parameter is selected then a set of credentials needs to be saved in the working directory using the Protect-creds command.
.PARAMETER Email
Specifies the email address the report should be sent to.
.PARAMETER ClientName
Specifies the name of the client the report is being run from.
.Example
Get-LTServerAdd 
This will check all currently online domain computers for the correct server setting and export the results to C:\Temp
.Example 
Get-LTServerAdd -Logdir C:\AgentCheck -Exclude Servers
This will check all currently online domain workstations and not the servers. The results will be exported to C:\AgentCheck
.Example
GEt-LTServerAdd -Report -Email someone@InCare360.com -ClientName "USA HealthCare"
Check all online computers in the domain, if any do not have the correct server setting, or have labtech installed a report will be emailed to "someone@incare360.com"
.Example
powershell.exe -noexit -command  &{Get-LTServerAdd -LogDir C:\Users\incare\Documents\LTAgent -report -email someone@incare360.com -ClientName "A Client"}; exit
Using this format the command can be added to the windows task scheduler. Make sure it is set to run during regular business hours when the most Computers will be online.
#>
    [cmdletbinding(DefaultParameterSetName = "Default")]
    param(
        [Parameter(ParameterSetName = "Default")]
        [Parameter(ParameterSetName = "Reporting", Mandatory = $false)]
        [string]$LogDir = "c:\temp",

        [Parameter(ParameterSetName = "Default")]
        [Parameter(ParameterSetName = "Reporting", Mandatory = $false)]
        [string]$ServerAddr = "https://cwa.incare360.com",

        [Parameter(ParameterSetName = "Default")]
        [Parameter(ParameterSetName = "Reporting", Mandatory = $false)]
        [ValidateSet("Servers", "Workstations", "List")]
        [string]$Exclude,

        [Parameter(ParameterSetName = "Reporting", Mandatory = $false)]
        [switch]$report,

        [Parameter(ParameterSetName = "Reporting", Mandatory = $true)]
        [string]$toemail,

        [Parameter(ParameterSetName = "Reporting", Mandatory = $true)]
        [string]$fromemail,

        [Parameter(ParameterSetName = "Reporting", Mandatory = $true)]
        [string]$smtpserver,

        [Parameter(ParameterSetName = "Reporting", Mandatory = $true)]
        [string]$ClientName

    )
    Begin {
        $CurrentFullLTVersion = (Get-ItemProperty -Path HKLM:\software\LabTech\Service\).'Version'
        $CurrentLTVersion = ([regex]::Match($CurrentFullLTVersion, '.*(?=\.)')).value
        if ($report) {
            #$credentials = Import-Clixml -path "$logdir\incare.xml"
        }
        if (!(Test-Path $LogDir)) {
            New-Item -Path $LogDir -ItemType Directory
        }
        Start-Job -Name Verify -ArgumentList $Logdir {
            Param($Logdir)
            Get-OnlineADComps -RunOnce -LogDir $LogDir
        }
        $waiting = $true
        while ($waiting) {
            $VerifyJob = Get-Job -Name Verify
            if ($VerifyJob.state -ne "Running" -and $VerifyJob.state -ne "Completed") {
                Write-Host "Could not complete computer query"
                Receive-Job -Name Verify
                $waiting = $false
            }
            if ($VerifyJob.State -eq "Completed") {
                $WRMComp = Import-Clixml -Path $LogDir\WRMComp.xml
                #$ComputerName = $WRMComp.name
                Receive-Job -Name Verify
                $waiting = $false
            }
        }
        switch ($Exclude) {
            "Servers" { $ComputerName = ($WRMComp | Where-Object { $_.operatingsystem -notmatch "server" }).name }
            "Workstations" { $ComputerName = ($WRMComp | Where-Object { $_.operatingsystem -match "server" }).name }
            "List" { $ComputerName = $WRMComp.name; $Excludes = Import-Csv $LogDir\exclude.csv; foreach ($ex in $Excludes.name) { $ComputerName = $ComputerName | Where-Object { $_ -notmatch $ex } } }
            default { $ComputerName = $WRMComp.name }
        }
    }
    Process {
        $agentlist = Invoke-Command -ComputerName $ComputerName {
            $serveraddress = (Get-ItemProperty -Path HKLM:\software\LabTech\Service\).'server address'
            $ltversion = (Get-ItemProperty -Path HKLM:\software\LabTech\Service\).'Version'
            If ([bool]$serveraddress) {
                $tempobj = @{
                    Computername  = $env:COMPUTERNAME
                    ServerAddress = $serveraddress
                    LTVersion     = $ltversion
                }
            }
            else {
                $installcheck = Get-WmiObject -Class Win32_Product | Where-Object { $_.name -match "labtech" }
                if ([bool]$installcheck) {
                    $installstate = "Server Address not found"
                }
                else {
                    $installstate = "Labtech Agent not installed"
                }
                $tempobj = @{
                    Computername  = $env:COMPUTERNAME
                    ServerAddress = $installstate
                    LTVersion     = "NA"
                }
            }
            $ExportObj = New-Object -TypeName psobject -Property $tempobj
            $ExportObj

        } | Select-Object Computername, ServerAddress, LTVersion #|Export-Csv -Path $LogDir\Get_LTAddr_Log.csv -Append -Force -NoTypeInformation
        if ($report) {
            $agentissues = $agentlist | Where-Object { $_.serveraddress -ne $ServerAddr -or ([regex]::Match($_.LTVersion, '.*(?=\.)')).value -ne $CurrentLTVersion }
            if ([bool]$agentissues) {
                $agentissues | Export-Csv -Path $LogDir\Get_LTAddr_Log.csv -Append -Force -NoTypeInformation
                $b = $agentissues | ConvertTo-Html -Fragment -PreContent "<h2>LTAgent Issues:</h2>" | Out-String
                $css = "https://incaretechnologies.com/css/incare.css"
                $precontent = "<img class='inc-logo' src='https://incaretechnologies.com/wp-content/uploads/InCare_Technologies_horizontal-NEW-NoCross-OUTLINES-for-Web.png'/><H1>$ClientName</H1>"
                $HTMLScratch = ConvertTo-Html -Title "InCare Agent Issues" -Head $precontent -CssUri $css -Body $b -PostContent "<H5><i>$(get-date)</i></H5>"
                $Body = $HTMLScratch | Out-String
                $MailMessage = @{
                    To          = "$toemail"
                    From        = "$fromemail"
                    Subject     = "InCare Agent Report From $ClientName"
                    Body        = "$body"
                    BodyAsHTML  = $True
                    Smtpserver  = "$smtpserver"
                    Attachments = "$LogDir\Get_LTAddr_Log.csv"
                }
                Send-MailMessage @MailMessage
            }
        }
        else {
            $agentlist | Export-Csv -Path $LogDir\Get_LTAddr_Log.csv -Append -Force -NoTypeInformation
        }
    }
    End {
        #($NWRM.name).tostring | Export-Csv -Path $LogDir\NoPSComps.csv -NoTypeInformation
        Remove-Item -Path $LogDir\WRMComp.xml
        Remove-Item -Path $LogDir\NOWRM.xml
        Remove-Job -Name Verify -ErrorAction SilentlyContinue
        if ($report) {
            Remove-Item -Path $LogDir\Get_LTAddr_Log.csv -ErrorAction SilentlyContinue
            Get-ChildItem $logdir\nopsremoting* | Where-Object { $_.creationtime -le ((get-date).AddDays(-7)) } | remove-item
        }
        else {
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

        [Parameter(Position = 0,
            ValueFromPipelineByPropertyName = $true)]
        [string[]]$ComputerName,

        [string]$Logdir = "C:\temp",

        [string]$ServerAddr = "https://cwa.incare360.com"
    )
    Begin {
        if (![bool]$ComputerName) {
            $JobRan = $true
            Start-Job -Name Verify -ArgumentList $Logdir {
                Param($Logdir)
                Get-OnlineADComps -RunOnce -LogDir $LogDir
            }
            $waiting = $true
            While ($waiting) {
                $VerifyJob = Get-Job -Name Verify
                if ($VerifyJob.state -ne "Running" -and $VerifyJob.State -ne "Completed") {
                    Write-Host "Could not complete computer query"
                    Receive-Job -Name Verify
                    $waiting = $false
                }
                if ($VerifyJob.State -eq "Completed") {
                    $WRMComp = Import-Clixml -Path $LogDir\WRMComp.xml
                    $ComputerName = $WRMComp.Name
                    Receive-Job -Name Verify
                    $waiting = $false
                }
                else {
                    Start-Sleep -Seconds 5
                }
            }
        }
    }
    Process {
        #Try {
        Invoke-Command -ComputerName $ComputerName -ArgumentList $ServerAddr {
            param($ServerAddr)
            try {
                $currentaddress = (Get-ItemProperty -Path HKLM:\software\LabTech\Service\).'server address'
            }
            catch {
            }
            $Targetname = $env:COMPUTERNAME
            If ([bool]$currentaddress) {
                $InitialRegEntry = $currentaddress
                if ($currentaddress -ne $ServerAddr) {
                    try {
                        $keychanged = "Yes"
                        #Stop-Service LTSvcMon,LTService -ErrorAction SilentlyContinue
                        Stop-Process -Name LTSVC, LTSvcMon, LTTray -Force -ErrorAction SilentlyContinue
                        Set-ItemProperty -Path HKLM:\software\LabTech\Service\ -Name "server address" -Value $ServerAddr -ErrorAction SilentlyContinue
                        Start-Service LTSvcMon, LTService -ErrorAction SilentlyContinue
                    }
                    catch {
                        $keychanged = "Error"
                    }
                }
                else {
                    $keychanged = "Already Correct"
                }
            }
            else {
                $InitialRegEntry = "Server Address not found"
            }
            $tempobj = @{
                "ComputerName"           = $Targetname
                "Initial Registry Entry" = $InitialRegEntry
                "Key Changed"            = $keychanged
            }
            $RegObj = New-Object -TypeName psobject -Property $tempobj
            $RegObj
        } | Select-Object "ComputerName", "Initial Registry Entry", "Key Changed" | Export-Csv -Path $LogDir\Set_LTAddr_Log.csv -Append -Force -NoTypeInformation
        #}
        <#Catch{
            Write-Host "Could not connect to $ComputerName"
        }#>
    }
    End {
        $FTimeStamp = (Get-Date -Format "dd-MM-yyyy HH-mm-ss")
        if ($JobRan) {
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

        [parameter(mandatory = $true)]
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

        [switch]$Beta,

        [string]$PSMName = "ICTools"
    )

    Begin {
        if ($Beta) {
            #Beta Test Variables
            $psmurl = "https://raw.githubusercontent.com/InCare-PST/ICTools/master/Modules/$($PSMName)/$($PSMName)-Beta.psm1"
            $psdurl = "https://raw.githubusercontent.com/InCare-PST/ICTools/master/Modules/$($PSMName)/$($PSMName)-Beta.psd1"
        }
        else {
            #Production Variables
            $psmurl = "https://raw.githubusercontent.com/InCare-PST/ICTools/master/Modules/$($PSMName)/$($PSMName).psm1"
            $psdurl = "https://raw.githubusercontent.com/InCare-PST/ICTools/master/Modules/$($PSMName)/$($PSMName).psd1"
        }
        #Determine current Module path
        $modulepaths = $env:PSModulePath.Split(";")
        $instance = 0
        foreach ($mpath in $modulepaths) {
            if (test-path $mpath\$PSMName\$PSMName.psm1) {
                $instance = $instance + 1
                if ($instance -eq 1) {
                    $installpath = $mpath
                }
                elseif ($instance -gt 1) {
                    write-host "$($PSMName) Module found in multiple locations" -ForegroundColor Red
                    Write-Host "$installpath and in $mpath" -ForegroundColor Yellow
                    Exit
                }
            }
        }
        if (![bool]$installpath) {
            $installpath = $modulepaths[0]
            $installed = $false
        }
        else {
            $installed = $true
        }
        #Get MD5 hash of online files
        $wc = New-Object System.Net.WebClient
        try {
            $psmhash = Get-FileHash -InputStream ($wc.openread($psmurl)) -Algorithm MD5 -ErrorAction Stop
        }
        catch {
            Write-Host "Could not access file at $($psmurl)" -ForegroundColor Yellow
        }
        try {
            $psdhash = Get-FileHash -InputStream ($wc.openread($psdurl)) -Algorithm MD5 -ErrorAction Stop
        }
        catch {
            Write-Host "Could not access file at $($psdurl)" -ForegroundColor Yellow
        }
        #declare non-dynamic variables
        $ictpath = "$installpath\$PSMName"
        $psmfile = "$ictpath\$PSMName.psm1"
        $psdfile = "$ictpath\$PSMName.psd1"
        #$psptest = Test-Path $Profile
        #$psp = New-Item -Path $Profile -Type File -Force

        #get the file hash for existing files
        if ($installed) {
            $cpsmhash = Get-FileHash -Path $psmfile -Algorithm MD5
        }
        $psdinstalled = $true
        if (test-path -Path $psdfile) {
            $cpsdhash = Get-FileHash -Path $psdfile -Algorithm MD5
        }
        else {
            $psdinstalled = $false
        }
    }
    Process {
        #install module if not present
        if (!($installed)) {
            New-Item -Path $ictpath -ItemType directory
            $wc.DownloadFile($psmurl, $psmfile)
            $wc.DownloadFile($psdurl, $psdfile)
        }
        else {
            $updated = $true
            #compare files and replace if necessary 
            if (!($psmhash.hash -eq $cpsmhash.hash)) {
                remove-item $psmfile -Force
                $wc.DownloadFile($psmurl, $psmfile)
            }
            else {
                Write-Host "Module file is already up to date."
                $updated = $false
            }
            if ($psdinstalled) {
                if (!($psdhash.hash -eq $cpsdhash.hash)) {
                    remove-item $psdfile -Force
                    $wc.DownloadFile($psdurl, $psdfile)
                }
            }
            else {
                $wc.DownloadFile($psdurl, $psdfile)
            }
        }
    }
    End {
        #reloading module either by restarting powershell or removing and importing the module
        if ($updated) {
            write-host "Reloading $($PSMName) Module." -ForegroundColor Green
            start-sleep -seconds 2
            Import-Module $PSMName
            Remove-Module $PSMName
            Import-Module $PSMName
        }
        else {
            Write-Host "$($PSMName) Module is already up to date." -ForegroundColor Green
        }
    }    #End of Function
}


Function Import-ICTHistory {
    <# This is to Install PSExec #>
    $ictpath = "$Home\Documents\WindowsPowerShell\Modules\ICTools"

    if (Test-Path -Path $ictpath\history.csv) {
        Import-Csv $ictpath\history.csv | Add-History
    }
    else {
        Write-Host "No History to Import"
    }
    #End of Function
}

Function Install-PSExec {
    <# This is to Install PSExec #>
    $url = "https://live.sysinternals.com/psexec.exe"
    $syspath = "$env:windir\System32\psexec.exe"



    if (!(test-path -Path $syspath)) {

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

    if (!(test-path $regpath)) {
        New-Item -Path $regpath -Force | Out-Null
        New-ItemProperty -Path $regpath -Name $regkey -Value "1" -PropertyType DWORD -Force | Out-Null
    }
    else {
        New-ItemProperty -Path $regpath -Name $regkey -Value "1" -PropertyType DWORD -Force | Out-Null
    }

    #End function
}

function Set-Immutid {
    <#
    .SYNOPSIS 
    Setup Immutable ID in Office 365 to streamline Azure AD sync
    .DESCRIPTION 
    Allows for a compareison between online office 365 and on premises AD to setup a 1 to 1 relationship between the two accounts for Azure AD Sync.
    You have the option to export to CSV, apply the ID to the Azure Account or just display on screen. The Default only displays the information on screen.
    .PARAMETER apply
    Applies the Immutable ID that is created to the Office 365/Azure AD account
    .PARAMETER export
    Created CSV file with information collected in function
    .PARMAETER path
    Specifies a path for the export file. Defauts to C:\Temp Default filename is exporteduserlist+Date.csv
    .EXAMPLE
    .EXAMPLE
    #>
    [CmdletBinding()]
    param (
        [switch]$apply,
    
        [switch]$export,
    
        [string]$path = "c:\temp"
    )
        
    begin {
        if (!(Test-Path -Path $path)) { New-Item -Path $path -Type Directory -Force }
    
        if (Get-Module -ListAvailable -Name azuread) {
            Import-Module azuread
        }
        else {
            Return "AzureAD module not installed."
        }

        if (Get-Module -ListAvailable -Name ActiveDirectory) {
            Import-Module ActiveDirectory
        }
        else {
            Return "Active diretory module not installed."
        }
        
        if ($export) {
            $date = Get-Date -Format yyyy-MM-dd-HH.mm.ss
            $newpath = "$($path)\exporteduserlist-$($date).csv"
        }
        Connect-AzureAD
        $azureUsers = Get-AzureADUser -All $true
        $adUsers = Get-ADUser -Filter * -Properties lastlogondate, objectguid
    }
        
    process {
        $userlist = foreach ($azuser in $azureUsers) {
            $adUser = $adUsers | Where-Object { $_.givenname -eq $azuser.GivenName -and $_.surname -eq $azuser.Surname }
            if (@($adUser).count -eq 1) {
                $immid = [system.convert]::ToBase64String(([GUID]($adUser.objectguid)).tobytearray())
                $props = @{
                    name           = $adUser.Name
                    samaccountname = $adUser.samaccountname
                    objectguid     = $adUser.objectguid
                    AzureADid      = $azuser.objectid
                    mail           = $azuser.Mail
                    immuteID       = $immid
                    lastlogondate  = $adUser.lastlogondate
                }
                $tempobject = New-Object psobject -Property $props
                $tempobject | Select-Object name, samaccountname, mail, lastlogondate, AzureADid, objectguid, immuteID
            }
            if (@($adUser).count -lt 1) {
                $props = @{
                    name = $azuser.DisplayName
                    mail = $azuser.Mail
                }
                $tempobject = New-Object psobject -Property $props
                $tempobject | Select-Object name, mail
            }
        }
        $userlist.count
        if ($apply) {
            foreach ($cuser in $userlist) {
                if ($cuser.immuteID) {
                    $objectid = $cuser.AzureADid
                    Set-AzureADUser -ObjectId $objectid -ImmutableId $cuser.immuteID
                    $cuser.mail
                }
            }
        }
        elseif ($export) {
            $userlist | Select-Object name, samaccountname, mail, lastlogondate, AzureADid, objectguid, immuteID | Export-Csv -Path $newpath -NoTypeInformation
        }
        else {
            $userlist | Select-Object name, samaccountname, mail, lastlogondate, AzureADid, immuteID
        }
    }
        
    end {
            
    }
}

function Get-FSMORoles {
    $forest = Get-ADForest
    $domain = Get-ADDomain

    New-Object -TypeName psobject -Property @{
        SchemaMaster         = $forest.SchemaMaster
        DomainNamingMaster   = $forest.DomainNamingMaster
        PDCEmulator          = $domain.PDCEmulator
        RIDMaster            = $domain.RIDMaster
        InfrastructureMaster = $domain.InfrastructureMaster
    }
}

Function Get-ServiceAccounts {
    [cmdletbinding()]
    param(

        [switch]$export,

        [string]$path = "C:\temp",

        [string]$username
            
    )
    Begin {
        Write-Verbose "Getting list of online servers"
        $date = (get-date).AddDays(-60)
        $onlineservers = @()
        $offlineservers = @()
        $allservers = Get-ADComputer -filter * -Properties operatingsystem, lastlogondate | Where-Object { $_.operatingsystem -match "server" -and $_.enabled -eq $true -and $_.lastlogondate -ge $date }
        foreach ($server in $allservers) {
            if (Test-Connection $server.name -Count 1 -Quiet) {
                $onlineservers += $server
            }
            else {
                $offlineservers += $server
            }
        }
        Write-Host -ForegroundColor Green "The following servers are online and will be examined."
        $onlineservers.Name
        Write-Host -ForegroundColor Red "The following servers are offline and will not be examined."
        $offlineservers.Name
    }
    Process {
        $serverNameList = $onlineservers.Name
        $serviceList = Invoke-Command -ComputerName $serverNameList {
            Get-WmiObject win32_service | Select-Object systemName, displayname, startname
        }
        if ([bool]$username) {
            $finalList = $serviceList | Where-Object { $_.startname -match $username } | Sort-Object -Property systemName
        }
        else {
            $finalList = $serviceList | Sort-Object -Property systemName
        }
        if ($export) {
            $finalList | Select-Object systemName, displayname, startname | Export-Csv -Path "$path\serviceaccounts.csv" -NoTypeInformation 
        }
        else {
            $finalList | Select-Object systemName, displayname, startname
        }

        <# Commenting out, going with Invoke-Command
        $dcomopt = New-CimSessionOption -Protocol Dcom
        $wsmanopt = New-CimSessionOption -Protocol Wsman
        $wsmanerrors = @()
        $dcomerrors = @()
        Write-Verbose "Establishing Connection to servers"
        foreach($onlineserver in $onlineservers){
            Write-Verbose "Checking for WSMAN"
            If([bool](Test-WSMan -ComputerName $onlineserver.name)){
                try{
                    Write-Verbose "Attempting to connect to $onlineserver via WSMAN"
                    New-CimSession -ComputerName $onlineserver.name -SessionOption $wsmanopt -ErrorAction Stop 
                }
                catch{
                }
            }
            else{
                Write-Verbose "Attempting DCOM because WSMAN unavailable"
                try{
                    Write-Verbose "Attempting to connect to $onlineserver via DCOM"
                    New-CimSession -ComputerName $onlineserver.name -SessionOption $dcomopt -ErrorAction Stop
                }
                catch{
                
                }
            }
        }
        $services = Get-CimInstance -CimSession (Get-CimSession) -ClassName win32_service | where {$_.startname -notmatch "local|Network\sService|NetworkService" -and $_.StartName -ne $null}
    #>
    }
    End {
    
    }
}

function Find-Folders {
    [Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
    [System.Windows.Forms.Application]::EnableVisualStyles()
    $browse = New-Object System.Windows.Forms.FolderBrowserDialog
    $browse.SelectedPath = "C:\"
    $browse.ShowNewFolderButton = $false
    $browse.Description = "Select a directory for file export"

    $loop = $true
    while($loop)
    {
        if ($browse.ShowDialog() -eq "OK")
        {
        $loop = $false
		
		#Insert your script here
		
        } else
        {
            $res = [System.Windows.Forms.MessageBox]::Show("You clicked Cancel. Would you like to try again or exit?", "Select a location", [System.Windows.Forms.MessageBoxButtons]::RetryCancel)
            if($res -eq "Cancel")
            {
                #Ends script
                return
            }
        }
    }
    $browse.SelectedPath
    $browse.Dispose()
}

function Get-SubscriptionInfo{
    param(

        [string]$path,

        [string]$clientname = "",

        [string]$scope = "User.Read.All,Organization.Read.All,AuditLog.Read.All,Directory.Read.All,Reports.Read.All,ReportSettings.ReadWrite.All",

        [string]$filename = "MappingFile.csv"
    )

    begin{

        #Making sure there is not an active MGGraph connection
        Disconnect-MgGraph -InformationAction SilentlyContinue -ErrorAction SilentlyContinue

        $date = Get-Date
        
        #determine working folder
        if(![bool]$path){
            $path = Find-Folders
        }

        #create filename
        $xlsxfilename = $date.tostring("dd-MM-yyyy") + " " + $clientname + "`.xlsx"

        #create temp file path for usage report csv
        $tempusagefile = $path + "`\" + "temporaryexportfile.csv"

        # create full path for export files
        $exportedFile = $path + "`\" + $xlsxfilename

        #check if path exists. If not, create it.
        if (!(Test-Path $Path)) {
            Write-Host "Creating Directory $Path" -ForegroundColor Yellow
            New-Item -Path $Path -ItemType Directory
        }

        #check to see if file already exists. If it does prompt the user to see if they want the existing file deleted.
        if(Test-Path $exportedFile){
            Write-Host "File $($xlsxfilename) already exists. Would you like to delete it?" -ForegroundColor Yellow
            
            $wshell = New-Object -ComObject Wscript.Shell
            $answer = $wshell.Popup("Delete $($xlsxfilename)?",0,"Delete File",32+4)
        }

        #delete file or exit script
        if($answer -eq 6){
            Remove-Item -Path $exportedFile -Force
        } elseif($answer -eq 7){
            Write-Host "Please rename or remove file and run command again." -ForegroundColor Yellow
            exit
        }


        # Define the URL of the mapping file hosted online
        $mappingFileUrl = "https://download.microsoft.com/download/e/3/e/e3e9faf2-f28b-490a-9ada-c6089a1fc5b0/Product%20names%20and%20service%20plan%20identifiers%20for%20licensing.csv"        
    
        # Download the mapping file and import data to variable
        $planMapping = Invoke-RestMethod -Uri $mappingFileUrl | ConvertFrom-Csv -Delimiter ","
       
        If(Get-Module -ListAvailable Microsoft.Graph.Beta.Users){
            Import-Module Microsoft.Graph.Beta.Users
        }else{
            Write-Host "Required Microsoft Module not installed. Please run 'Install-Module Microsoft.Graph.Beta'" -ForegroundColor Red
            exit
        }    
    
        # Check to see if neccessary modules have been installed.
        If(Get-Module -ListAvailable Microsoft.Graph.Beta.Identity.DirectoryManagement){
            Import-Module Microsoft.Graph.Beta.Identity.DirectoryManagement
        }else{
            Write-Host "Required Microsoft Module not installed. Please run Install-Module 'Microsoft.Graph.Beta.Identity.DirectoryManagement'" -ForegroundColor Red
            exit
        }

        If(Get-Module -ListAvailable ImportExcel){
            Import-Module ImportExcel
        }else{
            Write-Host "Required Microsoft Module not installed. Please run 'Install-Module ImportExcel'" -ForegroundColor Red
            exit
        }
        # Connect to Microsoft Graph using Connect-MgGraph with specified scope
        Connect-MgGraph -Scopes $scope -NoWelcome
        #Retrieve the current "Concealed reports setting"
        $reportsetting = Get-MgBetaAdminReportSetting       
    }

    process{

        if($reportsetting.DisplayConcealedNames){
            $report_params = @{
                displayConcealedNames = $false
            }
            Update-MgBetaAdminReportSetting -BodyParameter $report_params
            #Write-Host "Changing Concealed Report settings to export data." -ForegroundColor Green
        }
        # Retrieve information for each mailbox
        try {
            $mailboxes = Get-MgBetaUser -All -Property signinactivity -ErrorAction Stop -ErrorVariable NoSignin
        }
        catch {
            Write-Host "Unable to get Last Logon date. Most likely caused by a free level of Entra ID instead of Premium." -ForegroundColor Yellow
            $mailboxes = Get-MGBetaUser -All
        }
        # Retrieve usage report information
        Get-MgBetaReportMailboxUsageDetail -Period D7 -OutFile $tempusagefile
        # Import the data we just exported because someone at Microsoft is an idiot
        $usageimport = Import-Csv -Path $tempusagefile
        # Remove the temporary file we just created beause the command forces us to export it.
        Remove-Item -Path $tempusagefile -Force
        # Format and export the information
        $exportedData = foreach ($mailbox in $mailboxes) {
            $licenses = $mailbox.assignedlicenses.skuid
            $assignedlicenses = @()
            foreach($license in $licenses){
                $friendlyname = $planmapping | Where-Object {$_.GUID -eq $license} | Select-Object -First 1 | Select-Object Product_Display_Name
                $assignedlicenses += $friendlyname
            }
            $liclist = $assignedlicenses.Product_Display_Name -join "+"
            $officephone = $mailbox.BusinessPhones -join ";"
            
            [PSCustomObject]@{
                DisplayName = $mailbox.displayName
                FirstName = $mailbox.givenName
                LastName = $mailbox.surname
                Enabled = $mailbox.AccountEnabled
                "Last Logon" = $mailbox.SignInActivity.LastSignInDateTime
                "Sync Enabled" = $mailbox.OnPremisesSyncEnabled
                UserType = $mailbox.userType
                Licenses = $liclist  # Use the translated friendly names
                "User Principal Name" = $mailbox.UserPrincipalName
                "Street Address" = $mailbox.StreetAddress
                City = $mailbox.City
                State = $mailbox.State
                "Postal Code" = $mailbox.PostalCode
                "Country/Region" = $mailbox.Country
                Department = $mailbox.Department
                "Office Name" = $mailbox.OfficeLocation
                "Office Phone" = $officephone
                "Mobile Phone" = $mailbox.MobilePhone
                "When Created" = $mailbox.CreatedDateTime
            }
        }

        #Filter the list based on those with and without licenses
        $licensedAccounts = $exportedData | Where-Object {$_.Licenses -ne ""}
        $unlicensedAccounts = $exportedData | Where-Object {$_.Licenses -eq ""}

        #find number of licensed accounts and set starting row for subscriptions
        $startingrow = $licensedAccounts.count + 5

        $subskus = Get-MgBetaSubscribedSku -All

        $subscribtionexport = foreach($subsku in $subskus){
            $basesku = $subsku.skuid
            $friendlyname = $planMapping | Where-Object {$_.GUID -eq $basesku} | Select-Object -First 1 | Select-Object -ExpandProperty Product_Display_Name

            [PSCustomObject]@{
                License = $friendlyname
                Enabled = $subsku.PrepaidUnits.Enabled
                Assigned = $subsku.ConsumedUnits
                Expired = $subsku.PrepaidUnits.Suspended
                Available = $subsku.prepaidunits.enabled - $subsku.consumedUnits
            }
        }
        # Format Usage Data
        $exportedusage = foreach($user in $usageimport){
            $gibibyte = $user."Storage Used (Byte)"/[math]::Pow(1024, 3)
            $mebibyte = $user."Storage Used (Byte)"/[math]::Pow(1024, 2)
        
            [PSCustomObject]@{
                "Display Name" = $user."Display Name"
                "User Principal Name" = $user."User Principal Name"
                "Storage Used(MebiByte)" = $mebibyte
                "Storage Used(GibiByte)" = $gibibyte
                "Has Archive" = $user."Has Archive"
                "Created Date" = $user."Created Date"
                "Is Deleted" = $user."Is Deleted"
                "Deleted Date" = $user."Deleted Date"
                "Recipient Type" = $user."Recipient Type"
        
            }
        }
        #Export to Excel file 
        $licensedAccounts | Export-Excel $exportedFile -AutoSize -TableName Licensed -TableStyle Medium2 -WorksheetName "O365 Licensed Accounts"

        $unlicensedAccounts | Export-Excel $exportedFile -AutoSize -TableName UnLicensed -TableStyle Medium2 -WorksheetName "O365 UnLicensed Accounts"

        $subscribtionexport | Export-Excel $exportedFile -AutoSize -StartRow $startingrow -TableName Subscriptions -TableStyle Medium2 -WorksheetName "O365 Licensed Accounts" 

        $exportedusage | Export-Excel -path $exportedFile -AutoSize -TableName Usage -TableStyle Medium2 -WorksheetName "Mailbox Usage Report"
    }

    end{
        #Put the report sesttings back the way we found them.
        if($reportsetting.DisplayConcealedNames){
            $report_params = @{
                displayConcealedNames = $true
            }
            Update-MgBetaAdminReportSetting -BodyParameter $report_params
            #Write-Host "Changing Concealed Report settings back to previuos settings." -ForegroundColor Green
        }
        #Disconnect from Graph
        Disconnect-MgGraph -InformationAction SilentlyContinue -ErrorAction SilentlyContinue
    }
}
function Set-P81routes{
    #Requires -RunAsAdministrator
    [CmdletBinding(DefaultParameterSetName="default",SupportsShouldProcess = $True)]
    param (
        
        [Parameter(ParameterSetName='import')]
        [switch]$import = $false,

        [Parameter(ParameterSetName='export')]
        [switch]$export = $false,

        [Parameter(Mandatory,ParameterSetName='import')]
        [Parameter(Mandatory,ParameterSetName='export')]
        [string]$path,

        [Parameter(ValueFromPipeline=$True)]
        [string[]]$add,

        [string[]]$append,

        [switch]$list = $false,

        [switch]$list_only = $false

    )
    
    begin{
        $P81_Interface = Get-NetAdapter -Name "P81*"
        #Check that only 1 interface was found
        if ($P81_Interface.Count -eq 0) {
            Write-Host "No P81 adapter found. Are you currently connected?" -ForegroundColor Yellow
            Break
        } elseif ($P81_Interface.count -gt 1) {
            Write-Host "Too many P81 Adapters found. $($P81_Interface.count) found."
            Break
        }
        #Find the P81 Interface Address
        $P81_Address = $P81_Interface | Get-NetIPAddress | Select-Object -ExpandProperty IPAddress
        if ($P81_Address.Count -eq 0) {
            Write-Host "Could not get local IP of P81 adapter."
            Break
        } else {
            Write-Host "P81 adapter IP is $P81_Address" -ForegroundColor Green
        }
        #Check current P81 routing
        $P81_Routes = Get-NetRoute -InterfaceIndex $P81_Interface.ifIndex | Where-Object {$_.DestinationPrefix -notmatch $P81_Address}
        #If it looks like the script has already been run, verify that the user wants to run it again.
        if ($P81_Routes.count -ne 3 -and !$list_only) {
            Add-Type -AssemblyName PresentationCore,PresentationFramework
            $ButtonType = [System.Windows.MessageBoxButton]::YesNo
            $MessageboxTitle = “Confirm P81 Route Renewal”
            $Messageboxbody = “It looks like you might have run this script already, would you like to run it again?”
            $MessageIcon = [System.Windows.MessageBoxImage]::Warning
            $answer = [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)
            if ($answer -eq "No") {
                Write-Host -ForegroundColor Red "Exiting Script"
                Break
            }
        }
        #Set the list of DNS names to route through P81
        if($import){
            if (Test-Path $path) {
                $target = Get-ChildItem -Path $path
            }else {
                Write-Host "$path is not a valid file path." -ForegroundColor Yellow
            }
            if ($target.Extension -match ".csv") {
                $import_csv_file = Import-Csv -Path $path
                $FQDNS = $import_csv_file | Select-Object -ExpandProperty FQDNS
            }elseif ($target.Extension -match ".txt") {
                $FQDNS = Get-Content -Path $path
            }
            #$FQDNS = Get-Content -Path $path
        }else{
            $FQDNS = @(
                "vcloud.thrivenextgen.com",
                "ks.thrivenetworks.com",
                "vsa02.thrivenetworks.com",
                "vsa03.thrivenextgen.com",
                "vsa04.thrivenetworks.com",
                "vsa05.thrivenextgen.com",
                "vsa06.thrivenextgen.com",
                "vsa07.thrivenextgen.com",
                "vsa08.thrivenextgen.com",
                "vsa09.thrivenextgen.com",
                "vsa10.thrivenextgen.com"
            )
        }
        # Resolve the FQDNs to IP addresses for later use
        $IPs = foreach($FQDN in $FQDNS){
            try {
                $IP = Resolve-DnsName $FQDN -Type A -QuickTimeout -DnsOnly -ErrorAction Stop | Where-Object {$null -ne $_.IP4Address} | Select-Object -ExpandProperty IP4Address
            }catch {
                Write-Host "Failed to resolve host $FQDN"
            }
            if ($IP.count -gt 1) {
                foreach ($oneIP in $IP) {
                    $FQDN_temp = @{
                        Name = $FQDN
                        IP = $oneIP+"/32"
                    }
                    $tempobj = New-Object -TypeName psobject -Property $FQDN_temp
                    $tempobj | Select-Object Name, IP        
                }
            }
            else {
                $FQDN_temp = @{
                    Name = $FQDN
                    IP = $IP+"/32"
                } 
                $tempobj = New-Object -TypeName psobject -Property $FQDN_temp
                $tempobj | Select-Object Name, IP       
            }
        }

        if ($list -or $list_only) {
            Write-Host "The following destinations will route through the P81 interface." -ForegroundColor Green
            $IPs | Select-Object @{Name='Web Address';Expression={$_.Name}}, @{Name='Resolved Address';Expression={$_.IP}} | Format-Table -AutoSize
            if ($list_only) {
                break
            }
        }
    }
    process{
        #Removing Current routes
        $P81_Routes | Remove-NetRoute -Confirm:$false -ErrorAction SilentlyContinue
        #check to make sure all routes were removed. 
        $P81_Remaining_Routes = Get-NetRoute -InterfaceIndex $P81_Interface.ifIndex | Where-Object {$_.DestinationPrefix -notmatch $P81_Address}
        if ($P81_Remaining_Routes.count -ne 0) {
            Write-Host "Could not remove all default routes from Interface. $($P81_Remaining_Routes.count) remaining. Exiting Script" -ForegroundColor Red
            break
        }
        #Add Routes for $FQDN's specified earlier.
        foreach($IP in $IPs){
            try {
                New-NetRoute -DestinationPrefix $IP.ip -InterfaceIndex $P81_Interface.ifIndex -RouteMetric 10 -ErrorAction stop | Out-Null
            }
            catch {                
                Write-Host -ForegroundColor Yellow "Could not add route for $($IP.Name) with IP Address of $($IP.IP)"
            } 
        }
        #Check the new routes
        $New_P81_Routes = Get-NetRoute -InterfaceIndex $P81_Interface.ifIndex | Where-Object {$_.DestinationPrefix -notmatch $P81_Address}
        
        $ref_objects = @{
            ReferenceObject = ($IPs.IP)
            DifferenceObject = ($New_P81_Routes.DestinationPrefix)
        }

        $compare = Compare-Object @ref_objects

        if($compare.count -ne 0){
            foreach ($item in $compare) {
                $error_item = $IPs | Where-Object {$_.IP -match $item.InputObject}
                Write-Host "Route for $($error_item.Name) with IP Address of $($error_item.IP) could not be added." -ForegroundColor Red
            }
        }else{
            Write-Host "All routes were successfully added." -ForegroundColor Green
        }
    }
    End{

    }
}
function Get-P81routes{
    Set-P81routes -list_only
}
Export-ModuleMember -Function Get-FSMORoles, Set-Immutid, Set-LTServerAdd, Get-InactiveUsers, Remove-MalFiles, Get-OnlineADComps, Add-DHCPv4Reservation, Get-LTServerAdd, Protect-Creds, Update-ICTools, Install-PSExec, Import-ICTHistory, Set-FixCellular, Get-ServiceAccounts, Find-Folders, Get-SubscriptionInfo, Set-P81routes, Get-P81routes
