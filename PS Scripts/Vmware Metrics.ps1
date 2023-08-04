$metrics = "cpu.usage.average","mem.usage.average","disk.usage.average" 
$start = (Get-Date).AddDays(-30)

$folders = Get-Folder -Location (Get-Folder -Name vm -Location Datacenters)
# $folders = Get-Folder -Name Folder1,Folder2,Folder3
&{foreach($folder in $folders){
    $vms = Get-VM -Location $folder
    if($vms){
      $stats = Get-Stat -Entity $vms -Stat $metrics -Start $start -ErrorAction SilentlyContinue
      if($stats){
        $stats | Group-Object -Property {$_.Entity.Name} | %{
          New-Object PSObject -Property @{
            Folder = $folder.Name
            VM = $_.Values[0]
            CpuLow = ($_.Group | where {$_.MetricId -eq "cpu.usage.average"} | Sort-Object Value |Select-Object -First 1)
            CpuHigh = ($_.Group | where {$_.MetricId -eq "cpu.usage.average"} | Sort-Object Value -Descending |Select-Object -First 1)
            CpuAvg = ($_.Group | where {$_.MetricId -eq "cpu.usage.average"} | Measure-Object -Property Value -Average).Average
            MemLow = ($_.Group | where {$_.MetricId -eq "mem.usage.average"} | Sort-Object Value |Select-Object -First 1)
            MemHigh = ($_.Group | where {$_.MetricId -eq "mem.usage.average"} | Sort-Object Value -Descending |Select-Object -First 1)
            MemAvg = ($_.Group | where {$_.MetricId -eq "mem.usage.average"} | Measure-Object -Property Value -Average).Average
            DiskLow = ($_.Group | where {$_.MetricId -eq "disk.usage.average"} | Sort-Object Value |Select-Object -First 1)
            DiskHigh = ($_.Group | where {$_.MetricId -eq "disk.usage.average"} | Sort-Object Value -Descending |Select-Object -First 1)
            DiskAvg = ($_.Group | where {$_.MetricId -eq "disk.usage.average"} | Measure-Object -Property Value -Average).Average
                   
          }
        }
      }
    }
  }} | Export-Csv C:\temp\Chesters_report.csv -NoTypeInformation -UseCulture 