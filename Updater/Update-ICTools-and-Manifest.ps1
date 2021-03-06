<#
DO NOT USE; THIS IS NOT READY AND WILL BREAK EVERYTHING!!!!

#>
Function Update-ICTools {

BEGIN{
    #[Net.ServicePointManager]::SecurityProtocol = "Tls12, Tls11, Tls, Ssl3"
    $url = "https://raw.githubusercontent.com/InCare-PST/ICTools/master/Modules/ICTools/ICTools-Beta.psm1"
    $releaseurl = "https://github.com/InCare-PST/ICTools/releases/latest"
    $ProjectUri = "https://github.com/InCare-PST/ICTools-Beta"
    $ictpath = "$Home\Documents\WindowsPowerShell\Modules\ICTools-Beta"
    $psptest = Test-Path $Profile
    $psp = New-Item –Path $Profile –Type File –Force
    $file = "$ictpath\ICTools-Beta.psm1"
    $bakfile = "$ictpath\ICtools-Beta.bak"
    $temp = "$ictpath\ICTools-Beta.temp.psm1"
    $manifest = "$ictpath\ICTools-Beta.psd1"
    #$webclient = New-Object System.Net.WebClient
    #$Version = (Invoke-WebRequest $releaseurl -UseBasicParsing).links | Where {$_.Title -NotMatch "GitHub"} #-and $_.Title -GT "0"} | Select -Unique Title
    $company = "Incare Technologies"
    $Author = "InCare PST"
    $version = (Get-Content $file -Head 1).trim('#VERSION=') 




}
Process{
#Make Directories

if(!(Test-Path -Path $ictpath)){New-Item -Path $ictpath -Type Directory -Force}
if(!$psptest){$psp}
#if(!(Test-Path -Path $archive)){New-Item -Path $archive}

if(Test-Path -Path $bakfile){Remove-Item -Path $bakfile -Force}
if(Test-Path -Path $manifest){Remove-Item -Path $manifest -Force}
if(Test-Path -Path $file){Rename-Item -Path $file -NewName $bakfile -Force}

$webclient.downloadfile($url, $file)
}
End{
$version = $file 
#Planned for Version number check to temp and only update if not latest version
write-host -ForegroundColor Green("Creating Powershell Module Manifest")
start-sleep -seconds 1
#start-process PowerShell
#stop-process -Id $PID

#Create and Update ModuleManifest


new-modulemanifest -Path $manifest -CompanyName $company -Author $Author -ModuleVersion $version -ProjectUri $ProjectUri
remove-module ICTools
import-module ICTools
}
#End of Function
}
Update-ICTools
