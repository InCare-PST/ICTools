function Get-SubscriptionInfo{
    param(

        [string]$path,

        [string]$clientname = "",

        [string]$scope = "User.Read.All,Organization.Read.All,AuditLog.Read.All,Directory.Read.All,Reports.Read.All,ReportSettings.ReadWrite.All",

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

        #create temp file path for usage report csv
        $tempusagefile = $path + "`\" + "temporaryexportfile.csv"

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
       
        If(Get-Module -ListAvailable Microsoft.Graph.Beta.Users){
            Import-Module Microsoft.Graph.Beta.Users
        }else{
            Write-Host "Required Microsoft Module not installed. Please run 'Install-Module Microsoft.Graph.Beta'" -ForegroundColor Red
            exit
        }    
    
        # Check to see if neccessary modules have been installed.
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
        #Retrieve the current "Concealed reports setting"
        $reportsetting = Get-MgBetaAdminReportSetting       
    }

    process{

        if($reportsetting.DisplayConcealedNames){
            $report_params = @{
                displayConcealedNames = $false
            }
            Update-MgBetaAdminReportSetting -BodyParameter $report_params
            #Write-Host "Changing Concealed Report settings to export data." -ForegroundColor Green
        }
        # Retrieve information for each mailbox
        try {
            $mailboxes = Get-MgBetaUser -All -Property signinactivity -ErrorAction Stop -ErrorVariable NoSignin
        }
        catch {
            Write-Host "Unable to get Last Logon date. Most likely caused by a free level of Entra ID instead of Premium." -ForegroundColor Yellow
            $mailboxes = Get-MGBetaUser -All
        }
        # Retrieve usage report information
        Get-MgBetaReportMailboxUsageDetail -Period D7 -OutFile $tempusagefile
        # Import the data we just exported because someone at Microsoft is an idiot
        $usageimport = Import-Csv -Path $tempusagefile
        # Remove the temporary file we just created beause the command forces us to export it.
        Remove-Item -Path $tempusagefile -Force
        # Format and export the information
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

        $subskus = Get-MgBetaSubscribedSku -All

        $subscribtionexport = foreach($subsku in $subskus){
            $basesku = $subsku.skuid
            $friendlyname = $planMapping | Where-Object {$_.GUID -eq $basesku} | Select-Object -First 1 | Select-Object -ExpandProperty Product_Display_Name

            [PSCustomObject]@{
                License = $friendlyname
                Enabled = $subsku.PrepaidUnits.Enabled
                Assigned = $subsku.ConsumedUnits
                Expired = $subsku.PrepaidUnits.Suspended
                Available = $subsku.prepaidunits.enabled - $subsku.consumedUnits
            }
        }
        # Format Usage Data
        $exportedusage = foreach($user in $usageimport){
            $gibibyte = $user."Storage Used (Byte)"/[math]::Pow(1024, 3)
            $mebibyte = $user."Storage Used (Byte)"/[math]::Pow(1024, 2)
        
            [PSCustomObject]@{
                "Display Name" = $user."Display Name"
                "User Principal Name" = $user."User Principal Name"
                "Storage Used(MebiByte)" = $mebibyte
                "Storage Used(GibiByte)" = $gibibyte
                "Has Archive" = $user."Has Archive"
                "Created Date" = $user."Created Date"
                "Is Deleted" = $user."Is Deleted"
                "Deleted Date" = $user."Deleted Date"
                "Recipient Type" = $user."Recipient Type"
        
            }
        }
        #Export to Excel file 
        $licensedAccounts | Export-Excel $exportedFile -AutoSize -TableName Licensed -TableStyle Medium2 -WorksheetName "O365 Licensed Accounts"

        $unlicensedAccounts | Export-Excel $exportedFile -AutoSize -TableName UnLicensed -TableStyle Medium2 -WorksheetName "O365 UnLicensed Accounts"

        $subscribtionexport | Export-Excel $exportedFile -AutoSize -StartRow $startingrow -TableName Subscriptions -TableStyle Medium2 -WorksheetName "O365 Licensed Accounts" 

        $exportedusage | Export-Excel -path $exportedFile -AutoSize -TableName Usage -TableStyle Medium2 -WorksheetName "Mailbox Usage Report"
    }

    end{
        #Put the report sesttings back the way we found them.
        if($reportsetting.DisplayConcealedNames){
            $report_params = @{
                displayConcealedNames = $true
            }
            Update-MgBetaAdminReportSetting -BodyParameter $report_params
            #Write-Host "Changing Concealed Report settings back to previuos settings." -ForegroundColor Green
        }
        #Disconnect from Graph
        Disconnect-MgGraph -InformationAction SilentlyContinue -ErrorAction SilentlyContinue
    }
}
Get-SubscriptionInfo

<#
Get-MgBetaAdminReportSetting
Update-MgBetaAdminReportSetting
$params = @{
	displayConcealedNames = $false
}
Update-MgBetaAdminReportSetting -BodyParameter $params
$scope = "User.Read.All,Organization.Read.All,AuditLog.Read.All,Directory.Read.All,Reports.Read.All,ReportSettings.ReadWrite.All"
 #>