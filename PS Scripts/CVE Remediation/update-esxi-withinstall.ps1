

$mod = "VMware.PowerCLI"

if (!(Get-InstalledModule $mod)){
write-host -ForegroundColor Yellow "Module not installed, Installing..."
try{install-module -Name $mod -Force -Scope CurrentUser
}catch{
    Write-Error "Failed to installed module $mod.$_"
    Exit 1
}else{
    write-host -ForegroundColor Green "Module installed, importing"
}
 }

Import-Module $mod
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false

[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
$server = [Microsoft.VisualBasic.Interaction]::InputBox("Enter Server Requested", "Server", "")
$cred = (get-credential)

Connect-VIServer -Server $server -Credential $cred -Force


$esxiHosts = Get-VMHost

# Check ESXi version and update configurations if version is 7.x or 8.x
foreach ($esxi in $esxiHosts) {
    $esxiVersion = $esxi.Version
    $esxiAuth = Get-VMHostAuthentication -VMHost $esxi
    if ($esxiAuth.DomainMembershipStatus -ne "DomainMember"){
    
    if ($esxiVersion -ge "7") {
        Write-Host "Updating configuration for ESXi host: $($esxi.Name)"

        # Change Config.HostAgent.plugins.hostsvc.esxAdminsGroupAutoAdd to False
        
        $setting = "Config.HostAgent.plugins.hostsvc.esxAdminsGroupAutoAdd"
        $Value = $false

        get-advancedsetting -entity $esxi -Name $setting | set-advancedsetting -Value $Value -Confirm:$false
        
        $setting = $null
        $value = $null

        # Change Config.HostAgent.plugins.vimsvc.authValidateInterval to 90
        $setting = "Config.HostAgent.plugins.vimsvc.authValidateInterval"
        $Value = "90"
        
        get-advancedsetting -entity $esxi -Name $setting | set-advancedsetting -Value $Value -Confirm:$false
        $setting = $null
        $value = $null

        # Change Config.HostAgent.plugins.hostsvc.esxAdminsGroup to ""
        $setting = "Config.HostAgent.plugins.hostsvc.esxAdminsGroup"
        $Value = ""
        
        get-advancedsetting -entity $esxi -Name $setting | set-advancedsetting -Value $Value -Confirm:$false
        $setting = $null
        $value = $null
        
    } else {
        Write-Error "ESXi host $($esxi.Name) is not running VMware 7.x or 8.x. Version: $esxiVersion"
    }
}else{
    Write-Error "ESXi host $($esxi.Name) is AD joined."
}

}
