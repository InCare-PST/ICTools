<#
Find the username for the person logging in the most over the past 7 days.
#>

$startDate = (Get-Date) - (New-TimeSpan -Day 5)
$UserLoginTypes = 2,7
<#
Clean this up
#>
$user = Get-WinEvent  -FilterHashtable @{Logname='Security';ID=4624;StartTime=$startDate}  | SELECT TimeCreated, @{N='Username'; E={$_.Properties[5].Value}}, @{N='LogonType'; E={$_.Properties[8].Value}} | WHERE {$UserLoginTypes -contains $_.LogonType}  | Sort-Object count | Select -last 1


<#
Get a list of files from the C:\Users\%username% directory
#>
$files = Get-ChildItem -Path C:\temp -File -Recurse
foreach ($file in $files){
    $extension = $file.extension.split(".")[1]
    $varname = $extension
    if (!(Get-Variable -Name "$varname" -ErrorAction SilentlyContinue)) {
        New-Variable -Name "$varname" -Value @()
        }
    
}


$files = Get-ChildItem -Path C:\Users\bbris\Downloads -File -Recurse
$fextensions = $files | Sort-Object -Property Extension -Unique | Select-Object Extension
$report = @()
foreach($fextension in $fextensions){
    $extname = $fextension.extension.split(".")[1]
    New-Variable -Name $extname -Value ($files | Where-Object {$_.extension -match $fextension.Extension}) -Force
}






