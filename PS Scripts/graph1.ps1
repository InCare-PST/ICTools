Connect-Graph -Scopes "User.Read.All"

# Retrieve a list of users
$users = Get-MgUser -Top 1000

# Create an empty array to store the user data
$userData = @()

# Loop through each user
foreach ($user in $users) {
    # Retrieve the user's licensing information
    $licensing = Get-MGUserLicenseDetail -UserId $user.id

    # Create an object to store the user's data
    $userObject = [PSCustomObject]@{
        DisplayName = $user.displayName
        FirstName = $user.givenName
        LastName = $user.surname
        Licensing = ($licensing.servicePlans | Select-Object -ExpandProperty servicePlanName) -join ','
    }
    # Add the user data to the array
    $userData += $userObject
}

# Export the user data to a CSV file
$userData | Export-Csv -Path "c:\temp\UserData.csv" -NoTypeInformation