$computers = Get-ADComputer -Filter * -Properties * | where enabled -eq $true 
$verified = @()
 % ($comp in $computers) {
  $r = Test-WSMan $_ -ErrorAction Stop
  if ($r) {
    #$True
    #write-host ($comp.Name + " :Boom")
    $verified += ($comp | select -ExpandProperty name)
  }
  else {
    $False
    write-host ($comp.Name + " :Damn")
   }
  }



  $verified | sort