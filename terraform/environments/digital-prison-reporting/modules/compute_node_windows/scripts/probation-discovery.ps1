<powershell>
Write-Output "🔧 Bootstrapping Windows EC2 instance..."

# Install AWS CLI
Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.msi" -OutFile "C:\Windows\Temp\AWSCLIV2.msi"
Start-Process "msiexec.exe" -ArgumentList "/i C:\Windows\Temp\AWSCLIV2.msi /qn" -Wait

# Fetch RDP Secret from AWS Secrets Manager
$secretJson = & "C:\Program Files\Amazon\AWSCLIV2\aws.exe" secretsmanager get-secret-value `
  --secret-id "windows/rdp/administrator-password" `
  --query SecretString `
  --output text `
  --region eu-west-2

# Parse secret JSON
$secret = $secretJson | ConvertFrom-Json
$username = $secret.username
$password = $secret.password

# ✅ Set the Administrator password
net user $username $password

# 🔓 Enable RDP and start required services
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
Set-Service -Name TermService -StartupType Automatic
Start-Service -Name TermService

# ⬇️ Download Power BI installer
& "C:\Program Files\Amazon\AWSCLIV2\aws.exe" s3 cp `
  s3://dpr-artifact-store-development/third-party/PowerBI/PBIDesktopSetup_x64.exe `
  C:\Windows\Temp\PBIDesktopSetup_x64.exe

# ✅ Install Power BI silently
Start-Process -FilePath "C:\Windows\Temp\PBIDesktopSetup_x64.exe" -ArgumentList "/quiet /norestart" -Wait

Write-Output "✅ Bootstrap complete."
</powershell>