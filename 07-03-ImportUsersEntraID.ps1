$TenantID = "e0294a3a-a293-4611-b89a-4d48a2f076ca"
Connect-MgGraph -TenantId $TenantID -Scopes "User.ReadWrite.All", "Group.ReadWrite.All", "Directory.ReadWrite.All", "RoleManagement.ReadWrite.Directory"

$users = Import-CSV -Path '/Users/melling/git-projects/dcst1005/07-00-CSV-Users.csv' -Delimiter ","

$PasswordProfile = @{
    Password = 'DemoPassword12345!'
    }
foreach ($user in $users) {
    $Params = @{
        UserPrincipalName = $user.userPrincipalName + "digsecgr12.onmicrosoft.com"
        DisplayName = $user.displayName
        GivenName = $user.GivenName
        Surname = $user.Surname
        MailNickname = $user.userPrincipalName
        AccountEnabled = $true
        PasswordProfile = $PasswordProfile
        Department = $user.Department
        CompanyName = "DiggyCyb Sec"
        Country = "Norway"
        City = "Trondheim"
    }
    $Params
    New-MgUser @Params
}