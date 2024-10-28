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
$environmentName = (Get-EC2Tag -Filter @{Name="resource-id";Values=$instanceId}).Value | Where-Object { $_.Key -eq "Environment" } | Select-Object -ExpandProperty Value
$s3BucketName = "tribunals-ebs-backup-${environmentName}"

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

# Initial sync from S3 to EBS
"Starting initial sync from S3 to EBS at $(Get-Date)" >> $monitorLogFile
foreach ($tribunal in $tribunalNames) {
    $s3Path = "s3://${s3BucketName}/${tribunal}/"
    $localPath = "${targetPath}${tribunal}"
    
    "Syncing ${s3Path} to ${localPath}" >> $monitorLogFile
    & aws s3 sync $s3Path $localPath >> $monitorLogFile 2>&1
    if ($LASTEXITCODE -eq 0) {
        "Successfully synced ${tribunal}" >> $monitorLogFile
    } else {
        "Failed to sync ${tribunal}" >> $monitorLogFile
    }
}

# Create and start a background job to monitor for changes
$monitorScript = @"
while (`$true) {
    `$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "Monitor cycle starting at `$timestamp" >> "$monitorLogFile"
    
    foreach (`$tribunal in '$($tribunalNames -join "','")') {
        `$s3Path = "s3://${s3BucketName}/`${tribunal}/"
        `$localPath = "${targetPath}`${tribunal}"
        
        # Sync any changes from S3 to local
        & aws s3 sync `$s3Path `$localPath --delete >> "$monitorLogFile" 2>&1
        if (`$LASTEXITCODE -eq 0) {
            "`$timestamp - Successfully synced `$tribunal from S3" >> "$monitorLogFile"
        } else {
            "`$timestamp - Failed to sync `$tribunal from S3" >> "$monitorLogFile"
        }
    }
    
    # Wait for 5 minutes before next sync
    Start-Sleep -Seconds 300
}
"@

# Save the monitor script
$monitorScript | Out-File -FilePath $monitorScriptFile -Encoding UTF8

# Start the monitor script as a background job
Start-Job -ScriptBlock {
    param($scriptPath)
    PowerShell.exe -ExecutionPolicy Bypass -File $scriptPath
} -ArgumentList $monitorScriptFile

"Monitoring script started" >> $monitorLogFile

</powershell>