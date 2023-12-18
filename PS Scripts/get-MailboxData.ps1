function Get-TenantInfo{
    param(

        [string]$path = "C:\temp",

        [string]$clientname = "",

        [string]$scope = "User.Read.All,Organization.Read.All",

        [string]$filename = "MappingFile.csv"
    )

    begin{
        $date = Get-Date
        
        # create full path to mapping file
        $fullmappingfile = $path + "`\" + $filename

        # create full path for export files
        $mailboxexport = $path + "`\" + $clientname + "-mailbox.csv"
        $licenseexport = $path + "`\" + $clientname + "-licenses.csv"

        # Define the URL of the mapping file hosted online
        $mappingFileUrl = "https://download.microsoft.com/download/e/3/e/e3e9faf2-f28b-490a-9ada-c6089a1fc5b0/Product%20names%20and%20service%20plan%20identifiers%20for%20licensing.csv"        
    
        # Download the mapping file and import data to variable
        $planMapping = Invoke-RestMethod -Uri $mappingFileUrl | ConvertFrom-Csv -Delimiter ","

        # Load the mapping from the downloaded CSV file
        # $planMapping = Import-Csv $fullmappingfile
       
        If(Get-Module -ListAvailable Microsoft.Graph.Beta.Users){
            Import-Module Microsoft.Graph.Beta.Users
        }else{
            Write-Host "Required Microsoft Module not installed. Please run 'Install-Module Microsoft.Graph.Beta'" -ForegroundColor Red
            exit
        }
    
    
        If(Get-Module -ListAvailable Microsoft.Graph.Beta.Identity.DirectoryManagement){
            Import-Module Microsoft.Graph.Beta.Identity.DirectoryManagement
        }else{
            Write-Host "Required Microsoft Module not installed. Please run 'Microsoft.Graph.Beta.Identity.DirectoryManagement'" -ForegroundColor Red
            exit
        }
        # Connect to Microsoft Graph using Connect-MgGraph with specified scope
        Connect-MgGraph -Scopes $scope -NoWelcome
       
    }

    process{

        # Step 2: Retrieve information for each mailbox
        $mailboxes = Get-MgBetaUser -All

        # Step 3: Format and export the information
        $exportedData = foreach ($mailbox in $mailboxes) {
            $licenses = $mailbox.assignedlicenses.skuid
            $assignedlicenses = @()
            foreach($license in $licenses){
                $friendlyname = $planmapping | Where-Object {$_.GUID -eq $license} | Select-Object -First 1 | Select-Object Product_Display_Name
                $assignedlicenses += $friendlyname
            }
            $liclist = $assignedlicenses.Product_Display_Name -join "+"
            $officephone = $mailbox.BusinessPhones -join ","
            
            [PSCustomObject]@{
                DisplayName = $mailbox.displayName
                FirstName = $mailbox.givenName
                LastName = $mailbox.surname
                Enabled = $mailbox.AccountEnabled
                "Sync Enabled" = $mailbox.OnPremisesSyncEnabled
                UserType = $mailbox.userType
                Licenses = $liclist  # Use the translated friendly names
                "User Principal Name" = $mailbox.UserPrincipalName
                "Street Address" = $mailbox.StreetAddress
                City = $mailbox.City
                State = $mailbox.State
                "Postal Code" = $mailbox.PostalCode
                "Country/Region" = $mailbox.Country
                Department = $mailbox.Department
                "Office Name" = $mailbox.OfficeLocation
                "Office Phone" = $officephone
                "Mobile Phone" = $mailbox.MobilePhone
                "When Created" = $mailbox.CreatedDateTime
            }
        }

        # Export the data to a CSV file
        $exportedData | Export-Csv -Path $mailboxexport -NoTypeInformation

        $subskus = Get-MgBetaSubscribedSku -All

        $subscribtionexport = foreach($subsku in $subskus){
            $basesku = $subsku.skuid
            $friendlyname = $planMapping | Where-Object {$_.GUID -eq $basesku} | Select-Object -First 1 | Select-Object -ExpandProperty Product_Display_Name

            #$friendlyname = $friendlyname.Product_Display_Name

            [PSCustomObject]@{
                License = $friendlyname
                Enabled = $subsku.PrepaidUnits.Enabled
                Assigned = $subsku.ConsumedUnits
                Expired = $subsku.PrepaidUnits.Suspended
                Available = $subsku.prepaidunits.enabled - $subsku.consumedUnits
            }
        }
        $subscribtionexport | Where-Object {$_.License -ne $null} |  export-csv -Path $licenseexport -NoTypeInformation -Force
    }

    end{

        Disconnect-MgGraph
    }


}
Get-TenantInfo -clientname Periodontal
