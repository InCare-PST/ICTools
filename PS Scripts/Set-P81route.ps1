functiion Set-P81routes{
    [CmdletBinding(SupportsShouldProcess = $True)]
    param (

        [string]$FQDNS,

        [switch]$import = $false,

        [string]$path

    )
    
    begin{
        $P81_Interface = Get-NetAdapter -Name "P81*"

        if ($P81_Interface.Count -eq 0) {
            Write-Host "No P81 adapter found."
            Return
        } elseif ($P81_Interface.count -gt 1) {
            Write-Host "Too many P81 Adapters found. $($P81_Interface.count) found."
            Return
        }

        $P81_Address = $P81_Interface | Get-NetIPAddress | Select-Object -ExpandProperty IPAddress
        if ($P81_Address.Count -eq 0) {
            Write-Host "Could not get local IP of P81 adapter."
            Exit-WithDelay
        } else {
            Write-Host "P81 adapter IP found as $P81_Address"
        }




#Set the list of DNS names to route through P81
        if($import){
            $FQDNS = Get-Content -Path $path
        }
        else {
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
        
        $IPs = foreach($FQDN in $FQDNS){
            try {
                Resolve-DnsName $FQDN -Type A -QuickTimeout -DnsOnly -ErrorAction Stop | Where-Object {$_.IP4Address -ne $null} | Select-Object IP4Address
            }
            catch {
                Write-Host "Failed to resolve host $FQDN"
            }
        }

        $DestIPs = foreach($IP in $IPs){
            $IP.IP4Address+"/32"
        }

    }
    process{

    }
    End{

    }
}