$loop = 6


while ($loop -gt 0){

$ScanTime = (Get-Date).ToString('yyyy-MM-dd')
$pathname = "C:\temp\$ScanTime-InDelete-Loader.txt"
Invoke-Command -ComputerName $verified {
 $exclude32 = get-content "C:\WindowsPowerShell\goodexe.txt"
 $exclude64 = Get-Content "C:\WindowsPowerShell\goodexe64.txt"   
    if (Test-Path -Path "C:\windows\SysWOW64") {
        $file = Get-ChildItem -Path "C:\windows\syswow64" *.exe -Exclude $exclude64 | where {$_.creationtime -ge (get-date).AddDays(-1.5) -and $_.name -ne $_.originalname} 
            foreach ($bfile in $file){
                if ([bool]$bfile){
                Stop-Process -Name $bfile.basename -Confirm:$false
                Start-Sleep -Seconds 3
                $bfile.Delete() 
                    <#}else{
                    write-host ($env:COMPUTERNAME + " is 64 Bit Clean")
                    }#>
        }
        }
    }
    if (!(Test-Path -Path "C:\windows\syswow64")) {
        $file = Get-ChildItem -Path "C:\windows\system32" *.exe -Exclude $exclude32 | where {$_.creationtime -ge (get-date).AddDays(-1.5) -and $_.name -ne $_.originalname}
            foreach ($bfile in $file){
                    if ([bool]$bfile){
                    Stop-Process -Name $bfile.basename -Confirm:$false
                    Start-Sleep -Seconds 3
                    $bfile.Delete() 
                        <#}else{
                        write-host ($env:COMPUTERNAME + " is 32 Bit Clean")
                        }#>
                    }
                }
    }
            $file
} | Out-File -Append -FilePath $pathname

Write-Host "Starting Sleep 10 Minutes" -ForegroundColor Green
Write-Host $loop "Current Loop" -ForegroundColor Red
    $loop--
Write-Host $loop "Loops Left" -ForegroundColor Red

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
}



& \WindowsPowerShell\verify.ps1