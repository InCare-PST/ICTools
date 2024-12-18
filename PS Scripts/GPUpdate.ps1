$computers = Get-ADComputer -Filter "Enabled -eq 'True'"
foreach($c in $computers){
    if(Test-Connection -ComputerName $comp.name -Count 1 -Quiet){c:\temp\psexec.exe \\$($c.name) cmd /c "echo n | gpupdate /force"}
}