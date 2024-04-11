Function Get-ICTBacklog {
<#
Insert some rando explanation here...
Script a bit slow processing dfsrdiag command, see if it can be sped up
#>

$backlog = dfsrdiag backlog /rgname:'Public Data' /rfname:D /smem:WIN-VCPI01XMY7P /rmem:WSG-DC01

  write-host -ForegroundColor Red ($backlog | Select-String 'Backlog File Count')
  <#Insert Line here to Log and show last 5 entries!#>

}
$backlog = $Null

Get-ICTBacklog

