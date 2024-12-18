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
Get-OnlineADComps