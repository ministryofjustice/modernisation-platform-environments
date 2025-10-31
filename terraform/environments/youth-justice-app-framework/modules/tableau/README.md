# YJAF EC2 Teraform module

## Summary
This module manages the Tableau instance and Application load balancer and associated security groups. The Items created and modified are:

- Tableau Server ec2 instance.
- Tableau Applicaiton Load Balancer along with its listeners and its target resource of Tableau Server.
- A Security Group for the Tableau Server.
- A Secutity Group for the Load Balancer.
- PostgreSQL and Redshift security group rules to enable access from Tableau Server.
- Directory Service security group rules to enable LDAP & LDAPS access from Tableau Server.
- IAM policies, roles and instance role for Tableau Server.
- A key-pair for Tableau server.
- S3 buckets for ALB logs and Tableau backups.

## Inputs

**project_name**: (string) Project name within aws.
**environment**: (string) Deployment environment.
**test_mode**: (string) (Optional) When test mode is true the destroy command can be used to remove all items. Default false.
**tags** (map(string)) User defined extra tags to be added to all resources created in the module. Default is an empty map.**
**vpc_id**: (string) VPC ID.

### Tableasu Instance Inputs
**tableau_subnet_id**: (string) ID of the Subnet where the tableau instance is to be created.
**instance_type**: (string) Type of EC2 instance to provision for Tableau. Default "t3.nano".
**instance_volume_size**: (number) The size of the volumne to be alocated to the Tableau instance. Default 500.
**instance_key_name**: (string) The name suffix for the Key Pair to used for the Tableau instance. It will be suffixed with the project and environment name. Default "ec2-instance-keypair".
**private_ip**: (string) The IP address to be assigned to the Tablau instance. It is important to retaian this value for Tableau licencing. If not specified a new value will be assigned. Default null.
**patch_schedule**: (string) The required value for the PatchSchedule tag.
**availability_schedule**: (string) The required value for the Schedule tag.
### ALB Inputs
**alb_name**: (string) The name of the aplplication Load Balancer that publishes the Tableau server. Default "tableau-alb".
**alb_subnet_ids** (list(string)) List of subnet IDs to which the Tableau applcation load bbalancer will be assigned.
**certificate_arn** (string) The arn of the SSL cetificate to use for external access to Tableau.
### Tableau security gropup inputs
**directory_service_sg_id**: (string) The ID of the Active directory Service Security Group. Used to add a rules to aneble ldap & ldaps to AD.
**management_server_sg_id**: (string) The ID of the Management Servers security group.
**postgresql_sg_id**: (string) The ID of the RDS PostgreSQL Security Group. Used to add a rule to enable Tableau access to PostgreSQL.
**redshift_sg_id**: (string) The ID of the Redshift Serverless Security Group. Used to add a rule to enable Tableau access to Redshift.
### Datadog Inputs
**datadog_api_key_arn**: (string) The ARN of the Secret that holds the Datadog API Key.

**kms_key_arn**: (string) ARN of the AWS KMS key to be used to encrypt secret values.

## Outputs

**instance_ami**: The AMI of the Tableaue ec2 instance.
**instance_arn**: The ARN of the Tableau ec2 instance.{
**tableau_sg_id**: The ID of the Security Group hat controlls access to the Tableau ec3 instnce.


# Tableau Install and Setup

## Introduction
The process for restoring Tableau from backup is followed with some variations described below to deal with differences between the old and new environments.

The main difference is use of Site export and import functions rather than doing a repository backup and restore as the later results in broken user records due to the Acitive directory change.

## Install and Set-up
The process for recovery of Tableau from backups is outlined in Confluance at <https://yjb.atlassian.net/wiki/spaces/YAM/pages/5191794714/DOE+Tableau+Backup+and+Recovery#Recovery.1> which refers to detailed instructions in <https://yjb.atlassian.net/wiki/spaces/YAM/pages/4642507957/DOE+Tableau+Server+Install+Guide?atlOrigin=eyJpIjoiODA0MTExZDI0YjRhNGU0N2EwMGE1ZmQxOTBmYWEzNmMiLCJwIjoiYyJ9> and its subordinate documents.

The process will be followed but with alterations to deal with the new environment. In outline:

1. A new server is provisioned by Terraform.
2. Make Install and Backup Files available.
3. Create a new installation of Tableau as outlined in the Recovery instructions.
4. Enable External HTTPS with a certficicate signed by the new Subordinate CA.
5. Restore settings as described below. This is a variation of the the Setting Restore process in the Recovery instructions to account for differences between the environments.
6. Export and Import the Default and Guest sites as described in  (instead of restoring the Repository).

### Make Install and Backup Files Available
Upload the following files to S3 bucket `yjaf-<envoronment>-tableau-backups-archive`, folder `Install_Files`:
    - `AmazonRedshiftODBC-64-bit-1.5.9.1011-1.x86_64.rpm`
    - `identity-store-template.json`
    - `odbc.ini`
    - `odbcinst.ini`
    - `openssl-tableau.conf`
    - `postgresql-42.7.3.jar`
    - `registration.json`
    - `tableau_redshift_odbc.sh`
    - `tableau-backup.sh`
    - `tableau-server-2024-2-2.x86_64.rpm`

The latest Tableau backup files should have been replicated to S3 bucket `yjaf-<envoronment>-tableau-backups-archive`. The latest settings file needs to be copied to s3 location `yjaf-<envoronment>-tableau-backups/Install_Files` and renamed to `settings_for_restore.json`.

### Tableau Settings Restore
The process is as documented in the Recovey instructions but file `settings_for_restore.json` must first be eddited to reflect the new environment. Make the changes after Tableau instalation and setup when the new values are known. Change values of config keys as described below:

- **wgserver.domain.password**: To be set to the value assigned to the tableau domain user. The value can be copied from file `identify-store.json`.
- **wgserver.domain.port**: If present this config key must be removed.
- **wgserver.domain.ldap.hostname**: Copy from `identify-store.json`.
- **vizportal.rest_api.cors.allow_origin**: Need to be populated with a comma seperated list of external URL for the YJAF and Tableau websites.

In environments that are configured for ldaps (i.e. where setting `**wgserver.domain.sslport**` is present in the settings file rather than `**wgserver.domain.port**`) and the settings change should not be applied to Tableau until External HTTPs has been enabled as described in the next section.

### Enable External HTTPS
The process for this is described in Confluance document <https://yjb.atlassian.net/wiki/spaces/YAM/pages/4729470989/DOE+Tableau+Enable+External+HTTPS?atlOrigin=eyJpIjoiNWQyNjA4YTQxYjRlNGRiNDk3NjU0ZWJhNWM4Mzg3NGUiLCJwIjoiYyJ9>.

A copy of openssl-tableau.conf will already be available. The Siging Request and Certificate files can be copied beteen the Tableau and SubordinateCA servers via s3 location `yjaf-<envoronment>-tableau-backups/Install_Files`.

Review the proposed Tableau settings changes and, if they look OK, apply them.

# Tableau Site Export and Import #

## Introduction
Use of the Site Export and Import functions allows for mapping of all users to the new Active Directory Services, but has other limitaitons as described in <https://help.tableau.com/current/server-linux/en-us/sites_exportimport.htm>.

On the new Server all Tableau users must first be imported from Activey Directory and all must be enabled. Any disabled user will need to be removed from the old Tableasue service or enabled in Active Directory in the new environment.

It may also be necessary to create Prep flow scheduled in the new environment to enable their mapping form the old enviroment.

## Preperation - Old Tableau ##
The import will fail if any Tableau users are disabled in AD, so they must either be enabled in the new environment or, preferebly, removed from Tableau before running the Site extract. This activity must be done independantly for each Site - Default and Guest.

General tyding up id also recommended to ensure that the migration proceeds smoothly, e.g. removing reudundant work books and data sources.

## Preperation - New Tableau ##
All Users must be imported to Tableaus before the import is run.

1. For the Default site, ensure thatall Tableau users are members of Group `tableau_users` and that not and disabled. Any that are disabled must be recorded and removed from removed from both the Group and the Tableau instance.

2. For the Guest site, ensure that group `tableau_yjaf_guest` exsists and is a member of group `yot_f00` and all groups with name's in the format `yu_f00..00` (where . represents any value) and are not disabled. Any that are disabled must be recorded and removed from both the group and the old Tableau instance.

3. Actions need for Pre Flow schedules to be documented after repeating the whole migration.

## Site Export ##

1. As `root` or `tabadmin` run the following commands to export each site:

**NOTE:** The example scripts are for preprod and all occurances of `preprod` will need to be replace with the environment name, e.g. `sandpit` or `prod`.

  `tsm sites export --site-id Default --file site-export-preprod-default.zip`

  `tsm sites export --site-id Guest --file site-export-preprod-guest.zip`

2. Copy the export files to S3 for transfer to moj.

  `aws s3 cp /var/opt/tableau/tableau_server/data/tabsvc/files/siteexports/site-export-preprod-default.zip s3://yjaf-preprod-tableau-backups/Install_Files/site-export-preprod-default.zip`

  `aws s3 cp /var/opt/tableau/tableau_server/data/tabsvc/files/siteexports/site-export-preprod-guest.zip s3://yjaf-preprod-tableau-backups/Install_Files/site-export-preprod-guest.zip`

## Prepare Tableau ##
On each Tableaus Server administration site import the groups prepared above:
- On the Default Site import GRoup `tableau_users` and set the defauls role to `Unlicensed`
- On the Guest Site import GRoup `tableau_yjaf_guest` and set the default role to `Unlicensed`

## Import Sites ##

1. On the AWS S3 admin page for the new account copy the site export files (replacing `preproduction` and `preprod` as necessary for the account concerned).

   Copy `site-export-preprod-default.zip` and `site-export-preprod-default.zip` from the `Import_Files` folder in bucket `yjaf-preproduction-tableau-backups-archive` to the same folder in `yjaf-preproduction-tableau-backups`.

**The remaining Steps are to be completed on the Tableaus servers as `root` or `tabadmin`.**

2. Run the following commands to copy the site export files to Tableau Server:

  `aws s3 cp s3://yjaf-preproduction-tableau-backups/Install_Files/site-export-preprod-default.zip /var/opt/tableau/tableau_server/data/tabsvc/files/siteimports/site-export-preprod-default.zip`

  `chown tableau:tableau /var/opt/tableau/tableau_server/data/tabsvc/files/siteimports/site-export-preprod-default.zip`

  `aws s3 cp s3://yjaf-preproduction-tableau-backups/Install_Files/site-export-preprod-guest.zip /var/opt/tableau/tableau_server/data/tabsvc/files/siteimports/site-export-preprod-guest.zip`
  
 `chown tableau:tableau /var/opt/tableau/tableau_server/data/tabsvc/files/siteimports/site-export-preprod-guest.zip`

3. Generate import mppping files:

`tsm sites import --site-id Default --file site-export-preprod-default.zip`

`tsm sites import --site-id Guest --file site-export-preprod-guest.zip`

The above scripts output the location of the mappings files, which will be `/var/opt/tableau/tableau_server/data/tabsvc/files/siteimports/working/import_<id>_<date-time>/mappings` with <id> and <date-time> replaced with the site ID and time of the run.

4. Review each of the csv mapping files. Where any mapping is specified as `???` it must be replaced with an appropriate value before proceding to the next step eith by amending the file or by  repeating this step after changes to Tableau (e.g. importing a missing user).

5. Import correctly mapped files.

 `tsm sites import-verified --import-job-dir /var/opt/tableau/tableau_server/data/tabsvc/files/siteimports/working/import_<site_Id>_<date-time> --site-id Default`

 `tsm sites import-verified --import-job-dir /var/opt/tableau/tableau_server/data/tabsvc/files/siteimports/working/import_<site_Id>_<date-time> --site-id Guest`


6. If errors are reported review the log files (the location is output in the error message) and apply corrections before repeating the about steps as appropriate.


# Cutover

Repeat the Site Export and Imports activities.

It is assumed that any changes to settings applied after Install and Setup of the new Taleau Server will be applied to both the old and new instances and that only site content needs to be transferred at Cutover.

