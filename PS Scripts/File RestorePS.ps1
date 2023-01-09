
$restorelist = @()
$failedlist = @()
$tpath = "c:\temp"

$Files = (Get-ChildItem -Include *.jse -path d:\ -recurse | Where-Object {$_.LastWriteTime -GE (Get-Date).AddDays(-3)})

Foreach ($file in $files){
  $pass1 = $file.FullName
  $pass2 = $pass1.replace("D:\","X:\")
  $pass3 = $pass2.replace(".jse",".*")
  $pass4 = $file.DirectoryName

  copy-item $pass3 $pass4 -ErrorVariable Fail

  IF(!$Fail){
    write-host -ForegroundColor Green "`n"$pass3" Copied Normally`n"

  $tempobj = @{
  CorruptedFile = $file.Name
  CorruptedFilePath = $file.DirectoryName
  Status = "Success"
  TimeStamp = (Get-Date -Format "dd-MM-yyyy HH:mm:ss")
  FullPath = $file.fullname
  }

  $LogObj = New-Object -TypeName psobject -Property $tempobj
  $RestoreList += $LogObj

    }else{
      write-host -ForegroundColor Red "`n"$pass3" Copy Failed!`n"

    $tempobj = @{
    CorruptedFile = $file.Name
    CorruptedFilePath = $file.DirectoryName
    Status = "Failed"
    TimeStamp = (Get-Date -Format "dd-MM-yyyy HH:mm:ss")
    FullPath = $file.fullname
  }

  $LogObj = New-Object -TypeName psobject -Property $tempobj
  $FailedList += $LogObj
  $FailedList += $Fail
  $fail = $null
    }

$restorelist | Export-Csv -Path $tpath\Restoredlog.txt -NoTypeInformation -Append
$failedlist | Export-Csv -Path $tpath\Failedlog.txt -NoTypeInformation -Append
}
