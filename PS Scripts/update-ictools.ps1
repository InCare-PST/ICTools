$url = "https://raw.githubusercontent.com/InCare-PST/ICTools/master/Modules/ICTools/ICTools.psm1"
$wc = New-Object System.Net.WebClient
Get-FileHash -InputStream ($wc.openread($url)) -Algorithm MD5

$modulepaths = $env:PSModulePath.Split(";")
$instance = 0
foreach($mpath in $modulepaths){
    if(test-path $mpath\ICTools\ictools.psm1){
        $instance = $instance + 1
        if($instance -le 1){
            $installpath = $mpath
        }
        elseif ($instance -gt 1) {
            write-host "ICTools Module found in multiple locations" -ForegroundColor Red
            Write-Host "$installpath and in $mpath" -ForegroundColor Yellow
            Exit
        }
    }
}



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
        if (Test-Path $Home\Documents\WindowsPowerShell\Modules\ICtools) {
            <# Action to perform if the condition is true #>
        }

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

if(!(Test-Path -Path $ictpath)){New-Item -Path $ictpath -Type Directory -Force}
if(!$psptest){$psp}
#if(!(Test-Path -Path $archive)){New-Item -Path $archive}

if(Test-Path -Path $bakfile){Remove-Item -Path $bakfile -Force}
if(Test-Path -Path $file){Rename-Item -Path $file -NewName $bakfile -Force}

$webclient.downloadfile($url, $file)
}
End{
#Planned for Version number check to temp and only update if not latest version
write-host -ForegroundColor Green("Reloading Powershell to access updated module")
start-sleep -seconds 2


if($NoRestart){
Import-Module ICTools
Remove-Module ICTools
Import-Module ICTools
}
else{
start-process PowerShell
stop-process -Id $PID
}

}

#End of Function
}