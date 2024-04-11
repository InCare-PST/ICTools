
$outfile = "C:\WindowsPowershell\quicklog-local.txt"


"=======================================================
Scan Loop $loop
" | Out-File $outfile -Append
Get-Date | Out-File $outfile -Append
"
=======================================================
" | Out-File $outfile -Append




        Write-Host (Get-Date -f 'yyyy-MM-dd hh:mm:ss')

            $path1 = "C:\*"
            $path2 = "C:\Users\*"
            $path3 = "C:\Windows\*"
            $comp = $env:COMPUTERNAME
            # $filenames = @('mttvca.exe','mssvca.exe','44783m8uh77g8l8_nkubyhu5vfxxbh878xo6hlttkppzf28tsdu5kwppk_11c1jl.exe')
            $filelengths = @(578690)
            Write-Host $path1
            $files = Get-ChildItem -Path $path1 -Filter {LastWriteTime -ge (Get-Date).AddHours(-24) -and -not $_.PSIsContainer} -Include *.dll,*.ocx,*.exe
            $files | Select -First 1 | fl
          #  $files | Select Name, Path, LastWriteTime

            Write-Host $path2
            $files = Get-ChildItem -Path $path2 -Recurse -Filter {LastWriteTime -ge (Get-Date).AddHours(-24) -and -not $_.PSIsContainer} -Include "*.dll","*.ocx","*.exe"
            $files | Select -First 1 | fl

          $response  | Out-File $outfile -Append
  