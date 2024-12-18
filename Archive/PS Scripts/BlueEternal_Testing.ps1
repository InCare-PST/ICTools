function Time-Stamp() {Get-Date -f 'yyyy-MM-yy-hhmm'}
$verified = get-content "D:\Toolbox\Verified.txt" | sort
$timestamp = Time-Stamp
$ebcheck = Get-Item -path C:\Windows\system32\Drivers\srv.sys
$temp =@()
#ForEach ($comp in $verified) {
    Invoke-Command -ComputerName $verified {
    Get-Item C:\Windows\system32\Drivers\srv.sys | where {$_.productversion -le "6.3.9600.16384"} 
    } | Select PSComputername, @{n='fileversion';e={[System.Diagnostics.FileVersionInfo]::GetVersionInfo($_).FileVersion}},LastWriteTime | out-file -filepath c:\temp\eternal.txt
    #}