<powershell>
Write-Output "🔧 Bootstrapping Windows EC2 instance..."

# Install AWS CLI
Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.msi" -OutFile "C:\Windows\Temp\AWSCLIV2.msi"
Start-Process "msiexec.exe" -ArgumentList "/i C:\Windows\Temp\AWSCLIV2.msi /qn" -Wait

# Persist AWS CLI in system PATH
$awsCliPath = "C:\Program Files\Amazon\AWSCLIV2"
$currentPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)

if ($currentPath -notlike "*$awsCliPath*") {
  [Environment]::SetEnvironmentVariable("Path", "$currentPath;$awsCliPath", [EnvironmentVariableTarget]::Machine)
}

# Fetch RDP Secret from AWS Secrets Manager
$secretJson = & "$awsCliPath\aws.exe" secretsmanager get-secret-value `
  --secret-id "compute/dpr-windows-rdp-credentials" `
  --query SecretString `
  --output text `
  --region eu-west-2

# Parse secret JSON
$secret = $secretJson | ConvertFrom-Json
$username = $secret.username
$password = $secret.password

# Set the Administrator password
net user $username $password

# Enable RDP and start required services
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
Set-Service -Name TermService -StartupType Automatic
Start-Service -Name TermService

# Download Power BI installer
& "$awsCliPath\aws.exe" s3 cp `
  s3://dpr-artifact-store-development/third-party/PowerBI/PBIDesktopSetup_x64.exe `
  C:\Windows\Temp\PBIDesktopSetup_x64.exe

# Install Power BI silently
Start-Process -FilePath "C:\Windows\Temp\PBIDesktopSetup_x64.exe" -ArgumentList "/quiet /norestart" -Wait

Write-Output "✅ Bootstrap complete."
</powershell>
