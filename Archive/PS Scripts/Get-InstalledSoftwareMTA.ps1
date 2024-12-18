#﻿$date = (get-date).AddDays(-60)
$getcomputers = get-content -path c:\temp\online.txt
$pool = [RunspaceFactory]::CreateRunspacePool(1, [int]$env:NUMBER_OF_PROCESSORS + 6)
$pool.ApartmentState = "MTA"
$pool.Open()
$runspaces = @()
$scriptblock = {
    Param(
        $comp
            )

    $computers = ($getcomputers | select -ExpandProperty Name)
    $FileName = $Date.tostring("dd-MM-yyyy")+" "+"SoftwareList.csv"
    $array = @()
    $UninstallKey="SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
    $type = [Microsoft.Win32.RegistryHive]::LocalMachine
    $reg=[microsoft.win32.registrykey]::OpenRemoteBaseKey($Type,$comp)
    $regkey=$reg.OpenSubKey($UninstallKey)
    $subkeys=$regkey.GetSubKeyNames()
          foreach($key in $subkeys){
            $thisKey=$UninstallKey+"\\"+$key
            $thisSubKey=$reg.OpenSubKey($thisKey)

              $obj = New-Object PSObject
              $obj | Add-Member -MemberType NoteProperty -Name "ComputerName" -Value $pc
              $obj | Add-Member -MemberType NoteProperty -Name "DisplayName" -Value $($thisSubKey.GetValue("DisplayName"))
              $obj | Add-Member -MemberType NoteProperty -Name "DisplayVersion" -Value $($thisSubKey.GetValue("DisplayVersion"))
              $obj | Add-Member -MemberType NoteProperty -Name "InstallLocation" -Value $($thisSubKey.GetValue("InstallLocation"))
              $obj | Add-Member -MemberType NoteProperty -Name "Publisher" -Value $($thisSubKey.GetValue("Publisher"))
              $obj | Add-Member -MemberType NoteProperty -Name "InstanceId" -Value $($thisSubKey.GetValue("InstanceId"))
              $obj | Add-Member -MemberType NoteProperty -Name "SystemComponent" -Value $($thisSubKey.GetValue("SystemComponent"))

              $array += $obj

        }
        }

foreach($comp in $computers) {
    #Write-host "$comp temp"
    $runspace = [PowerShell]::Create()
    $null = $runspace.AddScript($scriptblock)
    $null = $runspace.AddArgument($comp.name)
    $runspace.RunspacePool = $pool
    $runspaces += [PSCustomObject]@{ Pipe = $runspace; Status = $runspace.BeginInvoke() }
}

$array = while ($runspaces.Status -ne $null){
    $completed = $runspaces | Where-Object { $_.Status.IsCompleted -eq $true }
    foreach ($runspace in $completed)
    {
        $runspace.Pipe.EndInvoke($runspace.Status)
        $runspace.Status = $null
    }
}


$installedSoftware = $array.where({$_.DisplayName})
return $installedSoftware | ft -Auto

$pool.Close()
$pool.Dispose()
