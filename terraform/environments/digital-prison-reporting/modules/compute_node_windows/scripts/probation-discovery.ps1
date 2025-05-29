<powershell>
$logPath = "C:\Windows\Temp\bootstrap.log"
$serialOut = "\\.\COM1"
Start-Transcript -Path $logPath -Force

"🔧 Bootstrapping Windows EC2 instance..." | Tee-Object -FilePath $serialOut -Append

# Install AWS CLI
"Downloading AWS CLI..." | Tee-Object -FilePath $serialOut -Append
Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.msi" -OutFile "C:\Windows\Temp\AWSCLIV2.msi"

"Installing AWS CLI..." | Tee-Object -FilePath $serialOut -Append
Start-Process "msiexec.exe" -ArgumentList "/i C:\Windows\Temp\AWSCLIV2.msi /qn" -Wait

# Persist AWS CLI in system PATH
$awsCliPath = "C:\Program Files\Amazon\AWSCLIV2"
$currentPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
if ($currentPath -notlike "*$awsCliPath*") {
  [Environment]::SetEnvironmentVariable("Path", "$currentPath;$awsCliPath", [EnvironmentVariableTarget]::Machine)
  "AWS CLI path added to system PATH." | Tee-Object -FilePath $serialOut -Append
}

# Fetch RDP Secret
"Fetching RDP credentials from Secrets Manager..." | Tee-Object -FilePath $serialOut -Append
$secretJson = & "$awsCliPath\aws.exe" secretsmanager get-secret-value `
  --secret-id "compute/dpr-windows-rdp-credentials" `
  --query SecretString `
  --output text `
  --region eu-west-2

$secret = $secretJson | ConvertFrom-Json
$username = $secret.username
$password = $secret.password

# Create user and add to administrators
"Creating user and adding to Administrators group..." | Tee-Object -FilePath $serialOut -Append
net user $username $password /add
net localgroup administrators $username /add

# Enable RDP
"Enabling RDP access..." | Tee-Object -FilePath $serialOut -Append
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
Set-Service -Name TermService -StartupType Automatic
Start-Service -Name TermService

# Download Power BI
"Downloading Power BI installer..." | Tee-Object -FilePath $serialOut -Append
& "$awsCliPath\aws.exe" s3 cp `
  s3://dpr-artifact-store-development/third-party/PowerBI/PBIDesktopSetup_x64.exe `
  C:\Windows\Temp\PBIDesktopSetup_x64.exe

# Install Power BI silently
"Installing Power BI silently..." | Tee-Object -FilePath $serialOut -Append
Start-Process -FilePath "C:\Windows\Temp\PBIDesktopSetup_x64.exe" -ArgumentList "/quiet /norestart" -Wait

# Marker file
"Bootstrap completed successfully." | Tee-Object -FilePath $serialOut -Append
New-Item -Path "C:\Windows\Temp\bootstrap-success.txt" -ItemType File -Force

Stop-Transcript
</powershell>
