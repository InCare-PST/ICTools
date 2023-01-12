[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null


#Verify DAG Location and Domains Prior to running script
#[CmdletBinding()]
param(
[switch]$Start,
[switch]$Restore,
[switch]$Check
)


###Connect MSOL
if(Get-Module -ListAvailable -Name MSOnline){
import-module MSOnline
Connect-MsolService
}else{
install-module MSOnline
import-module MSOnline
Connect-MsolService
}


###URLs
$dom = [Microsoft.VisualBasic.Interaction]::InputBox("Enter a Domain Name", "Input 365 Domain Name", "Domain Name")
$dag = [Microsoft.VisualBasic.Interaction]::InputBox("Enter a Dag Location", "Input DAG Name", "DAG Name")
$url = "https://$dag/dag/saml2/idp/SSOService.php"
$uri = "https://$dag/dag/saml2/idp/metadata.php"
$logoutUrl = "https://$dag/dag/saml2/idp/SingleLogoutService.php?ReturnTo=https://$dag/dag/module.php/duosecurity/logout.php"

#Certificates
$importcert = [Microsoft.VisualBasic.Interaction]::InputBox("Enter certificate location", "Certificate Information", "c:\temp\dag.crt")
$cert=New-Object System.Security.Cryptography.X509Certificates.X509Certificate2("$importcert")
$certData = [system.convert]::tobase64string($cert.rawdata)




#Production Settings
$update = Set-MsolDomainAuthentication -DomainName $dom -Authentication Federated -PassiveLogOnUri $url -ActiveLogOnUri $url -IssuerUri $uri -LogOffUri $logoutUrl -PreferredAuthenticationProtocol SAMLP -SigningCertificate $certData
$rollback = Set-MsolDomainAuthentication -DomainName $dom -Authentication Managed
$verify = Get-MsolDomain -DomainName $dom |Format-List *




<#
#Test Settings
$testupdate = write-host -ForegroundColor Green "$update"
$testrollback = write-host -ForegroundColor Green "$rollback"
$testverify = write-host -ForegroundColor Green "$verify"
#>

if([bool]$Start){$update}
if([bool]$Restore){$rollback}
if([bool]$Check){$Verify}
