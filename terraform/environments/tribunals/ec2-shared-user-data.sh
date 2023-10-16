<powershell>
$logFile = "C:\ProgramData\Amazon\EC2-Windows\Launch\Log\userdata.log"
$linkPath = "C:\ProgramData\docker\volumes\tribunals"
$targetDrive = "D"
$targetPath = $targetDrive + ":\storage\tribunals"
$ecsCluster = "tribunals-all-cluster"
$ebsVolumeTag = "tribunals-all-storage"


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

  # We should now have an online volume mapped to D:
  # There should also be a folder C:\ProgramData\docker\volumes
  # This is where container volumes are mapped to
  # Create a symbolic link (if it doesn't exist) for the tribunals storage to
  # a folder on the EBS volume (the D: drive)
  if (!(Test-Path $targetPath)) {
    New-Item -ItemType Directory -Path $targetPath
    "created " + $targetPath >> $logFile
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
}

"Link instance to shared tribunals cluster " + $ecsCluster >> $logFile
Initialize-ECSAgent -Cluster $ecsCluster -EnableTaskIAMRole -LoggingDrivers '["json-file","awslogs"]'

"Finished launch.ps1" >> $logFile
</powershell>