Param(
  [Parameter(Mandatory = $true,
             HelpMessage="URL of the secret stored in the keyvault")]
  [ValidateNotNullOrEmpty()]
  [string]$secretUrl,
  
  [Parameter(Mandatory = $true,
             HelpMessage="Resource group of keyvault")]
  [ValidateNotNullOrEmpty()]
  [string]$keyVaultResourceGroup,

  [Parameter(Mandatory = $true,
             HelpMessage="URL of the KEK")]
  [ValidateNotNullOrEmpty()]
  [string]$kekUrl,

  [Parameter(Mandatory = $true,
             HelpMessage="Location where the retrieved secret should be written to")]
  [ValidateNotNullOrEmpty()]
  [string]$secretFilePath
)

#Login-AzAccount;

#Install Active directory module
Install-Module -Name MSOnline;

#Get current logged in user and active directory tenant details
$ctx = Get-AzContext;
$adTenant = $ctx.Tenant.Id;
$currentUser = $ctx.Account.Id

#Parse the secret URL
$secretUri = [System.Uri] $secretUrl;

#Retrieve keyvault name, secret name and secret version from secret URL
$keyVaultName = $secretUri.Host.Split('.')[0];
$secretName = $secretUri.Segments[2].TrimEnd('/');
$secretVersion = $secretUri.Segments[3].TrimEnd('/');

#Set permissions for the current user to unwrap keys and retrieve secrets from KeyVault
$KeyVault = Get-AzKeyVault -VaultName $keyVaultName -ResourceGroupName $keyVaultResourceGroup;
$acl = $KeyVault.AccessPolicies;
$currentacl = $acl | Where-Object { $_.DisplayName -match $currentUser };
$aclp2k = $currentacl.PermissionsToKeys + "unwrapKey"
$aclp2s = $currentacl.PermissionsToSecrets + "get"
Set-AzKeyVaultAccessPolicy -VaultName $keyVaultName -PermissionsToKeys $aclp2k -PermissionsToSecrets $aclp2s -UserPrincipalName $currentUser;

#Retrieve secret from KeyVault secretUrl
$keyVaultSecret = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $secretName -Version $secretVersion;
$secretBase64 = $keyVaultSecret.SecretValue;
$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secretBase64)
$secretBase64 = [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)

#Unwrap secret if the secret is wrapped with KEK
if($kekUrl)
{

    ########################################################################################################################
    # Initialize ADAL libraries and get authentication context required to make REST API called against KeyVault REST APIs. 
    ########################################################################################################################
	
	# Install the ADAL Module
	Install-Module -Name Az.Accounts -Scope AllUsers -RequiredVersion "1.9.4" -Repository PSGallery -Force -AllowClobber

	# Load ADAL Assemblies. If the ADAL Assemblies cannot be found, please see the "Install Az PowerShell module" section. 
	$adal = "${env:ProgramFiles}\WindowsPowerShell\Modules\Az.Accounts\1.9.4\PreloadAssemblies\Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
	$adalforms = "${env:ProgramFiles}\WindowsPowerShell\Modules\Az.Accounts\1.9.4\PreloadAssemblies\Microsoft.IdentityModel.Clients.ActiveDirectory.Platform.dll"  

	If ((Test-Path -Path $adal) -and (Test-Path -Path $adalforms)) { 

	[System.Reflection.Assembly]::LoadFrom($adal)
	[System.Reflection.Assembly]::LoadFrom($adalforms)
	}
	else
	{
	 Write-output "ADAL Assemblies files cannot be found. Please set the correct path for `$adal` and `$adalforms`, then run the script again."
	 exit    
	}  

    # Set well-known client ID for AzurePowerShell
    $clientId = "1950a258-227b-4e31-a9cf-717495945fc2" 
    # Set redirect URI for Azure PowerShell
    $redirectUri = "urn:ietf:wg:oauth:2.0:oob"
    # Set Resource URI to Azure Service Management API
    $resourceAppIdURI = "https://vault.azure.net"
    # Set Authority to Azure AD Tenant
    $authority = "https://login.windows.net/$adTenant"
    # Create Authentication Context tied to Azure AD Tenant
    $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority
	# Acquire token
	$platformParameters = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.PlatformParameters" -ArgumentList "Auto"
	$authResult = $authContext.AcquireTokenAsync($resourceAppIdURI, $clientId, $redirectUri, $platformParameters).result
    # Generate auth header 
    $authHeader = $authResult.CreateAuthorizationHeader()
    # Set HTTP request headers to include Authorization header
    $headers = @{'x-ms-version'='2014-08-01';"Authorization" = $authHeader}
	
	# Place wrapped BEK in JSON object to send to KeyVault REST API
	

    ########################################################################################################################
    # 1. Retrieve the secret from KeyVault
    # 2. If Kek is not NULL, unwrap the secret with Kek by making KeyVault REST API call
    # 3. Convert Base64 string to bytes and write to the BEK file
    ########################################################################################################################

    #Call KeyVault REST API to Unwrap 
    $jsonObject = @"
    {
        "alg": "RSA-OAEP",
        "value" : "$secretBase64"
    }
"@

    $unwrapKeyRequestUrl = $kekUrl+ "/unwrapkey?api-version=2015-06-01";
    $result = Invoke-RestMethod -Method POST -Uri $unwrapKeyRequestUrl -Headers $headers -Body $jsonObject -ContentType "application/json";

    #Convert Base64Url string returned by KeyVault unwrap to Base64 string
    $secretBase64 = $result.value;
}

$secretBase64 = $secretBase64.Replace('-', '+');
$secretBase64 = $secretBase64.Replace('_', '/');
if($secretBase64.Length %4 -eq 2)
{
    $secretBase64+= '==';
}
elseif($secretBase64.Length %4 -eq 3)
{
    $secretBase64+= '=';
}

if($secretFilePath)
{
    $bekFileBytes = [System.Convert]::FromBase64String($secretBase64);
    [System.IO.File]::WriteAllBytes($secretFilePath,$bekFileBytes);
}

#Delete the key from the memory
[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
clear-variable -name secretBase64