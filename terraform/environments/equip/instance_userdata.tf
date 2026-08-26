data "template_file" "windows-userdata" {
  template = <<EOF
<powershell>
$dir = $env:TEMP + "\ssm"
New-Item -ItemType directory -Path $dir -Force
cd $dir
(New-Object System.Net.WebClient).DownloadFile("https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/windows_amd64/AmazonSSMAgentSetup.exe", $dir + "\AmazonSSMAgentSetup.exe")
Start-Process .\AmazonSSMAgentSetup.exe -ArgumentList @("/q", "/log", "install.log") -Wait
Restart-Service AmazonSSMAgent

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls, [Net.SecurityProtocolType]::Tls11, [Net.SecurityProtocolType]::Tls12, [Net.SecurityProtocolType]::Ssl3
[Net.ServicePointManager]::SecurityProtocol = "Tls, Tls11, Tls12, Ssl3"


if (-not(Test-Path "C:\UserAwsCli"))
{
    New-Item -ItemType directory -Path "C:\UserAwsCli"
    Write-Output -Message "Created folder to store log file."
} else {
    Write-Output -Message "Folder already exists."
}

# Installing AWS CLI
Try
{
    $InstalledAwsVersion = $(C:\"Program Files"\Amazon\AWSCLIV2\aws.exe --version) | Out-String -ErrorAction SilentlyContinue
}
Catch{}
if (($InstalledAwsVersion -match "aws-cli/") -and (Test-Path "C:\UserAwsCli\InstallAWSFlag.txt" -PathType Leaf))
{
    Write-Output -Message "aws cli is installed. Version: $InstalledAwsVersion"
} else {
    Write-Output -Message "aws cli is not installed and will be installed."
    if (-not(Test-Path "C:\UserAwsCli\awscliv2.msi" -PathType Leaf))
    {
        $WebClient = New-Object System.Net.WebClient
        $WebClient.DownloadFile("https://awscli.amazonaws.com/AWSCLIV2.msi","C:\UserAwsCli\awscliv2.msi")
        Write-Output -Message "Downloaded the cli installer."
    }
    Start-Process msiexec.exe -Wait -ArgumentList '/i C:\UserAwsCli\awscliv2.msi /qn /l*v C:\UserAwsCli\aws-cli-install.log'
    Write-Output -Message "aws cli installed."
    if(Test-Path "C:\UserAwsCli\InstallAWSFlag.txt" -PathType Leaf)
    {
        Remove-Item -Path "C:\UserAwsCli\InstallAWSFlag.txt" -Force
    }
    Set-Content C:\UserAwsCli\InstallAWSFlag.txt "true"
    Write-Output -Message "Restarting the machine."
}

#Hostname Settings
[string]$token = Invoke-RestMethod -Headers @{"X-aws-ec2-metadata-token-ttl-seconds" = "21600"} -Method PUT -Uri http://169.254.169.254/latest/api/token
$instanceId = (Invoke-RestMethod -Headers @{"X-aws-ec2-metadata-token" = $token} -Method GET -Uri http://169.254.169.254/latest/meta-data/instance-id)
$newhostname = (C:\"Program Files"\Amazon\AWSCLIV2\aws.exe ec2 describe-instances --instance-id $instanceId --region eu-west-2 --query 'Reservations[0].Instances[0].Tags[?Key==`Name`].Value' --output text)
Rename-Computer -NewName "$newhostname" -Force;
shutdown /r -t 10;
</powershell>
EOF
}
