param (
  [Parameter(Mandatory=$true,
  ValueFromPipeline=$true)]
  [switch]$backup,
  [switch]$remove,
  [switch]$repair
)

$ext = "$env:userprofile\AppData\Local\Microsoft\Edge\User Data\Default\Extensions\lfochlioelphaglamdcakfjemolpichk"
$bak = "C:\backups\keepervault"

if([bool]$backup){robocopy $ext $bak /MIR /E}


if([bool]$remove){
  Remove-Item $ext -Force -Recurse
  taskkill /f /im:*edge*
}

if([bool]$repair){
  if(Test-Path $bak){ 
  Remove-Item $ext -Recurse -Force -Verbose
  taskkill /f /im:*edge*
  invoke-command -ScriptBlock {robocopy $bak $ext /MIR /E}}
  else{
    write-host "The is no backup to restore" -ForegroundColor Red
    Start-Sleep 5
  }}

