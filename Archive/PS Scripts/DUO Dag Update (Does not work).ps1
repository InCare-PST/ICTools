[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null

<#
Verify DAG Location and Domains Prior to running script
#>

$dom = [Microsoft.VisualBasic.Interaction]::InputBox("Enter a Domain Name", "Input Domain Name", "beta.montevallo.edu")
$dag = [Microsoft.VisualBasic.Interaction]::InputBox("Enter a Dag Location", "Input DAG Name", "dag.montevallo.edu")
#$certloc = [Microsoft.VisualBasic.Interaction]::InputBox("Enter certificate location", "Certificate Information", "c:\temp\dag.crt")
$certloc = New-Object System.Windows.Forms.OpenFileDialog -Property @{
    InitialDirectory = [Environment]::GetFolderPath('Desktop')
    Filter = 'Certificates (*.crt)|*.crt'
}
$null = $certloc.ShowDialog()
$url = "https://$dag/dag/saml2/idp/SSOService.php"
$uri = "https://$dag/dag/saml2/idp/metadata.php"
$logoutUrl = "https://$dag/dag/saml2/idp/SingleLogoutService.php?ReturnTo=https://$dag/dag/module.php/duosecurity/logout.php"
$cert=New-Object System.Security.Cryptography.X509Certificates.X509Certificate2("$certloc.filename")
$certData = [system.convert]::tobase64string($cert.rawdata)



#Production Settings
Connect-MsolService -Credential Get-Credential
$update = Set-MsolDomainAuthentication –DomainName $dom -Authentication Federated -PassiveLogOnUri $url -ActiveLogOnUri $url -IssuerUri $uri -LogOffUri $logoutUrl -PreferredAuthenticationProtocol SAMLP -SigningCertificate $certData
$rollback = Set-MsolDomainAuthentication –DomainName $dom -Authentication Managed
$verify = Get-MsolDomainFederationSettings -DomainName $dom |fl *




#Test Settings
$testupdate = Get-Variable update
$testrollback = write-host -ForegroundColor Green "$rollback"
$testverify = write-host -ForegroundColor Green "$verify"




$go = [Microsoft.VisualBasic.Interaction]::MsgBox("Proceed? `n`nYes to Update $dom `nNo to Rollback the changes `nCancel to exit", "YesNoCancel,Question", "")
switch($go){
'Yes' {
$update
}
'No' {
$rollback
}
'Cancel'{
$verify | Format-Table Name,Value
Exit
}
}
