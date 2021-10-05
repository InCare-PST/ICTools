function update-EsxiHost {
    [cmdletbinding()]
        param(

            [string]$server


        )

Begin{
    $powermodule = Get-InstalledModule -Name "vmware.powercli" -ErrorAction SilentlyContinue
    if!([bool]$powermodule){
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


}
process{}
end{
    

    Connect-VIServer -Credential $creds -Server $server -Force
    $VH = Get-VMHost
    $VMS = Get-VM
    foreach ($VM in $VMS) {
        if($vm.PowerState -eq "PoweredOn"){
            Shutdown-VMGuest -VM $VM
        }
        Shutdown-VMGuest
    }
     
    Add-EsxSoftwareDepot https://hostupdate.vmware.com/software/VUM/PRODUCTION/main/vmw-depot-index.xml
    $profiles = Get-EsxImageProfile | Where-Object {$_.name -match "($($VH.version)).*standard"}

    $esxcli = $VH | Get-EsxCli -V2
}

}
