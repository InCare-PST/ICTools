function Get-InstalledSoftware {
<#
Synopsis Get List of Installed Software JTG
#>


[cmdletbinding()]
    param(
        [switch]$Export,
        [switch]$Display,
        [string]$Path="C:\temp",
        [switch]$Showall
        )


Begin{
Import-Module ActiveDirectory
$date = (get-date).AddDays(-60)
$getcomputers = Get-ADComputer -Filter * -Properties LastLogonDate,OperatingSystem | Where-Object lastlogondate -GE $date
$computers = ($getcomputers | Select-Object -ExpandProperty Name)
$FileName = $Date.tostring("dd-MM-yyyy")+" "+"SoftwareList.csv"
$array = @()
}
Process{
foreach($pc in $computers){


    $UninstallKey=”SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall”
    $type = [Microsoft.Win32.RegistryHive]::LocalMachine
    $reg=[microsoft.win32.registrykey]::OpenRemoteBaseKey($Type,$pc)
    $regkey=$reg.OpenSubKey($UninstallKey)
    $subkeys=$regkey.GetSubKeyNames()
      foreach($key in $subkeys){
        $thisKey=$UninstallKey+”\\”+$key
        $thisSubKey=$reg.OpenSubKey($thisKey)

          $obj = New-Object PSObject
          $obj | Add-Member -MemberType NoteProperty -Name “ComputerName” -Value $pc
          $obj | Add-Member -MemberType NoteProperty -Name “DisplayName” -Value $($thisSubKey.GetValue(“DisplayName”))
          $obj | Add-Member -MemberType NoteProperty -Name “DisplayVersion” -Value $($thisSubKey.GetValue(“DisplayVersion”))
          $obj | Add-Member -MemberType NoteProperty -Name “InstallLocation” -Value $($thisSubKey.GetValue(“InstallLocation”))
          $obj | Add-Member -MemberType NoteProperty -Name “Publisher” -Value $($thisSubKey.GetValue(“Publisher”))
          $obj | Add-Member -MemberType NoteProperty -Name "InstanceId" -Value $($thisSubKey.GetValue("InstanceId"))
          $obj | Add-Member -MemberType NoteProperty -Name "SystemComponent" -Value $($thisSubKey.GetValue("SystemComponent"))

          $array += $obj

    }

}}
End{
  if($Export){
  Write-Host -ForegroundColor Green ("Exporting to CSV..." + "$path\$Filename")
  if(!$Showall){
  $array | Where-Object { $_.DisplayName -and $_.SystemComponent -ne 1 } | Select-Object ComputerName, DisplayName, DisplayVersion, Publisher, InstanceId, InstallLocation, SystemComponent | export-csv -path "$path\$filename"
  }else{
  $array | Where-Object { $_.DisplayName } | Select-Object ComputerName, DisplayName, DisplayVersion, Publisher, InstanceId, InstallLocation, SystemComponent | export-csv -path "$path\$filename"
  }
}
  if($Display){
    if(!$showall){ $array | Where-Object { $_.DisplayName -and $_.SystemComponent -ne 1 } | Select-Object ComputerName, DisplayName, DisplayVersion, Publisher, InstanceId | Format-Table -auto
  }
  else{ $array | Where-Object { $_.DisplayName } | Select-Object ComputerName, DisplayName, DisplayVersion, Publisher, InstanceId | Format-Table -auto
  }
}
}
}
Get-InstalledSoftware
