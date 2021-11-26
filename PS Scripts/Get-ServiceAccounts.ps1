Function Get-ServiceAccounts{
    [cmdletbinding()]
        param(

            [switch]$export,

            [string]$path = "C:\temp",

            [string]$username = "Administrator"
            
        )
    Begin{
        Write-Verbose "Getting list of online servers"
        $date = (get-date).AddDays(-60)
        $onlineservers = @()
        $offlineservers = @()
        $allservers = Get-ADComputer -filter * -Properties operatingsystem,lastlogondate | Where-Object {$_.operatingsystem -match "server" -and $_.enabled -eq $true -and $_.lastlogondate -ge $date}
        foreach ($server in $allservers){
            if (Test-Connection $server.name -Count 1 -Quiet){
                $onlineservers += $server
            }
            else{
                $offlineservers +=$server
            }
        }
    }
    Process{
        $serverNameList = $onlineservers.Name
        $serviceList = Invoke-Command -ComputerName $serverNameList {
            Get-WmiObject win32_service | Select-Object systemName,displayname,startname
        }
        $finallist = $serviceList | Where-Object {$_.startname -match $username} | Sort-Object -Property systemName
        if ($export){
             $finallist | Export-Csv -Path $path -NoTypeInformation 
        }
        else {
            $finallist
        }

        <# Commenting out, going with Invoke-Command
        $dcomopt = New-CimSessionOption -Protocol Dcom
        $wsmanopt = New-CimSessionOption -Protocol Wsman
        $wsmanerrors = @()
        $dcomerrors = @()
        Write-Verbose "Establishing Connection to servers"
        foreach($onlineserver in $onlineservers){
            Write-Verbose "Checking for WSMAN"
            If([bool](Test-WSMan -ComputerName $onlineserver.name)){
                try{
                    Write-Verbose "Attempting to connect to $onlineserver via WSMAN"
                    New-CimSession -ComputerName $onlineserver.name -SessionOption $wsmanopt -ErrorAction Stop 
                }
                catch{
                }
            }
            else{
                Write-Verbose "Attempting DCOM because WSMAN unavailable"
                try{
                    Write-Verbose "Attempting to connect to $onlineserver via DCOM"
                    New-CimSession -ComputerName $onlineserver.name -SessionOption $dcomopt -ErrorAction Stop
                }
                catch{
                
                }
            }
        }
        $services = Get-CimInstance -CimSession (Get-CimSession) -ClassName win32_service | where {$_.startname -notmatch "local|Network\sService|NetworkService" -and $_.StartName -ne $null}
    #>
    }
    End{
    
    }
}


Get-CimInstance win32_service | select name,startname,startmode