workflow restartComputer{
    sequence {
        "[$([datetime]::Now)]Begin restart" | Out-File c:\temp\testwf.txt
        Restart-Computer -Wait
        "[$([datetime]::Now)]Return from restart" | Out-File c:\temp\testwf.txt -Append
        }
}
restartComputer