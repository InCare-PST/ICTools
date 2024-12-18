<#
.SYNOPSIS 
Check if both DNS Filter and Umbrella are installed
.DESCRIPTION 
Removes Umbrella and Restarts DNS filter
.PARAMETER apply
Removes Umbrella and Restarts DNS filter
.PARAMETER export

.EXAMPLE
.EXAMPLE
#>
IF([BOOL](Get-Service -DisplayName "DNS Agent" -ErrorAction SilentlyContinue)){
    IF([BOOL](Get-Service -DisplayName "Umbrella*" -ErrorAction SilentlyContinue)){
        write-host -ForegroundColor Yellow "Umbrella installed: removing now"
        Get-Service -DisplayName "DNS Agent" | stop-service -Force -Verbose
        wmic product where 'name like "%%Umbrella%%"' call uninstall
        Get-Service -DisplayName "DNS Agent" | start-service -Verbose
    }else{write-host -ForegroundColor Green "Umbrella not installed"}    
}else{write-host -ForegroundColor Red "DNS Filter not installed"}

$dnsadd= (Get-DnsClientServerAddress | Select-Object -ExpandProperty ServerAddresses)

IF([bool]($dnsadd -like "127.0.0.2")){write-host -ForegroundColor Green "Umbrella has been removed and DNS filter is running normally"
}else{write-host -ForegroundColor Red "DNS Filter is not running normally"}
{write-host -ForegroundColor Red "Here is the current list of DNS Servers: $($dnsadd)"}