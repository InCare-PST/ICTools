function Get-MachineInfo {
    [cmdletbinding()]
    Param(
        [Parameter(ValueFromPipeline=$True)]
        [string[]]$ComputerName,

        [ValidateSet('Wsman','Dcom')]
        [string]$Protocol = "Wsman"
    )
    Begin{
        #if $ComputerName isnt specified call Get-OnlineADComps to get a list of computers
        #Computer list should be divided between WSMAN enabled and not enabled
        #list should be divided between workstation and Servers
    }
    Process{
        #Establish Runspace and execute code
        $pool = [RunspaceFactory]::CreateRunspacePool(1, [int]$env:NUMBER_OF_PROCESSORS + 100)
        $pool.ApartmentState = "MTA"
        $pool.Open()
        $runspaces = @()
        $Scriptblock = {
            param(
                $ComputerName,
                $protocol
            )
            $option = New-CimSessionOption -Protocol $protocol
            $params = @{'ComputerName'=$ComputerName
                        'SessionOption'=$option
                        'ErrorAction'='Stop'}
            Write-Verbose "Connecting to $ComputerName over $protocol"
            $session = New-CimSession @params
        }
    }
    End{
        #Handle reporting and cleanup
    }
}