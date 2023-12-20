$unloadpass=Read-Host -Prompt "Unload Password"
$path1="C:\Program Files (x86)\Trend Micro\Security Agent\PccNtMon.exe"
$path2="C:\Program Files (x86)\Trend Micro\Client Server Security Agent\PccNtMon.exe"


If(test-path $path1){Start-process -filepath $path1 -ArgumentList "-n $unloadpass"}
If(test-path $path2){Start-process -filepath $path2 -ArgumentList "-n $unloadpass"}
