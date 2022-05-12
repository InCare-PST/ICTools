$psmurl = "https://raw.githubusercontent.com/InCare-PST/ICTools/master/Modules/ICTools/ICTools.psm1"
$psdurl = "https://raw.githubusercontent.com/InCare-PST/ICTools/master/Modules/ICTools/ICTools.psd1"
$wc = New-Object System.Net.WebClient
Get-FileHash -InputStream ($wc.openread($psmurl)) -Algorithm MD5
Get-FileHash -InputStream ($wc.openread($psdurl)) -Algorithm MD5

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
if(![bool]$installpath){
    $installpath = "$Home\Documents\WindowsPowerShell\Modules\"
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
        $psmurl = "https://raw.githubusercontent.com/InCare-PST/ICTools/master/Modules/ICTools/ICTools-Beta.psm1"
        $psdurl = "https://raw.githubusercontent.com/InCare-PST/ICTools/master/Modules/ICTools/ICTools-Beta.psd1"
            }else{
    #Production Variables
        $psmurl = "https://raw.githubusercontent.com/InCare-PST/ICTools/master/Modules/ICTools/ICTools.psm1"
        $psdurl = "https://raw.githubusercontent.com/InCare-PST/ICTools/master/Modules/ICTools/ICTools.psd1"
            }
    #Determine current ICTools path
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
    if(![bool]$installpath){
        $installpath = "$Home\Documents\WindowsPowerShell\Modules\"
        $installed = $false
    }
    #Get MD5 hash of online files
    $wc = New-Object System.Net.WebClient
    try {
        $psmhash = Get-FileHash -InputStream ($wc.openread($psmurl)) -Algorithm MD5 -ErrorAction Stop
    }
    catch {
        {Write-Host "Could not access file at $($psmurl)" -ForegroundColor Yellow}
    }
    try {
        $psdhash = Get-FileHash -InputStream ($wc.openread($psdurl)) -Algorithm MD5 -ErrorAction Stop
    }
    catch {
        {Write-Host "Could not access file at $($psdurl)" -ForegroundColor Yellow}
    }

    $ictpath = "$installpath\ICTools"
    $psmfile = "$ictpath\ICTools.psm1"
    $psdfile = "$ictpath\ICTools.psd1"
    $bakfile = "$ictpath\ICtools.bak"
    #$temp = "$ictpath\ICTools.temp.psm1"
    #$webclient = New-Object System.Net.WebClient
    $psptest = Test-Path $Profile
    $psp = New-Item -Path $Profile -Type File -Force

    #get the file hash for existing files
    $cpsmhash = Get-FileHash -Path $psmfile -Algorithm MD5
    $cpsdhash = Get-FileHash -Path $psdfile -Algorithm MD5
}
Process{
    #install module if not present
    if(!($installed)){
        New-Item -Path $ictpath -ItemType directory
        $wc.DownloadFile($psmurl,$psmfile)
        $wc.DownloadFile($psdurl,$psdfile)
    }
    else{
        #compare files and replace if necessary 
        if(!($psmhash.hash -eq $cpsmhash.hash)){
            remove-item $psmfile -Force
            $wc.DownloadFile($psmurl,$psmfile)
        }
        if(!($psdhash.hash -eq $cpsdhash.hash)){
            remove-item $psdfile -Force
            $wc.DownloadFile($psdurl,$psdfile)
        }
    }






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





try {
    $psmhash = Get-FileHash -InputStream ($wc.openread($psd2url)) -Algorithm MD5 -ErrorAction Stop
}
catch {
    {Write-Host $error.exemption}
    Exit
}