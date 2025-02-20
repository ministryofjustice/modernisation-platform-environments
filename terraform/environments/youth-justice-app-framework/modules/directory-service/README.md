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
# Issues and workarounds
## CouudFormation Template for the KPI Infrastructure
This does not rollback cleanly following a faulure. The CA instances are removed but artifacts created in the Directory Service are not removed automatically. This causes failures when it is rerun as it cannot create entries that already exist. The folllowing manual actions need to be completed from the Management Instance after a Rollback  which removes the CA Instances:

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

The following describes the process of copying data from one environment to another. For example copying from preprod to dev.

Once you are on a management server, export the OUs, groups, roles and users from the source environment using the following powershell commands
  
  ```powershell
  # Export Account Users
  Get-ADUser -Filter * -SearchBase "OU=Users,OU=Accounts,OU=i2N,DC=i2n,DC=com" -Properties * |  # retrieves users in OU i2N\Accounts\Users.
  Select-Object Name, SamAccountName, UserPrincipalName, GivenName, Initials, sn, displayName, mail, Enabled |  # selects required user properties.
  Export-Csv -Path users.csv -NoTypeInformation # exports the users to a CSV file.

  # Export Account Groups
  Get-ADGroup -Filter * -SearchBase "OU=Groups,OU=Accounts,OU=i2N,DC=i2n,DC=com" |  # retrieves all groups in OU i2N\Accounts\Groups
  Select-Object Name, SamAccountName, GroupCategory, GroupScope |  # selects the Name, SamAccountName, GroupCategory, and GroupScope properties of the groups.
  Export-Csv -Path groups.csv -NoTypeInformation # exports the groups to a CSV file.

  # Export Account Roles
  Get-ADGroup -Filter * -SearchBase "OU=Roles,OU=Accounts,OU=i2N,DC=i2n,DC=com" |  # retrieves all Groups in OU i2N\Accounts\Roles.
  Select-Object Name, SamAccountName, GroupScope, GroupCategory, DistinguishedName | # selects the Name, SamAccountName, GroupScope, GroupCategory, and DistinguishedName properties of the roles.
  Export-Csv -Path "roles.csv" -NoTypeInformation # exports the roles to a CSV file.

  # Export OUs - not needed as the UO structure is fixed
  $OUs = Get-ADOrganizationalUnit -Filter * | # retrieves all Organizational Units (OUs) in the Active Directory.
    Select-Object Name, DistinguishedName, 
    @{n='OUPath';e={$_.DistinguishedName -replace '^.+?,(CN|OU|DC.+)','$1'}}, #strip off initial DN part to get relevant path
    @{n='OUNum';e={([regex]::Matches($_.DistinguishedName, "OU=")).Count}} |  # count the number of OUs in the path so we can record depth
    Sort-Object OUNum | # sort by depth for later import
    Export-Csv -Path "OUTree.csv" -NoTypeInformation

  # Export Members for Groups in the Aoounts Groups OU (avoids use of Get-ADGroupMember due to its limit of 5,000 members)
  Get-ADGroup -Filter * -SearchBase "OU=Groups,OU=Accounts,OU=i2N,DC=i2n,DC=com" -Properties Member|  # retrieves menmbership details for all Groups in the Groups OU.
  %{$group_name = $_.Name; $_.Member} | # make the gounp name available and retun a list of members
  Select  @{label = "Group_Name"; expression={ $group_name }}, @{label = "Member_Name"; expression={ $_ }} | # Select group name and member name
  Export-Csv -Path group-members.csv -NoTypeInformation # exports group members to a CSV file.

  # Export Members for Groups in the Accounts Roles OU (avoids use of Get-ADGroupMember due to its limit of 5,000 members)
  Get-ADGroup -Filter * -SearchBase "OU=Roles,OU=Accounts,OU=i2N,DC=i2n,DC=com" -Properties Member|  # retrieves menmbership details for all Groups in the Roles OU.
  %{$group_name = $_.Name; $_.Member} | # make the group name available and retun a list of members
  Select  @{label = "Group_Name"; expression={ $group_name }}, @{label = "Member_Name"; expression={ $_ }} | # Select group name and member name
  Export-Csv -Path role-members.csv -NoTypeInformation # exports role members to a CSV file.

  # Export Administrators
  Get-ADUser -Filter * -SearchBase "OU=Users,OU=i2N,DC=i2n,DC=com" -Properties * |  # retrieves all users in OU i2N\Users.
  Select-Object Name, SamAccountName, UserPrincipalName, GivenName, Initials, sn, displayName, mail, Enabled |  # selects required user properties.
  Export-Csv -Path admins.csv -NoTypeInformation # exports the admin users to a CSV file.

  # Export Admin Group Membership
  Get-ADUser -Filter * -SearchBase "OU=Users,OU=i2N,DC=i2n,DC=com" -Properties MemberOf|  # retrieves membership details for all Users in the Users OU.
  %{$user_name = $_.Name; $_.MemberOf} | # make the user name available and retun a list of groups tha it is a member of
  Select  @{label = "User_Name"; expression={ $user_name }}, @{label = "Group_Name"; expression={ $_ }} | # Select the user name and group name
  Export-Csv -Path admin-membership.csv -NoTypeInformation # exports admin user member of groups to a CSV file.



Copy the output files to an S3 bucket that can be accessed by your target account management instance. Copy the files to the instance. Then import the files using the following powershell commands
  
    ```powershell
    #import custom OU structure 
    $OUs = import-csv OUTree-Default.csv
    ForEach ($OU in $OUs)
          {New-ADOrganizationalUnit -Name $OU.Name -Path $OU.OUPath}

    #Import Groups to OU i2N\Accounts\Groups
    Import-Csv -Path groups.csv | ForEach-Object { #for each line in csv add AD group
        New-ADGroup -Name $_.Name `
                    -GroupScope $_.GroupScope `
                    -Path "OU=Groups,OU=Accounts,OU=i2N,DC=i2n,DC=com" `
                    -GroupCategory Security
    }
    
    #import Groups the represent Roles to OU i2N\Accounts\Roles
    Import-Csv -Path "roles.csv" | ForEach-Object { #for each line in csv add AD role
        New-ADGroup -Name $_.Name `
                -SamAccountName $_.SamAccountName `
                -GroupScope $_.GroupScope `
                -GroupCategory $_.GroupCategory `
                -Path "OU=Roles,OU=Accounts,OU=i2N,DC=i2n,DC=com"
    }

    # Generate a random password fr user import 
    $password = [System.Web.Security.Membership]::GeneratePassword(20, 2)
    $secure = ConvertTo-SecureString $password -AsPlainText -Force)

    #Import Account usersvto OU i2n|Accounts\Users
    Import-Csv -Path users.csv | ForEach-Object { #for each line in csv add AD user
        New-ADUser -Name $_.Name `
                -SamAccountName $_.SamAccountName `
                -UserPrincipalName $_.UserPrincipalName `
                -GivenName $_.GivenName `
                -Initials $_.Initials `
                -Surname $_.sn `
                -DisplayName $_.displayName `
                -EmailAddress $_.mail `
                -Path "OU=Users,OU=Accounts,OU=i2N,DC=i2n,DC=com" `
                -AccountPassword $secure `
                -Enabled ($_.Enabled -eq "True")
    }

    #Import group members
    Import-Csv -Path group-members.csv | ForEach-Object { #for each line in csv add AD group
        Add-ADGroupMember -Identity $_.Group_Name `
                -Members $_.Member_Name
    }
   
    #Import Role members
    Import-Csv -Path role-members.csv | ForEach-Object { #for each line in csv add AD group
        Add-ADGroupMember -Identity $_.Group_Name `
                -Members $_.Member_Name
    }
  
    #Import admin users to OU i2N\Users
    Import-Csv -Path admins.csv | ForEach-Object { #for each line in csv add AD user
        New-ADUser -Name $_.Name `
                -SamAccountName $_.SamAccountName `
                -UserPrincipalName $_.UserPrincipalName `
                -GivenName $_.GivenName `
                -Initials $_.Initials `
                -Surname $_.sn `
                -DisplayName $_.displayName `
                -EmailAddress $_.mail `
                -Path "OU=Users,OU=i2N,DC=i2n,DC=com" `
                -AccountPassword $secure `
                -Enabled ($_.Enabled -eq "True")
    }

    #Import Admin user membership
    Import-Csv -Path admin-membership.csv | ForEach-Object { #for each line in csv add AD group
        Add-ADGroupMember -Identity $_.Group_Name `
                -Members "CN=$($_.User_Name),OU=Users,OU=i2N,DC=i2n,DC=com"
    }


## Outputs

- **ds_managed_ad_id**: AWS Microsoft Managed AD ID

- **ds_managed_ad_ips**: AWS Microsoft Managed AD DNS IPs

- **managed_ad_password_secret_id**: Admin password is set as an entry on AWS Secrets Manager as _managed-ad-fqdn\_admin_

## Initialise Management Instances

Location for User-DAta scripts and log files:


C:\Windows\System32\config\systemprofile\AppData\Local\Temp\Amazon\EC2-Windows\Launch\InvokeUserData