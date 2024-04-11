for($num = 1 ; $num -le 50 ; $num++){
    $source = "E:\HMScan"
    $dest = "g:\HMScan"
    Start-process -FilePath C:\Windows\system32\Robocopy.exe -ArgumentList  "$source $dest /E /purge /ZB /COPYALL /R:6 /W:5 /MT:128 /TEE" -wait #-WindowStyle Minimized
    write-host -ForegroundColor Green "Finished $num loops $(get-date -UFormat "%m/%d %R")"
    Start-Sleep -Seconds 3600
    }