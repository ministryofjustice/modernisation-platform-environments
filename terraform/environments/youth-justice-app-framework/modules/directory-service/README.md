# AWS Microsoft Managed AD Terraform module

Terraform module which manages AWS Microsoft Managed AD resources.

## Providers

- hashicorp/aws | version = "~> 4.0"
- hashicorp/random | version = "~>3.3.0"

## Variables description

- **environment_name (string)**: A short name for the enviroment.

- **ds_managed_ad_directory_name (string)**: Fully Qualified Domain Name (FQDN) for the Managed AD. i.e. "corp.local"

- **ds_managed_ad_short_name (string)**: Active Directory Forest NetBIOS name. i.e. "corp.local"

- **ds_managed_ad_edition (string)**: AWS Microsoft Managed AD edition, either _Standard_ or _Enterprise_. Default = _Standard_

- **ds_managed_ad_vpc_id (string)**: VPC ID where Managed AD should be deployed

- **private_subnet_ids (list(string))**: This of private subnet IDs (at least 2) across which instance will be distributed. The Certificate Authorites will go in the first subnet. The AD Domain Controllers will be distributed oher the first 2 subnets. The management instances will be distributed over all subnets.

- **ds_managed_ad_secret_key (string)**: ARN or Id of the AWS KMS key to be used to encrypt the secret values in the versions stored in this secret. Default "aws/secretsmanager".

- **management_keypair_name (string)**: The name of the keypair to use for the management server.

- **vpc_cidr_block (string)**: The CIDR block for the VPC.

- **project_name (string)**: project name within aws

- **tags (map(string))**: User defined extra tags to be added to all resources created in the module.

- **ad_management_instance_count (number)**: The number of Active Directory Management servers to be created. Default is 2.

- **desired_number_of_domain_controllers (number)**: The number of Doamin Coltrollers to create. Default is 2.

- **rds_cluster_security_group_id (string)**: The Id of the Security Group that enables access to the RDS PostgreSQL Cluster.


## Usage

```hcl
module "managed-ad" {
  source  = "./modules/directory-service"
  
 
  ds_managed_ad_directory_name = "corp.local"
  ds_managed_ad_short_name     = "corp"
  ds_managed_ad_edition        = "Standard"
  ds_managed_ad_vpc_id         = "vpc-123456789"
  ds_managed_ad_subnet_ids     = ["subnet-12345678", "subnet-87654321"]

  project_name = "yjaf"

  environment_name             = "yjaf-development"

  ds_managed_ad_directory_name = "i2n.com"
  ds_managed_ad_short_name     = "i2n"
  management_keypair_name      = "ad_management_server"
  ds_managed_ad_secret_key     = module.kms.key_arn

  ds_managed_ad_vpc_id     = data.aws_vpc.shared.id
  private_subnet_ids       = [data.aws_subnet.private_subnets_a.id, data.aws_subnet.private_subnets_b.id, data.aws_subnet.private_subnets_c.id]
  vpc_cidr_block           = data.aws_vpc.shared.cidr_block
  
  rds_cluster_security_group_id = module.aurora.rds_cluster_security_group_id

  depends_on = [module.aurora]
}
```

## Outputs

- **ds_managed_ad_id**: AWS Microsoft Managed AD ID

- **ds_managed_ad_ips**: AWS Microsoft Managed AD DNS IPs

- **managed_ad_password_secret_id**: Admin password is set as an entry on AWS Secrets Manager as _managed-ad-fqdn\_admin_


# Issues and workarounds
## CloudFormation Template for the KPI Infrastructure
It is recommended that rollback on failure is never disable to ensure that the infrastructure is tidied up to a state where a sucessfull rerun is possible when ever a failure occures. This is particurly important in enviroments other than development where a manual rollback may not be possible due to permissions restrictions.

If automatic rollbck is disabled for any reason the following manuall actions may be needed to tidy up entries in the Directory Sevice that would otherwise prevent a sucessfuly rerun:

1. Remove computer SubordinateCA from Activte Directory:
Open `Active Directory Users and Computers` for domain `i2N.com`. Navigate to OU i2n\Computers and delete `SubordinateCA`.
2. Remove DNS entries for SubordinateCA and KPI.
Open `DNS` management comsole and remove DNS entries from the Forward Lookup Zone `i2n.com` for `SubordinateCA` and `KPI`.
3. Removed `Public Key Services` entries for the CAs.
Open `Active Directory Sites and Services` and Show the Servics node. At Services\Public Key Services\AIA, Delete `RootCA` and `SubordinateCA`. At Services\Public Key Services\CDP, Delete container `SubordinateCA` with all its contents.

## Troublshooting Domain Join
If login doesn't work using the domain `admin` user as an alternative the local `Administrator` user can be used. The password for the local `Administrator` use is in Secret `ad_instance_password_secret_1`.

If the instances hasn't koined the domain, this is probably becuase the domain joint association has not been successfuly. When creating a 2nd instance it has been seen to fail with status `Undetermined`, whithout any other informaiotn regarding the cause. (The cause is probably that it tried to run before the instance was ready.) To identify if this is the cause and resolve via the AWS consoler:
1. Navigate to `AWS Systems Manager` > `State Manager` and look for the latest association for document `ssm_document_ad_schema2.2`.
2. Select the above association and use the `Resources` tab to check the status.
3. Reapply the association using button `Apply association now` and confirm that it is now successful.

# Management Server Setup
## Introduciton
This section contains instructions for [initialising the AD Management instances](#managment-server-setup), [copying active directory users and groups from the old to the new environment](#user-group-copy) and [Certificate Authority SetUp](#ca-setup).

## [Managment Server Setup](#managment-server-setup)

## Initial configuration

When each instance is created the User-Data script performs some language setup changes (including changing the date format to English(UK) and the Timezone) and install's the following software:
- Firefox
- Notepad++
- pgAdmin

### Location for User-Data scripts and log files

`C:\Windows\System32\config\systemprofile\AppData\Local\Temp\EC2Launch<nnnnnnnnn>\`
This will contin and copy of the User-Data script as well as error and output log files from running the script.

## Enable File Copy via Clipboard
While files can be uploaded and downloaded via a S3 bucket it may be  more converient to enable file copy via the clipboard by removing a setting in Group Policy. This only needs to be done once per environment to enable copy on all domain menbers (the management servers and the Suborginate CA server).

To amend launch the `Group Policy Editor` (`gpedit.msc`), navigate to `Local Computer Policy \ Computer Configuration \ Administrative Templates \ Windows Components \ Remote Desktop Services \ Remote Desktop Session Host \ Device and Resource Redirection` and change Setting `Do not allow drive redirection` to `Not Configured`.`

## Required Manual Configuraiton Changes

Limitaitons in what can be automated mean that the following actions must be completed manually. (A change to use W2022 may mean that more can be automated, but this activity is being deferred while higher priority re-palatforming activities are completed.)
- Installing Language English (UK) and making it the defauls for all users.

On each management instance:
1. At `Settings > Time & Language > Language` select `Add a language` and add `English (United Kingdom)`.
2. Move English (UK) to the top of the Preferred languages list.
3. Select `Options` for `English (United Kingdom)`:
    - Download everything.
    - Under `Regional format` select 'Settings' and change as necessary to ensure all are set to `United Kingdom`.
4. Return to the Language page and wait a few minities while the language finishes installing.
5. Change the `Windows display language` to `English (United Kingdom)`. (Need to signout and log back in for this to become effective.)
6. Remove language `English (Unites States)`.
7. Select `Administrative language settings` then `Copy settings...` and under `Copy your current settings to:` check both `Welcome screen and system accounts` and `New user accounts` then `OK`.
8. Restart Windows so that all the above changes become effective.

## Software Install
A script exists to install the following software after making the install files available by uploading them to the S3 bucket created for this purpose, `<envioronment>-install-files`.

1. Manually Upload the following files to folder `Management-Software` in the above bukket:
    - `GoogleChromeStandaloneEnterprise64.msi
    - `putty-64bit-0.82-installer.msi
    - `WinMerge-2.16.46-x64-Setup.exe
    - `WinSCP-6.3.6-Setup.exe
    - `management-server-app-install.ps1

2. Open a `Windows Powershell` command window with `Run as administrator`.
3. If the `Windows Poweshell` command window will not accept key board this is most likley to be due to a defect in module `PSReadLine` Version 2.0.0 and it can be resolved by pasting and running the following command `Remove-Module PSReadLine`.
4. Download the application install script using the following PowerShell command:

> `Copy-S3Object -BucketName yjaf-<environment>-install-files -Key Management-Software/management-server-app-install.ps1 -LocalFile c:\i2N\Scripts\management-server-app-install.ps1`

E.g.

> `Copy-S3Object -BucketName yjaf-development-install-files -Key Management-Software/management-server-app-install.ps1 -LocalFile c:\i2N\Scripts\management-server-app-install.ps1`


5. Run the downloaded script:
> 'C:\i2N\Scripts\management-server-app-install.ps1 yjaf-<environment>'
E'g.
> 'C:\i2N\Scripts\management-server-app-install.ps1 yjaf-development'

# [Certificate Authority SetUp](#ca-setup)

The additional configuration described in Confluence page <https://yjb.atlassian.net/wiki/spaces/YAM/pages/4642508592/DOE+LDAPS+and+Certificate+chaining#Domain-Controllers-Server-Certificates-AutoEnrol> has not been completed as the AD servers have auto-enroled for LDAPS certificates and LDAPS appears to be working successfully. This may need to be reconsidered following testing in Preproduction (or Test).

In addition the RootCA and SubordinateCA cetificates have been left with their default exiptiy periods of 10 and 5 years respectively, rather than changeing them to 20 and 10 years as mentioned in the above document.

## Create Tableau Server SSL Template

A template needs to be created on the SubordinateCA server for Tableau web site HTTPS access as follows:
1. Launch the Certificate Templates snapin.
2. Duplicate template `Web Server` to `Tableau Web Server` and make the following changes:
    - On the `General` tab set the `Valitory period` to 1 year and 6 weeks.
    - On the `Security` tab add Group `AWS Delegated Administrators`, remove `Allow` `Read` and add `Allow` `Write` and `Enroll`.
3. Launch Server Tool `Certificate Authority`, right click on `Certificate Templates`, choose option `New` > `Certificate Template to Issue`, highlight `Tableau Web Server` and `OK`.

# [User and Group Migration](#user-group-copy)

The following describes the process of copying data from one environment to another. For example copying from Sandpit to Test.

## Create SubCA Certificate Chain
1. Export the `RootCA` and `SubordinateCA` certificates (without private keys) in `Base-64 encoded X.509` format.
2. Create file `SubordinateCA-Chain-<enviroment>.cer` by appending the contents of the RootCA file to the SubordinateCA file using a text editor (e.g. `Notepad`).

## Export All
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

7. Copy the files to the Transfer S3 bucket, e.g. run a Powershell command like:
    `Write-S3Object -BucketName yjaf-sandpit-replication-source -KeyPrefix AD_Files -Folder C:\i2n\AD_Files\`

## Import All
1. RDP onto a management server in the destination environment as the initial docmin user `admin` whose password is in Secret `i2n.com_admin_secret_2`.
2. Create folder `C:\i2N\AD_Files`.
3. Copy all the exported AD files to the above folder, e.g.: `Copy-S3Object -BucketName yjaf-development-transfer -KeyPrefix AD_Files -LocalFolder c:\i2N\AD_Files`
3. Open a Powershell window at `C:\i2N\AD_Files`
4. Run powerShell script `.\create-ou-tree.ps1`
5. Create group `Admin-password-policy` in UO `i2N` and configure the password policy <TODO>.
6. Run powerShell script `.\import-yjaf-users.ps1`
7. Run powerShell script `.\import-admin-users.ps1`
Note: Errors relating to admin user should be ignored as this user is created when the infrastructure is built.

## Correct YJAF users
Passwords need to be rest for yjaf acconunts identified in the following secrets so that they match the value recorded in the secret and the accounts need to be configured to never expire the password:
- `LDAP-administration-user`
- `yjaf-auto-admit`
- `yjaf_Auth_Email_Account`


In addtion the user identified in `LDAP-administration-user` needs to be made a member of group `AWS Delegated Administrators`.

**[TODO]** Consider writing a script to make these change automatically for efficiency and to ensure that the changes are always made correctly.

# Cutover
For cutover repeat the export and import steps for Yjaf Users only.
On a source management server:
1. Run powershell script `export-yjaf-users.ps1`
2. Copy the files users.csv, groups.csv and roles.csv created by the above scripts to a management server in the destination environment.
On a destination management server:
1. Delete all Users from OU `i2N\Accounts\Users` and all Groups from `i2N\Accounts\Groups` and `i2N\Accounts\Roles`.
2. Run powerShell script import-yjaf-users.ps1




