param (
    [Parameter(Mandatory=$true)]
    [string]$Firstname,

    [Parameter(Mandatory=$true)]
    [string]$Lastname,

    [Parameter(Mandatory=$true)]
    [string]$Email
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

# Get service account credentials from SSM Parameter Store
Write-Host "Retrieving service account credentials..."
try {
    $ssmResponse = Get-SSMParameterValue -Name "/laa-workspaces/development/ad-service-account-password" -WithDecryption $true
    $adpasswordSecure = $ssmResponse.Parameters[0].Value
    
    # Service account details
    $adusername = 'LAAWORKSPACES\lambda.workspace'
    $securePassword = ConvertTo-SecureString $adpasswordSecure -AsPlainText -Force
    $adcredential = New-Object System.Management.Automation.PSCredential $adusername, $securePassword
    
    Write-Host "Service account credentials retrieved successfully"
}
catch {
    Write-Error "Failed to retrieve service account credentials: $_"
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if user already exists
Write-Host "Checking if user already exists..."
if (Get-ADUser -Credential $adcredential -Filter {SamAccountName -eq $username} -ErrorAction SilentlyContinue)
{
    Write-Warning "A user account $username already exists in Active Directory."
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
            -PasswordNeverExpires $True

        Write-Host -ForegroundColor Green "User account created successfully!"
        Write-Host -ForegroundColor Cyan "Username: $username"
        Write-Host -ForegroundColor Cyan "Password: $Password"
        
        # Store password in SSM Parameter Store for Lambda to retrieve
        Write-Host "Storing password in Parameter Store..."
        $passwordParamName = "/laa-workspaces/development/user-passwords/$username"
        Write-SSMParameter -Name $passwordParamName -Value $Password -Type "SecureString" -Overwrite $true
        Write-Host "Password stored successfully in $passwordParamName"
        
        # Return success indicator
        Write-Host "SUCCESS"
    }
    catch {
        Write-Host -ForegroundColor DarkRed "Error creating user: $_" -BackgroundColor White
        Read-Host "Press Enter to exit"
        exit 1
    }
}

Write-Host "User creation process completed."
