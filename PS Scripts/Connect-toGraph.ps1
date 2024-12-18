# Connect to Microsoft Graph
#JTG 

[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
$scope = [Microsoft.VisualBasic.Interaction]::InputBox("Enter Scope Requested", "Scope", "User.Read.All,Organization.Read.All,AuditLog.Read.All,Directory.Read.All,UserAuthenticationMethod.Read.All,Reports.Read.All,Policy.Read.All,Directory.Read.All,Application.Read.All")

Connect-MgGraph -Scopes $scope

