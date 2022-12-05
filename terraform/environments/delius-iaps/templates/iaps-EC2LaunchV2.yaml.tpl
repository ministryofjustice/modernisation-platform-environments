version: 1.0
tasks:
- task: executeScript
  inputs:
  - frequency: always
    type: powershell
    runAs: admin
    content: |-
      $ConfirmPreference="none"
      $ErrorActionPreference="Stop"
      $VerbosePreference="Continue"
      Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
      Install-Module -Name ComputerManagementDsc -RequiredVersion 8.5.0
      Install-Module -Name cChoco -RequiredVersion 2.5.0.0
      Install-Module -Name NetworkingDsc -RequiredVersion 9.0.0
