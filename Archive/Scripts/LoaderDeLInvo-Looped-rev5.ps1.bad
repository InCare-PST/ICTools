#function Time-Stamp() {Get-Date -f 'MM/dd/yyyy hh:mm'}
function Date-Stamp() {get-date -f 'yyyy-MM-dd'}
function Time-Stamp() {(Get-Date -f 'MM/dd/yyyy hh:mm') + (write-host "---------------------------------------------")}


Write-Host "--------------------Beginning Malware Removal Script------------------" -ForegroundColor DarkBlue -BackgroundColor White
#Start-Sleep -Seconds 5

while ($true){
#Global Variables
$datestamp = Date-Stamp
$ScanTime = (Get-Date).ToString('yyyy-MM-dd')
$pathname = "C:\temp\$datestamp-InDelete-Loader.txt"
$errorpath = "C:\temp\$datestamp-InDelete-Loader-Error.txt"
$verified = get-content "D:\Toolbox\Verified.txt" | sort
# Remote Commands
try{
#
write-host "-----------------------From the top!!!--------------------------------" -ForegroundColor DarkBlue -BackgroundColor White
#
##________________________________________________________________________________________________________________________________
##Begin Remote Block


Invoke-Command -ComputerName $verified -ErrorVariable errortxt -throttlelimit 6 <# 2>$null -AsJob -Debug -Verbose#> {
function Time-Stamp {Get-Date -f 'yyyy-MM-dd-hhmm'}
write-host -ForegroundColor Green("Scanning: " + $env:COMPUTERNAME)
    $exclude32 = get-content "\\192.168.2.160\Toolbox\goodexe.txt"
    $exclude64 = Get-Content "\\192.168.2.160\Toolbox\goodexe64.txt"
    $file1 = get-childitem -path C:\Users\,c:\windows\  *.exe -Recurse | where {$_.name -match "^44\w{62}\.exe$|^m\w\wvca\.exe$"}
    $file2 = get-childitem -path C:\  *.exe | where {$_.name -match "^44\w{62}\.exe$|^m\w\wvca\.exe$"}
    if(!(Test-Path -Path "C:\windows\SysWOW64")){$file3 = Get-ChildItem -Path "C:\windows\system32\*.exe" -Exclude $exclude32 | where {$_.creationtime -ge (get-date).AddDays(-1.5) -and $_.name -ne $_.originalname}}
    if(Test-Path -Path "C:\windows\SysWOW64") {$file4 = Get-ChildItem -Path "C:\windows\syswow64\*.exe" -Exclude $exclude64 | where {$_.creationtime -ge (get-date).AddDays(-1.5) -and $_.name -ne $_.originalname}}
    $path1 = get-childitem -path C:\Users\*\AppData\*\A???  -force | where {$_.name -ne "APPS"} 
        
##________________________________________________________________________________________________________________________________
##Begin Removals     
        
        #Begin File 1
        foreach ($bfile in $file1){
                if ([bool]$bfile){
                    Stop-Process -Name $bfile.basename -Confirm
                    Start-Sleep -Seconds 3
                    $bfile.Delete()         
    
    }
                
           
} if ($file1) { write-host ("Found Files on host: " + $env:Computername + " " + $file1)}
        
        #Begin File 2 
        foreach ($bfile in $file2){
                if ([bool]$bfile){
                    Stop-Process -Name $bfile.basename -Confirm
                    Start-Sleep -Seconds 3
                    $bfile.Delete()         
    
    }
           
} if ($file2) { write-host ("Found Files on host: " + $env:Computername + " " + $file2)}
        
        #Begin File 3
        foreach ($bfile in $file3){
                if ([bool]$bfile){
                    Stop-Process -Name $bfile.basename -Confirm
                    Start-Sleep -Seconds 3
                    $bfile.Delete()         
    
    }
           
    } if ($file3) { write-host ("Found Files on host: " + $env:Computername + " " + $file3)}
        
        #Begin File 4
        foreach ($bfile in $file4){
                if ([bool]$bfile){
                    Stop-Process -Name $bfile.basename -Confirm
                    Start-Sleep -Seconds 3
                    $bfile.Delete()
                                 }
                                 } if ($file4) { write-host ("Found Files on host: " + $env:Computername + " " + $file4)}
       
       
        #Begin Path 1 
        try{
           if ($path1){
                write-host ("Found Paths on host:" + $env:Computername + " " + $path1)
                Remove-Item -path $path1 -Force -Recurse}
         }catch{

            write-host ($path1 + ": Could not be removed")}

        <#foreach ($bpath in $path1){
            if([bool]$bpath){
            Remove-Item -path $path1 -Force -Recurse}
           
            } #write-host $path1
            #if ($path1) { write-host ("Found Paths on host: " + $env:Computername + " " + $path1)}#>
        
        
        <#foreach ($bfile in $file6){
                if ([bool]$bfile){
                    Stop-Process -Name $bfile.basename -Confirm
                    Start-Sleep -Seconds 3
                    $bfile.Delete()         
    
    }           
} if ($file6) { write-host ("Found Files on host: " + $env:Computername + " " + $file6)}#>


$files = @()
$files =+ , $file1
$files =+ , $file2
$files =+ , $file3
$files =+ , $file4
$files =+ , $path1
if ($files) {Time-Stamp}
if ($file1) {$file1}
#if ($file2) {Time-Stamp}
if ($file2) {$file2}
#if ($file3) {Time-Stamp}
if ($file3) {$file3}
#if ($file4) {Time-Stamp}
if ($file4) {$file4}
#if ($path1) {Time-Stamp}
if ($path1) {$path1}
if (!$files){write-host ($env:Computername + ": Clean Pass")}

#if ($file5) { Time-Stamp}
#if ($file5) { $file5}
#if ($file6) { Time-Stamp}
#if ($file6) { $file6}
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