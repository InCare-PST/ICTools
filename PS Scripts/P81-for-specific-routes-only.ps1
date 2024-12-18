#Allows addition of FQDN without updating script
param (
  [switch]$Add
)

#Requires -RunAsAdministrator

# List of FQDNs
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
$FQDNsPre = @("vcloud.thrivenextgen.com","cloud.thrivenextgen.com","ks.thrivenetworks.com","vsa02.thrivenetworks.com","vsa03.thrivenextgen.com","vsa04.thrivenetworks.com", "vsa05.thrivenextgen.com", "vsa06.thrivenextgen.com", "vsa07.thrivenextgen.com", "vsa08.thrivenextgen.com", "vsa09.thrivenextgen.com","vsa10.thrivenextgen.com","ukvsa01.thrivenextgen.co.uk")
if($Add){$FQDNsAdd = [Microsoft.VisualBasic.Interaction]::InputBox("Enter Additional FQDNs Requested", "FQDNs", "")}

$FQDNs = @()
$FQDNs += $FQDNsPre
if([BOOL]$FQDNsAdd){$FQDNs += $FQDNsAdd}

#[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
#[Microsoft.VisualBasic.Interaction]::Choose( "yes", "no")


#$FQDNs = @("vcloud.thrivenextgen.com", "vsa05.thrivenextgen.com", "vsa06.thrivenextgen.com", "vsa07.thrivenextgen.com", "vsa08.thrivenextgen.com", "vsa09.thrivenextgen.com","vsa10.thrivenextgen.com")

function Exit-WithDelay {
    $DelayInSeconds = 5

    for ($i = $DelayInSeconds; $i -gt 0; $i--) {
        Write-Host -NoNewline -ForegroundColor Yellow "`rExiting in $i seconds..."
        Start-Sleep -Seconds 1
    }

    Write-Host -ForegroundColor Yellow "`rExiting now.          "  # To clear the countdown message
    exit
}

function Resolve-FQDNToIP {
    param (
        [string]$FQDN
    )
    try {
        $IPs = [System.Net.Dns]::GetHostAddresses($FQDN)
        return $IPs
    } catch {
        Write-Host "Failed to resolve $FQDN"
        return @()
    }
}

$P81_Interface = Get-NetAdapter -Name "P81*"
if (@($P81_Interface).Count -eq 0) {
    Write-Host "No P81 adapter found."
    Exit-WithDelay
} else {
    Write-Host "P81 adapter found."
}

$P81_Address = $P81_Interface | Get-NetIPAddress | Select-Object -ExpandProperty IPAddress
if (@($P81_Address).Count -eq 0) {
    Write-Host "Could not get local IP of P81 adapter."
    Exit-WithDelay
} else {
    Write-Host "P81 adapter IP found as $P81_Address"
}

$P81_CatchAllRoutes = Get-NetRoute -InterfaceIndex $P81_Interface.ifIndex | Where-Object { $_.DestinationPrefix -notlike "$($P81_Address)*" }
if (@($P81_CatchAllRoutes).Count -ne 3) {
    Write-Host "Found $(if ($P81_CatchAllRoutes.Count -gt 3) { 'more' } else { 'less' }) routes than the expected 3 for P81 adapter. Did you run this already?"
    Exit-WithDelay
} else {
    Write-Host "P81 adapter catch-all routes found to be the expected number of 3 (aside from self)"
}

$P81_CatchAllRoutes | Remove-NetRoute -Confirm:$false -ErrorAction SilentlyContinue

$P81_RemainingCatchAllRoutes = Get-NetRoute -InterfaceIndex $P81_Interface.ifIndex | Where-Object { $_.DestinationPrefix -notlike "$($P81_Address)*" }
$P81_RemainingRoutes         = Get-NetRoute -InterfaceIndex $P81_Interface.ifIndex | Where-Object { $_.DestinationPrefix    -like "$($P81_Address)*" }
if (@($P81_RemainingCatchAllRoutes).Count -ne 0) {
    Write-Host "After removal of catch-all routes found more than zero non-self routes for P81 adapter."
    @($P81_RemainingCatchAllRoutes).Count
    Exit-WithDelay
} else {
    if (@($P81_RemainingRoutes).Count -ne 1) {
        Write-Host "Removal of catch-all routes seems OK but found more self routes then expected for P81 adapter."
        Exit-WithDelay
    } else {
        Write-Host "P81 adapter routes remaining after cleanup look OK (just self)"
    }
}

foreach ($FQDN in $FQDNs) {
    $IPs = Resolve-FQDNToIP -FQDN $FQDN
    foreach ($IP in $IPs) {
        $IPAddress = "$($IP.IPAddressToString)/32"
        $null = New-NetRoute -DestinationPrefix $IPAddress -InterfaceIndex $P81_Interface.ifIndex -RouteMetric 10

        $P81_NewRoute = Get-NetRoute | Where-Object {$_.DestinationPrefix -eq $IPAddress -and $_.InterfaceIndex -eq $P81_Interface.ifIndex}
        if (@($P81_NewRoute).Count -ne 1) {
            Write-Host "Adding new route to $FQDN ($IPAddress) through P81 seems to not have worked."
        } else {
            Write-Host "P81 adapter route to $FQDN at $IPAddress added. Should be good to go!"
        }
    }
}
Exit-WithDelay