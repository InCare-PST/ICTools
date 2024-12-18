function update-mappeddrives{
    [cmdletbinding(DefaultParameterSetName="Default")]
        param(
            [Parameter(ParameterSetName="Default",Mandatory=$true)]
            [Parameter(ParameterSetName="Reporting",Mandatory=$true)]
            [string]$oldserver,

            [Parameter(ParameterSetName="Default",Mandatory=$true)]
            [string]$newserver,

            [Parameter(ParameterSetName="Reporting",Mandatory=$true)]
            [switch]$report,

            [Parameter(ParameterSetName="Reporting",Mandatory=$false)]
            [string]$logdir = "C:\temp"
        )
    begin{
        #collect the drives currently mapped to the old server
        $mappeddrives = Get-SmbMapping | Where-Object {$_.RemotePath -match $oldserver}
        Write-Host "The following drives are currently connected to $oldserver"
        $mappeddrives | select-object localpath,remotepath
    }
    Process{
        #if reporting is enabled check the directory the export the mapped drive config
        if($report){
            $date = Get-Date -Format MM-dd-yyyy
            $reportname = "$date-mappeddrives.csv"
            if(!(test-path $logdir)){
                New-Item -Path $logdir -ItemType Directory
            }
            $mappeddrives | Export-Csv -Path $logdir\$reportname -NoTypeInformation
            Exit
        }else{
            foreach($drive in $mappeddrives){
                $oldpath = $drive.RemotePath
                $newpath = $oldpath.Replace($oldserver,$newserver)
                if(test-path $newpath){
                    Write-Host "Removing $($drive.localpath)" -ForegroundColor Green
                    Remove-SmbMapping -LocalPath $drive.LocalPath -RemotePath $drive.RemotePath -Force
                    New-SmbMapping -LocalPath $drive.LocalPath -RemotePath $newpath -Persistent $true 
                }else{
                    Write-Host "$newpath is not available. Please check spelling and network connections." -ForegroundColor Yellow
                }
            }
        }
    }
    End{
        #List the new Mapped drives
        write-host "The following drives were mapped to $newserver" -ForegroundColor Green
        $newdrives = Get-SmbMapping | Where-Object {$_.RemotePath -match $newserver}
        $newdrives | select-object localpath,remotepath
    }
}

update-mappeddrives -oldserver pstore1 -newserver padmin-dc01