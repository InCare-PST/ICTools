#############################################################################################################################
#
# DFS BACKLOG Scriptget
#
#
#############################################################################################################################

 param(
        [parameter(Mandatory=$false)]
        [switch]$showfiles


        )

    $var1=Read-Host -Prompt "Receive Group Name"
    $var2=Read-Host -Prompt "Receive Folder Name[$var1]"
    $var3=Read-Host -Prompt "Sending Server"
    $var4=Read-Host -Prompt "Receiving Server[$env:computername]"
    if($var2 -eq ""){$var2 = $var1}
    if($var4 -eq ""){$var4 = $env:computername}


$backlog = dfsrdiag backlog /rgname:$var1 /rfname:$var2 /smem:$var3 /rmem:$var4
$bl = $backlog | Select-String 'Backlog File Count'

IF($showfiles){
    $showbacklog = @()
    $showbacklog += $backlog
    $showbacklog | Out-GridView
    

}ELSE{
write-host $bl -ForegroundColor Green
}



