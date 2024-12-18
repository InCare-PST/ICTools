#function Time-Stamp() {Get-Date -f 'MM/dd/yyyy hh:mm'}
function Date-Stamp() {get-date -f 'yyyy-MM-dd'}
function Time-Stamp() {(Get-Date -f 'MM/dd/yyyy hh:mm') + (write-host "---------------------------------------------")}


Write-Host "--------------------Beginning Malware Removal Script------------------" -ForegroundColor DarkBlue -BackgroundColor White
#Start-Sleep -Seconds 5

#while ($true){
#Global Variables
$datestamp = Date-Stamp
$ScanTime = (Get-Date).ToString('yyyy-MM-dd')
$pathname = "C:\temp\$datestamp-$env:COMPUTERNAME-Check-Tasks.txt"
$errorpath = "C:\temp\$datestamp-InDelete-Loader-Error.txt"
$verified = get-content "D:\Toolbox\Verified.txt" | sort
$temparray = @()
# Remote Commands
#try{
#
write-host "-----------------------From the top!!!--------------------------------" -ForegroundColor DarkBlue -BackgroundColor White
#
Invoke-Command -ComputerName $verified -ErrorVariable errortxt -throttlelimit 6 <# 2>$null -AsJob -Debug -Verbose#> {
function Time-Stamp {Get-Date -f 'yyyy-MM-dd-hhmm'}
write-host -ForegroundColor Green("Scanning: " + $env:COMPUTERNAME)
       $temparray += Get-ChildItem -Path c:\windows\ *.job -Recurse | where {$_.creationtime -ge (get-date).AddDays(-90)}
        $temparray
}| Out-File -Append -FilePath $pathname
#}catch{ Write-Host ($env:Computername + ": Connection Error!!!") -ForegroundColor Red
#write-host ($errortxt.split(" "))[5]  + ": Connection Error" -ForegroundColor Red
#($errortxt.split(" "))[5] | Out-File -Append -FilePath $errorpath
#}
#Write-Host "Waiting for job to finish..." -ForegroundColor Green
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
#Write-Host "Almost There... (One Minute)" -ForegroundColor Green
#Start-Sleep -Seconds 60
#}