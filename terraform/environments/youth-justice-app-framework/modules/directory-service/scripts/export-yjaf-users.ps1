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

# Export Account Users
Get-ADUser -Filter * -SearchBase "OU=Users,OU=Accounts,OU=i2N,DC=i2n,DC=com" -Properties * |  # retrieves users in OU i2N\Accounts\Users.
Select-Object Name, SamAccountName, UserPrincipalName, GivenName, Initials, sn, displayName, mail, @{Name='uid';Expression={$_.uid -join ';'}}, Enabled |  # selects required user properties.
Export-Csv -Path "${usersFilePath}" -NoTypeInformation # exports the users to a CSV file.

# Export Account Groups
Get-ADGroup -Filter * -SearchBase "OU=Groups,OU=Accounts,OU=i2N,DC=i2n,DC=com" |  # retrieves all groups in OU i2N\Accounts\Groups
Select-Object Name, SamAccountName, GroupCategory, GroupScope |  # selects the Name, SamAccountName, GroupCategory, and GroupScope properties of the groups.
Export-Csv -Path "${groupsFilePath}" -NoTypeInformation # exports the groups to a CSV file.

# Export Account Roles
Get-ADGroup -Filter * -SearchBase "OU=Roles,OU=Accounts,OU=i2N,DC=i2n,DC=com" |  # retrieves all Groups in OU i2N\Accounts\Roles.
Select-Object Name, SamAccountName, GroupScope, GroupCategory, DistinguishedName | # selects the Name, SamAccountName, GroupScope, GroupCategory, and DistinguishedName properties of the roles.
Export-Csv -Path "${rolesFilePath}" -NoTypeInformation # exports the roles to a CSV file.

# Export Members for Groups in the Aoounts Groups OU (avoids use of Get-ADGroupMember due to its limit of 5,000 members)
Get-ADGroup -Filter * -SearchBase "OU=Groups,OU=Accounts,OU=i2N,DC=i2n,DC=com" -Properties Member|  # retrieves menmbership details for all Groups in the Groups OU.
%{$group_name = $_.Name; $_.Member} | # make the gounp name available and retun a list of members
Select  @{label = "Group_Name"; expression={ $group_name }}, @{label = "Member_Name"; expression={ $_ }} | # Select group name and member name
Export-Csv -Path "${groupMembersFilePath}" -NoTypeInformation # exports group members to a CSV file.

# Export Members for Groups in the Accounts Roles OU (avoids use of Get-ADGroupMember due to its limit of 5,000 members)
Get-ADGroup -Filter * -SearchBase "OU=Roles,OU=Accounts,OU=i2N,DC=i2n,DC=com" -Properties Member|  # retrieves menmbership details for all Groups in the Roles OU.
%{$group_name = $_.Name; $_.Member} | # make the group name available and retun a list of members
Select  @{label = "Group_Name"; expression={ $group_name }}, @{label = "Member_Name"; expression={ $_ }} | # Select group name and member name
Export-Csv -Path "${roleMembersFilePath}" -NoTypeInformation # exports role members to a CSV file.
