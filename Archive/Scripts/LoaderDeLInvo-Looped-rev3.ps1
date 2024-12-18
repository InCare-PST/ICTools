function Time-Stamp {Get-Date -f 'yyyy-MM-dd-hhmm'}
Write-Host "Beginning Malware Removal Script" -ForegroundColor DarkBlue -BackgroundColor White
#Start-Sleep -Seconds 5

while ($true){
#Global Variables
$ScanTime = (Get-Date).ToString('yyyy-MM-dd-hh')
$pathname = "C:\temp\$ScanTime-InDelete-Loader.txt"
$errorpath = "C:\temp\$scanTime-InDelete-Loader-Error.txt"
$verified = get-content "D:\Toolbox\Verified.txt" | sort
# Remote Commands
try{
write-host "From the top!!!"
Invoke-Command -ComputerName $verified -ErrorVariable errortxt -throttlelimit 4 <#2>$null -AsJob -Debug -Verbose#> {
function Time-Stamp {Get-Date -f 'yyyy-MM-dd-hhmm'}
write-host -ForegroundColor Green("Scanning: " + $env:COMPUTERNAME)
    $exclude32 = get-content "\\192.168.2.160\Toolbox\goodexe.txt"
    $exclude64 = Get-Content "\\192.168.2.160\Toolbox\goodexe64.txt"
    $infected = "44??????????????????????????????????????????????????????????????.exe","m??vca.exe"
    $file1 = get-childitem -path C:\Users\,c:\windows\  *.exe -Recurse | where {$_.name -match "^44\w{62}\.exe$|^m\w\wvca\.exe$"}
    $file2 = get-childitem -path C:\  *.exe | where {$_.name -match "^44\w{62}\.exe$|^m\w\wvca\.exe$"}
    #$file1 = get-childitem -path "C:\Users\*"  -Include "44??????????????????????????????????????????????????????????????.exe","m??vca.exe" -Recurse
    #$file2 = Get-ChildItem -path "c:\windows\*" -Exlcude "C:\Windows\WinSxS\" -Include "44??????????????????????????????????????????????????????????????.exe","m??vca.exe" -Recurse 
    #$file3 = Get-ChildItem -path "c:\*" -Include "44??????????????????????????????????????????????????????????????.exe","m??vca.exe"
    #$file4 = Get-ChildItem -Path "c:\documents and settings\all users\application data\*.exe" -Exclude $exclude64 | where {$_.creationtime -ge (get-date).AddDays(-1.5) -and $_.name -ne $_.originalname} 
    if(!(Test-Path -Path "C:\windows\SysWOW64")){$file5 = Get-ChildItem -Path "C:\windows\system32\*.exe" -Exclude $exclude32 | where {$_.creationtime -ge (get-date).AddDays(-1.5) -and $_.name -ne $_.originalname}}
    if(Test-Path -Path "C:\windows\SysWOW64") {$file6 = Get-ChildItem -Path "C:\windows\syswow64\*.exe" -Exclude $exclude64 | where {$_.creationtime -ge (get-date).AddDays(-1.5) -and $_.name -ne $_.originalname}}
       
        foreach ($bfile in $file1){
                if ([bool]$bfile){
                    Stop-Process -Name $bfile.basename -Confirm
                    Start-Sleep -Seconds 3
                    $bfile.Delete()         
    
    }
                
           
} if ($file1) { write-host ("Found Files on host: " + $env:Computername + " " + $file1)}
        foreach ($bfile in $file2){
                if ([bool]$bfile){
                    Stop-Process -Name $bfile.basename -Confirm
                    Start-Sleep -Seconds 3
                    $bfile.Delete()         
    
    }
           
} if ($file2) { write-host ("Found Files on host: " + $env:Computername + " " + $file2)}
        foreach ($bfile in $file3){
                if ([bool]$bfile){
                    Stop-Process -Name $bfile.basename -Confirm
                    Start-Sleep -Seconds 3
                    $bfile.Delete()         
    
    }
           
    } if ($file3) { write-host ("Found Files on host: " + $env:Computername + " " + $file3)}
        foreach ($bfile in $file4){
                if ([bool]$bfile){
                    Stop-Process -Name $bfile.basename -Confirm
                    Start-Sleep -Seconds 3
                    $bfile.Delete()         
    
    }
           
    } if ($file4) { write-host ("Found Files on host: " + $env:Computername + " " + $file4)}
        foreach ($bfile in $file5){
                if ([bool]$bfile){
                    Stop-Process -Name $bfile.basename -Confirm
                    Start-Sleep -Seconds 3
                    $bfile.Delete()         
    
    }
           
    } if ($file5) { write-host ("Found Files on host: " + $env:Computername + " " + $file5)}
        foreach ($bfile in $file6){
                if ([bool]$bfile){
                    Stop-Process -Name $bfile.basename -Confirm
                    Start-Sleep -Seconds 3
                    $bfile.Delete()         
    
    }           
} if ($file6) { write-host ("Found Files on host: " + $env:Computername + " " + $file6)}

if ($file1) { Time-Stamp}
if ($file1) { $file1}
if ($file2) { Time-Stamp}
if ($file2) { $file2}
if ($file3) { Time-Stamp}
if ($file3) { $file3}
if ($file4) { Time-Stamp}
if ($file4) { $file4}
if ($file5) { Time-Stamp}
if ($file5) { $file5}
if ($file6) { Time-Stamp}
if ($file6) { $file6}
}| Out-File -Append -FilePath $pathname
}catch{ Write-Host ($env:Computername + ": Connection Error!!!") -ForegroundColor Red
#write-host ($errortxt.split(" "))[5]  + ": Connection Error" -ForegroundColor Red
#($errortxt.split(" "))[5] | Out-File -Append -FilePath $errorpath
}
Write-Host "Waiting for job to finish..." -ForegroundColor Green
#get-job | Wait-Job
#get-job -State Completed | Remove-Job
#Write-Host $loop "Current Loop" -ForegroundColor Red
#    $loop--
#Write-Host $loop "Loops Left" -ForegroundColor Red

#Start-Sleep -Seconds 60
#Write-Host "9 more minutes" -ForegroundColor Green
#Start-Sleep -Seconds 60
#Write-Host "8 more minutes" -ForegroundColor Green
#Start-Sleep -Seconds 60
#Write-Host "7 more minutes" -ForegroundColor Green
#Start-Sleep -Seconds 60
#Write-Host "6 more minutes" -ForegroundColor Green
#Start-Sleep -Seconds 60
#Write-Host "5 more minutes" -ForegroundColor Green
#Start-Sleep -Seconds 60
#Write-Host "4 more minutes" -ForegroundColor Green
#Start-Sleep -Seconds 60
#Write-Host "3 more minutes" -ForegroundColor Green
#Start-Sleep -Seconds 60
#Write-Host "2 minutes" -ForegroundColor Green
#Start-Sleep -Seconds 60
Write-Host "Almost There... (One Minute)" -ForegroundColor Green
Start-Sleep -Seconds 60
}