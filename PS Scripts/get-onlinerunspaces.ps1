$LogDir = "C:\Temp"
$LastLogon = 60
$date = (get-date).AddDays(-$LastLogon)
$computers = Get-ADComputer -Filter * -Properties LastLogonDate | where lastlogondate -GE $date
$pool = [RunspaceFactory]::CreateRunspacePool(1, [int]$env:NUMBER_OF_PROCESSORS + 100)
$pool.ApartmentState = "MTA"
$pool.Open()
$runspaces = @()
$scriptblock = {
    Param(
        $Comp,
        $DistinguishedName,
        $LastLogonDate
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
        }
        $obj = New-Object -TypeName psobject -Property $tempobj
        $obj | select Name,DistinguishedName,LastLogonDate,PsRemoting                    
    }
}

foreach($comp in $computers) {
    $paramlist = @{
        Comp = $comp.name
        DistinguishedName = $comp.DistinguishedName
        LastLogonDate = $comp.LastLogonDate
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
$PsRemotingDisabled | Select-Object Name,DistinguishedName,LastLogonDate | Export-Csv $LogDir\NoPSRemoting_$FTimeStamp.csv -Append -NoTypeInformation


$pool.Close()
$pool.Dispose()