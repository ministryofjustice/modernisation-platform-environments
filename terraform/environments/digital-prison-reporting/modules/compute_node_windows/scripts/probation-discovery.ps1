<powershell>
# Example PowerShell startup script
Write-Output "Bootstrapping Windows EC2 instance..."

# Install AWS CLI
Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.msi" -OutFile "C:\Windows\Temp\AWSCLIV2.msi"
Start-Process "msiexec.exe" -ArgumentList "/i C:\Windows\Temp\AWSCLIV2.msi /qn" -Wait

# (Optional) Check version
& "C:\Program Files\Amazon\AWSCLIV2\aws.exe" --version

# Download file from S3
& "C:\Program Files\Amazon\AWSCLIV2\aws.exe" s3 cp s3://dpr-artifact-store-development/third-party/PowerBI/PBIDesktopSetup_x64.exe C:\Windows\Temp\PBIDesktopSetup_x64.exe

</powershell>


