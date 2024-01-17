function Find-Folders {
    [Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
    [System.Windows.Forms.Application]::EnableVisualStyles()
    $browse = New-Object System.Windows.Forms.FolderBrowserDialog
    $browse.SelectedPath = "C:\"
    $browse.ShowNewFolderButton = $false
    $browse.Description = "Select a directory for file export"

    $loop = $true
    while($loop)
    {
        if ($browse.ShowDialog() -eq "OK")
        {
        $loop = $false
		
		#Insert your script here
		
        } else
        {
            $res = [System.Windows.Forms.MessageBox]::Show("You clicked Cancel. Would you like to try again or exit?", "Select a location", [System.Windows.Forms.MessageBoxButtons]::RetryCancel)
            if($res -eq "Cancel")
            {
                #Ends script
                return
            }
        }
    }
    $browse.SelectedPath
    $browse.Dispose()
}

function Get-SubscriptionInfo{
    param(

        [string]$path,

        [string]$clientname = "",

        [string]$scope = "User.Read.All,Organization.Read.All,AuditLog.Read.All,Directory.Read.All",

        [string]$filename = "MappingFile.csv"

    )

    begin{

        #Making sure there is not an active MGGraph connection
        Disconnect-MgGraph -InformationAction SilentlyContinue -ErrorAction SilentlyContinue

        $date = Get-Date
        
        #determine working folder
        if(![bool]$path){
            $path = Find-Folders
        }

        #create filename
        $xlsxfilename = $date.tostring("dd-MM-yyyy") + " " + $clientname + "`.xlsx"

        # create full path for export files
        $exportedFile = $path + "`\" + $xlsxfilename

        #check if path exists. If not, create it.
        if (!(Test-Path $Path)) {
            Write-Host "Creating Directory $Path" -ForegroundColor Yellow
            New-Item -Path $Path -ItemType Directory
        }

        #check to see if file already exists. If it does prompt the user to see if they want the existing file deleted.
        if(Test-Path $exportedFile){
            Write-Host "File $($xlsxfilename) already exists. Would you like to delete it?" -ForegroundColor Yellow
            
            $wshell = New-Object -ComObject Wscript.Shell
            $answer = $wshell.Popup("Delete $($xlsxfilename)?",0,"Delete File",32+4)
        }

        #delete file or exit script
        if($answer -eq 6){
            Remove-Item -Path $exportedFile -Force
        } elseif($answer -eq 7){
            Write-Host "Please rename or remove file and run command again." -ForegroundColor Yellow
            exit
        }


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
            Write-Host "Required Microsoft Module not installed. Please run Install-Module 'Microsoft.Graph.Beta.Identity.DirectoryManagement'" -ForegroundColor Red
            exit
        }

        If(Get-Module -ListAvailable ImportExcel){
            Import-Module ImportExcel
        }else{
            Write-Host "Required Microsoft Module not installed. Please run 'Install-Module ImportExcel'" -ForegroundColor Red
            exit
        }
        # Connect to Microsoft Graph using Connect-MgGraph with specified scope
        Connect-MgGraph -Scopes $scope -NoWelcome
       
    }

    process{

        # Step 2: Retrieve information for each mailbox. Add LastLogon time if selected.
        <#if($LastLogon){
            $mailboxes = Get-MgBetaUser -All -Property signinactivity
        }
        else {
            $mailboxes = Get-MGBetaUser -All
        }#>
        try {
            $mailboxes = Get-MgBetaUser -All -Property signinactivity -ErrorAction Stop -ErrorVariable NoSignin
        }
        catch {
            Write-Host "Unable to get Last Logon date. Most likely caused by a free level of Entra ID instead of Premium." -ForegroundColor Yellow
            $mailboxes = Get-MGBetaUser -All
        }
        # Step 3: Format and export the information
        $exportedData = foreach ($mailbox in $mailboxes) {
            $licenses = $mailbox.assignedlicenses.skuid
            $assignedlicenses = @()
            foreach($license in $licenses){
                $friendlyname = $planmapping | Where-Object {$_.GUID -eq $license} | Select-Object -First 1 | Select-Object Product_Display_Name
                $assignedlicenses += $friendlyname
            }
            $liclist = $assignedlicenses.Product_Display_Name -join "+"
            $officephone = $mailbox.BusinessPhones -join ";"
            
            [PSCustomObject]@{
                DisplayName = $mailbox.displayName
                FirstName = $mailbox.givenName
                LastName = $mailbox.surname
                Enabled = $mailbox.AccountEnabled
                "Last Logon" = $mailbox.SignInActivity.LastSignInDateTime
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

        #Filter the list based on those with and without licenses
        $licensedAccounts = $exportedData | Where-Object {$_.Licenses -ne ""}
        $unlicensedAccounts = $exportedData | Where-Object {$_.Licenses -eq ""}

        #find number of licensed accounts and set starting row for subscriptions
        $startingrow = $licensedAccounts.count + 5

        # Export the data to a CSV file
        # $exportedData | Export-Csv -Path $mailboxexport -NoTypeInformation

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
        #$subscribtionexport | Where-Object {$_.License -ne $null} |  export-csv -Path $licenseexport -NoTypeInformation -Force

        #Export to Excel file 
        $licensedAccounts | Export-Excel $exportedFile -AutoSize -TableName Licensed -TableStyle Medium2 -WorksheetName "O365 Licensed Accounts"

        $unlicensedAccounts | Export-Excel $exportedFile -AutoSize -TableName UnLicensed -TableStyle Medium2 -WorksheetName "O365 UnLicensed Accounts"

        $subscribtionexport | Export-Excel $exportedFile -AutoSize -StartRow $startingrow -TableName Subscriptions -TableStyle Medium2 -WorksheetName "O365 Licensed Accounts" 
    }

    end{

        Disconnect-MgGraph -InformationAction SilentlyContinue -ErrorAction SilentlyContinue
    }


}
Get-SubscriptionInfo -clientname "ASID"
