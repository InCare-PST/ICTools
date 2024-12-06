<#
 drivemapper.ps1

 By Justin Gallups, Thrive Networks. Use at your own risk.  No warranties are given.

.DISCLAIMER
    THIS CODE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
 
.SYNOPSIS 
    Kittyhawk NAS Shares drive map

.DESCRIPTION
    Allows users to map, save, test, delete network shares for their NAS device. 

Command to add scheduled task: "schtasks.exe /Create /SC ONLOGON /ru "BUILTIN\Users" /TN "KH-Albany\Login Script" /TR "'%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe' -windowstyle hidden -noninteractive -ExecutionPolicy Bypass -File c:\ThriveAgent\drivemapper.ps1" /F"


#>

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
$sfirst = "$sfolder\firstrun.txt"
$eds = 'eds.kittyhawkinc.com'
$syn = 'kh-alb.synology.me'
$edsip = '10.10.0.*'
$synip = '192.168.160.*'


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
    #Do not use this unless it is an emergency as password will be visable in clear text.
    #This is for testing and troubleshooting ONLY!

    #Cleanup old drives
    foreach($d in $drivemaps){
        net use "$($d.letter):" /del /y 2>null
        net use "$($d.path)" /del /y 2>null
        }
<#
    #Manual deletion if the loop fails
    net use h: /del /y 2>null
    net use p: /del /y 2>null
    net use y: /del /y 2>null
    net use "\\kh-alb.synology.me\G-Drive" /del /y 2>null
    net use "\\kh-alb.synology.me\Public" /del /y 2>null
    net use "\\kh-alb.synology.me\Archive" /del /y 2>null
#>
    #Temp Save Creds
    $User = Read-Host -Prompt 'Enter an email address'
    $PWord = Read-Host -Prompt 'Enter a Password' -MaskInput
    
    #Map new drives
    foreach($d in $drivemaps){
        write-host "Mapping drive $($d.letter)"
        try{
            net use "$($d.letter):" "$($d.path)" $PWord /user:$user /PERSISTENT:YES
        }catch{
            Add-Type -AssemblyName PresentationCore,PresentationFramework
            $ButtonType = [System.Windows.MessageBoxButton]::OK
            $MessageboxTitle = "Misc error"
            $Messageboxbody = "Unable to map drive $($drive.Letter): `n$($_.Exception.Message) `n$(get-date)"
            $MessageIcon = [System.Windows.MessageBoxImage]::Error
            [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)

    }
    }
<#
    #Might as well be manually mapped 
    net use h: "\\kh-alb.synology.me\G-Drive" $PWord /user:$user
    net use p: "\\kh-alb.synology.me\Public" $PWord /user:$user
    net use y: "\\kh-alb.synology.me\Archive" $PWord /user:$user
#>
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
    foreach($d in $drivemaps){
        write-host "Deleteing drive $($d.letter):"
        net use "$($d.letter):" /del /y 2>null
        write-host "Deleteing path $($d.path)"
        net use "$($d.path)" /del /y 2>null
        }
    Exit
}

function ClearSaved{
    attrib.exe -h $sfile
    attrib.exe -h $sfirst
    Remove-item -Path $sfile -ErrorAction SilentlyContinue
    Remove-item -Path $sfirst -ErrorAction SilentlyContinue
    Exit
}

function Save{
    if(!(test-path $sfolder)){mkdir $sfolder}
    if(test-path $sfile){write-host "Credentials already saved on this computer, if not working use [clearsaved] flag"}
    else {
    Get-Credential | export-clixml -Path $sfile
    attrib.exe +h $sfile
    attrib.exe +h $sfolder
   }
}

function TestConnection{
    $resolveeds = Resolve-DnsName $eds
    $resolvesyn = Resolve-DnsName $syn
    if($resolveeds.ipaddress -notlike $edsip){
        Add-Type -AssemblyName System.Windows.Forms | Out-Null
        $box = [System.Windows.Forms.MessageBox]::Show("Can not communicate with Azure AD, please add routes or use local DNS. Currently resolves to: $($resolveeds.ipaddress)","Routing Error!",[System.Windows.Forms.MessageBoxButtons]::OK)
    }
    if($box -eq 'OK'){Exit}
    if($resolvesyn.ipaddress -notlike $synip){
        Add-Type -AssemblyName System.Windows.Forms | Out-Null
        $box = [System.Windows.Forms.MessageBox]::Show("Can not communicate with Synology NAS, please add routes or use local DNS. Currently resolves to: $($resolvesyn.ipaddress)","Routing Error!",[System.Windows.Forms.MessageBoxButtons]::OK)
    }
    if($box -eq 'OK'){Exit}
    
}

function FirstRun{
    Add-Type -AssemblyName PresentationCore,PresentationFramework
    $ButtonType = [System.Windows.MessageBoxButton]::YesNo
    $MessageboxTitle = "Save Prompt"
    $Messageboxbody = "This is your first time mapping the drives, would you like to save your credentials?"
    $MessageIcon = [System.Windows.MessageBoxImage]::Question
    $answer = [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)
    if(!(test-path $sfolder)){mkdir $sfolder}
    get-date | out-file $sfirst
    if($answer -eq "Yes"){Save}
}

TestConnection

if($enum){ShowDrives}
if($delete){Delete}
if($netuse){OldSchool}
if($save){Save}
if($clearsaved){ClearSaved}
if(!(test-path $sfirst)){FirstRun}



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

#Final check to see if any creds are present
if(!($creds)){
    Add-Type -AssemblyName PresentationCore,PresentationFramework
    $ButtonType = [System.Windows.MessageBoxButton]::OK
    $MessageboxTitle = "Credential Error!"
    $Messageboxbody = "You did not enter crendentials to map a drive, closing"
    $MessageIcon = [System.Windows.MessageBoxImage]::Error
    $answer = [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)
        if($answer -eq 'OK'){
            Exit
        }
}

#Map Drives section

foreach($drive in $driveMaps){
    if(Test-path "$($drive.letter):"){
        #write-host "Cleaning up old mapped drive $($drive.letter):"
        net use "$($drive.letter):" /del /y 2>null
        #start-sleep -Seconds 2
    }
    try{
        New-PSDrive -PSProvider FileSystem -Name $drive.Letter -Root $drive.Path -Description $drive.Label -Credential $creds -Scope global -ErrorAction Stop -Persist
    }catch{
        if($_.Exception.Message -eq "The specified network password is not correct."){
            #Write-Host "Unable to map drive due to invalid credentials."
            Add-Type -AssemblyName PresentationCore,PresentationFramework
            $ButtonType = [System.Windows.MessageBoxButton]::OK
            $MessageboxTitle = "Password error"
            $Messageboxbody = "Your password is incorrect, clearing your saved credentials"
            $MessageIcon = [System.Windows.MessageBoxImage]::Error
            $answer = [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)
                if($answer -eq 'OK'){
                    ClearSaved
                    Exit
                }
        }else{
            #Write-Host "Unable to map drive $($drive.Letter):"
            #Write-Error $_.Exception.Message 
            Add-Type -AssemblyName PresentationCore,PresentationFramework
            $ButtonType = [System.Windows.MessageBoxButton]::OK
            $MessageboxTitle = "Misc error"
            $Messageboxbody = "Unable to map drive $($drive.Letter): `n$($_.Exception.Message)"
            $MessageIcon = [System.Windows.MessageBoxImage]::Error
            $answer = [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)
                if($answer -eq 'OK'){
                    #ClearSaved
                    Exit
                }
             }
        }
    }

