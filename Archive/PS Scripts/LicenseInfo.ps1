#Get License Information
#$ClientName = [Microsoft.VisualBasic.Interaction]::InputBox("Enter a Client Name", "Client Name", "")
$OnlineComputers = @()
Import-Module ActiveDirectory
$date = (get-date).AddDays(-60)
$computers = Get-ADComputer -Filter * -Properties LastLogonDate,OperatingSystem | where lastlogondate -GE $date
Foreach ($computer in $computers)
{
Try
            {
                #License Info
                $LicenseInfo = Get-WmiObject SoftwareLicensingProduct -ComputerName $computer  -ErrorAction Stop | ` #-Credential $cred
                Where-Object { $_.PartialProductKey -and $_.ApplicationID -eq "55c92734-d682-4d71-983e-d6ec3f16059f" } | Select-Object PartialProductKey, Description, ProductKeyChannel, @{ N = "LicenseStatus"; E = { $lstat["$($_.LicenseStatus)"] } }
                $win32os = Get-WmiObject Win32_OperatingSystem -computer $computer  # -Credential $cred -ErrorAction Stop
                $WindowsEdition = $win32os.Caption
                $ServicePack = $win32os.CSDVersion
                $OSArchitecture = $win32os.OSArchitecture
                $BuildNumber = $win32os.BuildNumber
                $RegisteredTo = $win32os.RegisteredUser
                $ProductID = $win32os.SerialNumber
                $PartialProductKey = $LicenseInfo.PartialProductKey
                If ($LicenseInfo.ProductKeyChannel)
                {
                    $LicenseType = $LicenseInfo.ProductKeyChannel
                }
                Else
                {
                    $LicenseType = $LicenseInfo.Description.Split(",")[1] -replace " channel", "" -replace "_", ":" -replace " ", ""
                }
                $LicenseStatus = $LicenseInfo.LicenseStatus
            }
}
Out-File -FilePath .\LicenseInfo.txt -Append
