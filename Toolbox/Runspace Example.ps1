# BLOCK 1: Create and open runspace pool, setup runspaces array with min and max threads
$pool = [RunspaceFactory]::CreateRunspacePool(1, [int]$env:NUMBER_OF_PROCESSORS+1)
$pool.ApartmentState = "MTA"
$pool.Open()
$runspaces = $results = @()
# BLOCK 2: Create reusable scriptblock. This is the workhorse of the runspace. Think of it as a function.
$scriptblock = {
Param (
[string]$connectionString,
[object]$batch,
[int]$batchsize
)
$bulkcopy = New-Object Data.SqlClient.SqlBulkCopy($connectionstring,"TableLock")
$bulkcopy.DestinationTableName = "mytable"
$bulkcopy.BatchSize = $batchsize
$bulkcopy.WriteToServer($batch)
$bulkcopy.Close()
$dtbatch.Clear()
$bulkcopy.Dispose()
$dtbatch.Dispose()
# return whatever you want, or don't.
return $error[0]
}
# BLOCK 3: Create runspace and add to runspace pool
if ($datatable.rows.count -eq 50000) {
$runspace = [PowerShell]::Create()
$null = $runspace.AddScript($scriptblock)
$null = $runspace.AddArgument($connstring)
$null = $runspace.AddArgument($datatable)
$null = $runspace.AddArgument($batchsize)
$runspace.RunspacePool = $pool
# BLOCK 4: Add runspace to runspaces collection and "start" it
# Asynchronously runs the commands of the PowerShell object pipeline
$runspaces += [PSCustomObject]@{ Pipe = $runspace; Status = $runspace.BeginInvoke() }
$datatable.Clear()
}
# BLOCK 5: Wait for runspaces to finish
while ($runspaces.Status.IsCompleted -notcontains $true) {}
# BLOCK 6: Clean up
foreach ($runspace in $runspaces ) {
# EndInvoke method retrieves the results of the asynchronous call
$results += $runspace.Pipe.EndInvoke($runspace.Status)
$runspace.Pipe.Dispose()
}
$pool.Close()
$pool.Dispose()
# Bonus block 7
# Look at $results to see any errors or whatever was returned from the runspaces
