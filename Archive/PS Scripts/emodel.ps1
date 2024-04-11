while($true){
    $date = (get-date).AddDays(-45)
    $servers = Get-ADComputer -Filter * -Properties LastLogonDate | where lastlogondate -GE $date
    foreach ($server in $servers){
        $serversn = $server.name
        $path = "\\$serversn\c$\windows"
        if (test-path $path) {        
            $path
            #$file = get-childitem -file -Path $path * | where {$_.Name -match "(?i)(^[0-9]*\.exe)|(^[0-9]\w\w[0-9]*?\.exe)"}
            $file = get-childitem -file -Path $path * | where {$_.creationtime -ge (get-date).AddDays(-2) -and $_.Name -match "(?i)(\w\w\w\w\w\w\w\w\.exe)" -and $_.Name -notmatch "PSEXESVC\.exe"}
                foreach ($bfile in $file){
                #invoke-all ($bfile in $file){
                    if ([bool]$bfile){
                    #pskill \\$serversn $bfile.basename
                    $fname = $bfile.name
                    $truepath = $path + "\$fname"
                    Remove-Item -Path $truepath
                    $ScanTime = (Get-Date).ToString('yyyy-MM-dd')
                    $pathname = "C:\temp\$ScanTime-Emo-File-del.txt"
                    $fname + ' '+"on"+' ' + $serversn +' '+ (get-date).ToString('MM-dd-yyyy_hh:mm:ss') | Out-File -Append $pathname
                }

            }
            #$file | Out-File -Append C:\temp\computers02.txt
        }
    }
Start-Sleep -Seconds 600
}