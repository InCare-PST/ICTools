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
        if ($P81_Routes.count -gt 3 -and !$list_only -and ![bool]$append) {
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
        }elseif ([bool]$append) {
            $FQDNS = $append
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
                "vsa10.thrivenextgen.com",
                "fm01.thrivenetworks.com",
                "fm01.thrivenextgen.com"
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
        #Removing Current routes unless $append is chosen
        if (![bool]$append) {
                $P81_Routes | Remove-NetRoute -Confirm:$false -ErrorAction SilentlyContinue
                #check to make sure all routes were removed. 
                $P81_Remaining_Routes = Get-NetRoute -InterfaceIndex $P81_Interface.ifIndex | Where-Object {$_.DestinationPrefix -notmatch $P81_Address}
                if ($P81_Remaining_Routes.count -ne 0) {
                    Write-Host "Could not remove all default routes from Interface. $($P81_Remaining_Routes.count) remaining. Exiting Script" -ForegroundColor Red
                    break
                }
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
        if ([bool]$append) {
                foreach ($IP in $IPs) {
                    $New_appended_route = Get-NetRoute -InterfaceIndex $P81_Interface.ifIndex | Where-Object {$_.DestinationPrefix -match $IP.IP}
                    if ([bool]$New_appended_route) {
                        Write-Host "Route to $($IP.Name) at $($IP.IP) added to P81" -ForegroundColor Green
                    }
                }
        }else {
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

    }
    End{

    }
}
Set-P81routes