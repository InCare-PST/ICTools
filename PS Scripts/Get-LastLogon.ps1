Function Get-LastLogon{
[cmdletbinding()]
    param(
        [string]$Path="C:\temp",
        [switch]$Export,
        [string]$Days=60
        )
$getcomp = Get-ADComputer -Filter * -Properties LastLogonDate
$date = (get-date).AddDays(-$Days)

if($Export){
  $getcomp  | Where-Object lastlogondate -GE $date | Export-Csv -Path $Path\($Date.tostring("dd-MM-yyyy")+" "+"ActiveComputers.csv")
}else{
  $getcomp  | Where-Object lastlogondate -GE $date | Select-Object Name,LastLogonDate | Sort-Object LastLogonDate -Descending | Format-Table -AutoSize
}
}

Get-LastLogon
