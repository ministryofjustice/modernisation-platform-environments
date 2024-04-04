<powershell>
$logFile = "C:\ProgramData\Amazon\EC2-Windows\Launch\Log\userdata.log"
$linkPath = "C:\ProgramData\docker\volumes\tribunals\"
$targetDrive = "D"
$targetPath = $targetDrive + ":\storage\tribunals\"
$ecsCluster = "tribunals-all-cluster"
$ebsVolumeTag = "tribunals-all-storage"
$tribunalNames = "appeals","transport","care-standards","cicap","employment-appeals","finance-and-tax","immigration-services","information-tribunal","ahmlr","lands-tribunal"
$monitorLogFile = "C:\ProgramData\Amazon\EC2-Windows\Launch\Log\monitorLogFile.log"
# maybe monitorScriptFile should be on the D drive?
$monitorScriptFile = "C:\ProgramData\Amazon\EC2-Windows\Launch\monitor-ebs.ps1"

"Starting userdata execution" > $logFile

#Initialize-ECSAgent -Cluster $ecsCluster -EnableTaskIAMRole -LoggingDrivers '["json-file","awslogs"]'
#Install-Module -Name AWS.Tools.EC2

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

"Set Environment variable to enable awslogs attribute" >> $logFile
Import-Module ECSTools
[Environment]::SetEnvironmentVariable("ECS_ENABLE_AWSLOGS_EXECUTIONROLE_OVERRIDE", "true", "Machine")

"Link instance to shared tribunals cluster " + $ecsCluster >> $logFile
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
# Create a FileSystemWatcher object
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = "D:\storage\tribunals\"
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true

# Define the action to take when a file is created
$action = {
    param($source, $event)
    $filePath = $event.FullPath
    "A file was created at $filePath. Syncing to S3..." >> "C:\ProgramData\Amazon\EC2-Windows\Launch\Log\monitorLogFile.log"
    aws s3 sync D:\storage\tribunals\ s3://tribunals-ebs-backup >> "C:\ProgramData\Amazon\EC2-Windows\Launch\Log\monitorLogFile.log"
}

# Register the event
Register-ObjectEvent -InputObject $watcher -EventName Created -Action $action

# Keep the script running
while ($true) {
    Start-Sleep -Seconds 10
}
'@

# Output the script to the file
$scriptContent | Out-File -FilePath $monitorScriptFile

# Execute the monitor script
Start-Process -FilePath "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList "-File `"$monitorScriptFile`""

</powershell>
<persist>true</persist>