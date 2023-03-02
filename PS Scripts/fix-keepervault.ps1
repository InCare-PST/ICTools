$bad = "C:\Users\JGallups\AppData\Local\Microsoft\Edge\User Data\Default\Extensions\lfochlioelphaglamdcakfjemolpichk"
$bak = "C:\Users\JGallups\AppData\Local\Microsoft\Edge\User Data\Default\Extensions\keepervault"

Remove-Item $bad -Recurse -Force -Verbose
Start-Sleep 30
invoke-command -ScriptBlock {robocopy $bak $bad /MIR /E}