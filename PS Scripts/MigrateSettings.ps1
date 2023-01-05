#
# Use this PowerShell script to export the server configuration from a downlevel version of Azure AD Connect 
# that does not support the new JSON settings import and export feature.
#
#  Migration Steps
#
#     Please read the complete instructions for performing an in-place versus a legacy settings migration before
#     attempting the following steps: https://go.microsoft.com/fwlink/?LinkID=2117122
#
#     1.) Copy this script to your production server and save the downlevel server configuration directory
#         to a file share for use in installing a new staging server.
#
#     2.) Run this script on your new staging server and pass in the location of the configuration directory
#         generated in the previous step.  This will create a JSON settings file which can then be imported
#         in the Azure Active Directory Connect tool during Custom installation.
#

Param (
    [Parameter (Mandatory=$false)]
    [string] $ServerConfiguration
)
$helpLink = "https://go.microsoft.com/fwlink/?LinkID=2117122"
$helpMsg = "Please see $helpLink for more information."
$adSyncService = "HKLM:\SYSTEM\CurrentControlSet\services\ADSync"

# An installed wizard is the baseline requirement for this script
$wizard = Get-ItemProperty -Path "HKLM:\Software\Microsoft\Azure AD Connect" -ErrorAction Ignore
if ($wizard.WizardPath)
{
    [version] $wizardVersion = [Diagnostics.FileVersionInfo]::GetVersionInfo($wizard.WizardPath).FileVersion
    try {
        # The ADSync service must be installed in order to extract settings from the production server
        $service = Get-ItemProperty -Path $adSyncService -Name ObjectName -ErrorAction Ignore
        if (!$service.ObjectName)
        {
            Write-Host
            Write-Host "Azure AD Connect must be installed and configured on this server for settings migration to succeed."
            Write-Host "The Microsoft Azure AD Connect synchronization service (ADSync) is not present."
            Write-Host $helpMsg
            exit
        }

        $programData = [IO.Path]::Combine($Env:ProgramData, "AADConnect")
        if (!$ServerConfiguration)
        {
            # Create a temporary directory under %ProgramData%\AADConnect
            $tempDirectory = ("Exported-ServerConfiguration-" + [System.Guid]::NewGuid())
            $ServerConfiguration = [IO.Path]::Combine($programData, $tempDirectory)
        }

        # Export the server configuration in a new PS session to avoid loading legacy cmdLet assemblies
        try
        {
            # try first with new parameter that will validate the configuration 
            Get-ADSyncServerConfiguration -Path $ServerConfiguration $true
        }
        catch [System.Management.Automation.ParameterBindingException]
        {
            Get-ADSyncServerConfiguration -Path $ServerConfiguration
        }

        # Copy over the PersistedState.xml file to the configuration directory
        Copy-Item -Path "$programData\\PersistedState.xml" -Destination $ServerConfiguration

        $author = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        $timeCreated = $(Get-Date).ToUniversalTime().ToString("u", [System.Globalization.CultureInfo]::InvariantCulture)
        $policyMetadata = [ordered]@{
            "type" = "migration"
            "author" = $author
            "timeCreated" = $timeCreated
            "azureADConnectVersion" =  $wizardVersion.ToString()
        }

        $hostName = ([System.Net.Dns]::GetHostByName(($env:computerName))).Hostname
        $serviceParams = Get-ItemProperty -Path "$adSyncService\Parameters" -ErrorAction Ignore
        $databaseServer = $serviceParams.Server
        $databaseInstance = $serviceParams.SQLInstance
        $databaseName = $serviceParams.DBName

        # Retrieve the service account type for documentation purposes (may not be present on old builds)
        $serviceAccountType = "Unknown"
        $msolCoexistence = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\MSOLCoExistence" -ErrorAction Ignore
        if ($msolCoexistence.ServiceAccountType)
        {
            $serviceAccountType = $adSync.ServiceAccountType
        }
        
        [string[]]$connectorIds =(Get-ADSyncConnector | Select-Object -Property Identifier).Identifier

        # NOTE: databaseType is a calculated field and is intentionally ommitted
        $deploymentMetadata = [ordered]@{
            "hostName" = $hostName
            "serviceAccount" = $service.ObjectName
            "serviceAccountType" = $serviceAccountType
            "databaseServer" = $databaseServer
            "databaseInstance" = $databaseInstance
            "databaseName" = $databaseName
            "connectorIds" = $connectorIds
        }

        $policyJSON = [ordered]@{
            "policyMetadata" = $policyMetadata
            "deploymentMetadata" = $deploymentMetadata
        }                 

        # Create MigratedPolicy.json for the production server
        $policyJSON | ConvertTo-Json | Out-File "$ServerConfiguration\MigratedPolicy.json"

        Write-Host
        Write-Host "The downlevel server configuration was successfully exported.  Copy the entire directory to"
        Write-Host "your new staging server and select 'MigratedPolicy.json' from the UI to import these settings."
        Write-Host
        Write-Host "   " $ServerConfiguration
        Write-Host
        Write-Host "Please see $helpLink for more information on completing this process."
    }
    catch {
        Write-Host "Unable to export the server configuration due to an unexpected error."
        Write-Host $helpMsg
        Write-Host "Message: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    exit
}
else
{
    Write-Host
    Write-Host "The Azure AD Connect tool must be installed on this server for settings migration to succeed."
    Write-Host $helpMsg
}
# SIG # Begin signature block
# MIInwgYJKoZIhvcNAQcCoIInszCCJ68CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBFmuzW644A2hIU
# e0doTQIQOOZ59uIfCm+FbtM2rs/A1qCCDY0wggYLMIID86ADAgECAhMzAAAC2/M3
# vOrKEXLgAAAAAALbMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMjIwNjA3MTc0ODQxWhcNMjMwNjAxMTc0ODQxWjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQC5xkERA6QwbMoJVZMVPV6c7AzKHgtcuJs+4kQ5Vbiek9WEf2yOr5N4tsMHVAVO
# hCq9ziDeyS3NcEC3ttESjERLogPxRkWXi8WroF5ZkKql3fGab8RGN+Q28RSBwe6l
# hXpbA+JEn9xa9vS77Zm5M7qdAXvNMh/CYzRgKiHDcAfubxZjIFtbbXm1SFnCu/tV
# lRenqPPj01lJRhPJzS1MX1RbPvNSN412ru+5ngvrP/FwwHK9d3SgesbQbzgeO7Pt
# rvGyAU00EodyWv6tgikZHDDyWQxOc8SS5aP0qWh9cqyoar8q7t7MNWSBS13Dws3Q
# /1D+u/osUmfguZvF9NdJGemjAgMBAAGjggGKMIIBhjArBgNVHSUEJDAiBgorBgEE
# AYI3TBMBBgorBgEEAYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQUR2gIWLn69uXw
# 6kj6koXYxQeebGwwUAYDVR0RBEkwR6RFMEMxKTAnBgNVBAsTIE1pY3Jvc29mdCBP
# cGVyYXRpb25zIFB1ZXJ0byBSaWNvMRYwFAYDVQQFEw0yMzMxMTArNDcwODMzMB8G
# A1UdIwQYMBaAFEhuZOVQBdOCqhc3NyK1bajKdQKVMFQGA1UdHwRNMEswSaBHoEWG
# Q2h0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY0NvZFNpZ1BD
# QTIwMTFfMjAxMS0wNy0wOC5jcmwwYQYIKwYBBQUHAQEEVTBTMFEGCCsGAQUFBzAC
# hkVodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRzL01pY0NvZFNp
# Z1BDQTIwMTFfMjAxMS0wNy0wOC5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG9w0B
# AQsFAAOCAgEAVyPXK1YQ5rMWdATJMWOlquFpjJrdVE0B/eUct43gAUKpfLFDwFCk
# chusVz8IYvedbjKwnXDdoqr9d9D51/ZILhXdcoLZ/RSm5eGDUZgQSdxVduDh4uaL
# qOEI8/gh1imM3ISQZZ+q51eSrzXesQ/N/Hvjxtc54V4dENA+hHC82bUKkqXzwxTH
# XYSKGHsy44Ff+P/rPWuX7SzzUMnrhZoL2i312ckJuaAyrJHaIDLIwuWJ6USX507y
# iqPtiBtVJTeY950cdVvrO2Ybef4k25PYISJsajr4gZ4spRZuUcvhr4ZvHUQDfm7I
# SSQOpv+OKy5HRipyDdPTxQMdokK7S3awyRfg0bJ+rL6jwN7XzJqu0biDHqr4EAUf
# Gi2o8DdjL/G3iloCjmTJAydZ3FtB6q1oz6EO2dIJnFfZVFPI9PM6jkDPojvlYPz8
# HNI4rk5Y/BnjktYF0EJyesvdoDVTjAUCHmjtiaP7rrJNCHUuCvEJsR1SSKr3Pvxh
# GtIX4UdVj7BAhlsCaqvVb7U57bl8sVvc9qTeVmnV3cHRABxc/hJNuh3hU05YWsy4
# iPLWapHV5OANiCfGG/C0WZnL1Lj9KZnjdRaBr65yY+RKfqbEBy/ueH4Ss79U8SIK
# qq+M6DJhamw+aoNjBoMqM8a30r3vr1jdfFA9EoXfP+gq9qmUKTx9E60wggd6MIIF
# YqADAgECAgphDpDSAAAAAAADMA0GCSqGSIb3DQEBCwUAMIGIMQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUm9v
# dCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgMjAxMTAeFw0xMTA3MDgyMDU5MDlaFw0y
# NjA3MDgyMTA5MDlaMH4xCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9u
# MRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRp
# b24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTEwggIi
# MA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQCr8PpyEBwurdhuqoIQTTS68rZY
# IZ9CGypr6VpQqrgGOBoESbp/wwwe3TdrxhLYC/A4wpkGsMg51QEUMULTiQ15ZId+
# lGAkbK+eSZzpaF7S35tTsgosw6/ZqSuuegmv15ZZymAaBelmdugyUiYSL+erCFDP
# s0S3XdjELgN1q2jzy23zOlyhFvRGuuA4ZKxuZDV4pqBjDy3TQJP4494HDdVceaVJ
# KecNvqATd76UPe/74ytaEB9NViiienLgEjq3SV7Y7e1DkYPZe7J7hhvZPrGMXeiJ
# T4Qa8qEvWeSQOy2uM1jFtz7+MtOzAz2xsq+SOH7SnYAs9U5WkSE1JcM5bmR/U7qc
# D60ZI4TL9LoDho33X/DQUr+MlIe8wCF0JV8YKLbMJyg4JZg5SjbPfLGSrhwjp6lm
# 7GEfauEoSZ1fiOIlXdMhSz5SxLVXPyQD8NF6Wy/VI+NwXQ9RRnez+ADhvKwCgl/b
# wBWzvRvUVUvnOaEP6SNJvBi4RHxF5MHDcnrgcuck379GmcXvwhxX24ON7E1JMKer
# jt/sW5+v/N2wZuLBl4F77dbtS+dJKacTKKanfWeA5opieF+yL4TXV5xcv3coKPHt
# bcMojyyPQDdPweGFRInECUzF1KVDL3SV9274eCBYLBNdYJWaPk8zhNqwiBfenk70
# lrC8RqBsmNLg1oiMCwIDAQABo4IB7TCCAekwEAYJKwYBBAGCNxUBBAMCAQAwHQYD
# VR0OBBYEFEhuZOVQBdOCqhc3NyK1bajKdQKVMBkGCSsGAQQBgjcUAgQMHgoAUwB1
# AGIAQwBBMAsGA1UdDwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaA
# FHItOgIxkEO5FAVO4eqnxzHRI4k0MFoGA1UdHwRTMFEwT6BNoEuGSWh0dHA6Ly9j
# cmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY1Jvb0NlckF1dDIw
# MTFfMjAxMV8wM18yMi5jcmwwXgYIKwYBBQUHAQEEUjBQME4GCCsGAQUFBzAChkJo
# dHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY1Jvb0NlckF1dDIw
# MTFfMjAxMV8wM18yMi5jcnQwgZ8GA1UdIASBlzCBlDCBkQYJKwYBBAGCNy4DMIGD
# MD8GCCsGAQUFBwIBFjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2Rv
# Y3MvcHJpbWFyeWNwcy5odG0wQAYIKwYBBQUHAgIwNB4yIB0ATABlAGcAYQBsAF8A
# cABvAGwAaQBjAHkAXwBzAHQAYQB0AGUAbQBlAG4AdAAuIB0wDQYJKoZIhvcNAQEL
# BQADggIBAGfyhqWY4FR5Gi7T2HRnIpsLlhHhY5KZQpZ90nkMkMFlXy4sPvjDctFt
# g/6+P+gKyju/R6mj82nbY78iNaWXXWWEkH2LRlBV2AySfNIaSxzzPEKLUtCw/Wvj
# PgcuKZvmPRul1LUdd5Q54ulkyUQ9eHoj8xN9ppB0g430yyYCRirCihC7pKkFDJvt
# aPpoLpWgKj8qa1hJYx8JaW5amJbkg/TAj/NGK978O9C9Ne9uJa7lryft0N3zDq+Z
# KJeYTQ49C/IIidYfwzIY4vDFLc5bnrRJOQrGCsLGra7lstnbFYhRRVg4MnEnGn+x
# 9Cf43iw6IGmYslmJaG5vp7d0w0AFBqYBKig+gj8TTWYLwLNN9eGPfxxvFX1Fp3bl
# QCplo8NdUmKGwx1jNpeG39rz+PIWoZon4c2ll9DuXWNB41sHnIc+BncG0QaxdR8U
# vmFhtfDcxhsEvt9Bxw4o7t5lL+yX9qFcltgA1qFGvVnzl6UJS0gQmYAf0AApxbGb
# pT9Fdx41xtKiop96eiL6SJUfq/tHI4D1nvi/a7dLl+LrdXga7Oo3mXkYS//WsyNo
# deav+vyL6wuA6mk7r/ww7QRMjt/fdW1jkT3RnVZOT7+AVyKheBEyIXrvQQqxP/uo
# zKRdwaGIm1dxVk5IRcBCyZt2WwqASGv9eZ/BvW1taslScxMNelDNMYIZizCCGYcC
# AQEwgZUwfjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNV
# BAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEoMCYG
# A1UEAxMfTWljcm9zb2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMQITMwAAAtvzN7zq
# yhFy4AAAAAAC2zANBglghkgBZQMEAgEFAKCBrjAZBgkqhkiG9w0BCQMxDAYKKwYB
# BAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0B
# CQQxIgQgLbuuHvLlVd0xMUCZH891gVuzMAZpYKflc1ZbBY56uR4wQgYKKwYBBAGC
# NwIBDDE0MDKgFIASAE0AaQBjAHIAbwBzAG8AZgB0oRqAGGh0dHA6Ly93d3cubWlj
# cm9zb2Z0LmNvbTANBgkqhkiG9w0BAQEFAASCAQCgpMbyXAd6iGL/LlUWx7LjAFS7
# SSTbP+GdzaF8bvrO/qKfCDXKr6kEQbHKa7fASulwMa4BJTZxHVl0zNrSKJZsG4Gm
# 1UJIlig1r/O8KB2GzbTR50bYCuKQz3nSj2fnI2MJZWzVTvsq5z3rCrKxE6EJlj9c
# zWQy4EqzbjpG1GeS6x6hpkAt6YJNKCNcH00IsHK9b82BIYHzFgyEu7N92rNCYCqL
# ZWnnX40Zk6ac624e15JX3VTLQVNaxbWupOir+sEnhQ9Kx95algK8HvEC2fqUyjh4
# QXRRMUX7VuR5LLpwa/Hi//1AQbqiriSFHjj3eE1r8HF5XuN5BwtHVH/OERFfoYIX
# FTCCFxEGCisGAQQBgjcDAwExghcBMIIW/QYJKoZIhvcNAQcCoIIW7jCCFuoCAQMx
# DzANBglghkgBZQMEAgEFADCCAVgGCyqGSIb3DQEJEAEEoIIBRwSCAUMwggE/AgEB
# BgorBgEEAYRZCgMBMDEwDQYJYIZIAWUDBAIBBQAEIOOtWcqbfIGAUUp25JBrWtKo
# PO4tKIZPfimbyQeKPFzvAgZi3n8b5NoYEjIwMjIwNzI4MTY0ODQ1LjUyWjAEgAIB
# 9KCB2KSB1TCB0jELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAO
# BgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEt
# MCsGA1UECxMkTWljcm9zb2Z0IElyZWxhbmQgT3BlcmF0aW9ucyBMaW1pdGVkMSYw
# JAYDVQQLEx1UaGFsZXMgVFNTIEVTTjozQkQ0LTRCODAtNjlDMzElMCMGA1UEAxMc
# TWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZaCCEWUwggcUMIIE/KADAgECAhMz
# AAABibS/hjCEHEuPAAEAAAGJMA0GCSqGSIb3DQEBCwUAMHwxCzAJBgNVBAYTAlVT
# MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1l
# LVN0YW1wIFBDQSAyMDEwMB4XDTIxMTAyODE5Mjc0MVoXDTIzMDEyNjE5Mjc0MVow
# gdIxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdS
# ZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xLTArBgNVBAsT
# JE1pY3Jvc29mdCBJcmVsYW5kIE9wZXJhdGlvbnMgTGltaXRlZDEmMCQGA1UECxMd
# VGhhbGVzIFRTUyBFU046M0JENC00QjgwLTY5QzMxJTAjBgNVBAMTHE1pY3Jvc29m
# dCBUaW1lLVN0YW1wIFNlcnZpY2UwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIK
# AoICAQC9BlfFkWZrqmWa47K82lXzE407BxiiVkb8GPJlYZKTkk4ZovKsoh3lXFUd
# YeWyYkThK+fOx2mwqZXHyi04294hQW9Jx4RmnxVea7mbV+7wvtz7eXBdyJuNxyq0
# S+1CyWiRBXHSv4vnhpus0NqvAUbvchpGJ0hLWL1z66cnyhjKENEusLKwUBXHJCE8
# 1mRYrtnz9Ua6RoosBYdcKH/5HneHjaAUv73+YAAvHMJde6h+Lx/9coKbvE3BVzWE
# 40ILPqir3gC5/NU2SQhbhutRCBikJwmb1TRc2ZC+2uilgOf1S1jxhDQ0p6dc+12A
# sd1Dw2e/eKASsoutYjRrmfmON0p/CT7ya9qSp1maU6x545LVeylA0kArW5mWUAhN
# ydBk5w7mh+M5Dfe6NZyQBd3P7/HejuXgBT9NI4zMZkzCFR21XALd1Jsi2lJUWCeM
# zYI4Qn3OAJp286KsYMs3jvWNkjaMKWSOwlN2A+TfjdNADgkW92z+6dmrS4uv6eJn
# dfjg4HHbH6BWWWfZzhRtlc254DjJLVMkZtskUggsCZNQD0C6Pl4hIZNs2LJbHv0e
# cI5Nqvf1AQqjObgudOYNfLT8oj8f+dhkYq5Md9yQ/bzBBLTqsP58NLnEvBxEwJb3
# YOQdea1uEbJGKUE4vkvFl6VB/G3njCXhZQLQB0ASiU96Q4PA7wIDAQABo4IBNjCC
# ATIwHQYDVR0OBBYEFJdvH7NHWngggB6C4DqscqSt+XtQMB8GA1UdIwQYMBaAFJ+n
# FV0AXmJdg/Tl0mWnG1M1GelyMF8GA1UdHwRYMFYwVKBSoFCGTmh0dHA6Ly93d3cu
# bWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY3Jvc29mdCUyMFRpbWUtU3RhbXAl
# MjBQQ0ElMjAyMDEwKDEpLmNybDBsBggrBgEFBQcBAQRgMF4wXAYIKwYBBQUHMAKG
# UGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY2VydHMvTWljcm9zb2Z0
# JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3J0MAwGA1UdEwEB/wQCMAAw
# EwYDVR0lBAwwCgYIKwYBBQUHAwgwDQYJKoZIhvcNAQELBQADggIBAI60t2lZQjgr
# B8sut9oqssH3YOpsCykZYzjVNo7gmX6wfE+jnba67cYpAKOaRFat4e2V/LL2Q6Ts
# tZrHeTeR7wa19619uHuofQt5XZc5aDf0E6cd/qZNxmrsVhJllyHUkNCNz3z452Wj
# D6haKHQNu3gJX97X1lwT7WfXPNaSyRQR3R/mM8hSKzfen6+RjyzN24C0Jwhw8VSE
# jwdvlqU9QA8yMbPApvs0gpud/yPxw/XwCzki95yQXSiHVzDrdFj+88rrYsNh2mLt
# acbY5u+eB9ZUq3CLBMjiMePZw72rfscN788+XbXqBKlRmHRqnbiYqYwN9wqnU3iY
# R2zHPiix46s9h4WwcdYkUnoCK++qfvQpN4mmnmv4PFKpt5LLSbEhQ6r+UBpTGA1J
# BVRfbq3yv59yKSh8q/bdYeu1FXe3utVOwH1jOtFqKKSbPrwrkdZ230ypQvE9A+j6
# mlnQtGqQ5p7jrr5QpFjQnFa12sxzm8eUdl+eqNrCP9GwzZLpDp9r1P0KdjU3PsNg
# EbfJknII8WyuBTTmz2WOp+xKm2kV1SH1Hhx74vvVJYMszbH/UwUsscAxtewSnwqW
# gQa1oNQufG19La1iF+4oapFegR8M8Aych1O9A+HcYdDhKOSQEBEcvQxjvlqWEZMo
# daMLZotU6jyhsogGTyF+cUNR/8TJXDi5MIIHcTCCBVmgAwIBAgITMwAAABXF52ue
# AptJmQAAAAAAFTANBgkqhkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
# c29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlm
# aWNhdGUgQXV0aG9yaXR5IDIwMTAwHhcNMjEwOTMwMTgyMjI1WhcNMzAwOTMwMTgz
# MjI1WjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYD
# VQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDCCAiIwDQYJKoZIhvcN
# AQEBBQADggIPADCCAgoCggIBAOThpkzntHIhC3miy9ckeb0O1YLT/e6cBwfSqWxO
# dcjKNVf2AX9sSuDivbk+F2Az/1xPx2b3lVNxWuJ+Slr+uDZnhUYjDLWNE893MsAQ
# GOhgfWpSg0S3po5GawcU88V29YZQ3MFEyHFcUTE3oAo4bo3t1w/YJlN8OWECesSq
# /XJprx2rrPY2vjUmZNqYO7oaezOtgFt+jBAcnVL+tuhiJdxqD89d9P6OU8/W7IVW
# Te/dvI2k45GPsjksUZzpcGkNyjYtcI4xyDUoveO0hyTD4MmPfrVUj9z6BVWYbWg7
# mka97aSueik3rMvrg0XnRm7KMtXAhjBcTyziYrLNueKNiOSWrAFKu75xqRdbZ2De
# +JKRHh09/SDPc31BmkZ1zcRfNN0Sidb9pSB9fvzZnkXftnIv231fgLrbqn427DZM
# 9ituqBJR6L8FA6PRc6ZNN3SUHDSCD/AQ8rdHGO2n6Jl8P0zbr17C89XYcz1DTsEz
# OUyOArxCaC4Q6oRRRuLRvWoYWmEBc8pnol7XKHYC4jMYctenIPDC+hIK12NvDMk2
# ZItboKaDIV1fMHSRlJTYuVD5C4lh8zYGNRiER9vcG9H9stQcxWv2XFJRXRLbJbqv
# UAV6bMURHXLvjflSxIUXk8A8FdsaN8cIFRg/eKtFtvUeh17aj54WcmnGrnu3tz5q
# 4i6tAgMBAAGjggHdMIIB2TASBgkrBgEEAYI3FQEEBQIDAQABMCMGCSsGAQQBgjcV
# AgQWBBQqp1L+ZMSavoKRPEY1Kc8Q/y8E7jAdBgNVHQ4EFgQUn6cVXQBeYl2D9OXS
# ZacbUzUZ6XIwXAYDVR0gBFUwUzBRBgwrBgEEAYI3TIN9AQEwQTA/BggrBgEFBQcC
# ARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRv
# cnkuaHRtMBMGA1UdJQQMMAoGCCsGAQUFBwMIMBkGCSsGAQQBgjcUAgQMHgoAUwB1
# AGIAQwBBMAsGA1UdDwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaA
# FNX2VsuP6KJcYmjRPZSQW9fOmhjEMFYGA1UdHwRPME0wS6BJoEeGRWh0dHA6Ly9j
# cmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY1Jvb0NlckF1dF8y
# MDEwLTA2LTIzLmNybDBaBggrBgEFBQcBAQROMEwwSgYIKwYBBQUHMAKGPmh0dHA6
# Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljUm9vQ2VyQXV0XzIwMTAt
# MDYtMjMuY3J0MA0GCSqGSIb3DQEBCwUAA4ICAQCdVX38Kq3hLB9nATEkW+Geckv8
# qW/qXBS2Pk5HZHixBpOXPTEztTnXwnE2P9pkbHzQdTltuw8x5MKP+2zRoZQYIu7p
# Zmc6U03dmLq2HnjYNi6cqYJWAAOwBb6J6Gngugnue99qb74py27YP0h1AdkY3m2C
# DPVtI1TkeFN1JFe53Z/zjj3G82jfZfakVqr3lbYoVSfQJL1AoL8ZthISEV09J+BA
# ljis9/kpicO8F7BUhUKz/AyeixmJ5/ALaoHCgRlCGVJ1ijbCHcNhcy4sa3tuPywJ
# eBTpkbKpW99Jo3QMvOyRgNI95ko+ZjtPu4b6MhrZlvSP9pEB9s7GdP32THJvEKt1
# MMU0sHrYUP4KWN1APMdUbZ1jdEgssU5HLcEUBHG/ZPkkvnNtyo4JvbMBV0lUZNlz
# 138eW0QBjloZkWsNn6Qo3GcZKCS6OEuabvshVGtqRRFHqfG3rsjoiV5PndLQTHa1
# V1QJsWkBRH58oWFsc/4Ku+xBZj1p/cvBQUl+fpO+y/g75LcVv7TOPqUxUYS8vwLB
# gqJ7Fx0ViY1w/ue10CgaiQuPNtq6TPmb/wrpNPgkNWcr4A245oyZ1uEi6vAnQj0l
# lOZ0dFtq0Z4+7X6gMTN9vMvpe784cETRkPHIqzqKOghif9lwY1NNje6CbaUFEMFx
# BmoQtB1VM1izoXBm8qGCAtQwggI9AgEBMIIBAKGB2KSB1TCB0jELMAkGA1UEBhMC
# VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNV
# BAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEtMCsGA1UECxMkTWljcm9zb2Z0IEly
# ZWxhbmQgT3BlcmF0aW9ucyBMaW1pdGVkMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVT
# TjozQkQ0LTRCODAtNjlDMzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAg
# U2VydmljZaIjCgEBMAcGBSsOAwIaAxUAIaUJreR63J657Ltsk2laQy6IJxCggYMw
# gYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYD
# VQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0BAQUF
# AAIFAOaM8fAwIhgPMjAyMjA3MjgxOTMwNTZaGA8yMDIyMDcyOTE5MzA1NlowdDA6
# BgorBgEEAYRZCgQBMSwwKjAKAgUA5ozx8AIBADAHAgEAAgIUxTAHAgEAAgITtjAK
# AgUA5o5DcAIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgorBgEEAYRZCgMCoAowCAIB
# AAIDB6EgoQowCAIBAAIDAYagMA0GCSqGSIb3DQEBBQUAA4GBAEyvxTi2lRNWSDrv
# OcN3K4PrhXKr9et+/ojv8eIbi1cOCuZgzKo7v+TQ1exJyfVhYxOq7o7JxLjJucWJ
# xOjINFjr5B+h6f52sRf7l4Ll0XbbHrqGcr/In/wfCeCnKhkAU4RLPSKRkmzKBFPr
# IYfT0ocrrS3eqYBbUnePapSbgtl9MYIEDTCCBAkCAQEwgZMwfDELMAkGA1UEBhMC
# VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNV
# BAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRp
# bWUtU3RhbXAgUENBIDIwMTACEzMAAAGJtL+GMIQcS48AAQAAAYkwDQYJYIZIAWUD
# BAIBBQCgggFKMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0BCRABBDAvBgkqhkiG9w0B
# CQQxIgQgUPIaEhZduCs5HGtcLmSiiueFmItnTO9g1s6Pv7+/s/owgfoGCyqGSIb3
# DQEJEAIvMYHqMIHnMIHkMIG9BCBmd0cx3FBXVWxulYc5MepYTJy9xEmbtxjr2X9S
# ZPyPRTCBmDCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9u
# MRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRp
# b24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAAB
# ibS/hjCEHEuPAAEAAAGJMCIEIPIzil9vf31hsaCKDI2lDVQc8BabH/n6zMwnZV2g
# SLhyMA0GCSqGSIb3DQEBCwUABIICAAxKvSUC1E4vdsP6zScpcVgoBpy1v6VzyVzB
# KZP1ok4sNP+oPUc543ynGWmeLb9XPOYBQpWEfsY+1PX5Xe3Je9LAGp5UB2f0yrB9
# ZcbgFwUAqulY/ibz3F5EymAgaFcR2JhUk9aANSPA91WuVNKwa5xhyEYcNGR+qog5
# Ti+HVEkiHK4fQZ43SOUtHTRC9FMcdvmETIYPDrLP2WdXVDI9hTcszeVs6AIaVJ+d
# fFpLW3kNeYOoI7nE4DATfee4T/ADXtHroO4FqDAmtPlZnVywLJ3eDdHQL9ysBldL
# vmcivxFNKvasaaX3biy1ClDjx97IIMA128lFy5FPh4DOZKhEXBuv7I+CVY5/sSr+
# 2MM1WZ+cF/E5DJALCSzMVHG0/hB852dUvdgUvOGEZUjvBAkzDEGl/nmpT92FniVQ
# 3mPoO+NLpwNyxjXE5ns9/wmjLONc7SmxWUFYMEu7khn8bgcVyTGy3inOTMydy5xs
# YoEzkr+CR3v3vZFucu9RuxMl23mVY3GfkzVF0C+CPGDxHtEHREesqf5ECPIjXvf6
# XEDlJ8El9hJVCZ3W8DoR1cRmMQE1vNaNHLsLvyittdRnMtBlcPCvbcWz7N+rT7X3
# qHEf1l4f1FrWaPOEFvJiqku+pkFbgG27VKs2GIutz9FKMsLcPULRidUfDnTTkMe8
# UHsIKXtq
# SIG # End signature block
