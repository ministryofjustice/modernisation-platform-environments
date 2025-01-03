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

## Copy Data from one env to another

The following describes the process of copying data from one environment to another. For example copying from preprod to dev. 

Once you are on a management server, export the OUs, groups, roles and users from the source environment using the following powershell commands
  
  ```powershell
  # Export Users
  Get-ADUser -Filter * -SearchBase "OU=Users,OU=Accounts,OU=i2N,DC=i2n,DC=com" |  # retrieves all users in the Active Directory.
  Select-Object Name, SamAccountName, UserPrincipalName |  # selects the Name, SamAccountName, and UserPrincipalName properties of the users.
  Export-Csv -Path users.csv -NoTypeInformation # exports the users to a CSV file.

  # Export Groups # todo fix roles bug
  Get-ADGroup -Filter * -SearchBase "OU=Groups,OU=Accounts,OU=i2N,DC=i2n,DC=com" |  # retrieves all groups in the Active Directory.
  Select-Object Name, SamAccountName, GroupCategory, GroupScope |  # selects the Name, SamAccountName, GroupCategory, and GroupScope properties of the groups.
  Export-Csv -Path groups.csv -NoTypeInformation # exports the groups to a CSV file.

  # Export Roles
  Get-ADGroup -Filter * -SearchBase "OU=Roles,OU=Accounts,OU=i2N,DC=i2n,DC=com" |  # retrieves all roles in the Active Directory.
  Select-Object Name, SamAccountName, GroupScope, GroupCategory, DistinguishedName | # selects the Name, SamAccountName, GroupScope, GroupCategory, and DistinguishedName properties of the roles.
  Export-Csv -Path "roles.csv" -NoTypeInformation # exports the roles to a CSV file.

  # Export OUs
  $OUs = Get-ADOrganizationalUnit -Filter * | # retrieves all Organizational Units (OUs) in the Active Directory.
    Select-Object Name, DistinguishedName, 
    @{n='OUPath';e={$_.DistinguishedName -replace '^.+?,(CN|OU|DC.+)','$1'}}, #strip off initial DN part to get relevant path
    @{n='OUNum';e={([regex]::Matches($_.DistinguishedName, "OU=")).Count}} |  # count the number of OUs in the path so we can record depth
    Sort-Object OUNum | # sort by depth for later import
    Export-Csv -Path "OUTree.csv" -NoTypeInformation

Copy the output files to an S3 bucket that can be accessed by your target account management instance. Copy the files to the instance. Then import the files using the following powershell commands
  
    ```powershell
    #import OUS
    #might be cleaner to edit this and remove the default/aws managed ous
    $OUs = import-csv OUTree.csv
    ForEach ($OU in $OUs)
          {New-ADOrganizationalUnit -Name $OU.Name -Path $OU.OUPath}

    #Import groups
    #errors may occur if the OU already exists, you can ignore them as they are likely aws managed groups etc
    Import-Csv -Path groups.csv | ForEach-Object { #for each line in csv add AD group
        New-ADGroup -Name $_.Name `
                    -GroupScope $_.GroupScope `
                    -Path "OU=Groups,OU=Accounts,OU=i2N,DC=i2n,DC=com" `
                    -GroupCategory Security
    }
    
    #import roles
    Import-Csv -Path "roles.csv" | ForEach-Object { #for each line in csv add AD role
        New-ADGroup -Name $_.Name `
                -SamAccountName $_.SamAccountName `
                -GroupScope $_.GroupScope `
                -GroupCategory $_.GroupCategory `
                -Path "OU=Roles,OU=Accounts,OU=i2N,DC=i2n,DC=com"
    }

    #Import users
    Import-Csv -Path users.csv | ForEach-Object { #for each line in csv add AD user
        New-ADUser -Name $_.Name `
                  -SamAccountName $_.SamAccountName `
                  -UserPrincipalName $_.UserPrincipalName `
                  -Path "OU=Users,OU=Accounts,OU=i2N,DC=i2n,DC=com" `
                  -AccountPassword (ConvertTo-SecureString "DefaultPassword123!" -AsPlainText -Force) `
                  -Enabled $true
    }



## Outputs

- **ds_managed_ad_id**: AWS Microsoft Managed AD ID

- **ds_managed_ad_ips**: AWS Microsoft Managed AD DNS IPs

- **managed_ad_password_secret_id**: Admin password is set as an entry on AWS Secrets Manager as _managed-ad-fqdn\_admin_