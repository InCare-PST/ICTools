for($num = 1 ; $num -le 50 ; $num++){
    Start-process -FilePath C:\Windows\system32\Robocopy.exe -ArgumentList  "\\10.255.255.11\SHARED D:\SHARED\ /E /B /COPYALL /R:6 /W:5 /MT:64 /XD DfsrPrivate /TEE /XF *.pst ~$* ~*.tmp /XD LASERFICHE" -wait -WindowStyle Minimized
    write-host -ForegroundColor Green "Finished $num loops"
    }