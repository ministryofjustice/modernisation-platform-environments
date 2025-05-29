<powershell>
$logPath = "C:\Windows\Temp\bootstrap.log"
Start-Transcript -Path $logPath -Force

# Output to both transcript and EC2 system log
function Write-Log {
  param ([string]$Message)
  $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  $formatted = "$timestamp - $Message"
  Write-Output $formatted
  $formatted | Out-File -Append -FilePath $logPath
  $formatted | Out-File -Append -FilePath "COM1"
}

Write-Log "Bootstrapping Windows EC2 instance..."

# Install AWS CLI
Write-Log "Installing AWS CLI..."
Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.msi" -OutFile "C:\Windows\Temp\AWSCLIV2.msi"
Start-Process "msiexec.exe" -ArgumentList "/i C:\Windows\Temp\AWSCLIV2.msi /qn" -Wait

# Add AWS CLI to system PATH
$awsCliPath = "C:\Program Files\Amazon\AWSCLIV2"
$currentPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
if ($currentPath -notlike "*$awsCliPath*") {
  Write-Log "Adding AWS CLI to system PATH..."
  [Environment]::SetEnvironmentVariable("Path", "$currentPath;$awsCliPath", [EnvironmentVariableTarget]::Machine)
} else {
  Write-Log "AWS CLI already in PATH"
}

# Fetch RDP credentials from AWS Secrets Manager
Write-Log "Fetching RDP credentials from Secrets Manager..."
$secretJson = & "$awsCliPath\aws.exe" secretsmanager get-secret-value `
  --secret-id "compute/dpr-windows-rdp-credentials" `
  --query SecretString `
  --output text `
  --region eu-west-2

$secret = $secretJson | ConvertFrom-Json
$username = $secret.username
$password = $secret.password

# Create user and set password
Write-Log "Creating user: $username"
net user $username $password /add
net localgroup administrators $username /add

# Enable Remote Desktop and firewall
Write-Log "Enabling Remote Desktop and configuring firewall..."
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
Set-Service -Name TermService -StartupType Automatic
Start-Service -Name TermService

# Download Power BI installer from S3
Write-Log "Downloading Power BI installer from S3..."
& "$awsCliPath\aws.exe" s3 cp `
  s3://dpr-artifact-store-development/third-party/PowerBI/PBIDesktopSetup_x64.exe `
  C:\Windows\Temp\PBIDesktopSetup_x64.exe

# Install Power BI silently
$installer = "C:\Windows\Temp\PBIDesktopSetup_x64.exe"
if (Test-Path $installer) {
  Write-Log "Installing Power BI Desktop..."
  Start-Process -FilePath $installer -ArgumentList "/quiet /norestart" -Wait
} else {
  Write-Log "Power BI installer not found. Skipping installation."
}

# Create marker file
Write-Log "Bootstrap script completed."
New-Item -Path "C:\Windows\Temp\bootstrap-success.txt" -ItemType File -Force

Stop-Transcript
</powershell>
