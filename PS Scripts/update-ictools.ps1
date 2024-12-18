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
            if($instance -eq 1){
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
        $installpath = $modulepaths[0]
        $installed = $false
    }else {
        $installed = $true
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
    #declare non-dynamic variables
    $ictpath = "$installpath\ICTools"
    $psmfile = "$ictpath\ICTools.psm1"
    $psdfile = "$ictpath\ICTools.psd1"
    #$psptest = Test-Path $Profile
    #$psp = New-Item -Path $Profile -Type File -Force

    #get the file hash for existing files
    if($installed){
        $cpsmhash = Get-FileHash -Path $psmfile -Algorithm MD5
    }
    $psdinstalled = $true
    if(test-path -Path $psdfile){
        $cpsdhash = Get-FileHash -Path $psdfile -Algorithm MD5
    }else{
        $psdinstalled = $false
    }
}
Process{
    #install module if not present
    if(!($installed)){
        New-Item -Path $ictpath -ItemType directory
        $wc.DownloadFile($psmurl,$psmfile)
        $wc.DownloadFile($psdurl,$psdfile)
    }else{
        $updated = $true
        #compare files and replace if necessary 
        if(!($psmhash.hash -eq $cpsmhash.hash)){
            remove-item $psmfile -Force
            $wc.DownloadFile($psmurl,$psmfile)
        }
        else{
            Write-Host "Module file is already up to date."
            $updated = $false
        }
        if($psdinstalled){
            if(!($psdhash.hash -eq $cpsdhash.hash)){
                remove-item $psdfile -Force
                $wc.DownloadFile($psdurl,$psdfile)
            }
        }else{
            $wc.DownloadFile($psdurl,$psdfile)
        }
    }
}
End{
    #reloading module either by restarting powershell or removing and importing the module
    if($updated){
        write-host "Reloading Powershell to access updated module" -ForegroundColor Green
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
    else{
        Write-Host "ICTools Module is already up to date." -ForegroundColor Green
    }
}
    #End of Function
}