Function Remove-EmotetLegacy{
<#
Synopsis
#>
    [cmdletbinding()]
        param(
            [string[]]$ComputerName,

            [string]$LogDir,

            [Bool]$Logonly
        )

            #$date = (get-date).AddDays(-45)
            #$servers = Get-ADComputer -Filter * -Properties lastlogondate | where lastlogondate -GE $date
            $exclude32 = Get-Content -Path $LogDir\exclude32.txt
            $exclude64 = Get-Content -Path $LogDir\exclude64.txt
            $excludewin = Get-Content -Path $LogDir\excludewin.txt
            foreach ($Computer in $ComputerName){
                    $serversn = $Computer.name
                    Start-Job {Start-Process $Logdir\psexec.exe -ArgumentList "\\$serversn -s winrm.cmd quickconfig -q" -NoNewWindow}
                    if (Test-Path -Path "\\$serversn\c$\windows\SysWOW64") {
                        $file = Get-ChildItem -Path "C:\windows\syswow64" *.exe | Where-Object {$_.creationtime -ge (get-date).AddDays(-1.5) -and $_.name -ne $_.originalname -and $_.name -notmatch $exclude64}
                            foreach ($bfile in $file){
                                if ([bool]$bfile){
                                    $filedeleted = $false
                                    if (!($LogOnly)){
                                        try {
                                            Stop-Process -Name $bfile.basename -Force -ErrorAction SilentlyContinue
                                        }
                                        catch{

                                        }
                                        #Start-Sleep -Seconds 3
                                        try {
                                            Remove-Item $bfile.fullname -ErrorAction SilentlyContinue
                                            $filedeleted = $true
                                        }
                                        catch{
                                            $filedeleted = $false
                                        }
                                    }
                                    if ($filedeleted){
                                        $delstatus = "Yes"
                                    }
                                    else {
                                        $delstatus = "No"
                                    }
                                    $tempobj = @{
                                        Name = $bfile.name
                                        Directory = $bfile.FullName
                                        CreationDate = $bfile.creationtime
                                        Deleted = $delstatus
                                        Type = "Dropper"
                                        ComputerName = $serversn
                                        TimeStamp = (Get-Date -Format "dd-MM-yyyy HH:mm:ss")
                                    }
                                    $FileObj = New-Object -TypeName psobject -Property $tempobj
                                    $deletedfiles += $FileObj
                                }else{
                                write-host "$Serversn 64 Bit Clean"
                                }
                        }
                    }
                    if (!(Test-Path -Path "\\$serversn\c$\SysWOW64")) {
                        $file = Get-ChildItem -Path "C:\windows\system32" *.exe | Where-Object {$_.creationtime -ge (get-date).AddDays(-1.5) -and $_.name -ne $_.originalname -and $_.name -notmatch $exclude32}
                            foreach ($bfile in $file){
                                if ([bool]$bfile){
                                    $filedeleted = $false
                                    if (!($LogOnly)){
                                        try {
                                            Stop-Process -Name $bfile.basename -Force -ErrorAction SilentlyContinue
                                        }
                                        catch{

                                        }
                                    }
                                        #Start-Sleep -Seconds 3
                                        try {
                                            Remove-Item $bfile.fullname -ErrorAction SilentlyContinue
                                            $filedeleted = $true
                                        }
                                        catch{
                                            $filedeleted = $false
                                        }
                                    if ($filedeleted){
                                        $delstatus = "Yes"
                                    }
                                    else {
                                        $delstatus = "No"
                                    }
                                    $tempobj = @{
                                        Name = $bfile.name
                                        Directory = $bfile.FullName
                                        CreationDate = $bfile.creationtime
                                        Deleted = $delstatus
                                        Type = "Dropper"
                                        ComputerName = $serversn
                                        TimeStamp = (Get-Date -Format "dd-MM-yyyy HH:mm:ss")
                                    }
                                    $FileObj = New-Object -TypeName psobject -Property $tempobj
                                    $deletedfiles += $FileObj
                                }else{
                                write-host "$Serversn 32 Bit Clean"
                                }
                        }
                    }
                    $file = get-childitem -Path "\\$serversn\c$\Windows" *.exe | Where-Object {$_.creationtime -ge (get-date).AddDays(-1.5) -and $_.Name -match "(?i)(\w{8}\.exe)"}
                            foreach ($bfile in $file){
                                if ([bool]$bfile){
                                    $filedeleted = $false
                                    if (!($LogOnly)){
                                        try {
                                            Stop-Process -Name $bfile.basename -Force -ErrorAction SilentlyContinue
                                        }
                                        catch{

                                        }
                                        #Start-Sleep -Seconds 3
                                        try {
                                            Remove-Item $bfile.fullname -ErrorAction SilentlyContinue
                                            $filedeleted = $true
                                        }
                                        catch{
                                            $filedeleted = $false
                                        }
                                    }
                                    if ($filedeleted){
                                        $delstatus = "Yes"
                                    }
                                    else {
                                        $delstatus = "No"
                                    }
                                    $tempobj = @{
                                        Name = $bfile.name
                                        Directory = $bfile.FullName
                                        CreationDate = $bfile.creationtime
                                        Deleted = $delstatus
                                        Type = "Emotet"
                                        ComputerName = $serversn
                                        TimeStamp = (Get-Date -Format "dd-MM-yyyy HH:mm:ss")
                                    }
                                    $FileObj = New-Object -TypeName psobject -Property $tempobj
                                    $deletedfiles += $FileObj
                                    #$deletedfiles += ($bfile | select name,directory,creationtime)
                                }else{
                                write-host "$Serversn Windows Directory does not have emotet files"
                                }
                            }
                    $timestamp = (Get-Date -Format “ddMMyyyy hh-mm-ss”)
                    $deletedfiles | Select-Object Name,Directory,CreationDate,Deleted,ComputerName,TimeStamp | Export-Csv -Path .\Deleted-Emotet-Legacy-Files-$timestamp.csv -NoTypeInformation
            }
}
