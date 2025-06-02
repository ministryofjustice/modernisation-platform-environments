param (
    [Parameter(
        Position = 1)]
    [String]$Export_Folder = "C:\i2N\AD_Files",
    [Parameter(
        Position = 2)]
    [String]$yjaf_users_file = "users.csv",
    [Parameter(
        Position = 3)]
    [String]$yjaf_groups_file = "groups.csv",
    [Parameter(
        Position = 4)]
    [String]$yjaf_roles_File = "roles.csv",
    [Parameter(
        Position = 3)]
    [String]$yjaf_group_members_file = "group-members.csv",
    [Parameter(
        Position = 4)]
    [String]$yjaf_role_members_File = "role-members.csv"
)

$usersFilePath        = "${Export_Folder}\${yjaf_users_file}"
$groupsFilePath        = "${Export_Folder}\${yjaf_groups_file}"
$rolesFilePath        = "${Export_Folder}\${yjaf_roles_File}"
$groupMembersFilePath        = "${Export_Folder}\${yjaf_group_members_file}"
$roleMembersFilePath        = "${Export_Folder}\${yjaf_role_members_File}"

$logFile        = "${Export_Folder}\Import_YJAF_Users_Log_$(Get-Date -Format "yyyyMMdd hhmm").log"

Write-Output "$(Get-Date) Starting Group Import from ${groupsFilePath}" | Tee-Object -FilePath $logFile -Append

#Import Groups to OU i2N\Accounts\Groups
Import-Csv -Path "${groupsFilePath}" | ForEach-Object { #for each line in csv add AD group
    New-ADGroup -Name $_.Name `
                -GroupScope $_.GroupScope `
                -Path "OU=Groups,OU=Accounts,OU=i2N,DC=i2n,DC=com" `
                -GroupCategory Security
}

Write-Output "$(Get-Date) Starting Roles Import from ${rolesFilePath}" | Tee-Object -FilePath $logFile -Append

#import Groups the represent Roles to OU i2N\Accounts\Roles
Import-Csv -Path "${rolesFilePath}" | ForEach-Object { #for each line in csv add AD role
    New-ADGroup -Name $_.Name `
            -SamAccountName $_.SamAccountName `
            -GroupScope $_.GroupScope `
            -GroupCategory $_.GroupCategory `
            -Path "OU=Roles,OU=Accounts,OU=i2N,DC=i2n,DC=com"
}

# Load Password File and generate a randonm password
. .\generate-password.ps1
$secure = GeneratePassword 20

Write-Output "$(Get-Date) Starting User Import from ${usersFilePath}" | Tee-Object -FilePath $logFile -Append

#Import Account usersvto OU i2n|Accounts\Users
Import-Csv -Path "${usersFilePath}" | ForEach-Object { #for each line in csv add AD user
    $user = New-ADUser -Name $_.Name `
            -SamAccountName $_.SamAccountName `
            -UserPrincipalName $_.UserPrincipalName `
            -GivenName $_.GivenName `
            -Initials $_.Initials `
            -Surname $_.sn `
            -DisplayName $_.displayName `
            -EmailAddress $_.mail `
            -Path "OU=Users,OU=Accounts,OU=i2N,DC=i2n,DC=com" `
            -AccountPassword $secure `
            -Enabled ($_.Enabled -eq "True") `
            -PassThru
    if ($_.uid) {
        $user | Set-AdUser -Add @{uid=$_.uid}
    }

}

Write-Output "$(Get-Date) Starting Group Membership Import from ${groupMembersFilePath}" | Tee-Object -FilePath $logFile -Append

#Import group members
Import-Csv -Path "${groupMembersFilePath}" | ForEach-Object { #for each line in csv add AD group
    Add-ADGroupMember -Identity $_.Group_Name `
            -Members $_.Member_Name
}

Write-Output "$(Get-Date) Starting Role Membership Import from ${roleMembersFilePath}" | Tee-Object -FilePath $logFile -Append

#Import Role members
Import-Csv -Path "${roleMembersFilePath}" | ForEach-Object { #for each line in csv add AD group
    Add-ADGroupMember -Identity $_.Group_Name `
            -Members $_.Member_Name
}

Write-Output "$(Get-Date) Import Complete" | Tee-Object -FilePath $logFile -Append
