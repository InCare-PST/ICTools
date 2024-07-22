functiion Set-P81routes{
    [CmdletBinding(SupportsShouldProcess = $True)]
    param (

        [string]$FQDNS,

        [switch]$import = $false,

        [string]$path

    )
    
    begin{

        if($import){
            $FQDNS = Get-Content -Path $path
        }
        
        $IPs = foreach($FQDN in $FQDNS){
            Resolve-DnsName $FQDN -Type A | Select-Object IPAddress
        }

        $DestIPs = foreach($IP in $IPs){
            $IP.IPAddress+"/32"
        }

    }
    process{

    }
    End{

    }
}