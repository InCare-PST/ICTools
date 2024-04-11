#$looptime = (Get-Date).AddMinutes(30)
#    while ((Get-Date) -le $looptime){
while($true){
$computers = Get-ADComputer -Filter * -Properties * | where enabled -eq $true
$verify = "D:\Toolbox"
$temparray = @()
$temparray2 = @()
$noconnecton = @()
$noconnectoff = @()
$scandate = Get-date -f 'yyyy-MM-dd-hh'
ForEach ($comp in $computers){
    try{
        [bool](Test-WSMan -ComputerName $comp.Name -Verbose -ErrorAction Stop -Errorvariable errortxt 2>$null)
        $temparray += ($comp | select -ExpandProperty name)
        Write-Host -ForegroundColor Green ($comp.name + ": Connection Successful")
    }
    catch{
        if(Test-Connection -ComputerName $comp.name -Count 1 -Quiet){
            $noconnecton += ($comp | select -ExpandProperty name)
            Write-Host -ForegroundColor yellow ($comp.name + ": Connection UnSuccessful - Ping Completed") 
            }
        else {
            $noconnectoff+= ($comp | select -ExpandProperty name)
            Write-Host -ForegroundColor red ($comp.name + ": Connection UnSuccessful - No Answer Ping") 
            }

         }
} 
$temparray | out-file -filepath D:\Toolbox\Verified.txt
$noconnecton | Out-File -FilePath D:\Toolbox\$scandate-NoConnection-on.txt -Append
$noconnectoff| Out-File -FilePath D:\Toolbox\$scandate-NoConnection-off.txt -Append
#get-job -State Completed | Remove-Job
Write-host -ForegroundColor Green ("Starting 1 hour Verify Sleep at " + (Get-Date -Format "hh:mm"))
Start-Sleep -Seconds 3600
}