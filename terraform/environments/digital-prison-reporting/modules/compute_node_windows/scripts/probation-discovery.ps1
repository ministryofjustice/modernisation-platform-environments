<powershell>
$logPath = "C:\Windows\Temp\bootstrap.log"
Start-Transcript -Path $logPath -Force

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

# Fetch RDP Secret
$secretJson = & "$awsCliPath\aws.exe" secretsmanager get-secret-value `
  --secret-id "compute/dpr-windows-rdp-credentials" `
  --query SecretString `
  --output text `
  --region eu-west-2

$secret = $secretJson | ConvertFrom-Json
$username = $secret.username
$password = $secret.password

# Create user and add to administrators
net user $username $password /add
net localgroup administrators $username /add

# Enable RDP
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
Set-Service -Name TermService -StartupType Automatic
Start-Service -Name TermService

# Download Power BI
& "$awsCliPath\aws.exe" s3 cp `
  s3://dpr-artifact-store-development/third-party/PowerBI/PBIDesktopSetup_x64.exe `
  C:\Windows\Temp\PBIDesktopSetup_x64.exe

# Install Power BI silently
Start-Process -FilePath "C:\Windows\Temp\PBIDesktopSetup_x64.exe" -ArgumentList "/quiet /norestart" -Wait

# ✅ Marker file
New-Item -Path "C:\Windows\Temp\bootstrap-success.txt" -ItemType File -Force

Stop-Transcript
</powershell>
