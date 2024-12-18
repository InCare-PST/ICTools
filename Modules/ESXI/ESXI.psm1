function Update-EsxiHost {
    [cmdletbinding()]
        param(

            [string]$server,

            [string]$depot = "https://hostupdate.vmware.com/software/VUM/PRODUCTION/main/vmw-depot-index.xml",

            [string]$vhprofile,

            [switch]$updatevib,

            [string]$vibname,

            [string]$vibversion

        )

    Begin{
        $powermodule = Get-InstalledModule -Name "vmware.powercli" -ErrorAction SilentlyContinue
        if (!([bool]$powermodule)){
            $title = 'PowerCLI Module'
            $message = 'PowerCLI was not detected, would you like to install?'
            $yes = New-Object System.Management.Automation.Host.ChoiceDescription '&Yes'
            $no = New-Object System.Management.Automation.Host.ChoiceDescription '&No'
            $options = [System.Management.Automation.Host.ChoiceDescription[]] ($yes, $no)
            $result = $host.ui.PromptForChoice($title, $message, $options, 1)

            if($result -eq 0){
                Install-Module -Name vmware.powercli -Force
            }
            else {
                Write-Host "Need VMWare PowerCLi to continue." -ForegroundColor Red
                Exit
            }
        }
        $creds = Get-Credential -Message "Please Enter EXSi Host Credentials"
        Connect-VIServer -Credential $creds -Server $server -Force
        $VH = Get-VMHost
        if (!([bool]$vhprofile)){
            $listargs = $EXSCLI.software.sources.profile.list.CreateArgs()
            $listargs.depot = $depot
            $VHProfiles = $EXSCLI.software.sources.profile.list.Invoke($listargs)
            $profileNames = $VHProfiles | Where-Object {$_.name -match "$($vh.version).*standard"} | Sort-Object -Property name | Select-Object -Property name  -Last 3

            $profTitle = "Profile Choices"
            $profMessage = "Please Choose a profile to install"
            $choice01 = [System.Management.Automation.Host.ChoiceDescription]("$($profilenames[0].Name) &1")
            $choice02 = [System.Management.Automation.Host.ChoiceDescription]("$($profilenames[1].Name) &2")
            $choice03 = [System.Management.Automation.Host.ChoiceDescription]("$($profilenames[2].Name) &3")
            $profOptions = [System.Management.Automation.Host.ChoiceDescription[]]($choice01,$choice02,$choice03)
            $profResults = $host.UI.PromptForChoice($profTitle, $profMessage, $profOptions, 0) + 1
            $vhprofile = $($profilenames[$profResults-1].Name)
        }
    }

    process{
        $esxcli = Get-EsxCli -V2
        #vib update
        if ($updatevib) {
            $vibargs = $esxcli.software.vib.update.CreateArgs()
            $vibargs.depot = $depot
            $vibargs.vibname = "$($vibname):$($vibversion)"
            $esxcli.software.vib.update.invoke($vibargs)
            }
        #profile update
        else {
            $argsupdate = $esxcli.software.profile.update.CreateArgs()
            $argsupdate.depot = $depot
            $argsupdate.profile = $vhprofile
            $esxcli.software.profile.update.invoke($argsupdate)
            }
    }

    end{ 
        Disconnect-VIServer      
    <#
        foreach ($VM in $VMS) {
            if($vm.PowerState -eq "PoweredOn"){
                Shutdown-VMGuest -VM $VM
            }
            Shutdown-VMGuest
        }
        
        Add-EsxSoftwareDepot https://hostupdate.vmware.com/software/VUM/PRODUCTION/main/vmw-depot-index.xml
        $profiles = Get-EsxImageProfile | Where-Object {$_.name -match "($($VH.version)).*standard"}

        $esxcli = $VH | Get-EsxCli -V2
    #>
    }
}
Export-ModuleMember -Function Update-EsxiHost