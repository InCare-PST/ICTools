Function Remove-MalFiles {
<#
Synopsis
Local Only Version


#>
    [cmdletbinding(SupportsShouldProcess = $True)]
        param(
          [switch]$LogOnly

        )


$file = get-childitem -path C:\programdata *.dll -Recurse -Force -ErrorAction SilentlyContinue | Where-Object {$_.name -match "\w{8}-(\w{4}-){3}\w{12}\.dll"}
                            foreach ($bfile in $file){
                                if ([bool]$bfile){
                                    $filedeleted = $false
                                    $filepath = $bfile.fullname
                                    if (!($LogOnly)){
                                        try {
                                            Stop-Process -Name $bfile.basename -Force -ErrorAction SilentlyContinue
                                        }
                                        catch{

                                        }
                                        #Start-Sleep -Seconds 3
                                        try {
                                            Remove-Item $bfile.fullname -ErrorAction Stop
                                            $filedeleted = $true
                                        }
                                        catch{
                                            $filedeleted = $false
                                        }
                                    }
                                    if ($filedeleted){
                                        $delstatus = "Yes"
                                        write-host "$filepath was detected on $ComputerName and was deleted" -ForegroundColor Red
                                    }
                                    else {
                                        $delstatus = "No"
                                        write-host "$filepath was detected on $ComputerName but was not deleted" -ForegroundColor Red
                                    }
                                    $tempobj = @{
                                        Name = $bfile.name
                                        Directory = $bfile.FullName
                                        CreationDate = $bfile.creationtime
                                        Deleted = $delstatus
                                        Command = $Task
                                        Type = "Trojan"
                                        ComputerName = $ComputerName
                                        TimeStamp = (Get-Date -Format "dd-MM-yyyy HH:mm:ss")
                                    }
                                    $FileObj = New-Object -TypeName psobject -Property $tempobj
                                    $deletedfiles += $FileObj
                                    #$deletedfiles += ($bfile | select name,directory,creationtime)
                                }else{
                                write-host "$ComputerName C:\ Directory does not have Trojan files" -ForegroundColor Green
                                }
                            }


Remove-MalFiles
