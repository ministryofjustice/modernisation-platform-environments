param (
    [Parameter(Mandatory=$true)]
    [string]$Firstname,

    [Parameter(Mandatory=$true)]
    [string]$Lastname,

    [Parameter(Mandatory=$true)]
    [string]$Email,

    [Parameter(Mandatory=$true)]
    [string]$ServiceAccountSecretArn,

    [Parameter(Mandatory=$true)]
    [string]$Region
)

function Generate-password ($length)
{
    $characters = "1234567890!&@%$£^abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    $random = 1..$length | ForEach-Object {Get-Random -Maximum $characters.length}
    $private:ofs=""
    return [string]$characters[$random]
}

Write-Host "Starting user creation process..."
Write-Host "Firstname: $Firstname"
Write-Host "Lastname: $Lastname"
Write-Host "Email: $Email"

$username = "$Firstname.$Lastname"
$domain = "laa-workspaces.local"
$OU = "OU=Users,OU=LAAWORKSPACES,DC=laa-workspaces,DC=local"
$Password = Generate-password -length 14

# Get AD service account credentials from Secrets Manager
Write-Host "Retrieving service account credentials from Secrets Manager..."
try {
    $secretJson = Get-SECSecretValue -SecretId $ServiceAccountSecretArn -Region $Region
    $secretObject = $secretJson.SecretString | ConvertFrom-Json
    $adusername = $secretObject.username
    $adpasswordSecure = $secretObject.password

    $fqdn = "$adusername@laa-workspaces.local"
    $securePassword = ConvertTo-SecureString $adpasswordSecure -AsPlainText -Force
    $adcredential = New-Object System.Management.Automation.PSCredential $fqdn, $securePassword

    Write-Host "Service account credentials retrieved successfully"
}
catch {
    Write-Error "Failed to retrieve service account credentials from Secrets Manager: $_"
    exit 1
}

# Check if user already exists
Write-Host "Checking if user already exists..."
if (Get-ADUser -Credential $adcredential -Filter {SamAccountName -eq $username} -ErrorAction SilentlyContinue)
{
    Write-Warning "A user account $username already exists in Active Directory."

    try {
        Set-ADUser -Credential $adcredential -Identity $username -ChangePasswordAtLogon $true -ErrorAction Stop
        Write-Host "Set ChangePasswordAtLogon for existing user."
    }
    catch {
        Write-Error "Failed to set ChangePasswordAtLogon for existing user: $_"
        exit 1
    }

    Write-Host "User creation skipped."
}
else
{
    Write-Host -ForegroundColor Yellow "Creating user account $username..."

    try {
        New-ADUser `
            -Credential $adcredential `
            -SamAccountName $username `
            -UserPrincipalName "$username@$domain" `
            -Name "$Firstname $Lastname" `
            -Surname $Lastname `
            -GivenName $Firstname `
            -Enabled $True `
            -Path $OU `
            -DisplayName "$Firstname $Lastname" `
            -EmailAddress $Email `
            -Description "$Firstname $Lastname - Created $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" `
            -AccountPassword (ConvertTo-SecureString $Password -AsPlainText -Force) `
            -PasswordNeverExpires $False

        Set-ADUser -Credential $adcredential -Identity $username -ChangePasswordAtLogon $true -ErrorAction Stop

        Write-Host -ForegroundColor Green "User account created successfully!"
        Write-Host -ForegroundColor Cyan "Username: $username"
        Write-Host -ForegroundColor Cyan "Password: $Password"

        Write-Host "SUCCESS"
    }
    catch {
        Write-Host -ForegroundColor DarkRed "Error creating user: $_" -BackgroundColor White
        exit 1
    }
}

Write-Host "User creation process completed."
'@ | Set-Content -Path .\user-creation.ps1 -Encoding UTF8