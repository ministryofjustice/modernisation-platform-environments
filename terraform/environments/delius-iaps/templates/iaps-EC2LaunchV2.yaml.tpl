version: 1.0
tasks:
- task: executeScript
  inputs:
  - frequency: always
    type: powershell
    runAs: localSystem
    content: |-
      $ConfirmPreference="none"
      $ErrorActionPreference="Stop"
      $VerbosePreference="Continue"
      Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
      Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
      Install-Module -Name ComputerManagementDsc -RequiredVersion 8.5.0
      Install-Module -Name cChoco -RequiredVersion 2.5.0.0
      Install-Module -Name NetworkingDsc -RequiredVersion 9.0.0
