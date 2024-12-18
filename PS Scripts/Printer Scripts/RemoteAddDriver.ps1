$comps= Get-ADComputer -Filter * -Properties PasswordLastSet | Where-Object PasswordLastSet -GT ((get-date).AddDays(-365)) | Select-Object Name
$logdir = "C:\temp"
$logfile = "$($(get-date -Format yyyy-MM-dd))"+"-driverlog.txt"
$logs = "$logdir"+"\"+"$logfile"

foreach($comp in $comps){
    if(test-connection -ComputerName $comp.name -Count 1 -Quiet){
    write-host "Installing driver on $($comp.name)" 
    Add-PrinterDriver -ComputerName $comp.name -InfPath "C:\Windows\System32\DriverStore\FileRepository\hpcu170t.inf_amd64_19ebd2869a0eaf0d\hpcu170t.inf" -Name "HP Universal Printing PCL 5" -verbose -ErrorAction SilentlyContinue -ErrorVariable ProcessError 2>&1 | Tee-Object $logs -Append
    Add-PrinterDriver -ComputerName $comp.name -InfPath "C:\Windows\System32\DriverStore\FileRepository\hpcu255u.inf_amd64_883dd40f467c5d42\hpcu255u.inf" -Name "HP Universal Printing PCL 6" -verbose -ErrorAction SilentlyContinue -ErrorVariable ProcessError 2>&1  | Tee-Object $logs -Append

}else{
    write-host "Error connecting to $($comp.name)"-ForegroundColor DarkRed -BackgroundColor Green
}
if ([bool]$ProcessError){
    write-host "$($comp.name) has an error" -ForegroundColor Red
    if(!(Test-path $logdir)){new-item $logdir -ItemType Directory}

    
}else{
    write-host "$($comp.name) worked great, good job" -ForegroundColor Green -BackgroundColor Black
}
}
