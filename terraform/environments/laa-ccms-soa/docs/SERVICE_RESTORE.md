# CCMS-SOA Service Restoration

This document should serve as a detailed breakdown as to how to bring CCMS SOA (Service Oriented Architecture) online from a cold start. In all likelihood this will only ever need to be done in the event that:

1. A new environment needs to be created.
2. Some catastrophic event has led to the destruction of a previous deployment and a Disaster Recovery needs to be undertaken.

Whilst application backups would make a restoration easier, they are not essential. The data that passes through SOA is transient and SOA can be brought online with no backups.

## External Dependencies

### S3

SOA depends on two external S3 buckets which are used for FTP integrations by a number of other applications. At time of writing, these buckets are part of the CCMS-EBS Infrastructure.

From SOA's perspective, these buckets are mounted to all servers at the EC2 level and implicitly exposed to running SOA containers as below:

| Bucket                           | Mount Point              | Mode |
|----------------------------------|--------------------------|------|
| laa-ccms-inbound-ENVIRONMENT-mp  | /home/ec2-user/Inbound   | 0777 |
| laa-ccms-outbound-ENVIRONMENT-mp | /home/ec2-user/Outbound  | 0777 |

Mounting is handled by the EC2 boot script which is baked in the to the EC2 Autoscaling Group Launch Template. If these Buckets are not present, boot of the EC2 instances will succeed and containers will still start, but the boot script will fail to complete properly, leading to issues deploying some Composites later in the deployment process. To this end it is better to ensure that the Buckets are in place before attempting a deployment.

Buckets should be input via the `inbound_s3_bucket_name` and `outbound_s3_bucket_name` application variables. This will configure the appropriate IAM policies from the perspective of SOA. A corresponding Bucket Policy relationship will also need to be in place in the account hosting the Buckets to allow access.

## Apply Terraform and Populate Secrets

Complete the `application_variables.json` file as appropriate for the environment being deployed to, ensuring in particular that the  `app_count_admin` and `app_count_managed` values are set to `0` and commit (this will prevent any ECS services from booting). If unsure on suitable variables for a cold start, see the file `_application_variables_starter.json`.

In the Github Actions pipeline; Terraform will Plan and Apply for lower environments. When applying for the first time the apply will fail part way through due to missing Secret Values, this is to be expected. The Secrets themselves however will be created.

Log in to the AWS console for each environment and populate the Secrets with appropriate Values, these are to be agreed with the relevant application teams that will be integrating with SOA.

## Apply Terraform

With the secrets populated, commit again (once again ensuring that `app_count_admin` and `app_count_managed` are still set to `0`). In the Github Actions Pipeline, run Terraform Plan and Apply to bring up the remaining infrastructure.

## Git clone to EFS, only needs to be done once for all envs. This is handled by the script

Within the AWS console, browse to SSM and start a session on any of the EC2 Instances that has booted and execute:

```bash
sudo su ec2-user
cd ~/efs/laa-ccms-app-soa/Scripts
```

This directory contains a number of `build.properties.environment` files (one per environment). These files are encrypted with `git-crypt` and currently there is no automated process for decrypting them on the host. Because of this limitation, the best method currently available to get files in to EFS is to have a user who currently has access to [https://github.com/ministryofjustice/laa-ccms-app-soa/tree/master/Scripts](https://github.com/ministryofjustice/laa-ccms-app-soa/tree/master/Scripts) copy cleartext versions of these files to EFS, rather than adding another GPG key to the EFS share (a long term solution to this problem is WIP).

With these files in place, any reference to passwords and endpoints should be updated to reflect:

- External Services
- Newcastle created RDS Databses
- Passwords added to Secrets Manager

## Configure the Databases

These steps should be undertaken by a DBA.

**NOTE: Prior to boot of the application, ONLY THESE STATEMENTS SHOULD BE RUN**. When the Admin Server boots for the first time, the Oracle [RCU](https://docs.oracle.com/cd/E21764_01/doc.1111/e14259/overview.htm) will initiate the SOA-DB and create various components. If any of these are created manually, the application will find itself in a crash loop.

### TDS-DB

```bash
CREATE TABLESPACE "CCMSSOA_MDS" EXTENT MANAGEMENT LOCAL AUTOALLOCATE SEGMENT SPACE MANAGEMENT AUTO DATAFILE SIZE 100M AUTOEXTEND ON NEXT 30M MAXSIZE UNLIMITED;
```

```bash
#--Obtain password from Secrets Manager -- ccms/soa/xxsoa/ds/password
CREATE USER CCMSSOA_MDS IDENTIFIED BY PASSWORD12345! DEFAULT TABLESPACE CCMSSOA_MDS;
GRANT CREATE SESSION TO CCMSSOA_MDS;
GRANT CREATE JOB TO CCMSSOA_MDS;
GRANT CREATE PROCEDURE TO CCMSSOA_MDS;
GRANT CREATE SEQUENCE TO CCMSSOA_MDS;
GRANT CREATE TABLE TO CCMSSOA_MDS;
ALTER USER CCMSSOA_MDS QUOTA UNLIMITED ON CCMSSOA_MDS;
```

### SOA-DB

```bash
#--This fix is needed to allow RCU to execute
EXECUTE rdsadmin.rdsadmin_util.grant_sys_object( p_obj_name => 'DBA_TABLESPACE_USAGE_METRICS', p_grantee => 'SOAPDB', p_privilege => 'SELECT', p_grant_option => true);
```

## Start the Admin Server

In `application_variables.json`; set `app_count_admin` to `1` and commit. Allow the Github Actions pipeline to run. This will bring up the Admin Server.

Pay attention to the application logs. The boot process can take up to 30 minutes, as part of the boot process the Oracle [RCU](https://docs.oracle.com/cd/E21764_01/doc.1111/e14259/overview.htm) will run and configure the SOA-DB database ready for use. The application should be ready for use when the weblogic console is available and can be logged in to at http://ccms-soa-admin.laa-ENVIRONMENT.modernisation-platform.service.justice.gov.uk:7001/console.

## Start a Managed Server

In `application_variables.json`; set `app_count_managed` to `1` and commit. Allow the Github Actions pipeline to run. This will bring up the Admin Server.

Pay attention to the application logs. The boot process can take around 10-15 minutes. The service is stable when the EC2 shows a healthy service **AND** Weblogic shows a healthy server. To verify in Weblogic, browse to **Environments** > **Servers** and correlate the active servers to the IPs of the currently stable servers in the **MANAGED** EC2 Loadbalancers Target Group.

## Deploy Composites

With the application stable. Deploy the application Composites. Connect to the Admin Server via the SSM console and execute:

```bash
sudo su ec2-user
cd ~/efs/laa-ccms-app-soa/Scripts
./prepare_env environment #--dev, stg, tst or prod
./weblogic update
./weblogic deploy
```

This will build and deploy Composites to Weblogic

## Scale Up

Once Composites are successfully deployed, in `application_variables.json`; increment `app_count_managed` to the desired number (incrementing by 1, committing and applying) until the desired number has been reached. This should be:

| Environment | Count |
|-------------|-------|
| Prod        | 6     |
| Preprod     | 2     |
| Test        | 2     |
| Dev         | 2     |

## Create apply_user

This step should be undertaken by a DBA. A user needs to be manually created for the Apply team named **apply_user** and the password communicated to the Apply team through an appropriate channel. There is currently no mechanism to do this programmatically.
