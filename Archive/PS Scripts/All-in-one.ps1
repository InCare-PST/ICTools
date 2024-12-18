$date = (get-date).AddDays(-25)
$computers = Get-ADComputer -Filter * -Properties LastLogonDate | where lastlogondate -GE $date
$verified = @()
$WRMComp = @()
$NWRM = @()
ForEach ($comp in $computers) {
    if (Test-Connection -ComputerName $comp.name -Count 1 -Quiet) {
        Write-Host $comp.name "is Alive"
        if ([bool](Test-WSMan -ComputerName $comp.Name)){
            $WRMComp += $comp
        }
        else {
            $NWRM += $comp
        }
        $verified += ($comp | select -ExpandProperty name)
    }
    $nwrm | Export-Clixml c:\temp\
}
$looptime = (Get-Date).AddMinutes(5)
while ((Get-Date) -le $looptime){
    $exclude = get-content "C:\WindowsPowerShell\goodexe2.txt"
    $ScanTime = (Get-Date).ToString('yyyy-MM-dd')
    $pathname = "C:\temp\$ScanTime-InDelete-Loader.txt"
    Invoke-Command -ComputerName $WRMComp.name {
        $deletedfiles = @()
        if (Test-Path -Path "C:\windows\SysWOW64") {
            $file = Get-ChildItem -Path "C:\windows\syswow64" -Exclude $exclude | where {$_.creationtime -ge (get-date).AddDays(-1.5) -and $_.name -ne $_.originalname -and $_.name -match "\.exe"} 
                foreach ($bfile in $file){
                    if ([bool]$bfile){
                    $deletedfiles += ($bfile | select name,directory,creationtime)
                    Stop-Process -Name $bfile.basename -Force
                    Start-Sleep -Seconds 3
                    $bfile.Delete() 
                    <#$rfile = $bfile.fullname
                    Remove-Item -Path $rfile#>
                    }else{
                    write-host "64 Bit Clean"
                    }
            }
        }
        if (!(Test-Path -Path "C:\windows\syswow64")) {
            $file = Get-ChildItem -Path "C:\windows\system32" -Exclude $exclude |where $_.name -notin $exclude | where {$_.creationtime -ge (get-date).AddDays(-1.5) -and $_.name -ne $_.originalname -and $_.name -match "\.exe"}
                foreach ($bfile in $file){
                    if ([bool]$bfile){
                    $deletedfiles += ($bfile | select name,directory,creationtime)
                    #if ($bfile -notin $exclude){
                    Stop-Process -Name $bfile.basename -Force
                    Start-Sleep -Seconds 3
                    $bfile.Delete() 
                    <#$rfile = $bfile.fullname
                    Remove-Item -Path $rfile#>
                    }else{
                    write-host "32 Bit Clean"
                    }
                    }
        }
    $deletedfiles
    } | Export-Csv -Path $pathname -NoTypeInformation -
}
