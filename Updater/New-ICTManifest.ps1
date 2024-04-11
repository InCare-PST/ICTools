Function Update-ICTools {
    [cmdletbinding()]
    param(
        [switch]$NoRestart,
        [switch]$Beta
      )


Begin{

if($Beta){
  #Beta Variables
    $url = "https://raw.githubusercontent.com/InCare-PST/ICTools/master/Modules/ICTools/ICTools-Beta.psm1"
          }else{
  #Production Variables
    $url = "https://raw.githubusercontent.com/InCare-PST/ICTools/master/Modules/ICTools/ICTools.psm1"

          }

  #Constant Variables
    $ictpath = "$Home\Documents\WindowsPowerShell\Modules\ICTools"
    $file = "$ictpath\ICTools.psm1"
    $bakfile = "$ictpath\ICtools.bak"
    $temp = "$ictpath\ICTools.temp.psm1"
    $webclient = New-Object System.Net.WebClient
    $psptest = Test-Path $Profile
    $psp = New-Item –Path $Profile –Type File –Force
}
Process{
#Make Directories

if(!(Test-Path -Path $ictpath)){New-Item -Path $ictpath -Type Directory -Force | out-null }
if(!$psptest){$psp | out-null }
#if(!(Test-Path -Path $archive)){New-Item -Path $archive}

if(Test-Path -Path $bakfile){Remove-Item -Path $bakfile -Force | out-null }
if(Test-Path -Path $file){Rename-Item -Path $file -NewName $bakfile -Force | out-null }

$webclient.downloadfile($url, $file)
}
End{
#Planned for Version number check to temp and only update if not latest version
write-host -ForegroundColor Green("`n`nICTools has been installed!")
start-sleep -seconds 2

Import-Module ICTools
Remove-Module ICTools
Import-Module ICTools
}

#End of Function
}
Function New-ICToolsManifest {

BEGIN{
    #[Net.ServicePointManager]::SecurityProtocol = "Tls12, Tls11, Tls, Ssl3"
    $url = "https://raw.githubusercontent.com/InCare-PST/ICTools/master/Modules/ICTools/ICTools.psm1"
    $releaseurl = "https://github.com/InCare-PST/ICTools/releases/latest"
    $ProjectUri = "https://github.com/InCare-PST/ICTools"
    $ictpath = "$Home\Documents\WindowsPowerShell\Modules\ICTools"
    $psptest = Test-Path $Profile
    $psp = New-Item –Path $Profile –Type File –Force
    $file = "$ictpath\ICTools.psm1"
    $bakfile = "$ictpath\ICtools.bak"
    $temp = "$ictpath\ICTools.temp.psm1"
    $manifest = "$ictpath\ICTools.psd1"
    #$webclient = New-Object System.Net.WebClient
    #$Version = (Invoke-WebRequest $releaseurl -UseBasicParsing).links | Where {$_.Title -NotMatch "GitHub"} #-and $_.Title -GT "0"} | Select -Unique Title
    $company = "Incare Technologies"
    $Author = "InCare PST"
    #$version = (Get-Content $file -Head 1).trim('#VERSION=')
    $version = "0.0.1"

}
PROCESS{
  if(Test-Path -Path $file){new-modulemanifest -Path $manifest -RootModule $file -CompanyName $company -Author $Author -ModuleVersion $version -ProjectUri $ProjectUri
        }
  else{
      update-ictools -NoRestart
      new-modulemanifest -Path $manifest -RootModule $file -CompanyName $company -Author $Author -ModuleVersion $version -ProjectUri $ProjectUri
      }

       }



END{
remove-module ICTools
import-module ICTools
write-host -ForegroundColor Green "`n`nICTools Manifest has been created!"
}

}
New-ICToolsManifest
