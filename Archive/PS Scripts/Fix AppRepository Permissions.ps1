#This is not a finished script, just an example, do not use!

cd c:\ProgramData\Microsoft\Windows

#Take ownership of all the files and folders from AppRepository and enclosing files/folders:

takeown /F AppRepository /R

#Grant current user full control on all files and folders from AppRepository and enclosing files/folders. My current user is “tcadmin” so replace that with the name of your current user:
#icacls AppRepository /grant tcadmin:F /T /C

#Restore from a known good machine using the file copied in step 1. There may be a some errors about files not found but the far majority of the permissions should be successful:

icacls . /restore c:\AppRepo_export_full /C

#Now that the permissions are set correctly, we’ll set the ownership to the SYSTEM user. However, to do this, we give ourself full control over the files and folders and then set ownership. After we are all done, we’ll remove this full control permission. Make ownership of AppRepository and enclosing files/folders to the SYSTEM user (remember to replace tcadmin with your current user name):

icacls AppRepository /grant tcadmin:F /T /C
icacls AppRepository /setowner SYSTEM /T /C

#Make ownership of top level folders to (AppRport, packages, family) to NT Service\TrustedInstaller
icacls AppRepository /setowner “NT Service\TrustedInstaller”
icacls AppRepository\Packages /setowner “NT Service\TrustedInstaller”
icacls AppRepository\Families /setowner “NT Service\TrustedInstaller”

icacls AppRepository /remove:g tcadmin /T /C
