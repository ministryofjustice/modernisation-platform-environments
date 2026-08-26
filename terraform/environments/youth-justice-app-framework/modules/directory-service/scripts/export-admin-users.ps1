param (
    [Parameter(
        Position = 1)]
    [String]$Export_Folder = "C:\i2N\AD_Files",
    [Parameter(
        Position = 2)]
    [String]$Admin_Users_File = "admins.csv",
    [Parameter(
        Position = 3)]
    [String]$Admin_Membership_File = "admin-membership.csv"
)

$usersFilePath        = "${Export_Folder}\${Admin_Users_File}"
$membershipFilePath        = "${Export_Folder}\${Admin_Membership_File}"

# Export Administrators
 Get-ADUser -Filter * -SearchBase "OU=Users,OU=i2N,DC=i2n,DC=com" -Properties * |  # retrieves all users in OU i2N\Users.
 Select-Object Name, SamAccountName, UserPrincipalName, GivenName, Initials, sn, displayName, mail, Enabled |  # selects required user properties.
 Export-Csv -Path $usersFilePath -NoTypeInformation # exports the admin users to a CSV file.

 # Export Admin Group Membership
 Get-ADUser -Filter * -SearchBase "OU=Users,OU=i2N,DC=i2n,DC=com" -Properties MemberOf|  # retrieves membership details for all Users in the Users OU.
 %{$user_name = $_.Name; $_.MemberOf} | # make the user name available and retun a list of groups tha it is a member of
 Select  @{label = "User_Name"; expression={ $user_name }}, @{label = "Group_Name"; expression={ $_ }} | # Select the user name and group name
 Export-Csv -Path $membershipFilePath -NoTypeInformation # exports admin user member of groups to a CSV file.
