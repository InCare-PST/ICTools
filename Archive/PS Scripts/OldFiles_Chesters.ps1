$fiveyears = (get-date).adddays(-1825)
Get-ChildItem -Directory -Recurse | ForEach-Object -Process {Get-ChildItem .\ -file | Where-Object {$_.LastWriteTime -lt $fiveyears} | Select-Object FullName,LastWriteTime,@{Name="KB Size";Expression={ "{0:N0}" -f ($_.Length / 1KB) }} | Export-Csv -Path c:\temp\D_OldFiles.csv -notypeinformation}

