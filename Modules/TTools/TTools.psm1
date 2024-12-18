Function Update-TTools {
    [cmdletbinding()]
    param(

        [switch]$Beta,

        [string]$PSMName = "TTools"
    )

    Begin {
        if ($Beta) {
            #Beta Test Variables
            $psmurl = "https://raw.githubusercontent.com/InCare-PST/ICTools/master/Modules/$($PSMName)/$($PSMName)-Beta.psm1"
            $psdurl = "https://raw.githubusercontent.com/InCare-PST/ICTools/master/Modules/$($PSMName)/$($PSMName)-Beta.psd1"
        }
        else {
            #Production Variables
            $psmurl = "https://raw.githubusercontent.com/InCare-PST/ICTools/master/Modules/$($PSMName)/$($PSMName).psm1"
            $psdurl = "https://raw.githubusercontent.com/InCare-PST/ICTools/master/Modules/$($PSMName)/$($PSMName).psd1"
        }
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
function Set-Immutid {
    <#
    .SYNOPSIS 
    Setup Immutable ID in Office 365 to streamline Azure AD sync
    .DESCRIPTION 
    Allows for a compareison between online office 365 and on premises AD to setup a 1 to 1 relationship between the two accounts for Azure AD Sync.
    You have the option to export to CSV, apply the ID to the Azure Account or just display on screen. The Default only displays the information on screen.
    .PARAMETER apply
    Applies the Immutable ID that is created to the Office 365/Azure AD account
    .PARAMETER export
    Created CSV file with information collected in function
    .PARMAETER path
    Specifies a path for the export file. Defauts to C:\Temp Default filename is exporteduserlist+Date.csv
    .EXAMPLE
    .EXAMPLE
    #>
    [CmdletBinding()]
    param (
        [switch]$apply,
    
        [switch]$export,
    
        [string]$path = "c:\temp"
    )
        
    begin {
        if (!(Test-Path -Path $path)) { New-Item -Path $path -Type Directory -Force }
    
        if (Get-Module -ListAvailable -Name azuread) {
            Import-Module azuread
        }
        else {
            Return "AzureAD module not installed."
        }

        if (Get-Module -ListAvailable -Name ActiveDirectory) {
            Import-Module ActiveDirectory
        }
        else {
            Return "Active diretory module not installed."
        }
        
        if ($export) {
            $date = Get-Date -Format yyyy-MM-dd-HH.mm.ss
            $newpath = "$($path)\exporteduserlist-$($date).csv"
        }
        Connect-AzureAD
        $azureUsers = Get-AzureADUser -All $true
        $adUsers = Get-ADUser -Filter * -Properties lastlogondate, objectguid
    }
        
    process {
        $userlist = foreach ($azuser in $azureUsers) {
            $adUser = $adUsers | Where-Object { $_.givenname -eq $azuser.GivenName -and $_.surname -eq $azuser.Surname }
            if (@($adUser).count -eq 1) {
                $immid = [system.convert]::ToBase64String(([GUID]($adUser.objectguid)).tobytearray())
                $props = @{
                    name           = $adUser.Name
                    samaccountname = $adUser.samaccountname
                    objectguid     = $adUser.objectguid
                    AzureADid      = $azuser.objectid
                    mail           = $azuser.Mail
                    immuteID       = $immid
                    lastlogondate  = $adUser.lastlogondate
                }
                $tempobject = New-Object psobject -Property $props
                $tempobject | Select-Object name, samaccountname, mail, lastlogondate, AzureADid, objectguid, immuteID
            }
            if (@($adUser).count -lt 1) {
                $props = @{
                    name = $azuser.DisplayName
                    mail = $azuser.Mail
                }
                $tempobject = New-Object psobject -Property $props
                $tempobject | Select-Object name, mail
            }
        }
        $userlist.count
        if ($apply) {
            foreach ($cuser in $userlist) {
                if ($cuser.immuteID) {
                    $objectid = $cuser.AzureADid
                    Set-AzureADUser -ObjectId $objectid -ImmutableId $cuser.immuteID
                    $cuser.mail
                }
            }
        }
        elseif ($export) {
            $userlist | Select-Object name, samaccountname, mail, lastlogondate, AzureADid, objectguid, immuteID | Export-Csv -Path $newpath -NoTypeInformation
        }
        else {
            $userlist | Select-Object name, samaccountname, mail, lastlogondate, AzureADid, immuteID
        }
    }
        
    end {
            
    }
}
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
function Set-P81routes{
    #Requires -RunAsAdministrator
    [CmdletBinding(DefaultParameterSetName="default",SupportsShouldProcess = $True)]
    param (
        
        [Parameter(ParameterSetName='import')]
        [switch]$import = $false,

        [Parameter(ParameterSetName='export')]
        [switch]$export = $false,

        [Parameter(Mandatory,ParameterSetName='import')]
        [Parameter(Mandatory,ParameterSetName='export')]
        [string]$path,

        [Parameter(ValueFromPipeline=$True)]
        [string[]]$add,

        [string[]]$append,

        [switch]$list = $false,

        [switch]$list_only = $false

    )
    
    begin{
        $P81_Interface = Get-NetAdapter -Name "P81*"
        #Check that only 1 interface was found
        if ($P81_Interface.Count -eq 0) {
            Write-Host "No P81 adapter found. Are you currently connected?" -ForegroundColor Yellow
            Break
        } elseif ($P81_Interface.count -gt 1) {
            Write-Host "Too many P81 Adapters found. $($P81_Interface.count) found."
            Break
        }
        #Find the P81 Interface Address
        $P81_Address = $P81_Interface | Get-NetIPAddress | Select-Object -ExpandProperty IPAddress
        if ($P81_Address.Count -eq 0) {
            Write-Host "Could not get local IP of P81 adapter."
            Break
        } else {
            Write-Host "P81 adapter IP is $P81_Address" -ForegroundColor Green
        }
        #Check current P81 routing
        $P81_Routes = Get-NetRoute -InterfaceIndex $P81_Interface.ifIndex | Where-Object {$_.DestinationPrefix -notmatch $P81_Address}
        #If it looks like the script has already been run, verify that the user wants to run it again.
        if ($P81_Routes.count -gt 3 -and !$list_only -and ![bool]$append) {
            Add-Type -AssemblyName PresentationCore,PresentationFramework
            $ButtonType = [System.Windows.MessageBoxButton]::YesNo
            $MessageboxTitle = “Confirm P81 Route Renewal”
            $Messageboxbody = “It looks like you might have run this script already, would you like to run it again?”
            $MessageIcon = [System.Windows.MessageBoxImage]::Warning
            $answer = [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)
            if ($answer -eq "No") {
                Write-Host -ForegroundColor Red "Exiting Script"
                Break
            }
        }
        #Set the list of DNS names to route through P81
        if($import){
            if (Test-Path $path) {
                $target = Get-ChildItem -Path $path
            }else {
                Write-Host "$path is not a valid file path." -ForegroundColor Yellow
            }
            if ($target.Extension -match ".csv") {
                $import_csv_file = Import-Csv -Path $path
                $FQDNS = $import_csv_file | Select-Object -ExpandProperty FQDNS
            }elseif ($target.Extension -match ".txt") {
                $FQDNS = Get-Content -Path $path
            }
        }elseif ([bool]$append) {
            $FQDNS = $append
        }else{
            $FQDNS = @(
                "vcloud.thrivenextgen.com",
                "cloud.thrivenextgen.com",
                "ks.thrivenetworks.com",
                "vsa02.thrivenetworks.com",
                "vsa03.thrivenextgen.com",
                "vsa04.thrivenetworks.com",
                "vsa05.thrivenextgen.com",
                "vsa06.thrivenextgen.com",
                "vsa07.thrivenextgen.com",
                "vsa08.thrivenextgen.com",
                "vsa09.thrivenextgen.com",
                "vsa10.thrivenextgen.com",
                "ukvsa01.thrivenextgen.co.uk"
            )
        }
        # Resolve the FQDNs to IP addresses for later use
        $IPs = foreach($FQDN in $FQDNS){
            try {
                $IP = Resolve-DnsName $FQDN -Type A -QuickTimeout -DnsOnly -ErrorAction Stop | Where-Object {$null -ne $_.IP4Address} | Select-Object -ExpandProperty IP4Address
            }catch {
                Write-Host "Failed to resolve host $FQDN"
            }
            if ($IP.count -gt 1) {
                foreach ($oneIP in $IP) {
                    $FQDN_temp = @{
                        Name = $FQDN
                        IP = $oneIP+"/32"
                    }
                    $tempobj = New-Object -TypeName psobject -Property $FQDN_temp
                    $tempobj | Select-Object Name, IP        
                }
            }
            else {
                $FQDN_temp = @{
                    Name = $FQDN
                    IP = $IP+"/32"
                } 
                $tempobj = New-Object -TypeName psobject -Property $FQDN_temp
                $tempobj | Select-Object Name, IP       
            }
        }

        if ($list -or $list_only) {
            Write-Host "The following destinations will route through the P81 interface." -ForegroundColor Green
            $IPs | Select-Object @{Name='Web Address';Expression={$_.Name}}, @{Name='Resolved Address';Expression={$_.IP}} | Format-Table -AutoSize
            if ($list_only) {
                break
            }
        }
    }
    process{
        #Removing Current routes unless $append is chosen
        if (![bool]$append) {
                $P81_Routes | Remove-NetRoute -Confirm:$false -ErrorAction SilentlyContinue
                #check to make sure all routes were removed. 
                $P81_Remaining_Routes = Get-NetRoute -InterfaceIndex $P81_Interface.ifIndex | Where-Object {$_.DestinationPrefix -notmatch $P81_Address}
                if ($P81_Remaining_Routes.count -ne 0) {
                    Write-Host "Could not remove all default routes from Interface. $($P81_Remaining_Routes.count) remaining. Exiting Script" -ForegroundColor Red
                    break
                }
            }
        #Add Routes for $FQDN's specified earlier.
        foreach($IP in $IPs){
            try {
                New-NetRoute -DestinationPrefix $IP.ip -InterfaceIndex $P81_Interface.ifIndex -RouteMetric 10 -ErrorAction stop | Out-Null
            }
            catch {                
                Write-Host -ForegroundColor Yellow "Could not add route for $($IP.Name) with IP Address of $($IP.IP)"
            } 
        }
        #Check the new routes
        if ([bool]$append) {
                foreach ($IP in $IPs) {
                    $New_appended_route = Get-NetRoute -InterfaceIndex $P81_Interface.ifIndex | Where-Object {$_.DestinationPrefix -match $IP.IP}
                    if ([bool]$New_appended_route) {
                        Write-Host "Route to $($IP.Name) at $($IP.IP) added to P81" -ForegroundColor Green 
                    }
                }
        }else {
            $New_P81_Routes = Get-NetRoute -InterfaceIndex $P81_Interface.ifIndex | Where-Object {$_.DestinationPrefix -notmatch $P81_Address}
        
            $ref_objects = @{
                ReferenceObject = ($IPs.IP)
                DifferenceObject = ($New_P81_Routes.DestinationPrefix)
            }
    
            $compare = Compare-Object @ref_objects
    
            if($compare.count -ne 0){
                foreach ($item in $compare) {
                    $error_item = $IPs | Where-Object {$_.IP -match $item.InputObject}
                    Write-Host "Route for $($error_item.Name) with IP Address of $($error_item.IP) could not be added." -ForegroundColor Red
                }
            }else{
                Write-Host "All routes were successfully added." -ForegroundColor Green
            }       
        }

    }
    End{

    }
}

function Get-P81routes{
    Set-P81routes -list_only
}

Export-ModuleMember -Function Set-P81routes,Get-P81routes,Set-Immutid,Update-ICTools,Get-SubscriptionInfo