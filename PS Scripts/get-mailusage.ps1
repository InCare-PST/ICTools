$tempusagefile = $path + "`\" + "temporaryexportfile.csv"

Get-MgBetaReportMailboxUsageDetail -Period D7 -OutFile $tempusagefile
$usageimport = Import-Csv -Path $tempusagefile
Remove-Item -Path $tempusagefile -Force

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
$exportedusage | Export-Excel -path $exportedFile -AutoSize -TableName UnLicensed -TableStyle Medium2 -WorksheetName "Mailbox Usage Report"
Get-MgBetaReportMailboxUsageDetail