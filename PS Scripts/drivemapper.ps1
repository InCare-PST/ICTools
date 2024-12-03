#Put together for Kittyhawk NAS Shares
param(
[switch]$Testing,
[switch]$Netuse,
[switch]$kaseya
)


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
},
[PSCustomObject]@{
Letter = "Y"
Path = "\\kh-alb.synology.me\Archive"
Label = "Archive Drive"
}
)




if(Test-Connection -ComputerName eds.kittyhawkinc.com -Count 1 -Quiet){
#Get Creds (IF is for testing)
if([bool]$kaseya){
    $User = Read-Host -Prompt 'Enter an email address'
    $PWord = Read-Host -Prompt 'Enter a Password' -AsSecureString
    $creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord
}
if(!($creds)){
    $creds = Get-Credential
}
#Map Drives
foreach($drive in $driveMaps){
$null = New-PSDrive -PSProvider FileSystem -Name $drive.Letter -Root $drive.Path -Description $drive.Label -Credential $creds -Scope global -ErrorAction Stop -Persist

}
}else{
write-host No Connection at this time -ForegroundColor Red
Exit
}
if([bool]$testing){
net use h: /del /y 
net use p: /del /y 
net use y: /del /y
net use "\\kh-alb.synology.me\G-Drive" /del /y 
net use "\\kh-alb.synology.me\Public" /del /y 
net use "\\kh-alb.synology.me\Archive" /del /y
}
if([bool]$Netuse){ 
#net use h: "\\kh-alb.synology.me\G-Drive"
#net use p: "\\kh-alb.synology.me\Public"
#net use y: "\\kh-alb.synology.me\Archive"
}