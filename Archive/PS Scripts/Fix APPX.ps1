<# This is not an IC Team original Script
Credit goes to https://gist.github.com/aplocher/b10131abc9a4db3dff984416ababd2c1
#>

param (
[switch]$Relaunched = $false
)

$ScriptPath = (Get-Variable MyInvocation).Value.MyCommand.Path

function StartOperation {
    Write-Host
    Write-Host Now attempting to regenerate missing manifest files...
    Write-Host
    Find-Module PSSqlite | Install-Module
    Write-Host Installing PSSqlite Module if necessary
    Write-Host

    Import-Module PSSqlite
    Write-Host Importing PSSqlite Module
    Write-Host

    $appRepoPath="$($env:ProgramData)\Microsoft\Windows\AppRepository"
    #$appRepoPath="C:\Users\a\Desktop\testapprep"

    Invoke-SqliteQuery -Query "SELECT _PackageID, PackageFullName FROM Package" -Datasource "$($appRepoPath)\StateRepository-Machine.srd" |
        Select-Object _PackageID, PackageFullName, @{Name="FullPath";Expression={"$($appRepoPath)\$($_.PackageFullName).xml"}} |
        Where-Object { (Test-Path $_.FullPath) -eq $false } |
        % {
            $fullPath=$_.FullPath
            Write-Host * Generating $fullPath
            Invoke-SqliteQuery -Query "SELECT * FROM AppxManifest WHERE Package=$($_._PackageID)" -Datasource "$($appRepoPath)\StateRepository-Deployment.srd" |
            % { Out-File -NoClobber -FilePath $fullPath -InputObject $_.Xml }
        }

    Write-Host
    Write-Host Done
    Start-Sleep 3
}

function RelaunchProcessAsSystem {
 	try {
        $AdminProcess = Start-Process -NoNewWindow -Wait -PassThru "psexec.exe" -ArgumentList "-AcceptEula -s ""$PSHOME\powershell.exe"" -ExecutionPolicy Unrestricted -file ""$ScriptPath"" -Relaunched"
		return $AdminProcess
    } catch {
        $Error[0]
        exit 1
    }
}

function RunAsSystem {
	if ($Relaunched) {
        Write-Host 'Starting Operation'
        Start-Sleep -Seconds 1
		StartOperation
	} else {
        CheckDependencies
        Write-Host
		Write-Host 'Running tasks under LOCAL SYSTEM user account'
        Write-Host '(note, a separate window may popup)'
		$AdminProcess = RelaunchProcessAsSystem

		while (-not $AdminProcess.HasExited) {
	        Start-Sleep -Seconds 1
	    }
	}
}

function CheckDependencies {
    Write-Host 'Running as admin? .......... ' -nonewline
    $isRunningAsAdmin=([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if ($isRunningAsAdmin) {
    	Write-Host -foregroundcolor Green 'YES'
	} else {
		Write-Host -foregroundcolor Red 'NO'
		exit 1
	}

    Write-Host 'Is psexec.exe found? ....... ' -nonewline
    $isPsExecFound=((Get-Command "psexec.exe" -ErrorAction SilentlyContinue) -ne $null)
    if ($isPsExecFound) {
    	Write-Host -foregroundcolor Green 'YES'
	} else {
		Write-Host -foregroundcolor Red 'NO'
		exit 1
	}
}

RunAsSystem
Start-Sleep -Seconds 1
