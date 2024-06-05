<#This script sets all local Network Profile Types to Private

Ideas for furture use:
1) Delete all profiles and recreate the one that is currently being used, then set it to private.

#>
function Set-FirewallPrivate{

  [cmdletbinding()]
  param(
      [switch]$UmbrellaOnly
    )

$alpha = @()
$bravo = @()

if($UmbrellaOnly){
  $alpha =  (Get-childitem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles" | Get-ItemProperty -Name ProfileName | Where-Object ProfileName -match "Umbrella").pspath
}else{
  $alpha = (Get-childitem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles" | Get-ItemProperty -Name Category | Where-Object Category -eq 0).pspath
}
if([bool]$alpha){$bravo += $alpha.trim("Microsoft.PowerShell.Core\")
}else{
  write-host -Foregroundcolor Red "ERROR: There are no profiles selected"
  start-sleep 2
  Exit
}

foreach($b in $bravo){
set-itemproperty -path $b -Name Category -Value 1 -ErrorAction SilentlyContinue
set-itemproperty -path $b -Name CategoryType -Value 0 -ErrorAction SilentlyContinue
write-host -Foregroundcolor Green (($(get-itemproperty -path $b -Name ProfileName).profilename) + ": has been updated")
}
#Restarting Location Awareness
Restart-Service NlaSvc -Force
}
Set-FirewallPrivate
