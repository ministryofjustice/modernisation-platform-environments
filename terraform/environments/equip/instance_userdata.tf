data "template_file" "windows-userdata" {
  template = <<EOF
<powershell>
#SSM Installation
$dir = $env:TEMP + "\ssm"
New-Item -ItemType directory -Path $dir -Force
cd $dir
(New-Object System.Net.WebClient).DownloadFile("https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/windows_amd64/AmazonSSMAgentSetup.exe", $dir + "\AmazonSSMAgentSetup.exe")
Start-Process .\AmazonSSMAgentSetup.exe -ArgumentList @("/q", "/log", "install.log") -Wait

# Installing AWS CLI
Try
{
    $InstalledAwsVersion = $(aws --version) | Out-String -ErrorAction SilentlyContinue
}
Catch{}
if (($InstalledAwsVersion -match "aws-cli/") -and (Test-Path "C:\UserDataLog\InstallAWSFlag.txt" -PathType Leaf))
{
    Write-Log -Message "aws cli is installed. Version: $InstalledAwsVersion"
} else {
    Write-Log -Message "aws cli is not installed and will be installed."
    if (-not(Test-Path "C:\UserDataLog\awscliv2.msi" -PathType Leaf))
    {
        $WebClient = New-Object System.Net.WebClient
        $WebClient.DownloadFile("https://awscli.amazonaws.com/AWSCLIV2.msi","C:\UserDataLog\awscliv2.msi")
        Write-Log -Message "Downloaded the cli installer."
    }
    Start-Process msiexec.exe -Wait -ArgumentList '/i C:\UserDataLog\awscliv2.msi /qn /l*v C:\UserDataLog\aws-cli-install.log'
    Write-Log -Message "aws cli installed."
    if(Test-Path "C:\UserDataLog\InstallAWSFlag.txt" -PathType Leaf)
    {
        Remove-Item -Path "C:\UserDataLog\InstallAWSFlag.txt" -Force
    }
    Set-Content C:\UserDataLog\InstallAWSFlag.txt "true"
    Write-Log -Message "Restarting the machine."
}

# Rename Hostname to Tag Name
$instanceId = ((Invoke-WebRequest -Uri http://169.254.169.254/latest/meta-data/instance-id -UseBasicParsing).Content)
$newhostname = (aws ec2 describe-instances --instance-id $instanceId --region eu-west-1 --query 'Reservations[0].Instances[0].Tags[?Key==`hostname`].Value' --output text)
Rename-Computer -NewName "$newhostname" -Force;
shutdown /r -t 10;
</powershell>
<persist>true</persist>
EOF
}
