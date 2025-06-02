<powershell>
# --- Logging setup ---
#---New logs----
$logPath = "C:\Windows\Temp\bootstrap-transcript.log"

Start-Transcript -Path $logPath -Force
Write-Host "Bootstrap started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# --- Install AWS CLI ---
try {
    Write-Host "Installing AWS CLI..."
    Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.msi" -OutFile "C:\Windows\Temp\AWSCLIV2.msi"
    Start-Process "msiexec.exe" -ArgumentList "/i C:\Windows\Temp\AWSCLIV2.msi /qn" -Wait
    Write-Host "AWS CLI installed."
} catch {
    Write-Host "ERROR: AWS CLI installation failed: $_"
}

# --- Add to PATH ---
$awsCliPath = "C:\Program Files\Amazon\AWSCLIV2"
$currentPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
if ($currentPath -notlike "*$awsCliPath*") {
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$awsCliPath", [EnvironmentVariableTarget]::Machine)
}

# --- Fetch RDP credentials ---
try {
    Write-Host "Fetching RDP credentials..."
    $secretJson = & "$awsCliPath\aws.exe" secretsmanager get-secret-value `
      --secret-id "compute/dpr-windows-rdp-credentials" `
      --query SecretString `
      --output text `
      --region eu-west-2

    $secret = $secretJson | ConvertFrom-Json
    $username = $secret.username
    $password = $secret.password

    if (-not $username -or -not $password) {
        throw "Username or password is empty"
    }

    Write-Host "Retrieved username: $username"
} catch {
    Write-Host "ERROR: Failed to fetch credentials: $_"
}

# --- Create or reset Windows user ---
if ($username -and $password) {
    try {
        Write-Host "Checking for existing user..."
        net user $username > $null 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "User $username does not exist. Creating..."
            net user $username $password /add
            net localgroup administrators $username /add
        } else {
            Write-Host "User $username exists. Resetting password..."
            net user $username $password
        }
        net user $username
    } catch {
        Write-Host "ERROR: User creation/reset failed: $_"
    }
} else {
    Write-Host "ERROR: Username/password not available"
}


# --- Download and install Power BI Desktop ---
$powerBIPath = "C:\Windows\Temp\PBIDesktopSetup_x64.exe"
$bucketPath = "s3://dpr-artifact-store-development/third-party/PowerBI/PBIDesktopSetup_x64.exe"

try {
    Write-Host "Downloading Power BI..."
    & "$awsCliPath\aws.exe" s3 cp $bucketPath $powerBIPath
} catch {
    Write-Host "ERROR: Power BI download failed: $_"
}

if (Test-Path $powerBIPath) {
    try {
        Write-Host "Installing Power BI..."
        Start-Process -FilePath $powerBIPath -ArgumentList "/quiet /norestart" -Wait
        Write-Host "Power BI installed."
    } catch {
        Write-Host "ERROR: Power BI install failed: $_"
    }
} else {
    Write-Host "Power BI installer not found"
}

# --- Mark success ---
New-Item -Path "C:\Windows\Temp\bootstrap-success.txt" -ItemType File -Force | Out-Null

# --- End Transcript ---
Stop-Transcript
</powershell>
