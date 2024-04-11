$ScanTime = (Get-Date).ToString('yyyy-MM-dd')
$pathname = "C:\temp\$ScanTime-InDelete-Loader.txt"
Invoke-Command -ComputerName $verified {
    if (Test-Path -Path "C:\windows\SysWOW64") {
        $file = Get-ChildItem -Path "C:\windows\syswow64" * | where {$_.creationtime -ge (get-date).AddDays(-1.5) -and $_.name -ne $_.originalname -and $_.name -match "\.exe"}
            foreach ($bfile in $file){
                if ([bool]$bfile){
                Stop-Process -Name $bfile.basename -Confirm
                Start-Sleep -Seconds 3
                $bfile.Delete() 
                <#$rfile = $bfile.fullname
                Remove-Item -Path $rfile#>
                }
        }
    }
    if (!(Test-Path -Path "C:\windows\syswow64")) {
        $file = Get-ChildItem -Path "C:\windows\system32" * | where {$_.creationtime -ge (get-date).AddDays(-1.5) -and $_.name -ne $_.originalname -and $_.name -match "\.exe"}
            foreach ($bfile in $file){
                    if ([bool]$bfile){
                    Stop-Process -Name $bfile.basename -Confirm
                    Start-Sleep -Seconds 3
                    $bfile.Delete() 
                    <#$rfile = $bfile.fullname
                    Remove-Item -Path $rfile#>
                    }
                }
    }
            $file
} | Out-File -Append -FilePath $pathname
