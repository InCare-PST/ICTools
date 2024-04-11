$verified = get-content "D:\Toolbox\Verified.txt"
# Remote Commands
try{
    Invoke-Command -ComputerName $verified -ErrorVariable errortxt {
    #Set-Item WSMan:\localhost\Shell\MaxMemoryPerShellMB 2048
        winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="0"}'
        Set-Item WSMan:\localhost\Shell\MaxMemoryPerShellMB 5000
        Set-Item WSMan:\localhost\Plugin\Microsoft.PowerShell\Quotas\MaxMemoryPerShellMB 5000
    write-host -ForegroundColor Green($env:COMPUTERNAME + ": Successfull")
    Restart-Service winrm
    }
}
catch{ write-host ($env:COMPUTERNAME + ": Connection Error")
       #write-host $errortxt
}