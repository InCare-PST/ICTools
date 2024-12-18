$date = (get-date).AddDays(-45)
$servers = Get-ADComputer -Filter * -Properties LastLogonDate | where lastlogondate -GE $date
foreach ($server in $servers){
    $serversn = $server.name
    $path = "\\$serversn\c$\windows\system32"
    $path64 = "\\$serversn\c$\windows\syswow64"
    if (!(test-path $path64)) {
       if (test-path $path){         
            $path
            $file = get-childitem -file -Path $path * | where {$_.creationtime -ge (get-date).AddDays(-1) -and $_.name -ne $_.originalname -and $_.name -match ".*\.exe"}
                foreach ($bfile in $file){
                    if ([bool]$bfile){
                    #pskill \\$serversn $bfile.basename
                    $fname = $bfile.name
                    $truepath = $path + "\$fname"
                    $ScanTime = (Get-Date).ToString('yyyy-MM-dd')
                    $pathname = "C:\temp\$ScanTime-loader-test32.txt"
                    #Remove-Item -Path $truepath
                    $fname + ' '+"on"+' ' + $serversn +' '+ (get-date).ToString('MM-dd-yyyy_hh:mm:ss')| Out-File -Append $pathname
                }

            }
        }
            #$file | Out-File -Append C:\temp\computers02.txt
    }
}