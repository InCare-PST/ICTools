$comps= Get-ADComputer -Filter * -Properties PasswordLastSet | Where-Object PasswordLastSet -GT ((get-date).AddDays(-365)) | Select-Object Name
$nokaseyalog = "c:\temp\nokaseya.txt"
$fconlog = "c:\temp\failedconnection.txt"

foreach($comp in $comps){
    if(test-connection -ComputerName $comp.name -Count 1 -Quiet){
    write-host "Connecting to $($comp.name)" -ForegroundColor Green -BackgroundColor Black
    if(!([bool](get-service -ComputerName $comp.name -DisplayName "Kaseya Agent" -ErrorAction SilentlyContinue))){
    $tempobj = @{
        Computer = $comp.name
        Date = (get-date -Format yyy-MM-dd)
        #Variable1 = $Var1
        #Variable2 = $Var2
    }
    $log = New-Object -TypeName psobject -Property $tempobj
    $log | out-file $nokaseyalog -Append
}
}else{
    write-host "Connection to $($comp.name) Failed" -ForegroundColor Red -BackgroundColor Black
    $tempobj = @{
        Computer = $comp.name
        Date = (get-date -Format yyy-MM-dd)
        #Variable1 = $Var1
        #Variable2 = $Var2
    }
    $log = New-Object -TypeName psobject -Property $tempobj
    $log | out-file $fconlog -Append

}
}