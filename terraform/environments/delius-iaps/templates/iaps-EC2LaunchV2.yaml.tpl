version: 1.0
tasks:
- task: executeScript
  inputs:
  - frequency: once
    type: powershell
    runAs: localSystem
    content: |-
      $ConfirmPreference="none"
      $ErrorActionPreference="Stop"
      $VerbosePreference="Continue"
      Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force # Needed for PS module installs
      Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
      Install-Module -Name AWSPowerShell -MinimumVersion 4.1.196 # Current latest version as of 3/1/23 is 4.1.196
  - frequency: always
    type: powershell
    runAs: admin
    content: |-
      # Join computer to domain if not already joined
      if (! ((Get-WmiObject -Class Win32_ComputerSystem).PartOfDomain) ) {
        # Server is not joined to the domain
        $secretName = "${delius_iaps_ad_password_secret_name}"
        $domainJoinUserName = "Admin"
        $domainJoinPassword = ConvertTo-SecureString((Get-SECSecretValue -SecretId $secretName).SecretString) -AsPlainText -Force
        $domainJoinCredential = New-Object System.Management.Automation.PSCredential($domainJoinUserName, $domainJoinPassword)
        $token = invoke-restmethod -Headers @{"X-aws-ec2-metadata-token-ttl-seconds"=3600} -Method PUT -Uri http://169.254.169.254/latest/api/token
        $instanceId = invoke-restmethod -Headers @{"X-aws-ec2-metadata-token" = $token} -Method GET -uri http://169.254.169.254/latest/meta-data/instance-id
        Add-Computer -DomainName "${delius_iaps_ad_domain_name}" -Credential $domainJoinCredential -NewName $instanceId -Force
        exit 3010 # Reboot instance, see https://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/ec2launch-v2-settings.html#ec2launch-v2-exit-codes-reboots
      }
  - frequency: once
    type: powershell
    runAs: admin
    content: |-
      # Configure IM Interface
      $ErrorActionPreference = "Stop"
      $VerbosePreference = "Continue"

      $IMConfigFile = "C:\Program Files (x86)\I2N\IapsIMInterface\Config\IMIAPS.xml"
      $configXML = [xml](Get-Content $IMConfigFile)
      $configXML.DLLDEF.IAPSORACLE.USER = (Get-SSMParameter -Name "/IMInterface/IAPSOracle/user" -WithDecryption $true).Value
      $configXML.DLLDEF.IAPSORACLE.PASSWORD = (Get-SSMParameter -Name "/IMInterface/IAPSOracle/password" -WithDecryption $true).Value
      $configXML.save($IMConfigFile)

      $service = Restart-Service -Name IMIapsInterfaceWinService -Force -PassThru
      if ($service.Status -match "Running") {
          Write-Host('Restart of IMIapsInterfaceWinService successful')
      } else {
          Write-Host('Error - Failed to restart IMIapsInterfaceWinService - see logs')
          Exit 1
      }