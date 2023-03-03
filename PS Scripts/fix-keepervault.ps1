param (
  [switch]$backup
)

$ext = "C:\Users\JGallups\AppData\Local\Microsoft\Edge\User Data\Default\Extensions\lfochlioelphaglamdcakfjemolpichk"
$bak = "C:\backups\keepervault"

if([bool]$backup){robocopy $ext $bak /MIR /E}
else{
    Remove-Item $ext -Recurse -Force -Verbose
    invoke-command -ScriptBlock {robocopy $bak $ext /MIR /E}
}

