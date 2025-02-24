# AWS Microsoft Managed AD Terraform module

Terraform module which manages AWS Microsoft Managed AD resources.

## Providers

- hashicorp/aws | version = "~> 4.0"
- hashicorp/random | version = "~>3.3.0"

## Variables description

- **ds_managed_ad_directory_name (string)**: Fully Qualified Domain Name (FQDN) for the Managed AD. i.e. "corp.local"

- **ds_managed_ad_short_name (string)**: Active Directory Forest NetBIOS name. i.e. "corp.local"

- **ds_managed_ad_edition (string)**: AWS Microsoft Managed AD edition, either _Standard_ or _Enterprise_. Default = _Standard_

- **ds_managed_ad_vpc_id (string)**: VPC ID where Managed AD should be deployed

- **ds_managed_ad_subnet_ids (list(string))**: Two private subnet IDs where Managed AD Domain Controllers should be set

## Usage

```hcl
module "managed-ad" {
  source  = "aws-samples/windows-workloads-on-aws/aws//modules/managed-ad"

  ds_managed_ad_directory_name = "corp.local"
  ds_managed_ad_short_name     = "corp"
  ds_managed_ad_edition        = "Standard"
  ds_managed_ad_vpc_id         = "vpc-123456789"
  ds_managed_ad_subnet_ids     = ["subnet-12345678", "subnet-87654321"]
}
```

## Outputs

- **ds_managed_ad_id**: AWS Microsoft Managed AD ID

- **ds_managed_ad_ips**: AWS Microsoft Managed AD DNS IPs

- **managed_ad_password_secret_id**: Admin password is set as an entry on AWS Secrets Manager as _managed-ad-fqdn\_admin_


# Issues and workarounds
## CouudFormation Template for the KPI Infrastructure
It is recommended the rollback on failure is never disable to ensure that the infrastructure is tidied up to a state where a sucessfull rerun is possible when ever a failure occures. This is particurly important in enviroments other than development where a manual rollback may not be possible due to permissions restrictions. 

If automatic rollbck is disabled for any reason the following manuall actions may be needed to tidy up entries in the Directory Sevice that would otherwise prevent a sucessfuly rerun:

1. Remove computer SubordinateCA from Activte Directory:
Open `Active Directory Users and Computers` for domain `i2N.com`. Navigate to OU i2n\Computers and delete `SubordinateCA`.
2. Remove DNS entries for SubordinateCA and KPI.
Open `DNS` management comsole and remove DNS entries from the Forward Lookup Zone `i2n.com` for `SubordinateCA` and `KPI`.
3. Removed `Public Key Services` entries for the CAs.
Open `Active Directory Sites and Services` and Show the Servics node. At Services\Public Key Services\AIA, Delete `RootCA` and `SubordinateCA`. At Services\Public Key Services\CDP, Delete container `SubordinateCA` with all its contents. 


# Cutover and Setup Guidance
## Introduciton
This section contains instructions for [initialising the AD Management instances](#managment-server-setup) and [copying active directory users and groups from the old to the new environment](#user-group-copy).

## [Managment Server Setup](#managment-server-setup)

## Initial configuration

When each instance is created the User-Data script performs some language setup changes (including changing the date format to English(UK) and the Timezone) and install's the following software:
- Firefox
- Notepad++
- pgAdmin

###Location for User-DAta scripts and log files:

`C:\Windows\System32\config\systemprofile\AppData\Local\Temp\EC2Launch<nnnnnnnnn>\`
This will contin and copy of the User-DAte script as well as err and output log files from running the script.

## Enable File Copy via Clipboard
While files can be uploaded and downloaded via a S3 bucket it may be  more converient to enable file copy via the clipboard by removing a setting in Group Policy. This only need to be done once per environment to enable copy on all domain manbers (the management servers and the Suborginate CA server).

To amend launch the `Group Policy Editor` (`gpedit.msc`), navigate to `Local Computer Policy \ Computer Configuration \ Administrative Templates \ Windows Components \ Remote Desktop Services \ Remote Desktop Session Host \ Device and Resource Redirection` and change Setting `Do not allow drive redirection` to `Not Configured`.` 

## Required Manual Configuraiton Changes

Limitaitons in what can be automated mean that the following actions must be completed manually. (A change to use W2022 may mean that more can be automated, but this activity is being deferred while higher priority re-palatforming activities are completed.)
- Installing Language English (UK) and making it the defauls for all users.

On each management instance:
1. At `Settings > Time & Language > Language` select `Add a language` and add `English (United Kingdom)`.
2. Move English (UK) to the top of the Preferred languages list.
3. Select `Options` for `English (United Kingdom)`:
    - Download everything.
    - Under `Regional format` select 'Settings' and change and necessary to ensure all are set to `United Kingdom`.
4. Return to the Language page and wait a few minities while the language finishes installing.
5. Change the `Windows display language` to `English (United Kingdom)`.
6. Remove language `English (Unites States)`.
7. Select `Administrative language settings` then `Copy settings...` and under `Copy your current settings to:` check both `Welcome screen and system accounts` and `New user accounts` then `OK`.
8. Restart Windows to that all the above changes become effective.

## Software Install
A script exists to install the following software after making the install files available by uploading them to the S3 bucket created for this purpose, `<envioronment>-install-files`.

1. Manually Upload the following files to folder `Management-Software` in the above bukket:
    - `GoogleChromeStandaloneEnterprise64.msi
    - `putty-64bit-0.82-installer.msi
    - `WinMerge-2.16.46-x64-Setup.exe
    - `WinSCP-6.3.6-Setup.exe
    - `management-server-app-install.ps1

2. Open a `Windows Powershell` command windows with 'Run as administrator`.
3. If the `Windows Poweshell` command window will not accept key board this is most likley to be due to a defect in module `PSReadLine` Version 2.0.0 and it can be resolved by pasting and running the following command `Remove-Module PSReadLine`.
4. Download the application install script using the following PowerShell command:

> `Copy-S3Object -BucketName yjaf-<environment>-install-files -Key Management-Software/management-server-app-install.ps1 -LocalFile c:\i2N\Scripts\management-server-app-install.ps1`

E.g.

> `Copy-S3Object -BucketName yjaf-development-install-files -Key Management-Software/management-server-app-install.ps1 -LocalFile c:\i2N\Scripts\management-server-app-install.ps1`


5. Run the downloaded script:
> 'C:\i2N\Scripts\management-server-app-install.ps1 yjaf-<environment>'
E'g.
> 'C:\i2N\Scripts\management-server-app-install.ps1 yjaf-development'


## [Copy Users & Groups](#user-group-copy)

The following describes the process of copying data from one environment to another. For example copying from Sandpit to Test.

### Export All
1. RDP onto a management server in the source environment.
2. Create folder `C:\i2N\AD_Files`.
3. Copy the following files to the folder just created: export-admin-users.ps1 and export-yjaf-users.ps1.
4. Run powerShell script `export-admin-users.ps1`
5. Run powerShell script `export-yjaf-users.ps1`
6. Copy the files created by the above scripts to a management server in the destination environment. This can eith rt be done using RDP file copy or by uploading them to an S3 bucket that is configured for replication. The files are:
    - `admins.csv`
    - `admin-membership.csv`
    - `users.csv`
    - `groups.csv`
    - `roles.csv`

### Import All
1. RDP onto a management server in the destination environment as the initial docmin user `admin` whose password is in Secret `i2n.com_admin_secret_2`.
2. Create folder `C:\i2N\AD_Files`.
3. Copy all the exported AD files to the above folder.
3. Copy the following files to the folder just created: `create-ou-tree.ps1`, `OUTree-DEfault.csv`, `import-admin-users.ps1` and `import-yjaf-users.ps1`.
4. Open a Powershell wondow at `C:\i2N\AD_Files`
4. Run powerShell script `.\create-ou-tree.ps1`
5. Run powerShell script `.\import-yjaf-users.ps1`
6. Run powerShell script `.\import-admin-users.ps1`
Note: Errors relating to admin user should be ignored as this user is created when the infrastructure is built.

### Cutover 
For cutover repeat the export and import steps for Yjaf Users only.
On a source management server:
1. Run powershell script `export-yjaf-users.ps1`
2. Copy the files users.csv, groups.csv and roles.csv created by the above scripts to a management server in the destination environment.
On a destination management server:
1. Delete all Users from OU `i2N\Accounts\Users`.
2. Run powerShell script import-yjaf-users.ps1
