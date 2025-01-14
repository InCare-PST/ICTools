#Script to clear Google Chrome Passwords

Function DeletePasswords {
    $users = Get-ChildItem -Path c:\users -Directory
    ForEach ($user in $users) {    
            remove-item "C:\Users\$($user.name)\AppData\Local\Google\Chrome\User Data\Default\Login Data" -Force -ErrorAction SilentlyContinue
        }
}

Function KillChrome {
    Stop-Process -Name Chrome -Force
}


KillChrome
DeletePasswords

