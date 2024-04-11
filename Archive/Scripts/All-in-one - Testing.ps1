$RunTime = (Get-Date).AddHours(24)
While((Get-date) -le $RunTime){
    $verified = @()
    $WRMComp = @()
    $NWRM = @()
    $date = (get-date).AddDays(-25)
    $computers = Get-ADComputer -Filter * -Properties LastLogonDate | where lastlogondate -GE $date
    ForEach ($comp in $computers) {
        try (Test-Connection -ComputerName $comp.name -Count 1 -Quiet) {
            Write-Host $comp.name "is Alive"
            if ([bool](Test-WSMan -ComputerName $comp.Name -ErrorAction SilentlyContinue)){
                $WRMComp += $comp
            }
        }
        catch {
                $NWRM += $comp
                #Insert PSEXEC script to attempt to enable PSRemoting
            }
            #$verified += ($comp | select -ExpandProperty name)
        Finally{
        $nwrm | Export-Clixml .\nowrm.xml
    }
    $looptime = (Get-Date).AddMinutes(30)
    while ((Get-Date) -le $looptime){
        #$exclude = get-content ".\goodexe2.txt"
        $ScanTime = (Get-Date).ToString('yyyy-MM-dd')
        $pathname = "C:\temp\$ScanTime-InDelete-Loader.txt"
        Invoke-Command -ComputerName $WRMComp.name {
            $deletedfiles = @()
            $exclude32 = get-content "\\192.168.2.160\Toolbox\goodexe.txt"
            $exclude64 = Get-Content "\\192.168.2.160\Toolbox\goodexe64.txt"        #Checking the syswow64 directory for the emotet loader and deleting it
            if (Test-Path -Path "C:\windows\SysWOW64") {
                $file = Get-ChildItem -Path "C:\windows\syswow64" -Exclude $exclude64 | where {$_.creationtime -ge (get-date).AddDays(-1.5) -and $_.name -ne $_.originalname -and $_.name -match "\.exe"} 
                    foreach ($bfile in $file){
                        if ([bool]$bfile){
                            $filedeleted = $true
                            $ComputerName = $env:COMPUTERNAME
                           <# try {
                                Stop-Process -Name $bfile.basename -Force -ErrorAction SilentlyContinue
                            }
                            catch{
                            
                            }
                            #Start-Sleep -Seconds 3
                            try {
                                Remove-Item $bfile.fullname -ErrorAction SilentlyContinue
                            }
                            catch{
                                $filedeleted = $false
                            }#>
                            if ($filedeleted){$delstatus = "Yes"}enter
                            else {$delstatus = "No"}
                            $tempobj = @{
                                Name = $bfile.name
                                Directory = $bfile.directory
                                CreationDate = $bfile.creationtime
                                Deleted = $delstatus
                                ComputerName = $ComputerName
                                TimeStamp = (Get-Date -Format "dd-MM-yyyy HH:mm:ss")
                            }
                            $FileObj = New-Object -TypeName psobject -Property $tempobj
                            $deletedfiles += $FileObj
                            #$deletedfiles += ($bfile | select name,directory,creationtime)
                        }else{
                        write-host "$ComputerName 64 Bit Clean"
                        }
                }
            }
            #Checking 32 Bit machines for the Emotet Loader and deleting the files
            if (!(Test-Path -Path "C:\windows\SysWOW64")) {
                $file = Get-ChildItem -Path "C:\windows\system32" -Exclude $exclude32 | where {$_.creationtime -ge (get-date).AddDays(-1.5) -and $_.name -ne $_.originalname -and $_.name -match "\.exe"}
                    foreach ($bfile in $file){
                        if ([bool]$bfile){
                        $filedeleted = $true
                           <# try {
                                Stop-Process -Name $bfile.basename -Force -ErrorAction SilentlyContinue
                            }
                            catch{
                            
                            }
                            #Start-Sleep -Seconds 3
                            try {
                                Remove-Item $bfile.fullname -ErrorAction SilentlyContinue
                            }
                            catch{
                                $filedeleted = $false
                            }#>
                            if ($filedeleted){$delstatus = "Yes"}
                            else {$delstatus = "No"}
                            $tempobj = @{
                                Name = $bfile.name
                                Directory = $bfile.directory
                                CreationDate = $bfile.creationtime
                                Deleted = $delstatus
                                ComputerName = $ComputerName
                                TimeStamp = (Get-Date -Format "dd-MM-yyyy HH:mm:ss")
                            }
                            $FileObj = New-Object -TypeName psobject -Property $tempobj
                            $deletedfiles += $FileObj
                            #$deletedfiles += ($bfile | select name,directory,creationtime)
                        }else{
                        write-host "$ComputerName 32 Bit Clean"
                        }
                    }
            }
            #Deleting the emotet files from the Windows directory
            $file = get-childitem -Path $path * -Exclude $exclude | where {$_.creationtime -ge (get-date).AddDays(-1.5) -and $_.Name -match "(?i)(\w{8}\.exe)" -and $_.Name -notmatch "PSEXESVC\.exe"}
                    foreach ($bfile in $file){
                        if ([bool]$bfile){
                            $filedeleted = $true
                            $ComputerName = $env:COMPUTERNAME
                            <#try {
                                Stop-Process -Name $bfile.basename -Force -ErrorAction SilentlyContinue
                            }
                            catch{
                            
                            }
                            #Start-Sleep -Seconds 3
                            try {
                                Remove-Item $bfile.fullname -ErrorAction SilentlyContinue
                            }
                            catch{
                                $filedeleted = $false
                            }#>
                            if ($filedeleted){$delstatus = "Yes"}enter
                            else {$delstatus = "No"}
                            $tempobj = @{
                                Name = $bfile.name
                                Directory = $bfile.directory
                                CreationDate = $bfile.creationtime
                                Deleted = $delstatus
                                ComputerName = $ComputerName
                                TimeStamp = (Get-Date -Format "dd-MM-yyyy HH:mm:ss")
                            }
                            $FileObj = New-Object -TypeName psobject -Property $tempobj
                            $deletedfiles += $FileObj
                            #$deletedfiles += ($bfile | select name,directory,creationtime)
                        }else{
                        write-host "$ComputerName Windows Directory does not have emotet files"}
                    }
 
 
 
 
        $deletedfiles
        } | Select-Object Name,Directory,CreationDate,Deleted,ComputerName,TimeStamp | Export-Csv -Path .\Deleted-Emotet-Files.csv -Append -Force -NoTypeInformation
    }
}


-and ($_.length -eq 135168 -or $_.length -eq 243592)