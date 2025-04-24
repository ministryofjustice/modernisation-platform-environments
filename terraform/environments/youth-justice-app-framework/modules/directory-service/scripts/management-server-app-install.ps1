param (
    [Parameter(
        Mandatory,
        Position = 1)]
    [String]$Env_Name
)


$logFile        = "C:\i2N\Log\App_LogFile_$(Get-Date -Format "yyyyMMdd hhmm").log"
$valid_env_name_values = @("yjaf-development", "yjaf-test","yjaf-preproduction","yjaf-production")
if (-Not ($valid_env_name_values -Contains $Env_Name)) {
    Write-Output "The Environment Name must be one of: $($valid_env_name_values -join ", ")"
    Exit
}

$bucket_name = "$($Env_Name)-install-files"
$key_prefix = "Management-Software/"

Write-Output "$(Get-Date) Downloading Software for Environment ${Env_Name}" | Tee-Object -FilePath $logFile -Append

Get-S3Object -BucketName $bucket_name -KeyPrefix $key_prefix | `
Where-Object -Property Key -NE $key_prefix | `
    ForEach-Object { Copy-S3Object -BucketName $bucket_name -Key $_.Key -LocalFile "c:\i2N\Software\$($_.Key -replace $key_prefix, '')" }


Write-Output "$(Get-Date) Installing Software for Environment ${Env_Name}" | Tee-Object -FilePath $logFile -Append
$Download_Folder = "C:\i2N\Software"


#Download and install Chrome
$Download = join-path $Download_Folder GoogleChromeStandaloneEnterprise64.msi
Start-Process "$Download" -Wait -ArgumentList "/qn"
Write-Output "$(Get-Date) Chrome Installed" | Tee-Object -FilePath $logFile -Append


#Install PuTTy after manual download
$Download = join-path $Download_Folder putty-64bit-0.82-installer.msi

Start-Process msiexec.exe -Wait -ArgumentList "/I $Download /quiet"
Write-Output "$(Get-Date) PuTTy installed" | Tee-Object -FilePath  $logFile -Append


#Install WinMerge after manual download
$Download = join-path $Download_Folder WinMerge-2.16.46-x64-Setup.exe

Start-Process "$Download" -Wait -ArgumentList "/SILENT /ALLUSERS /NORESTART"
Write-Output "$(Get-Date) WinMerge installed" | Tee-Object -FilePath $logFile -Append


#Install WinSCP after manual download
$Download = join-path $Download_Folder WinSCP-6.3.6-Setup.exe

Start-Process "$Download" -Wait -ArgumentList "/VERYSILENT /ALLUSERS /NORESTART"
Write-Output "$(Get-Date) WinSCP installed" | Tee-Object -FilePath $logFile -Append


Write-Output "$(Get-Date) All Installs Complete" | Tee-Object -FilePath  $logFile -Append
