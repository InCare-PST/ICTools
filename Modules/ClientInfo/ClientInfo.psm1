function Get-ClientInfo {
    <#
    .SYNOPSIS
    Collects account information and exports to csv
    .DESCRIPTION
    Cmdlet for exporting current enabled users to .csv file to be examined by client for updating.
    .PARAMETER ClientName
    Name of the client. This will be used for the exported file name. If not declared the script will prompt for it.
    .PARAMETER path
    Declares the folder location for the exported csv file. Defaults to "C:\temp"
    .EXAMPLE
    Get-ClientInfo
    .EXAMPLE
    Get-ClientInfo -ClientName ExampleCompany -path C:\users\username\documents
    #>
    [CmdletBinding()]
    param (

        [string]$ClientName,

        [string]$path = "C:\temp"

    )
    Begin {
        if (![bool]$ClientName) {
            $ClientName = Read-Host -Prompt "Please enter Client Name"
        }
        $userlist = Get-ADUser -Filter * -Properties MobilePhone, OfficePhone, Enabled, displayname
    }
    Process {
        $EnabledUsers = $userlist | Where-Object { $_.enabled -eq $true -and [bool]($_.surname) -eq $true -and $_.name -notmatch "360" } 
        $EnabledUsers | Select-Object @{N = 'Name'; E = { $_.displayname } }, @{N = 'Email'; E = { $_.userprincipalname } }, MobilePhone, OfficePhone, Enabled | Export-Csv -Path $path\$ClientName.csv -NoTypeInformation
    }
    End {
        
    }
}
function Update-ClientInfo {
    <#
    .SYNOPSIS
    Cmdlet updates and or disables users. 
    .DESCRIPTION
    Cmdlet updates information based on a CSV that is exported using Get-ClienInfo. The updated fields are Mobile Number, Office Number, and if the account should be disabled. Numbers will be formatted as +1########## Reports will be placed in a zip file in the directory determined by the "Path" Parameter.
    .PARAMETER path
    Provides the base path to the csv file with the updated Contact phone info. Defaults to C:\temp
    .PARAMETER filename
    Provides the name of the CSV file. The default is clietnupdate.csv
    .PARAMETER disable
    If this parameter is enabled then any user that is marked to be disabled in the csv file will be disabled.
    .PARAMETER apply
    Used to apply the mobile and office numbers in the CSV. By default the cmdlet will only report on proposed changes.
    .EXAMPLE
    Update-ClientInfo
    .EXAMPLE
    Update-ClientInfo -disable -apply
    .EXAMPLE
    Update-ClientInfo -path c:\users\usersname\documents -filename clientname.csv
    #>
    [CmdletBinding()]
    Param (

        [string]$path = "c:\temp\",

        [string]$filename = "clientupdate.csv",

        [switch]$disable = $false,

        [switch]$apply = $false
            
    )
    Begin {
        if (Test-Path -Path $path\$filename) {
            $userinfo = Import-Csv -Path $path\$filename
        }
        else {
            Write-Error "$filename does not exist at $path. Cannot update contact information."
            Break
        }

        $adusers = Get-ADUser -Filter * -Properties MobilePhone, OfficePhone

        $date = Get-Date -UFormat %e-%m-%G-%H.%M

        $workingpath = "$path\ClientUpdate$date"

        New-Item -Path $workingpath -Type Directory
        
    }
    Process {
        foreach ($user in $userinfo) {
            $adaccount = $adusers | Where-Object { $_.UserPrincipalName -match $user.email }
            if ([bool]$adaccount) {
                if ($user.enabled -eq "FALSE") {
                    if (($adaccount.enabled -eq $true) -and ($disable -eq $false)) {
                        $adaccount | Select-Object name, UserPrincipalName, enabled | Export-Csv -Path $workingpath\accountstodisable.csv -NoTypeInformation -Append
                    }
                    elseif (($adaccount.enabled -eq $true) -and ($disable -eq $true)) {
                        $adaccount | Set-ADUser -Enabled $false
                        $disabledaccount = Get-ADUser -Filter * -Properties enabled | Where-Object { $_.name -match $adaccount.name }
                        $disabledaccount | Select-Object name, UserPrincipalName, enabled | Export-Csv -Path $workingpath\accountsdisable.csv -NoTypeInformation -Append
                    }
                }
                else {
                    if (([bool]$user.Mobilephone) -or ([bool]$user.OfficePhone)) {
                        $addcommand = @{}
                        $newmobile = ""
                        $newoffice = ""
                        if ([bool]$user.Mobilephone) {
                            $tempmobile = $user.mobilephone -replace "\D+"
                            if ($tempmobile.length -eq 10) {
                                $newmobile = "{0:+1##########}" -f [int64]$tempmobile
                                $addcommand['MobilePhone'] = $newmobile
                            }
                            elseif ($tempmobile.length -eq 11) {
                                $newmobile = "{0:+###########}" -f [int64]$tempmobile
                                $addcommand['MobilePhone'] = $newmobile
                            }
                            else {
                                Write-Host "$($user.name) with mobile number $($user.Mobilephone) does not match required formatting."
                            }
                        }
                        if ([bool]$user.OfficePhone) {
                            $tempoffice = $user.OfficePhone -replace "\D+"
                            if ($tempoffice.length -eq 10) {
                                $newoffice = "{0:+1##########}" -f [int64]$tempoffice
                                $addcommand['OfficePhone'] = $newoffice
                            }
                            elseif ($tempoffice.length -eq 11) {
                                $newoffice = "{0:+###########}" -f [int64]$tempoffice
                                $addcommand['OfficePhone'] = $newoffice
                            }
                            else {
                                Write-Host "$($user.name) with Office number $($user.Businessphone) does not match required formatting."
                            }
                        }
                        #$adaccount | Select-Object name
                        $props = @{
                            username      = $adaccount.name
                            snowname      = $user.name
                            enabled       = $adaccount.enabled
                            currentmobile = $adaccount.mobilephone
                            newmobile     = $newmobile
                            currentoffice = $adaccount.OfficePhone
                            newoffice     = $newoffice
                        }
                        $tempobject = New-Object psobject -Property $props
                        if ($apply -eq $false) {
                            $tempobject | Select-Object username, snowname, enabled, currentmobile, newmobile, currentoffice, newoffice | Export-Csv -Path $workingpath\proposed-mobile-update.csv -NoTypeInformation -Append
                        }
                        elseif ($apply -eq $true) {
                            if (([bool]$newmobile) -and ([bool]$newoffice)) {
                                Set-ADUser -Identity $adaccount.SamAccountName -OfficePhone $newoffice -MobilePhone $newmobile
                            }
                            elseif (([bool]$newmobile) -and (![bool]$newoffice)) {
                                Set-ADUser -Identity $adaccount.SamAccountName -MobilePhone $newmobile
                            }
                            elseif ((![bool]$newmobile) -and ([bool]$newoffice)) {
                                Set-ADUser -Identity $adaccount.SamAccountName -OfficePhone $newoffice
                            }
                            #Set-ADUser -Identity $adaccount.SamAccountName $addcommand
                            $tempobject | Select-Object username, snowname, enabled, currentmobile, newmobile, currentoffice, newoffice | Export-Csv -Path $workingpath\mobile-update.csv -NoTypeInformation -Append
                        }
                    }
                }
            }
            else {

                Write-Host "Cannot find AD account for $($user.name) with user id $($user.userid)" -ForegroundColor Red

                $user | Export-Csv -Path $workingpath\noaccount.csv -NoTypeInformation -Append

            }
        }
    }
    End {
        Compress-Archive -LiteralPath $workingpath -DestinationPath $path\ClientUpdate$date.zip
        if (Test-Path -Path $path\ClientUpdate$date.zip) {
            Remove-Item -LiteralPath $workingpath -Recurse -Force
        }
    }
}
function Compare-SnowContacts {
    <#
    .SYNOPSIS
    Compares contacts from SNOW to Client's AD
    .DESCRIPTION
    This cmdlet will compare an exported list of contacts from SNOW to local client AD to determine if there are any disabled users currently approved in SNOW for call in.
    .PARAMETER path
    Provides the base path to the csv file.
    .PARAMETER file
    Declares the name of the csv file. Default is SnowExport.csv
    .PARAMETER clientname
    sets the name of the client for the exported report. If not set it will be promopted for.
    .EXAMPLE
    Compare-SnowContacts
    .EXAMPLE
    Compare-SnowContacts -clientname "Client Name"
    #>
    [CmdletBinding()]
    param (
        [string]$path = "c:\temp",

        [string]$file = "SnowExport.csv",

        [string]$clientname

    )
    begin {
        if (!(Test-Path $path\$file)) {
            Write-Error "$($path)\$($file) does not exist. Script cannot proceed without source information."
            Exit
        }
        else {
            $SnowInfo = Import-Csv -Path $path\$file
        }
        if (![bool]$clientname) {
            $clientname = Read-Host "Please enter client name."
        }
        $adusers = Get-ADUser -Filter * -Properties enabled, mail
        $approved = $SnowInfo | Where-Object { $_.u_approval_status -eq "Approved" }
    }
    process {
        foreach ($user in $approved) {
            $useraccount = $adusers | Where-Object { $_.mail -match $user.email }
            $props = @{
                Name     = $useraccount.Name
                SNOWName = $user.name
                Enabled  = $useraccount.enabled
                Approved = $user.u_approval_status
            }
            $tempobject = New-Object -TypeName psobject -Property $props
            $tempobject | Where-Object { $_.enabled -eq $false -and $_.Approved -eq "Approved" } | Select-Object Name, SNOWName, Enabled, Approved | Export-Csv -Path "$($path)\$($clientname)"+"-SnowCompare.csv" -NoTypeInformation -Append
        }
        end {
        }
    }
}
Function Update-CIModule {
    [cmdletbinding()]
    param(

        [switch]$Beta,

        [string]$PSMName = "ClientInfo"
    )

    Begin {
  
        #Production Variables
        $psmurl = "https://raw.githubusercontent.com/InCare-PST/ICTools/master/Modules/$($PSMName)/$($PSMName).psm1"
        $psdurl = "https://raw.githubusercontent.com/InCare-PST/ICTools/master/Modules/$($PSMName)/$($PSMName).psd1"
            
        #Determine current Module path
        $modulepaths = $env:PSModulePath.Split(";")
        $instance = 0
        foreach ($mpath in $modulepaths) {
            if (test-path $mpath\$PSMName\$PSMName.psm1) {
                $instance = $instance + 1
                if ($instance -eq 1) {
                    $installpath = $mpath
                }
                elseif ($instance -gt 1) {
                    write-host "$($PSMName) Module found in multiple locations" -ForegroundColor Red
                    Write-Host "$installpath and in $mpath" -ForegroundColor Yellow
                    Exit
                }
            }
        }
        if (![bool]$installpath) {
            $installpath = $modulepaths[0]
            $installed = $false
        }
        else {
            $installed = $true
        }
        #Get MD5 hash of online files
        $wc = New-Object System.Net.WebClient
        try {
            $psmhash = Get-FileHash -InputStream ($wc.openread($psmurl)) -Algorithm MD5 -ErrorAction Stop
        }
        catch {
            Write-Host "Could not access file at $($psmurl)" -ForegroundColor Yellow
        }
        try {
            $psdhash = Get-FileHash -InputStream ($wc.openread($psdurl)) -Algorithm MD5 -ErrorAction Stop
        }
        catch {
            Write-Host "Could not access file at $($psdurl)" -ForegroundColor Yellow
        }
        #declare non-dynamic variables
        $ictpath = "$installpath\$PSMName"
        $psmfile = "$ictpath\$PSMName.psm1"
        $psdfile = "$ictpath\$PSMName.psd1"
        #$psptest = Test-Path $Profile
        #$psp = New-Item -Path $Profile -Type File -Force

        #get the file hash for existing files
        if ($installed) {
            $cpsmhash = Get-FileHash -Path $psmfile -Algorithm MD5
        }
        $psdinstalled = $true
        if (test-path -Path $psdfile) {
            $cpsdhash = Get-FileHash -Path $psdfile -Algorithm MD5
        }
        else {
            $psdinstalled = $false
        }
    }
    Process {
        #install module if not present
        if (!($installed)) {
            New-Item -Path $ictpath -ItemType directory
            $wc.DownloadFile($psmurl, $psmfile)
            $wc.DownloadFile($psdurl, $psdfile)
        }
        else {
            $updated = $true
            #compare files and replace if necessary 
            if (!($psmhash.hash -eq $cpsmhash.hash)) {
                remove-item $psmfile -Force
                $wc.DownloadFile($psmurl, $psmfile)
            }
            else {
                Write-Host "Module file is already up to date."
                $updated = $false
            }
            if ($psdinstalled) {
                if (!($psdhash.hash -eq $cpsdhash.hash)) {
                    remove-item $psdfile -Force
                    $wc.DownloadFile($psdurl, $psdfile)
                }
            }
            else {
                $wc.DownloadFile($psdurl, $psdfile)
            }
        }
    }
    End {
        #reloading module either by restarting powershell or removing and importing the module
        if ($updated) {
            write-host "Reloading $($PSMName) Module." -ForegroundColor Green
            start-sleep -seconds 2
            Import-Module $PSMName
            Remove-Module $PSMName
            Import-Module $PSMName
        }
        else {
            Write-Host "$($PSMName) Module is already up to date." -ForegroundColor Green
        }
    }    #End of Function
}
