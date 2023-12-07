# Install the required modules
Install-Module -Name Microsoft.Graph.Authentication -Force -AllowClobber

# Import the required modules
Import-Module Microsoft.Graph.Authentication

# Your app registration details
$clientID = "your-client-id"
$tenantID = "your-tenant-id"
$scope = "User.Read.All,Organization.Read.All"  # Specify the "User.Read" scope for basic user profile read access

# Connect to Microsoft Graph using Connect-MgGraph with specified scope
Connect-MgGraph -ClientId $clientID -TenantId $tenantID -Scopes $scope

# Define the URL of the mapping file hosted online
$mappingFileUrl = "https://download.microsoft.com/download/e/3/e/e3e9faf2-f28b-490a-9ada-c6089a1fc5b0/Product%20names%20and%20service%20plan%20identifiers%20for%20licensing.csv"

# Download the mapping file
Invoke-RestMethod -Uri $mappingFileUrl -OutFile "C:\temp\MappingFile.csv"

# Load the mapping from the downloaded CSV file
$planMapping = Import-Csv "C:\temp\MappingFile.csv"

# Step 2: Retrieve information for each mailbox
$mailboxes = Get-MgUser -All

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
$exportedData | Export-Csv -Path "C:\Path\To\Exported\MailboxInfo.csv" -NoTypeInformation

Import-Module Microsoft.Graph.beta.Identity.DirectoryManagement

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

$subscribtionexport | Where-Object {$_.License -ne $null} |  export-csv -Path C:\temp\Stansell_Licenses.csv -NoTypeInformation -Force

function Export-TenantUsers {
    param(
        [Parameter(Mandatory=$true)]
        [string]$AppId,

        [Parameter(Mandatory=$true)]
        [string]$AppSecret,

        [Parameter(Mandatory=$true)]
        [string]$TenantId
    )

    # Import required module
    Import-Module Microsoft.Graph.Users.Actions

    # Connect to Microsoft Graph
    $credential = New-Object System.Management.Automation.PSCredential($AppId, (ConvertTo-SecureString $AppSecret -AsPlainText -Force))
    Connect-MgGraph -Credential $credential -TenantId $TenantId -Scopes Domain.Read.All

    # Get the list of users
    $users = Get-MgUser -All

    # Create an empty array to hold user data
    $userData = @()

    # Loop through each user
    foreach ($user in $users) {
        # Get user licenses
        $licenses = $user.AssignedLicenses.SkuId

        # Create a PSObject for each user
        $userObj = New-Object PSObject
        $userObj | Add-Member -MemberType NoteProperty -Name "Display Name" -Value $user.DisplayName
        $userObj | Add-Member -MemberType NoteProperty -Name "UPN" -Value $user.UserPrincipalName

        # Iterate over each license and add it to the user object
        foreach ($license in $licenses) {
            $userObj | Add-Member -MemberType NoteProperty -Name "License" -Value $license
        }

        # Add the user object to the array
        $userData += $userObj
    }

    # Export the data to a CSV file
    $userData | Export-Csv -Path .\UserData.csv -NoTypeInformation
} 