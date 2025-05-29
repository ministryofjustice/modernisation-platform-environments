<powershell>
# --- Setup COM1 logging (EC2 System Log) ---
$logPath = "C:\Windows\Temp\bootstrap.log"
"Bootstrap script started at $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")" | Out-File -Append -FilePath "COM1"

# Function to log to both file and system log
function Write-Log {
  param ([string]$Message)
  $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  $formatted = "$timestamp - $Message"
  try {
    Add-Content -Path $logPath -Value $formatted
  } catch {
    # fallback if file is locked
    "$timestamp - (log file busy) $Message" | Out-File -Append -FilePath "COM1"
  }
  $formatted | Out-File -Append -FilePath "COM1"
}

Write-Log "Starting transcript..."
try {
  Start-Transcript -Path $logPath -Force
} catch {
  Write-Log "Failed to start transcript: $_"
}

Write-Log "Bootstrapping Windows EC2 instance..."

# --- Install AWS CLI ---
Write-Log "Installing AWS CLI..."
try {
  Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.msi" -OutFile "C:\Windows\Temp\AWSCLIV2.msi"
  Start-Process "msiexec.exe" -ArgumentList "/i C:\Windows\Temp\AWSCLIV2.msi /qn" -Wait
} catch {
  Write-Log "Failed to install AWS CLI: $_"
}

# --- Add AWS CLI to system PATH ---
$awsCliPath = "C:\Program Files\Amazon\AWSCLIV2"
$currentPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
if ($currentPath -notlike "*$awsCliPath*") {
  Write-Log "Adding AWS CLI to system PATH..."
  [Environment]::SetEnvironmentVariable("Path", "$currentPath;$awsCliPath", [EnvironmentVariableTarget]::Machine)
} else {
  Write-Log "AWS CLI already in PATH"
}

# --- Fetch RDP credentials from AWS Secrets Manager ---
Write-Log "Fetching RDP credentials from Secrets Manager..."
try {
  $secretJson = & "$awsCliPath\aws.exe" secretsmanager get-secret-value `
    --secret-id "compute/dpr-windows-rdp-credentials" `
    --query SecretString `
    --output text `
    --region eu-west-2
  $secret = $secretJson | ConvertFrom-Json
  $username = $secret.username
  $password = $secret.password
} catch {
  Write-Log "Failed to retrieve secret: $_"
}

# --- Create user if not exists ---
if ($username -and $password) {
  $existingUser = net user $username 2>$null
  if (-not $?) {
    Write-Log "Creating user: $username"
    net user $username $password /add
    net localgroup administrators $username /add
  } else {
    Write-Log "User $username already exists. Skipping creation."
  }
} else {
  Write-Log "Username or password is missing. Skipping user creation."
}

# --- Enable Remote Desktop and firewall ---
Write-Log "Enabling Remote Desktop and configuring firewall..."
try {
  Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
  Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
  Set-Service -Name TermService -StartupType Automatic
  Start-Service -Name TermService
} catch {
  Write-Log "Failed to configure RDP: $_"
}

# --- Download and Install Power BI ---
Write-Log "Downloading Power BI installer from S3..."
try {
  & "$awsCliPath\aws.exe" s3 cp `
    s3://dpr-artifact-store-development/third-party/PowerBI/PBIDesktopSetup_x64.exe `
    C:\Windows\Temp\PBIDesktopSetup_x64.exe
} catch {
  Write-Log "Power BI download failed: $_"
}

$installer = "C:\Windows\Temp\PBIDesktopSetup_x64.exe"
if (Test-Path $installer) {
  Write-Log "Installing Power BI Desktop..."
  try {
    Start-Process -FilePath $installer -ArgumentList "/quiet /norestart" -Wait
  } catch {
    Write-Log "Power BI install failed: $_"
  }
} else {
  Write-Log "Power BI installer not found. Skipping install."
}

# --- Final Marker and Completion ---
Write-Log "Bootstrap script completed successfully."
New-Item -Path "C:\Windows\Temp\bootstrap-success.txt" -ItemType File -Force

try {
  Stop-Transcript
} catch {
  Write-Log "Failed to stop transcript: $_"
}
</powershell>