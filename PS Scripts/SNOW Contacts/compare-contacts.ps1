function Compare-SnowContacts {
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