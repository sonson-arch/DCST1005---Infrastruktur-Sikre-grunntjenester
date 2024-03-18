# Get all groups
$groups = Get-MgGroup -All

# For each group, get its members
$groupsWithMembers = $groups | ForEach-Object {
    $group = $_
    $members = Get-MgGroupMember -GroupId $group.Id -All

    # For each member, get the user object and select only the relevant properties
    $members = $members | ForEach-Object {
        $user = Get-MgUser -UserId $_.Id
        [PSCustomObject]@{
            UserPrincipalName = $user.UserPrincipalName
            DisplayName = $user.DisplayName
        }
    }

    # Create a custom object for the group that includes its members
    [PSCustomObject]@{
        GroupId = $group.Id
        GroupDisplayName = $group.DisplayName
        Members = $members
    }
}

# Output the groups with their members
foreach ($group in $groupsWithMembers) {
    Write-Host "Group ID: $($group.GroupId)"
    Write-Host "Group Display Name: $($group.GroupDisplayName)"
    Write-Host "Members:"
    $group.Members | Format-Table
    Write-Host "`n"  # Add a newline for readability
}
