# Title: Add group members in Microsoft Entra Identity
# Created: 2024-03-15
# This scrip add's users to their department security group in Microsoft Entra Identity
#
# The script uses the Microsoft Graph PowerShell SDK to create the groups
# The script uses the Add-MgGroupMember and Get-MgGroup cmdlets
#
# Micorosoft Learn: Groups
# Get-MgGroup - https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.groups/get-mggroup?view=graph-powershell-1.0
# New-MgGroupMember - https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.groups/new-mggroupmember?view=graph-powershell-1.0
#

$TenantID = "e0294a3a-a293-4611-b89a-4d48a2f076ca" # Remember to change this to your own TenantID
Connect-MgGraph -TenantId $TenantID -Scopes "User.ReadWrite.All", "Group.ReadWrite.All", "Directory.ReadWrite.All", "RoleManagement.ReadWrite.Directory"

# Get the current session details
$Details = Get-MgContext
$Scopes = $Details | Select-Object -ExpandProperty Scopes
$Scopes = $Scopes -join ","
$OrgName = (Get-MgOrganization).DisplayName
""
""
"Microsoft Graph current session details:"
"---------------------------------------"
"Tenant Id = $($Details.TenantId)"
"Client Id = $($Details.ClientId)"
"Org name  = $OrgName"
"App Name  = $($Details.AppName)"
"Account   = $($Details.Account)"
"Scopes    = $Scopes"
"---------------------------------------"



# Root folder for the project
$rootFolder = "C:\Users\sondr\OneDrive - NTNU\DIGSEC\1. år DIGSEC\Vår 24\DCST1005 - Infrastruktur, sikre grunntjenester\DCST1005 GIT\DCST1005---Infrastruktur-Sikre-grunntjenester"

# Variables for groups created and not created
$usersAddedToGroup = @()
$usersNotAddedToGroup = @()
$groupsNotExists = @()

# Group prefix / suffix
$prefix = "s_" # s_ for security groups, m_ for Microsoft 365 groups etc.
$suffix = "_group"


# Getting all users into an array with the Get-MgUser cmdlet and department property
$users = Get-MgUser -All -Property Group, Department, UserPrincipalName, Id |
    Where-Object { $_.Department -ne $null -and $_.Department -ne '' } | 
    Select-Object Group, Department, UserPrincipalName, Id

foreach ($user in $users) {
    $group = $prefix + $user.Department + $suffix
    $existingGroup = Get-MgGroup -Filter "displayName eq '$group'"
    if ($existingGroup) {
        try {
            Write-Host "Adding user $($user.UserPrincipalName) to group $group" -ForegroundColor Green
            New-MgGroupMember -GroupId $existingGroup.Id -DirectoryObjectId $user.Id 
            $usersAddedToGroup += $user.UserPrincipalName
        }
        catch {
            Write-Host "Failed to add user $($user.UserPrincipalName) to group $group" -ForegroundColor Red
            $usersNotAddedToGroup += $user.UserPrincipalName
        }
    }
    else {
        Write-Host "Group $group does not exist" -ForegroundColor Red
        $groupsNotExists += $group
    }
}

# Convert the array of strings to an array of objects with a 'UserPrincipalName' and 'department' property
$usersAddedToGroup = $usersAddedToGroup | ForEach-Object { [PSCustomObject]@{ UserPrincipalName = $_ } }
$usersNotAddedToGroup = $usersNotAddedToGroup | ForEach-Object { [PSCustomObject]@{ UserPrincipalName = $_ } }
$groupsNotExists = $groupsNotExists | ForEach-Object { [PSCustomObject]@{ Group = $_ } }

# Export the results to CSV files
$usersAddedToGroup | Export-Csv "$rootFolder\users_added_to_group.csv" -NoTypeInformation -Encoding utf8
$usersNotAddedToGroup | Export-Csv "$rootFolder\users_not_added_to_group.csv" -NoTypeInformation -Encoding utf8
$groupsNotExists | Export-Csv "$rootFolder\groups_not_exists.csv" -NoTypeInformation -Encoding utf8

