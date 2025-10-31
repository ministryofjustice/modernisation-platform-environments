<powershell>
$logFile = "C:\ProgramData\Amazon\EC2-Windows\Launch\Log\userdata.log"
$linkPath = "C:\ProgramData\docker\volumes\tribunals\"
$targetDrive = "D"
$targetPath = $targetDrive + ":\storage\tribunals\"
$ecsCluster = "tribunals-all-cluster"
$ebsVolumeTag = "tribunals-backup-storage"
$tribunalNames = "appeals","transport","care-standards","cicap","employment-appeals","finance-and-tax","immigration-services","information-tribunal","hmlands","lands-chamber", "asylum-support", "ftp-admin-appeals", "ftp-tax-tribunal", "ftp-tax-chancery", "ftp-sscs-venues", "ftp-siac", "ftp-primary-health", "ftp-estate-agents", "ftp-consumer-credit", "ftp-claims-management", "ftp-charity-tribunals"
$monitorLogFile = "C:\ProgramData\Amazon\EC2-Windows\Launch\Log\monitorLogFile.log"
$monitorScriptFile = "C:\ProgramData\Amazon\EC2-Windows\Launch\monitor-ebs.ps1"

"Starting userdata execution" >> $logFile

# Get the volumeid based on its tag
$instanceId = Get-EC2InstanceMetadata -Path '/instance-id'
"Got instanceid " + $instanceid >> $logFile

$volumeid = Get-EC2Volume -Filter @{ Name="tag:Name"; Values=$ebsVolumeTag } -Select Volumes.VolumeId
"Got volumeid " + $volumeid >> $logFile

if ([string]::IsNullorEmpty($volumeid)) {
    "No volume exists with the tag " + $ebsVolumeTag >> $logFile
}
else {
  "Adding volume $volumeid" >> $logFile
  Add-EC2Volume -VolumeId $volumeid -InstanceId $instanceid -Device /dev/xvdf
  "result of Adding volume is " + $? >> $logfile

  # Does the attached volume contain a raw disk?
  $rawdisks = Get-Disk | Where PartitionStyle -eq 'raw'

  "get-disk result is " + $rawdisks >> $logfile

  # If not, put the disk online and assign the drive letter
  if ([string]::IsNullorEmpty($rawdisks)) {
    Get-Disk >> $logFile
    Set-Disk -Number 1 -IsOffline $False -IsReadOnly $False
    Set-Partition -DiskNumber 1 -PartitionNumber 1 -NewDriveLetter $targetDrive
  }
  else {
    "Formatting volume..." >> $logFile

    # If it does have a raw disk, format it and create the partition and assign
    Get-Disk | Where PartitionStyle -eq 'raw' | Initialize-Disk -PartitionStyle MBR -PassThru | New-Partition -DriveLetter D -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel "Tribunals" -Confirm:$false
  }

  for ($i=0; $i -lt $tribunalNames.Length; $i++) {
    $subDirPath = ($targetPath + $tribunalNames[$i])
    if (!(Test-Path $subDirPath)) {
        New-Item -ItemType Directory -Path $subDirPath
        "created " + $subDirPath >> $logFile
    }
  }
}

if (Test-Path $linkPath) {
  "Link exists for " + $linkPath >> $logFile
  Get-Item $linkPath >> $logFile
  if ((Get-Item $linkPath).LinkType -eq "SymbolicLink") {
    "It is a symbolic link " >> $logFile
  } else {
    "It is not a symbolic link" >> $logFile
  }
} else {
  "Linking " + $linkPath + " to " + $targetPath >> $logFile
  New-Item -Path $linkPath -ItemType SymbolicLink -Value $targetPath
}

"Set Environment variable to enable awslogs attribute" >> $logFile
Import-Module ECSTools
[Environment]::SetEnvironmentVariable("ECS_ENABLE_AWSLOGS_EXECUTIONROLE_OVERRIDE", "true", "Machine")

"Link instance to shared tribunals cluster " + $ecsCluster >> $logFile
[Environment]::SetEnvironmentVariable("ECS_INSTANCE_ATTRIBUTES", "{`"Role`":`"Backup`"}", "Machine")
Initialize-ECSAgent -Cluster $ecsCluster -EnableTaskIAMRole -LoggingDrivers '["json-file","awslogs"]'

"Finished launch.ps1" >> $logFile

# Check if AWS CLI is installed
$awsCliInstalled = $null -ne (Get-Command aws -ErrorAction SilentlyContinue)

if (-not $awsCliInstalled) {
    # Download and install the AWS CLI
    "AWS CLI not found. Installing..." > $monitorLogFile
    $installerPath = "$env:TEMP\AWSCLIV2.msi"
    Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.msi" -OutFile $installerPath
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", $installerPath, "/quiet", "/qn", "/norestart" -Wait
    Remove-Item -Path $installerPath
    $env:Path += ";C:\Program Files\Amazon\AWSCLIV2"
    "AWS CLI installed successfully." >> $monitorLogFile
} else {
    "AWS CLI is already installed." >> $monitorLogFile
}

$scriptContent = @'

function GetEnvironmentName {
  $instanceId = Get-EC2InstanceMetadata -Path '/instance-id'
  $environmentName = aws ec2 describe-tags --filters "Name=resource-id,Values=$instanceId" "Name=key,Values=Environment" --query 'Tags[0].Value' --output text
  return $environmentName
}

function SyncFromS3 {
  $environmentName = GetEnvironmentName
  "Instance Environment: $environmentName" >> "C:\ProgramData\Amazon\EC2-Windows\Launch\Log\userdata.log"
  "Sync from S3 started at $(Get-Date)" >> "C:\ProgramData\Amazon\EC2-Windows\Launch\Log\monitorLogFile.log"
  aws s3 sync s3://tribunals-ebs-backup-$environmentName D:\storage\tribunals\ >> "C:\ProgramData\Amazon\EC2-Windows\Launch\Log\monitorLogFile.log"
  "Sync from S3 completed at $(Get-Date)" >> "C:\ProgramData\Amazon\EC2-Windows\Launch\Log\monitorLogFile.log"
}

# Call the functions
SyncFromS3
'@

Set-ExecutionPolicy RemoteSigned -Scope LocalMachine

# Save the script to a file on the EC2 instance
$scriptContent | Out-File -FilePath "C:\SyncFromS3.ps1"

$Action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument '-ExecutionPolicy Bypass -File "C:\SyncFromS3.ps1"'

# Create a trigger for the immediate execution with a 5-minute delay
$ImmediateTrigger = New-ScheduledTaskTrigger -Once -At ((Get-Date).AddMinutes(5))

# Create a trigger for the weekly execution
$WeeklyTrigger = New-ScheduledTaskTrigger -Weekly -At "12:00AM" -DaysOfWeek Sunday

# Register the scheduled task with both triggers
Register-ScheduledTask -Action $Action -Trigger $ImmediateTrigger, $WeeklyTrigger -TaskName "SyncFromS3" -Description "Sync files from S3 bucket to EBS volume" -RunLevel Highest -User "SYSTEM" -Force

</powershell>