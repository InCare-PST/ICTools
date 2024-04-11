Echo off
powershell.exe -executionpolicy bypass .\get-softwareinventory.ps1
del .\get-softwareinventory.ps1
cd ..
del .\"incareanalysis.zip"