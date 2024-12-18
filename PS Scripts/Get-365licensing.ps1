Connect-MgGraph -Scopes "Organization.Read.All", "Directory.Read.All", "Directory.ReadWrite.All"
Select-MgProfile beta
[Array]$Skus = Get-MgSubscribedSku
# Generate CSV of all product SKUs used in tenant
$Skus | Select-Object SkuId, SkuPartNumber, DisplayName  | Export-Csv -NoTypeInformation c:\temp\ListOfSkus.Csv
# Generate list of all service plans used in SKUs in tenant
$SPData = [System.Collections.Generic.List[Object]]::new()
ForEach ($S in $Skus) {
   ForEach ($SP in $S.ServicePlans) {
     $SPLine = [PSCustomObject][Ordered]@{  
         ServicePlanId = $SP.ServicePlanId
         ServicePlanName = $SP.ServicePlanName
         ServicePlanDisplayName = $SP.ServicePlanName }
     $SPData.Add($SPLine)
 }
}
$SPData | Sort-Object ServicePlanId -Unique | Export-csv c:\Temp\ServicePlanData.csv -NoTypeInformation

$msskulist = Import-Csv -Path 'C:\temp\Product names and service plan identifiers for licensing.csv'
foreach($K in $Skus){
    $MSplan = $msskulist | Where-Object {$_.Guid -Match $K.skuid} | Select-Object -First 1
    $k.PrepaidUnits
    $k.skuid
    $K.consumedunits
    $msplan.Product_Display_Name
}