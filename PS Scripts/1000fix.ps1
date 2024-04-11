#Let's work around the 1001 authentication issue
#Justin Gallups
param(
[switch]$work,$personal,$cleanup
)

#Microsoft Fix
if([bool]$work){
if (-not (Get-AppxPackage Microsoft.AAD.BrokerPlugin)){ Add-AppxPackage -Register "$env:windir\SystemApps\Microsoft.AAD.BrokerPlugin_cw5n1h2txyewy\Appxmanifest.xml" -DisableDevelopmentMode -ForceApplicationShutdown }
}

if([bool]$personal){
if (-not (Get-AppxPackage Microsoft.Windows.CloudExperienceHost)) { Add-AppxPackage -Register "$env:windir\SystemApps\Microsoft.Windows.CloudExperienceHost_cw5n1h2txyewy\Appxmanifest.xml" -DisableDevelopmentMode -ForceApplicationShutdown } 
}

if([bool]$cleanup){
    stop-process -Force "Microsoft.AAD.BrokerPlugin.exe" -ErrorAction SilentlyContinue
    Remove-Item -Path "$($env:localappdata)\Packages\Microsoft.AAD.BrokerPlugin_cw5n1h2txyewy" -Recurse -Force -Confirm
    
}