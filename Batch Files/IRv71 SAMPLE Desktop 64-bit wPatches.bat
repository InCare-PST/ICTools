@echo off
REM *** 11/01/2021
REM *** Hotfixes as of 11/01/2021
CLS

REM ------------------------------------------------------
REM --------------- SET Location of InstallFiles ---------
REM ------------------------------------------------------
REM *****************  UPDATE = UPDATE = UPDATE   ********
REM ******  !!! VERIFY this location share or path !!! ***
REM             ----------------------------------
SET InstallFiles=\\c:\ThriveAgent\ImageRight
Set VersionNumber=7.1


REM ------------------------------------------------------
REM --------------- NOTES --------------------------------
REM ------------------------------------------------------
REM *** Make sure the following files are in the SAME location as the batch file :

REM - IRDesktop.msi
REM - ImageRight.PDFPrinter.64.msi
REM - IRDocumentconverter.64.msi
REM - IRMicrosoftAddin.msi - ......................................	
REM - IROutlookInterface.msi - Outlook Interface for Web Browser ..	** CLIENT SPECIFIC - May Not Be Implemented in Your environment? **
REM - IRConnect.msi - Web Browser document import .................	
REM - IRAdobePlugin.msi - .........................................	** CLIENT SPECIFIC - May Not Be Implemented in Your environment? **
REM - IRInstallerService.msi - upgrader component .................	** CLIENT SPECIFIC - May Not Be Implemented in Your environment? **
REM - !!!  imageright.desktop.exe.config  ** Copy from app_server\program files (x86)\imageright\clients\imageright.desktop.exe.config
REM - Patches
REM - 	IRDesktop.Patch.7.106.1799.msp
REM - 	IRConnect.Patch.7.106.1788.msp
REM - 	IRWFStudio.Patch.7.106.1803.msp
REM -   IRAdmin.Patch.7.0.106.1804.msp   ( Enterprise Management Console )
REM -   IRScanner.Patch.7.0.106.1789.msp

REM ------------------------------------------------------
REM --------------- CHECK FOR IRMARKER FILE --------------
REM --------Has this already been run on this Desktop? ---
REM ------------------------------------------------------
REM if exist "%programFiles%\IRmarker.%VersionNumber%.setup.log" goto END

REM --------------- Install Document Converter -----------
REM ------------------------------------------------------
ECHO ...... INSTALL 64-BIT DOCUMENT CONVERTER ......
start /w msiexec /qn /i "%InstallFiles%\IRDocumentConverter.64.msi" /passive /l*v %windir%\Temp\IRDocumentConverter.log ALLUSERS=true

REM ------------------------------------------------------
REM ----------- Install ImageRight PDF Printer -----------
REM ------------------------------------------------------
ECHO ...... INSTALL 64-BIT IMAGERIGHT PDF PRINTER ......
start /w msiexec /qn /i "%InstallFiles%\ImageRight.PDFPrinter.64.msi" /passive /log %windir%\Temp\IRPDFPrinter.log ALLUSERS=true

REM ------------------------------------------------------
REM --------------- Install ImageRight Desktop -----------
REM ------------------------------------------------------
ECHO ...... INSTALLING IMAGERIGHT Desktop ......
start /w msiexec /qn /i "%InstallFiles%\IRDesktop.msi" /passive /log %windir%\Temp\IRDesktop.log ALLUSERS=true

REM ------------ v7 End User Patches -------------------
ECHO ...... INSTALLING IMAGERIGHT DESKTOP Patch......
msiexec /qn /update "%InstallFiles%\IRDesktop.Patch.7.1.112.2401.msp" /l*v %windir%\Temp\IRDesktop_patch.log

REM ------------------------------------------------------
REM --------------- Install Microsoft AddIn --------------
REM --------------- ** CLIENT SPECIFIC ** ----------------
REM --- Unremark if Used in Your Environment -------------
REM ------------------------------------------------------
 ECHO ...... INSTALLING MICROSOFT ADDIN ......
 start /w msiexec /i "%InstallFiles%\IRMicrosoftAddin.msi" /passive /log %windir%\Temp\IRMicrosoftAddin.log ALLUSERS=true

REM ------------------------------------------------------
REM --------------- Install Adobe PlugIn -----------------
REM --------------- ** CLIENT SPECIFIC ** ----------------
REM --- Unremark if Used in Your Environment -------------
REM ------------------------------------------------------
ECHO ...... INSTALLING ADOBE PLUGIN ......
start /w msiexec /i "%InstallFiles%\IRAdobePlugin.msi" /passive /log %windir%\Temp\IRMicrosoftAddin.log ALLUSERS=true

REM ------------------------------------------------------
REM --------------- Install Outlook Interface ------------ 
REM --------------- ** CLIENT SPECIFIC ** ---------------- 
REM --- Unremark if Used in Your Environment -------------
REM ------------------------------------------------------
REM ECHO ...... INSTALLING OUTLOOK INTERFACE ......
REM start /w msiexec /i "%InstallFiles%\IROutlookInterface.msi" /passive /log %windir%\Temp\IRMicrosoftAddin.log ALLUSERS=true

REM ------------------------------------------------------
REM ---- UNInstall PREVIOUS VERSION ImageRight Printer ---
REM --- Unremark if To Remove from Your Environment ------
REM ------------------------------------------------------
REM ECHO ...... UnINSTALLING PREVIOUS VERSION IMAGERIGHT PRINTER ......
REM start /w msiexec /x "%windir%\install5\installs\IRDocCap.msi" /passive /log %windir%\Temp\IRDocCap.log ALLUSERS=true


REM *****************  UPDATE = UPDATE = UPDATE   ********
REM ------------------------------------------------------
REM --------------- Install ImageRight Connect -----------
REM ------------------------------------------------------
REM	WEB_CLIENT_URL  - Web Browser server url
REM	SSL_PORT_NUMBER	- default => 21738
REM	INSTALL_SERVICE - FALSE
REM ECHO ...... INSTALLING IMAGERIGHT CONNECT ......
REM start /w msiexec /i "%InstallFiles%\IRConnect.msi" WEB_CLIENT_URL="https://server.domain.com" SSL_PORT_NUMBER="21738" INSTALL_SERVICE="FALSE" /passive /l*v %windir%\Temp\IRConnect.log ALLUSERS=true

REM ------------------------------------------------------
REM ECHO ...... INSTALLING IMAGERIGHT CONNECT Patch......
REM msiexec /qn /update "%InstallFiles%\IRConnect.Patch.7.106.1788.msp" /l*v %windir%\Temp\IR1540patch.log


REM *****************  UPDATE = UPDATE = UPDATE   ********
REM ------------------------------------------------------
REM --------------- Install Installer Service  -----------
REM --------------- ** CLIENT SPECIFIC ** ----------------
REM --- Unremark if Used in Your Environment -------------
REM ------------------------------------------------------
REM	SERVICE_URL - InstallerServer port must be given � 80 is the default
REM	ACCOUNT - Domain\user should be a Domain Admin so that it run the installs regardless of local rights 
REM	PASSWORD - user password, Password1 is just an example
REM ECHO ...... INSTALLING IMAGERIGHT INSTALLER SERVICE ......
REM Verifiy the location of the irinstallerservice.msi
REM
REM start /w msiexec /i "%InstallFiles%\irinstallerservice.msi" SERVICE_URL="http://server.domain.com:80/IRInstallerServer" ACCOUNT="domain\user" PASSWORD="password_value" /passive /l*v %windir%\Temp\IRInstaller.log ALLUSERS=true

REM ------------------------------------------------------
REM --------------- Copy Desktop Config File -------------
REM ------------------------------------------------------
ECHO ...... COPY IMAGERIGHT.DESKTOP.EXE.CONFIG ......
cd "%ProgramFiles% (x86)\ImageRight\Clients"
copy /Y /V "%InstallFiles%\imageright.desktop.exe.config"

REM ------------------------------------------------------
REM --------------- Create IRMarker File -----------------
REM ------------------------------------------------------
REM echo done >> "%programFiles%\IRmarker.%VersionNumber%.setup.log"


:END
EXIT


============================================================================================
REM ---- FOR Reference ONLY ------------------------------
REM ---- OTHER INSTALLS  - separate batch file
REM ---- When installing from .msi you must! copy a Correct .config file over the installed one
REM ---- Installing from .msi ~~ Does Not Read ~~ from Settings.ini for correct values
============================================================================================
REM Scanner
REM ECHO ...... INSTALLING IMAGERIGHT Scanner......
REM start /w msiexec /qn /i "%InstallFiles%\IRscanner.msi" /passive /log %windir%\Temp\IRDesktop.log ALLUSERS=true
ECHO ...... INSTALLING IMAGERIGHT Scanner Patch......
msiexec /qn /update "%InstallFiles%\IRScanner.Patch.7.0.106.1789.msp" /l*v %windir%\Temp\IRscan_patch.log


REM Workflow Studio
REM ECHO ...... INSTALLING IMAGERIGHT WorkFlow Studio......
REM start /w msiexec /qn /i "%InstallFiles%\IRWFStudio.msi" /passive /log %windir%\Temp\IRWF.log ALLUSERS=true
ECHO ...... INSTALLING IMAGERIGHT Workflow Patch......
msiexec /qn /update "%InstallFiles%\IRDesktop.Patch.7.0.106.1803.msp" /l*v %windir%\Temp\IRWF.log

REM EMC
REM ECHO ...... INSTALLING IMAGERIGHT EMC......
REM start /w msiexec /qn /i "%InstallFiles%\IRAdmin.msi" /passive /log %windir%\Temp\IRDesktop.log ALLUSERS=true
ECHO ...... INSTALLING IMAGERIGHT EMC Patch......
msiexec /qn /update "%InstallFiles%\IRadmin.Patch.7.0.106.1804.msp" /l*v %windir%\Temp\IREMC.patch.log




