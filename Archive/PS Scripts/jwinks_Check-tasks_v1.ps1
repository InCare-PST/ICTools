
function Date-Stamp() {get-date -f 'yyyy-MM-dd'}
function Time-Stamp() {(Get-Date -f 'MM/dd/yyyy hh:mm') + (write-host "---------------------------------------------")}


Write-Host "--------------------Scanning for MSNETCS Tasks------------------" -ForegroundColor DarkBlue -BackgroundColor White

$datestamp = Date-Stamp
$ScanTime = (Get-Date).ToString('yyyy-MM-dd')
$pathname = "C:\temp\$datestamp-$env:COMPUTERNAME-Check-Tasks.txt"
$errorpath = "C:\temp\$datestamp-InDelete-Loader-Error.txt"
$verified = get-content "D:\Toolbox\Verified.txt" | sort
$temparray = @()

Invoke-Command -ComputerName $verified -ErrorVariable errortxt -throttlelimit 6 <# 2>$null -AsJob -Debug -Verbose#> {
function Time-Stamp {Get-Date -f 'yyyy-MM-dd-hhmm'}
write-host -ForegroundColor Green("Scanning: " + $env:COMPUTERNAME)
       # $temparray += Get-ChildItem -Path c:\windows\ *.job -Recurse | where {$_.creationtime -ge (get-date).AddDays(-90)}
       # $temparray
    Write-Host ($env:COMPUTERNAME) + " : " + (Get-ScheduledTask | ? {$_.TaskName -like "*MSNETCS*"}).Actions.Execute
} # | Out-File -Append -FilePath $pathname

