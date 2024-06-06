#Just a bunch of repair commands
[cmdletbinding()]
param(
[switch]$dism,
[switch]$sfc,
[switch]$checklog,
[switch]$store
)

if($dism){
    Repair-WindowsImage -CheckHealth
    Repair-WindowsImage -ScanHealth
    Repair-WindowsImage -RestoreHealth
}

if($sfc){
    invoke-command -ScriptBlock { sfc /scannow }
}

if($checklog){
    #invoke-cmd -ArgumentList findstr /c:"[SR]" "%windir%\Logs\CBS\CBS.log"
    get-content $env:windir\logs\cbs\cbs.log | select-string -SimpleMatch "[SR]" | Out-GridView
}

if($store){
    Get-AppXPackage *WindowsStore* -AllUsers | ForEach-Object {Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml"}
}

#Get-AppXPackage | Foreach {Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml"}
