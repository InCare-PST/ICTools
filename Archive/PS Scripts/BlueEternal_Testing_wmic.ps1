$verified = get-content "D:\Toolbox\Verified.txt"
# Remote Commands
try{
    #Invoke-Command -ComputerName $verified -ErrorVariable errortxt {
    #Set-Item WSMan:\localhost\Shell\MaxMemoryPerShellMB 2048
       foreach ($comp in $verified){
       wmic /node:$comp qfe where 'caption like "%%401221%%"' | Out-File C:\temp\bluetesting-2.txt -append
       write-host -ForegroundColor Green($comp + ": Successfull")
    
}
}
catch [NativeCommandError]{ write-host ($env:COMPUTERNAME + ": Connection Error")
       #write-host $errortxt
}