Function Update-ICTools {
    [cmdletbinding()]
    param(
        [switch]$NoRestart,
        [switch]$Beta,
        [switch]$NoManifest
      )


Begin{

if($Beta){
  #Beta Variables
    $url = "https://raw.githubusercontent.com/InCare-PST/ICTools/master/Modules/ICTools/ICTools-Gamma.psm1"
          }else{
  #Production Variables
    $url = "https://raw.githubusercontent.com/InCare-PST/ICTools/master/Modules/ICTools/ICTools.psm1"

          }

  #Constant Variables
    $ictpath = "$Home\Documents\WindowsPowerShell\Modules\ICTools"
    $file = "$ictpath\ICTools.psm1"
    $bakfile = "$ictpath\ICtools.bak"
    #$temp = "$ictpath\ICTools.temp.psm1"
    $webclient = New-Object System.Net.WebClient
    $psptest = Test-Path $Profile
    $psp = New-Item –Path $Profile –Type File –Force
}
Process{
#Make Directories

if(!(Test-Path -Path $ictpath)){New-Item -Path $ictpath -Type Directory -Force}
if(!$psptest){$psp}
#if(!(Test-Path -Path $archive)){New-Item -Path $archive}

if(Test-Path -Path $bakfile){Remove-Item -Path $bakfile -Force}
if(Test-Path -Path $file){Rename-Item -Path $file -NewName $bakfile -Force}

$webclient.downloadfile($url, $file)
}
End{
#Planned for Version number check to temp and only update if not latest version
write-host -ForegroundColor Green("`n`n InCare Tools has been Updated!")
start-sleep -seconds 2


if($NoRestart){
write-host -ForegroundColor Green("`n`nThe NoRestart switch is no longer needed")
#start-process PowerShell
#stop-process -Id $PID
}

if(!$NoRefresh){Reset-ICTools}

}

#End of Function
}

Function Reset-ICTools{
  Import-Module ICTools
  Remove-Module ICTools
  Import-Module ICTools -Verbose
}

Update-ICTools
