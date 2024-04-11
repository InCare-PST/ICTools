$loop = 6

function Time-Stamp {(Get-Date).ToString('yyyy-MM-dd-hh-mm')}
Write-Host "Beginning Malware Removal Script" -ForegroundColor DarkBlue -BackgroundColor White
#Start-Sleep -Seconds 5

$verified = "EX10-CAS-01"

while ($loop -gt 0){
#Global Variables
$ScanTime = Time-Stamp
$pathname = "C:\temp\$ScanTime-InDelete-Loader.txt"
$errorpath = "C:\temp\$scanTime-InDelete-Loader-Error.txt"
# Remote Commands
try{   
Invoke-Command -ComputerName $verified -ErrorVariable errortxt <#2>$null#> {
    $exclude = get-content "\\192.168.2.160\Toolbox\goodexeall.txt"
    $path1 = "C:\"
    $path2 = "C:\windows\system32\*"
    $path3 = "C:\windows\syswow64\*"
    $path4 = "C:\windows\*"
    $path5 = "C:\documents and settings\*\AppData\*"
    $path6 = "C:\Users\*\AppData\*"
    $filename1 = "4478????????????????????????????????????????????????????????????.exe"
    $filename2 = "m??vca.exe"

    ForEach ($path in @($path1,$path2,$path3)) {
        $file = Get-ChildItem -Path $path -Exclude $exclude -Include $filename1,$filename2
        $file
    }

    <#

    if (Test-Path -Path "C:\windows\SysWOW64") {
        $file = Get-ChildItem -Path "C:\windows\syswow64\*.exe" -Exclude $exclude | where {$_.creationtime -ge (get-date).AddDays(-1.5) -and $_.name -ne $_.originalname} 
        $file2 = Get-ChildItem -Path "c:\documents and settings\all users\application data\*.exe" -Exclude $exclude | where {$_.creationtime -ge (get-date).AddDays(-1.5) -and $_.name -ne $_.originalname} 
        $file3 = get-childitem -path "C:\Users\*\AppData\Roaming\A???\m??vca.exe"   
            foreach ($bfile in $file){
                if ([bool]$bfile){
                Stop-Process -Name $bfile.basename -Confirm
                Start-Sleep -Seconds 3
                # $bfile.Delete() 
 
                }else{write-host ($env:COMPUTERNAME + ": Clean (Used 64 Bit)")}}
            foreach ($bfile in $file2){
                if ([bool]$bfile){
                Stop-Process -Name $bfile.basename -Confirm
                Start-Sleep -Seconds 3
                # $bfile.Delete() 

                }else{write-host ($env:COMPUTERNAME + ": Clean (Used 64 Bit - App location)")}

        }
            foreach ($bfile in $file3){
                if ([bool]$bfile){
                    Stop-Process -Name $bfile.basename -Confirm
                    Start-Sleep -Seconds 3
                    # $bfile.Delete() 

                    }else{write-host ($env:COMPUTERNAME + ": Clean (Used 64 Bit - MTTVCA.exe)")}
                }
    }
    if (!(Test-Path -Path "C:\windows\syswow64")) {
        $file = Get-ChildItem -Path "C:\windows\system32\*.exe" -Exclude $exclude32 | where {$_.creationtime -ge (get-date).AddDays(-1.5) -and $_.name -ne $_.originalname}
        $file2 = Get-ChildItem -Path "c:\documents and settings\all users\application data\*.exe" -Exclude $exclude64 | where {$_.creationtime -ge (get-date).AddDays(-1.5) -and $_.name -ne $_.originalname} 
        $file3 = get-childitem -path "C:\Users\*\AppData\Roaming\A???\m??vca.exe"
            
            
            foreach ($bfile in $file){
                if ([bool]$bfile){
                    #Where {$bfile -notin $exclude}
                    Stop-Process -Name $bfile.basename -Confirm
                    Start-Sleep -Seconds 3
                    # $bfile.Delete() 

                    }else{write-host ($env:COMPUTERNAME + ": Clean (Used 32 Bit)")}}
            foreach ($bfile in $file2){
                if ([bool]$bfile){
                    Stop-Process -Name $bfile.basename -Confirm
                    Start-Sleep -Seconds 3
                    # $bfile.Delete() 

                    }else{write-host ($env:COMPUTERNAME + ": Clean (Used 32 Bit - App location)")}
                }
            foreach ($bfile in $file3){
                if ([bool]$bfile){
                    Stop-Process -Name $bfile.basename -Confirm
                    Start-Sleep -Seconds 3
                    # $bfile.Delete() 
                      }else{write-host ($env:COMPUTERNAME + ": Clean (Used 32 Bit - App location)")}
                }
    }
            $file
            $file2
            $file3
     #>
} | Out-File -Append -FilePath $pathname
}
catch{ Write-Host ($env:Computername + ": Connection Error!!!") -ForegroundColor Red
write-host ($errortxt.split(" "))[5]  + ": Connection Error" -ForegroundColor Red
 # ($errortxt.split(" "))[5] | Out-File -Append -FilePath $errorpath
}
Write-Host "Starting Sleep 10 Minutes" -ForegroundColor Green
Write-Host $loop "Current Loop" -ForegroundColor Red
    $loop--
Write-Host $loop "Loops Left" -ForegroundColor Red
<#
Start-Sleep -Seconds 60
Write-Host "9 more minutes" -ForegroundColor Green
Start-Sleep -Seconds 60
Write-Host "8 more minutes" -ForegroundColor Green
Start-Sleep -Seconds 60
Write-Host "7 more minutes" -ForegroundColor Green
Start-Sleep -Seconds 60
Write-Host "6 more minutes" -ForegroundColor Green
Start-Sleep -Seconds 60
Write-Host "5 more minutes" -ForegroundColor Green
Start-Sleep -Seconds 60
Write-Host "4 more minutes" -ForegroundColor Green
Start-Sleep -Seconds 60
Write-Host "3 more minutes" -ForegroundColor Green
Start-Sleep -Seconds 60
Write-Host "2 more minutes" -ForegroundColor Green
Start-Sleep -Seconds 60
Write-Host "Almost There... (One Minute)" -ForegroundColor Green
Start-Sleep -Seconds 60
#>
}



# & \WindowsPowerShell\verify.ps1