function Remove-FullControl{
    [CmdletBinding(SupportsShouldProcess)]
        param(
            [Parameter(Position = 0, Mandatory)]
            [string]$Domain,
            [Parameter(Position = 1, Mandatory)]
            [string]$UserName,
            [Parameter(Position = 2, Mandatory)]
            [string]$FolderPath,
            [Parameter(Position = 3)]
            [pscustomobject]$NewAccessType = [pscustomobject]@{
                "FileSystemRights"  = [System.Security.AccessControl.FileSystemRights]::ReadAndExecute;
                "AccessControlType" = [System.Security.AccessControl.AccessControlType]::Allow;
            }, 
            [Parameter(Position = 4)]
            [Bool]$RemoveInheritance = $true
            
        )
    
        process {
            $CombinedUserName = "$($Domain)\$($UserName)" #Combine the domain and the username for the IdentityReference property.
            Write-Verbose "Getting the current ACL for '$($FolderPath)'."
            $FolderAcl = Get-Acl -Path $FolderPath
            
            if ($RemoveInheritance){
                Write-Verbose "Removing explicit inheritance for '$($FolderPath)'."
                $isProtected = $true
                $preserveInheritance = $true
                $FolderAcl.SetAccessRuleProtection($isProtected, $preserveInheritance)
                Set-Acl -Path $FolderPath -AclObject $FolderAcl -ErrorAction Stop
                $FolderAcl = Get-Acl -Path $FolderPath
            }
           
        #Create a list containing the user's and the creator owner's permissions from the acl.
        $Rules = $FolderAcl.access | Where-Object { $_.IdentityReference -like "CREATOR OWNER" -or $_.IdentityReference -eq $CombinedUserName  }
    
            #If any access rules were found, remove them from the ACL object.
            foreach ($Rule in $Rules) {
                $removeResult = $FolderAcl.RemoveAccessRule($Rule)
    
                switch ($removeResult) {
                    $false {
                        Write-Warning "Failed to remove a permission for '$($UserName)'."
                        break
                    }
    
                    Default {
                        Write-Verbose "Removed '$($Rule.FileSystemRights) permission for '$($Rule.IdentityReference)'."
                        break
                    }
                }
            }
    
            if ($NewAccessType) {
                #If 'NewAccessType' was provided (true by default), then generate a new access rule with the provided settings.
                #This adds a new access for the user
                Write-Verbose "'NewAccessType' was provided. Adding the new rule to the ACL."
    
                $identity = $combinedUsername
                $rights = 'ReadAndExecute'
                $inheritance = 'ContainerInherit, ObjectInherit'
                $propagation = 'None'
                $type = 'Allow'
                $NewAclRule = New-Object System.Security.AccessControl.FileSystemAccessRule($identity,$rights,$inheritance,$propagation, $type)
                $FolderAcl.AddAccessRule($NewAclRule) #Add the new access rule to the ACL object.
            }
    
            if ($PSCmdlet.ShouldProcess($FolderPath, "Update ACL")){
            #apply any modifiations made above (inheritance or new acces)
                Set-Acl -Path $FolderPath -AclObject $FolderAcl -ErrorAction Stop
            }
        }
    }
    function Convert-EmailToOneDrive {
    #Create a string from the users emailaddress and convert it to the OD personal URL
        Param(     
            [Parameter(Position = 0, Mandatory)]
            [string]$Email 
        )
    
        $suffix = $Email -replace "\.", "_"
        $suffix = $suffix -replace "@", "_"
        $prefix = "<ChangeMe>"
        $output = $prefix + $suffix.ToString()
        return $output
    }
    function Clean-HomeDrivePath {
    #Get root user folder
    #Triming any trailing slashes, add back to the start of string
    [CmdletBinding(SupportsShouldProcess)]
        param(
            [Parameter(Position = 0, Mandatory)]
            [string]$homePath
        )
        $homePath = $homePath.ToLower()
        "\\" + ($homePath.Replace("my documents", "").Replace("documents", "").trim('\'))
    }
    function Main {
    #Main, takes a user and a list of folders to process
        [CmdletBinding(SupportsShouldProcess)]
            param(
                [Parameter(Position = 0, Mandatory)]
                [Object]$ADUsers,
                [Parameter(Position = 1, Mandatory)]
                [Object]$TargetSubFolder
            )
    
        $global:UserData = [System.Collections.ArrayList]::new()
        $i=1
        if(!$user.count){$total = 1}else{$total = $user.count}
        foreach ($ADUser in $ADUsers){
            Write-Progress -Activity "Iterating Users" -Status "User $i of $($total)" -PercentComplete (($i / $total) * 100) 
    
            $LegacyGroup = $ADUser.MemberOf | ? {$_ -like "*Legacy File Server*"} | %{$_ -replace '^CN=([^,]+),OU=.+$','$1'}
    
            if(!$ADUser.HomeDirectory){Write-Warning "'$($ADUser.Name)' does not have a home directory. Skipping.";$i++;Continue}
            if(!$LegacyGroup ){Write-Warning "'$($ADUser.Name)' already migrated. Skipping.";$i++;Continue;} else {
                Write-Verbose "Removing $ADUser.name from $LegacyGroup"
                Remove-ADGroupMember -identity $LegacyGroup -Members $ADUser -Confirm:$false
            }
         
            $ODPath = Convert-EmailToOneDrive -Email ($ADUser.EmailAddress.tolower())
            $RootHomeDirectory = Clean-HomeDrivePath $ADUser.HomeDirectory.toString()
    
            Remove-FullControl -Domain <ChangeMe> -UserName $ADUser.samaccountname -FolderPath $RootHomeDirectory -Verbose
    
            Foreach ($Target in $TargetSubFolder){
                $TargetFolderPath = try{(gci $RootHomeDirectory $Target -Recurse -Depth 1).FullName } catch [System.UnauthorizedAccessException] { Write-Host "Caught unauthorized access exception to" $ADUser.Name; $i++;continue }
                $Nested = $TargetFolderPath -like ($ADUser.HomeDirectory) -and ($Target -notlike "My Documents")
    
                if($TargetFolderPath){
                    if(!$Nested){
                    #If libraries are not nested, ie 'My Documents\My Photos'
                    Write-Verbose "Adding '$($ADUser.Name)' '$($Target)' to list"
                        $UserData.Add(
                            [pscustomobject]@{
                                "Source"          = $TargetFolderPath;
                                "SourceDocLib"    = $null;
                                "SourceSubFolder" = $null;
                                "TargetWeb"       = $ODPath;
                                "TargetDocLib"    = "Documents";
                                "TargetSubFolder" = $(($Target -split "\\")[-1] -replace "My ", "");
                            } ) | Out-Null
    
                        }else{
                            #Do not upload folders if libraries are nested within Documents. 
                            Write-Warning "'$($ADUser.Name)' library '$($Target)' follows the home directory. Skipping."
                        }
                    }Else{
    
                        #If the 'Target' property does not exist on the AD object, return a warning message to the console. 
                        Write-Warning "'$($ADUser.Name)' does not have a $Target directory. Skipping."
                    }
                }
                $i++
        }
        Return $UserData
        
    
    }
    
    $userOption = 1
    
    switch($userOption){
        
        1 {
        #From Single or Multiple School Distro's
        $schools = Get-ADOrganizationalUnit -SearchBase "<ChangeMe>" -SearchScope OneLevel -Filter * | ? {$_.name -notlike "CORE" -and $_.name -notlike "Servers" -and $_.name -notlike "*Deleted*"}
        $schoolChoice = $schools.name | Out-GridView -PassThru -Title "Chose Your Schools"
        $school = $schoolChoice | %{ $thisSchool = $_; $schools.Where({$_.name -match $thisSchool })}
        $group = $school | %{Get-ADGroup -SearchBase ("OU=Distribution,OU=Groups,"+($_.distinguishedname)) -Filter * | select Name | sort Name | Out-GridView -PassThru -Title "Choose Distro For Each School"}
        $user = $group | %{Get-ADGroupMember $_.Name | sort Name | Out-GridView -PassThru -Title "Select Users" | Get-ADUser -Properties homedirectory, emailaddress, memberof}
        ;break}
    
        2 {#List of User Names
        $list = "user.name1", "user.name2", "user.name3"
        $user = $list | Get-ADUser -Properties homedirectory, emailaddress, memberof
        ;break}
    
        3 {
        #Single User
        $user = Get-ADUser user.name1 -Properties homedirectory, emailaddress, memberof
        ;break}
    }
    
    $PossibleTargetSubFolders = "Desktop", "Documents", "My Music", "My Pictures", "My Videos"
    $TargetSubFolders = $PossibleTargetSubFolders | Out-GridView -PassThru -Title "Chose Which Document Libraries To Upload"
    #$TargetSubFolders = $PossibleTargetSubFolders
    
    $data = Main -ADUser $user $TargetSubFolders
    $data
    
    $data | select * -ExcludeProperty RowError, RowState, HasErrors, Name, Table, ItemArray |ConvertTo-Csv -NoTypeInformation | Select-Object -Skip 1 | Set-Content -path "$(get-date -f yyyy-MM-dd)_ODSP_MT_Upload.csv"
    
    start $pwd