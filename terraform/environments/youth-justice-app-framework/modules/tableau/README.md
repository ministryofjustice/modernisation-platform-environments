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

## Install and Restore
The process for recovery of Tableau from backups is outlined in Confluance at <https://yjb.atlassian.net/wiki/spaces/YAM/pages/5191794714/DOE+Tableau+Backup+and+Recovery#Recovery.1> which refers to detailed instructions in <https://yjb.atlassian.net/wiki/spaces/YAM/pages/4642507957/DOE+Tableau+Server+Install+Guide?atlOrigin=eyJpIjoiODA0MTExZDI0YjRhNGU0N2EwMGE1ZmQxOTBmYWEzNmMiLCJwIjoiYyJ9> and its subordinate documents.

The process will be followed but with changes, particurally to the process for restoring Tableau settings, to account for difference between the old and ned environments. In outline:

1. A new server is provisioned by Terraform.
2. Make Install and Backup Files available.
3. Create a new installation of Tableau as outlined in the Recovery instructions.
4. Enable External HTTPS with a certficicate signed by the new Subordinate CA.
5. Restore settings as described below. This is a variation of the the Setting Restore process in the Recovery instructions to account for differences between the environments.
6. Restore the Respostory as described in the Recovery instructions using file `repository_for_restore.tsbak` copied below.

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

The latest Tableau backup files should have been replicated to S3 bucket `yjaf-<envoronment>-tableau-backups-archive`. The latest settings and repository files need to be copied to s3 location  `yjaf-<envoronment>-tableau-backups/Install_Files` and renamed to `settings_for_restore.json` and `repository_for_restore.tsbak`.

### Tableau Settings Restore
The process is as documented in the Recovey instructions but file `settings_for_restore.json` must first be eddited to reflect the new environment. Make the changes after Tableau instalation and setup when the new values are known. Change values of config keys as described below:

- **wgserver.domain.password**: To be set to the value assigned to the tableau domain user. The value can be copied from file `identify-store.json`.
- **wgserver.domain.port**: If present this config key must be removed.
- **wgserver.domain.ldap.hostname**: Copy from `identify-store.json`.
- **wgserver.domain.ssl_port**: Add if not already present and set the value to `636`.
- **vizportal.rest_api.cors.allow_origin**: Need to be populated with a comma seperated list of external URL for the YJAF and Tableau websites. It will probable not need to be changes in `preproduction` and `production`.

After restoring the settings they should not be applied to Tableau until External HTTPs has been enabled as described in the next section.

### Enable External HTTPS
The process for this is described in Confluance document <https://yjb.atlassian.net/wiki/spaces/YAM/pages/4729470989/DOE+Tableau+Enable+External+HTTPS?atlOrigin=eyJpIjoiNWQyNjA4YTQxYjRlNGRiNDk3NjU0ZWJhNWM4Mzg3NGUiLCJwIjoiYyJ9>.

A copy of openssl-tableau.conf will already be available. The Siging Request and Certificate files can be copied beteen the Tableau and SubordinateCA servers via s3 location `yjaf-<envoronment>-tableau-backups/Install_Files`.

Review the proposed Tableau settings changes and, if they look OK, apply them.

### Restore the Repositiory
See the restore instuctions referenced above.

### Recreate All Users
The move between AWS accounts involves the creation of a new Directory service and transfer of all users and groups. As a consequecnce it is not possibel to authenticate to Tableau using an existing account. The solution is to remove a recreate Tableau users. The can be done as follows:

1. Capture information on all users in Tableau. This is best done as a services of screen prints of the Site Users page. First sort by Site role to make it easier to identify user in each role. Save the screnprints to a word document with an appropriate name (e.g. `Tableau Users Preprod 30042025.docx`).

2. Create the following groups in AD if they do not already exist.
- **Tableau_Creator**
- **Tableau_Publisher**
- **Tableau_Viewer**
- **Tableau_Site_Admin**

3. Ensure that each of the above groups has the same

# Cutover

## Final Backup
1. On the old Tableau server, manually run the Tableau backup job.
2. In the new environment wait for the backup files to appear in S3 bucket `yjaf-<envoronment>-tableau-backups-archive`.

## Restore the Repository
As described above.