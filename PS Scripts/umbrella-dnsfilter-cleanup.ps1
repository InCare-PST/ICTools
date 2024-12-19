$DNSA = Get-Service | Where-Object {$_.DisplayName -like "DNS Agent"}
$URC = Get-Service | Where-Object {$_.DisplayName -like "*Umbrella*"}
$connadapt = Get-NetAdapter | Where-Object Status -eq "Up" | Get-DnsClientServerAddress -AddressFamily IPv4
$good = $connadapt | Where-Object ServerAddresses -ne $null

function UninstallUmbrella{
    Add-Type -AssemblyName PresentationCore,PresentationFramework
    $ButtonType = [System.Windows.MessageBoxButton]::YesNo
    $MessageboxTitle = "Uninstall Umbrella?"
    $Messageboxbody = "Do you want to uninstall Umbrella"
    $MessageIcon = [System.Windows.MessageBoxImage]::Question
    $answer = [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)
    if ($answer -eq "Yes"){
        wmic product where 'name like "%%Umbrella%%"' call uninstall
    }else{
        write-host "Please remedy this as soon as possible!"
    }
}

if([bool]$dnsa -and $DNSA.status -eq "Running"){write-host $($dnsa) service installed and running}
if([bool]$dnsa -and $DNSA.status -eq "Stopped"){write-host $($dnsa) service installed and stopped}
if([bool]$urc-and $urc.status -eq "Running"){write-host $($urc.displayname) service installed and running}
if([bool]$urc-and $urc.status -eq "Stopped"){write-host $($urc.displayname) service installed and stopped}
if($dnsa.status -eq "Running" -and $urc.status -eq "Running"){
    write-host "Both $($urc.displayname) and $($dnsa.DisplayName) is running! Starting remediation" -ForegroundColor Red
#Remediation
    foreach($g in $good){
        if($g.ServerAddresses -notcontains "127.0.0.2"){
            $wrong = $True
        }
    }
    if([bool]$wrong){
        #Stop & Disable Umbrella
        if($URC.StartupType -ne "Disabled"){
            Set-Service $URC.name -StartupType Disabled
            Stop-Service $URC -Force
        }
        #DNS Filter 
        if($DNSA.StartupType -eq "Disabled"){
            Set-Service $DNSA -StartupType AutomaticDelayedStart
            Start-service $DNSA
        }else{
            if($DNSA.Status -eq 'Stopped'){
            Start-Service $DNSA
            }else{
            Restart-Service $DNSA -Force
            }
        }
    }
    #Uninstall Umbrella?
        UninstallUmbrella
}