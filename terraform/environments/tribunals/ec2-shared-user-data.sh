<powershell>
$logFile = "C:\ProgramData\Amazon\EC2-Windows\Launch\Log\userdata.log"
$linkPath = "C:\ProgramData\docker\volumes\tribunals\"
$targetDrive = "D"
$targetPath = $targetDrive + ":\storage\tribunals\"
$ecsCluster = "tribunals-all-cluster"
$ebsVolumeTag = "tribunals-all-storage"
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
[Environment]::SetEnvironmentVariable("ECS_INSTANCE_ATTRIBUTES", "{`"Role`":`"Primary`"}", "Machine")

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

function MonitorAndSyncToS3 {
  $environmentName = GetEnvironmentName
  "Instance Environment: $environmentName" >> "C:\ProgramData\Amazon\EC2-Windows\Launch\Log\userdata.log"
  "Script started at $(Get-Date)" >> "C:\ProgramData\Amazon\EC2-Windows\Launch\Log\monitorLogFile.log"
  # Create a FileSystemWatcher object
  $watcher = New-Object System.IO.FileSystemWatcher
  $watcher.Path = "D:\storage\tribunals\"
  $watcher.IncludeSubdirectories = $true
  $watcher.EnableRaisingEvents = $true
  
  # Define the action to take when a file is created
  $action = {
      param($source, $event, $environmentName)
      $filePath = $event.FullPath
      $relativePath = $filePath -replace '^D:\\storage\\tribunals\\', '' -replace '\\', '/'
      "A file was created at $filePath 's3://tribunals-ebs-backup-$environmentName/$relativePath'. Uploading to S3..." >> "C:\ProgramData\Amazon\EC2-Windows\Launch\Log\monitorLogFile.log"
      aws s3 cp $filePath "s3://tribunals-ebs-backup-$environmentName/$relativePath" >> "C:\ProgramData\Amazon\EC2-Windows\Launch\Log\monitorLogFile.log"
    }

    # Register the event
    Register-ObjectEvent -InputObject $watcher -EventName Created -Action $action

    # Keep the script running
    while ($true) {
        Start-Sleep -Seconds 10
    }
}

function InitialSyncToS3 {
  $environmentName = GetEnvironmentName
  "Instance Environment: $environmentName" >> "C:\ProgramData\Amazon\EC2-Windows\Launch\Log\userdata.log"
  "Initial sync to S3 started at $(Get-Date)" >> "C:\ProgramData\Amazon\EC2-Windows\Launch\Log\monitorLogFile.log"
  aws s3 sync D:\storage\tribunals\ s3://tribunals-ebs-backup-$environmentName >> "C:\ProgramData\Amazon\EC2-Windows\Launch\Log\monitorLogFile.log"
  "Initial sync to S3 completed at $(Get-Date)" >> "C:\ProgramData\Amazon\EC2-Windows\Launch\Log\monitorLogFile.log"
}

# Call the functions
InitialSyncToS3
MonitorAndSyncToS3
'@

Set-ExecutionPolicy RemoteSigned -Scope LocalMachine

# Save the script to a file on the EC2 instance
$scriptContent | Out-File -FilePath "C:\MonitorAndSyncToS3.ps1"

$Action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument '-ExecutionPolicy Bypass -File "C:\MonitorAndSyncToS3.ps1"'

$Trigger = New-ScheduledTaskTrigger -Once -At ((Get-Date).AddMinutes(5))

Register-ScheduledTask -Action $Action -Trigger $Trigger -TaskName "MonitorAndSyncToS3" -Description "Monitor EBS Volume and copy newly added files to S3" -RunLevel Highest -User "SYSTEM" -Force

</powershell>