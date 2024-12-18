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
Specifies if certain computers should be excluded from the scan. The options are Servers, Workstations, or a list in a csv file. The file should
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
    [cmdletbinding(DefaultParameterSetName="Default")]
        param(
            [Parameter(ParameterSetName="Default")]
            [Parameter(ParameterSetName="Reporting",Mandatory=$false)]
            [string]$LogDir = "c:\temp",

            [Parameter(ParameterSetName="Default")]
            [Parameter(ParameterSetName="Reporting",Mandatory=$false)]
            [string]$ServerAddr = "https://cwa.incare360.com",

            [Parameter(ParameterSetName="Default")]
            [Parameter(ParameterSetName="Reporting",Mandatory=$false)]
            [ValidateSet("Servers", "Workstations", "List")]
            [string]$Exclude,

            [Parameter(ParameterSetName="Reporting",Mandatory=$false)]
            [switch]$report,

            [Parameter(ParameterSetName="Reporting",Mandatory=$true)]
            [string]$email,

            [Parameter(ParameterSetName="Reporting",Mandatory=$true)]
            [string]$ClientName

        )
    Begin{
        $CurrentFullLTVersion = (Get-ItemProperty -Path HKLM:\software\LabTech\Service\).'Version'
        $CurrentLTVersion = ([regex]::Match($CurrentFullLTVersion, '.*(?=\.)')).value
        if($report){
            $credentials = Import-Clixml -path "$logdir\incare.xml"
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
                #$ComputerName = $WRMComp.name
                Receive-Job -Name Verify
                $waiting = $false
            }
        }
        switch ($Exclude){
            "Servers" {$ComputerName = ($WRMComp | Where-Object {$_.operatingsystem -notmatch "server"}).name}
            "Workstations" {$ComputerName = ($WRMComp | Where-Object {$_.operatingsystem -match "server"}).name}
            "List" {$ComputerName = $WRMComp.name;$Excludes = Import-Csv $LogDir\exclude.csv;foreach ($ex in $Excludes.name){$ComputerName = $ComputerName | Where-Object {$_ -notmatch $ex}} }
            default {$ComputerName = $WRMComp.name}
        }
    }
    Process{
        $agentlist = Invoke-Command -ComputerName $ComputerName{
            $serveraddress = (Get-ItemProperty -Path HKLM:\software\LabTech\Service\).'server address'
            $ltversion = (Get-ItemProperty -Path HKLM:\software\LabTech\Service\).'Version'
            If ([bool]$serveraddress) {
                $tempobj = @{
                    Computername = $env:COMPUTERNAME
                    ServerAddress = $serveraddress
                    LTVersion = $ltversion
                }
            }
            else{
                $installcheck = Get-WmiObject -Class Win32_Product | Where-Object {$_.name -match "labtech"}
                if ([bool]$installcheck){
                    $installstate = "Server Address not found"
                }
                else{
                    $installstate = "Labtech Agent not installed"
                }
                $tempobj = @{
                    Computername = $env:COMPUTERNAME
                    ServerAddress = $installstate
                    LTVersion = "NA"
                }
            }
            $ExportObj = New-Object -TypeName psobject -Property $tempobj
            $ExportObj

        } | Select-Object Computername,ServerAddress,LTVersion #|Export-Csv -Path $LogDir\Get_LTAddr_Log.csv -Append -Force -NoTypeInformation
        if ($report){
            $agentissues = $agentlist | Where-Object {$_.serveraddress -ne $ServerAddr -or ([regex]::Match($_.LTVersion,'.*(?=\.)')).value -ne $CurrentLTVersion}
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
            Get-ChildItem $logdir\nopsremoting* | Where-Object {$_.creationtime -le ((get-date).AddDays(-7))} | remove-item
        }
        else{
            $FTimeStamp = (Get-Date -Format "dd-MM-yyyy HH-mm-ss")
            Rename-Item -Path $LogDir\Get_LTAddr_Log.csv -NewName Get_LTAddr_Log_$FTimeStamp.csv
        }

    }
}
Get-LTServerAdd -LogDir "c:\temp\Version\" -report -email bbristow@incare360.com -ClientName "City of Leeds"
