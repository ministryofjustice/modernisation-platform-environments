<powershell>
$logFile = "C:\ProgramData\Amazon\EC2-Windows\Launch\Log\userdata.log"
$linkPath = "C:\ProgramData\docker\volumes\tribunals\"
$targetDrive = "D"
$targetPath = $targetDrive + ":\storage\tribunals\"
$ecsCluster = "tribunals-all-cluster"
$ebsVolumeTag = "tribunals-backup-storage"
$tribunalNames = "appeals","transport","care-standards","cicap","employment-appeals","finance-and-tax","immigration-services","information-tribunal","hmlands","lands-chamber", "ftp-admin-appeals", "ftp-tax-tribunal", "ftp-tax-chancery", "ftp-sscs-venues", "ftp-siac", "ftp-primary-health", "ftp-estate-agents", "ftp-consumer-credit", "ftp-claims-management", "ftp-charity-tribunals"
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

# Ensure the target directory exists
if (-not (Test-Path D:\storage\tribunals)) {
    New-Item -ItemType Directory -Path D:\storage\tribunals
}

# Copy files from S3 to local directory
aws s3 cp s3://tribunals-ebs-backup-development D:\storage\tribunals --recursive

# Optional: Log the result
if ($?) {
    "Files copied successfully from S3 to D:\storage\tribunals" >> $logFile
} else {
    "Failed to copy files from S3" >> $logFile
}

</powershell>