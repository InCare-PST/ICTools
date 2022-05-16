$oldserver = "pstore1"
$newserver = "padmin-dc01"
$mappeddrives = Get-SmbMapping | Where-Object {$_.RemotePath -match $oldserver }
foreach($drive in $mappeddrives){
    $oldroot = $drive.RemotePath
    $newroot = $oldroot.Replace($oldserver,$newserver)
    if(test-path $newroot){
            Remove-SmbMapping -LocalPath $drive.LocalPath -RemotePath $oldroot
            New-SmbMapping -LocalPath $drive.LocalPath -RemotePath $newroot -Persistent $true
        }else{
            Write-Host "$($newrooot) not available. Please check $newserver path." -ForegroundColor Red
        }

}


function update-mappeddrives{
    [cmdletbinding()]
        param(
            [string]$oldserver,

            [string]$newserver,

            [switch]$report,

            [string]$logdir = "C:\temp"
        )
begin{
    #collect the drives currently mapped to the old server
    $mappeddrives = Get-SmbMapping | Where-Object {$_.RemotePath -match $oldserver}

    #if reporting is enabled check the directory
    if($report){
        $date = Get-Date -Format MM-dd-yyyy
        if(!(test-path $logdir)){
            New-Item -Path $logdir -ItemType Directory
        }
    }

}
Process{

}
End{

}
}