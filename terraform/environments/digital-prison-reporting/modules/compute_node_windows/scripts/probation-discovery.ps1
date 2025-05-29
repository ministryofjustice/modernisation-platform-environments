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

# Create the user if not exists and set password
net user $username $password /add
net localgroup administrators $username /add

# Enable RDP and start required services
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
Set-Service -Name TermService -StartupType Automatic
Start-Service -Name TermService

# Download Power BI installer
$powerBIInstaller = "C:\Windows\Temp\PBIDesktopSetup_x64.exe"
& "$awsCliPath\aws.exe" s3 cp `
  s3://dpr-artifact-store-development/third-party/PowerBI/PBIDesktopSetup_x64.exe `
  $powerBIInstaller

# Install Power BI silently if downloaded
if (Test-Path $powerBIInstaller) {
  Write-Output "Installing Power BI Desktop..."
  Start-Process -FilePath $powerBIInstaller -ArgumentList "/quiet /norestart" -Wait
} else {
  Write-Output "Power BI installer not found at $powerBIInstaller"
}

Write-Output "Bootstrap complete."
</powershell>
