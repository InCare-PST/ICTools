#Script for Joey to fix Computer Names

$TCPIP="HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
$TCPIPa="HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
$CompN=$env:COMPUTERNAME
$regbackup="C:\Backups"
$regbackupfile="C:\Backups\ToUpperFix.reg"



if(!(test-path $regbackup)){new-item $regbackup -ItemType Directory}
if(!(test-path $regbackupfile)){
    Invoke-Command -ScriptBlock {reg export $TCPIPa "$regbackupfile" /y}
    New-ItemProperty -Path $TCPIP -Name "HostName" -Value "$CompN" -PropertyType String -Force
    New-ItemProperty -Path $TCPIP -Name "NV HostName" -Value "$CompN" -PropertyType String -Force
}else{

}
