#Put together for Kittyhawk NAS Shares
param(
[switch]$Netuse,
[switch]$kaseya,
[switch]$delete,
[switch]$enum,
[switch]$save,
[switch]$clearsaved
)


#Variables
$sfolder = "$env:USERPROFILE\Secure"
$sfile = "$sfolder\thrive.xml"
$adip = '10.10.0.4'

#Set drives to map here, drive letter, path, label
$driveMaps = @(
    [PSCustomObject]@{
        Letter = "H"
        Path = "\\kh-alb.synology.me\G-Drive"
        Label = "G Drive"
    },
    [PSCustomObject]@{
        Letter = "P"
        Path = "\\kh-alb.synology.me\Public"
        Label = "Public Drive"
    }<#,
    [PSCustomObject]@{
        Letter = "Y"
        Path = "\\kh-alb.synology.me\Archive"
        Label = "Archive Drive"
    }#>
)

function OldSchool{
    #Do not use this unless it is an emergency as password will be visable in clear text
    #Cleanup old drives
    net use h: /del /y 2>null
    net use p: /del /y 2>null
    net use y: /del /y 2>null
    net use "\\kh-alb.synology.me\G-Drive" /del /y 2>null
    net use "\\kh-alb.synology.me\Public" /del /y 2>null
    net use "\\kh-alb.synology.me\Archive" /del /y 2>null

    #Temp Save Creds
    $User = Read-Host -Prompt 'Enter an email address'
    $PWord = Read-Host -Prompt 'Enter a Password'
    
    #Map new drives
    net use h: "\\kh-alb.synology.me\G-Drive" $PWord /user:$user
    net use p: "\\kh-alb.synology.me\Public" $PWord /user:$user
    #net use y: "\\kh-alb.synology.me\Archive" $PWord /user:$user

    #Force clear creds
    $user = $null
    $PWord = $null
    Exit 
}

function ShowDrives{
    write-host "Enumerating Drives"
    Get-PSDrive -PSProvider FileSystem
    net use
    Exit
    }

function Delete{
    write-host "Deleteing Drives"
    net use h: /del /y 2>null
    net use p: /del /y 2>null
    net use y: /del /y 2>null
    net use "\\kh-alb.synology.me\G-Drive" /del /y 2>null
    net use "\\kh-alb.synology.me\Public" /del /y 2>null
    net use "\\kh-alb.synology.me\Archive" /del /y 2>null
    Exit
}

function ClearSaved{
    Remove-item -Path $sfile
}

function Save{
    if(!(test-path $sfolder)){mkdir $sfolder}
    if(test-path $sfile){write-host "Credentials already saved on this computer, if not working use [clearsaved] flag"}
    else {
    Get-Credential | export-clixml -Path $sfile
    attrib.exe +h +s $sfile
    attrib.exe +h +s $sfolder
    }
}

function TestConnection{
    if(!(Test-Connection $adip -Count 1 -Quiet)){
        Add-Type -AssemblyName System.Windows.Forms | Out-Null
        $box = [System.Windows.Forms.MessageBox]::Show("Can not communicate with Azure AD, please add routes or use local DNS.","Routing Error!",[System.Windows.Forms.MessageBoxButtons]::OK)
    }
    if($box -eq 'OK'){Exit}
    
}

TestConnection

if($enum){ShowDrives}
if($delete){Delete}
if($netuse){OldSchool}
if($save){Save}
if($clearsaved){ClearSaved}




#if(Test-Connection -ComputerName eds.kittyhawkinc.com -Count 1 -Quiet){
#Credentials collection

if([bool]$kaseya){
    $User = Read-Host -Prompt 'Enter an email address'
    $PWord = Read-Host -Prompt 'Enter a Password' -AsSecureString
    $creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord
}
if(!($creds)){
    if(test-path $sfile){$creds = Import-Clixml -Path $sfile
    }else{
    $creds = Get-Credential
}
    
}
#Map Drives
foreach($drive in $driveMaps){
    if(Test-path "$($drive.letter):"){
        write-host "Cleaning up old mapped drive $($drive.letter):"
        cmd.exe /c "net use $($drive.letter): /del /y 2>null"
        start-sleep -Seconds 2
    }
    $null = New-PSDrive -PSProvider FileSystem -Name $drive.Letter -Root $drive.Path -Description $drive.Label -Credential $creds -Scope global -ErrorAction Stop -Persist

}

