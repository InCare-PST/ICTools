function Set-VMHostPassword
{
<#
.NOTES
===========================================================================
Created by: Ankush Sethi
Blog:       www.vmwarecode.com
===========================================================================
.SYNOPSIS
Recover the ESXI root/other user's Password
.DESCRIPTION
Function will recover the esxi root password using PowerCli
.PARAMETER VMHost
Enter the esxi Hotsname for which we need to recover the password.
.PARAMETER UserName
Enter the username of esxi host.
.PARAMETER Password
Enter the new password for esxi host.
.EXAMPLE
example 1>Set-VMHostPassword -VMHost (Get-VMHost homelab.vmwarecode.com) -UserName root -Password VMware123! `
example 2>Get-VMHost Homelab.vmwarecode.com|Set-VMHostPassword -UserName root -Password VMware123!
#>
param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [VMware.VimAutomation.ViCore.Impl.V1.VIObjectImpl]$VMHost,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String[]]$UserName,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]$Password

    )
process {
    try{
        $validation1=Get-VMHost $VMHost -ErrorAction Stop
    }
    catch{
        Write-Error -Message "Please check the host is part of connected vCenter or not and try again" -ErrorAction Stop
    }
    If(($validation1.ConnectionState -eq "Connected") -or ( $validation1.ConnectionState -eq "Maintenance"))
    {
        $esxcli=Get-EsxCli -VMHost $VMHost -V2
        $IDList=$esxcli.system.account.list.invoke().UserID
        If(($IDList -contains $UserName) -ne $true){Write-Error -Message "Entered Username does not exist in esxi userid list" -ErrorAction stop}
    }
    else{
        Write-Error -Message "ESXI is not connected or maintenance mode to perform the action" -ErrorAction Stop
    }
    $argu=$esxcli.system.account.set.CreateArgs()
    $argu.id=$UserName
    $argu.password=$Password
    $argu.passwordconfirmation=$Password
    $output=$esxcli.system.account.set.invoke($argu)
    }
end{
    If($output -eq $true)
        {
            Get-VIEvent -Entity (Get-VMHost $VMHost) -MaxSamples 1| Where-Object{$_.fullformattedmessage -match "Password"}|Select-Object UserLogin,Createdtime,Username,Fullformattedmessage|Format-Table -AutoSize
            $hostd=Get-Log -Key hostd -VMHost (Get-VMHost $VMHost)
            $hostd.Entries|Select-String "Password was changed for account" | Select-Object -Last 1
        }
    }
}