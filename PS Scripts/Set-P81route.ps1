functiion Set-P81routes{
    [CmdletBinding(SupportsShouldProcess = $True)]
    param (

        [string]$FQDNS,

        [switch]$import = $false,

        [string]$path,

        [string]$add,

        [string]$append

    )
    
    begin{
        $P81_Interface = Get-NetAdapter -Name "P81*"
        #Check that only 1 interface was found
        if ($P81_Interface.Count -eq 0) {
            Write-Host "No P81 adapter found."
            Return
        } elseif ($P81_Interface.count -gt 1) {
            Write-Host "Too many P81 Adapters found. $($P81_Interface.count) found."
            Return
        }
        #Find the P81 Interface Address
        $P81_Address = $P81_Interface | Get-NetIPAddress | Select-Object -ExpandProperty IPAddress
        if ($P81_Address.Count -eq 0) {
            Write-Host "Could not get local IP of P81 adapter."
            Return
        } else {
            Write-Host "P81 adapter IP found as $P81_Address"
        }
        #Check current P81 routing
        $P81_Routes = Get-NetRoute -InterfaceIndex $P81_Interface.ifIndex | Where-Object {$_.DestinationPrefix -notmatch $P81_Address}
        #If it looks like the script has already been run, verify that the user wants to run it again.
        if ($P81_Routes.count -ne 3) {
            Add-Type -AssemblyName PresentationCore,PresentationFramework
            $ButtonType = [System.Windows.MessageBoxButton]::YesNo
            $MessageboxTitle = “Confirm P81 Route Renewal”
            $Messageboxbody = “It looks like you might have run this script already, would you like to run it again?”
            $MessageIcon = [System.Windows.MessageBoxImage]::Warning
            $answer = [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)
            if ($answer -eq "No") {
                Write-Host -ForegroundColor Red "Exiting Script"
                Return
            }
        }
        #Set the list of DNS names to route through P81
        if($import){
            $FQDNS = Get-Content -Path $path
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
                $IP = Resolve-DnsName $FQDN -Type A -QuickTimeout -DnsOnly -ErrorAction Stop | Where-Object {$_.IP4Address -ne $null} | Select-Object -ExpandProperty IP4Address
            }
            catch {
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
    }
    process{
        #Removing Current routes
        try {
            $P81_Routes | Remove-NetRoute -Confirm:$false -ErrorAction Stop
        }catch{
            Write-Host -ForegroundColor Red "Could not remove P81 global routes. Exiting script."
            Return
        }
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

        $compare = Compare-Object $ref_objects

        if($compare.count -ne 0){
            foreach ($item in $compare) {
                $error_item = $IPs | Where-Object {$_.IP -match $item.InputObject}
                Write-Host "Route for $($error_item.Name) with IP Address of $($error_item.IP) could not be added." -ForegroundColor Red
            }else {
                Write-Host "All routes were successfully added." -ForegroundColor Green
            }
        }
    }
    End{

    }
}