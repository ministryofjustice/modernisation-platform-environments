<powershell>
# IAM NEW SCRIPT NEW
# --- Setup COM1 logging and transcript (separate files) ---
$logPath = "C:\Windows\Temp\bootstrap-transcript.log"
$consoleLog = "COM1"

"Bootstrap script started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File -Append -FilePath $consoleLog

function Write-Log {
  param ([string]$Message)
  $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  "$timestamp - $Message" | Out-File -Append -FilePath $consoleLog
}

Write-Log "Starting transcript...."
try {
  Start-Transcript -Path $logPath -Force
} catch {
  Write-Log "Failed to start transcript: $_"
}

Write-Log "Installing AWS CLI..."
try {
  Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.msi" -OutFile "C:\Windows\Temp\AWSCLIV2.msi"
  Start-Process "msiexec.exe" -ArgumentList "/i C:\Windows\Temp\AWSCLIV2.msi /qn" -Wait
} catch {
  Write-Log "Failed to install AWS CLI: $_"
}

$awsCliPath = "C:\Program Files\Amazon\AWSCLIV2"
$currentPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
if ($currentPath -notlike "*$awsCliPath*") {
  Write-Log "Adding AWS CLI to system PATH..."
  [Environment]::SetEnvironmentVariable("Path", "$currentPath;$awsCliPath", [EnvironmentVariableTarget]::Machine)
}

Write-Log "Fetching RDP credentials..."
try {
  $secretJson = & "$awsCliPath\aws.exe" secretsmanager get-secret-value `
    --secret-id "compute/dpr-windows-rdp-credentials" `
    --query SecretString `
    --output text `
    --region eu-west-2
  $secret = $secretJson | ConvertFrom-Json
  $username = $secret.username
  $password = $secret.password
  Write-Log "Got username: $username"
} catch {
  Write-Log "Error retrieving secret: $_"
}

# --- Reliable user creation using net user + LASTEXITCODE ---
if ($username -and $password) {
  try {
    Write-Log "Checking if user $username exists..."
    $null = cmd /c "net user $username"
    if ($LASTEXITCODE -ne 0) {
      Write-Log "User $username does not exist. Creating..."
      net user $username $password /add
      net localgroup administrators $username /add
    } else {
      Write-Log "User $username exists. Resetting password..."
      net user $username $password
    }
  } catch {
    Write-Log "User creation/reset failed: $_"
  }
} else {
  Write-Log "Username or password missing"
}

Write-Log "Enabling RDP and firewall..."
try {
  Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
  Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
  Set-Service -Name TermService -StartupType Automatic
  Start-Service -Name TermService
} catch {
  Write-Log "RDP setup failed: $_"
}

Write-Log "Downloading Power BI..."
$powerBIPath = "C:\Windows\Temp\PBIDesktopSetup_x64.exe"
$bucketPath = "s3://dpr-artifact-store-development/third-party/PowerBI/PBIDesktopSetup_x64.exe"

try {
  & "$awsCliPath\aws.exe" s3 cp $bucketPath $powerBIPath
} catch {
  Write-Log "Power BI download failed: $_"
}

if (Test-Path $powerBIPath) {
  try {
    Start-Process -FilePath $powerBIPath -ArgumentList "/quiet /norestart" -Wait
    Write-Log "Power BI installed successfully"
  } catch {
    Write-Log "Power BI install failed: $_"
  }
} else {
  Write-Log "Power BI installer not found"
}

New-Item -Path "C:\Windows\Temp\bootstrap-success.txt" -ItemType File -Force

try {
  Stop-Transcript
} catch {
  Write-Log "Failed to stop transcript: $_"
}
</powershell>
