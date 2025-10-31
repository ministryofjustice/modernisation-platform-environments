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

$logFile        = "${Export_Folder}\Import_Admin_Users_Log_$(Get-Date -Format "yyyyMMdd hhmm").log"

# Load Password File and generate a randonm password
. .\generate-password.ps1
$secure = GeneratePassword 20

Write-Output "$(Get-Date) Starting User Import from ${usersFilePath}" | Tee-Object -FilePath $logFile -Append

 #Import admin users to OU i2N\Users
 Import-Csv -Path "${usersFilePath}" | ForEach-Object { #for each line in csv add AD user
    New-ADUser -Name $_.Name `
            -SamAccountName $_.SamAccountName `
            -UserPrincipalName $_.UserPrincipalName `
            -GivenName $_.GivenName `
            -Initials $_.Initials `
            -Surname $_.sn `
            -DisplayName $_.displayName `
            -EmailAddress $_.mail `
            -Path "OU=Users,OU=i2N,DC=i2n,DC=com" `
            -AccountPassword $secure `
            -Enabled ($_.Enabled -eq "True")
}

Write-Output "$(Get-Date) Starting Admin User Membership Import from ${membershipFilePath}" | Tee-Object -FilePath $logFile -Append

#Import Admin user membership
Import-Csv -Path "${membershipFilePath}" | ForEach-Object { #for each line in csv add AD group
    Add-ADGroupMember -Identity $_.Group_Name `
            -Members "CN=$($_.User_Name),OU=Users,OU=i2N,DC=i2n,DC=com"
}

Write-Output "$(Get-Date) Import Complete" | Tee-Object -FilePath $logFile -Append