# CCMS-SOA Service Restoration

This document should serve as a detailed breakdown as to how to bring CCMS SOA (Service Oriented Architecture) online from a cold start. In all likelihood this will only ever need to be done in the event that:

1. A new environment needs to be created.
2. Some catastrophic event has led to the destruction of a previous deployment and a Disaster Recovery needs to be undertaken.

Whilst application backups would make a restoration easier, they are not essential. The data that passes through SOA is transient and SOA can be brought online with no backups.

## Apply Terraform and Populate Secrets

Complete the `application_variables.json` file as appropriate for the environment being deployed to, ensuring in particular that the  `admin_app_count` and `managed_app_count` values are set to `0` and commit (this will prevent any ECS services from booting). If unsure on suitable variables for a cold start, see the file `_application_variables_starter.json`.

In the Github Actions pipeline; Terraform will Plan and Apply for lower environments. When applying for the first time the apply will fail part way through due to missing Secret Values, this is to be expected. The Secrets themselves however will be created.

Log in to the AWS console for each environment and populate the Secrets with appropriate Values, these are to be agreed with the relevant application teams that will be integrating with SOA.

## Apply Terraform

With the secrets populated, commit again (once again ensuring that `admin_app_count` and `managed_app_count` are still set to `0`). In the Github Actions Pipeline, run Terraform Plan and Apply to bring up the remaining infrastructure.

## External S3 Dependencies

SOA depends on two external S3 buckets which are used for FTP integrations by a number of other applications. At time of writing, these buckets are part of the [CCMS-EBS Infrastructure](https://github.com/ministryofjustice/modernisation-platform-environments/tree/main/terraform/environments/ccms-ebs).

From SOA's perspective, these buckets are mounted to all servers at the EC2 level and implicitly exposed to running SOA containers as below:

| Bucket                           | EC2 Mount Point          | IAM Role                   |
|----------------------------------|--------------------------|----------------------------|
| laa-ccms-inbound-ENVIRONMENT-mp  | /home/ec2-user/Inbound   | ccms-soa-ec2-instance-role |
| laa-ccms-outbound-ENVIRONMENT-mp | /home/ec2-user/Outbound  | ccms-soa-ec2-instance-role |

Mounting is handled by the EC2 boot script which is baked in the to the EC2 Autoscaling Group Launch Template. If these Buckets are not present, boot of the EC2 instances will succeed and containers will still start, but the boot script will fail to complete properly, leading to issues deploying some Composites later in the deployment process. To this end it is better to ensure that the Buckets are in place before attempting a deployment.

Buckets should be input via the `inbound_s3_bucket_name` and `outbound_s3_bucket_name` application variables. This will configure the appropriate IAM policies from the perspective of SOA. A corresponding Bucket Policy relationship will also need to be in place in the account hosting the Buckets to allow access. So to this end it is **essential that the relevant IAM Roles shown above are already created within the SOA Account before attempting to configure inside the corresponding EBS Account**.

Once the IAM/S3 integration is completed. Log in to the AWS console and **TERMINATE** any EC2 Instances (both Admin and Managed). The Auto Scaling Group will start new instances which should mount the newly integrated S3 Buckets during boot.

## Git clone to EFS, only needs to be done once for all envs. This is handled by the script

Within the AWS console, browse to SSM and start a session on any of the EC2 Instances that has booted and execute:

```bash
sudo su ec2-user
cd ~/efs/laa-ccms-app-soa/Scripts
```

This directory contains a number of `build.properties.environment` files (one per environment). These files are encrypted with `git-crypt` and currently there is no automated process for decrypting them on the host. Because of this limitation, the best method currently available to get the file you need on to EFS is to have a user who currently has access to [https://github.com/ministryofjustice/laa-ccms-app-soa/tree/master/Scripts](https://github.com/ministryofjustice/laa-ccms-app-soa/tree/master/Scripts) copy a cleartext version of these file you need to EFS, rather than adding another GPG key to the EFS share (a long term solution to this problem is WIP).

For example if you are building a dev environment, you will need to delete `build.properties.dev` from EFS, then create a new file and populate it with the cleartext contents of `build.properties.dev`. As each of these files is environment specific, there is no need to copy every environment's build files, only the single file for the environment you are building.

With the configuration file in place, any reference to passwords and endpoints should be updated to reflect:

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

In `application_variables.json`; set `admin_app_count` to `1` and commit. Allow the Github Actions pipeline to run. This will bring up the Admin Server.

Pay attention to the application logs. The boot process can take up to 30 minutes, as part of the boot process the Oracle [RCU](https://docs.oracle.com/cd/E21764_01/doc.1111/e14259/overview.htm) will run and configure the SOA-DB database ready for use. The application should be ready for use when the weblogic console is available and can be logged in to at http://ccms-soa-admin.laa-ENVIRONMENT.modernisation-platform.service.justice.gov.uk:7001/console.

## Start a Managed Server

In `application_variables.json`; set `managed_app_count` to `1` and commit. Allow the Github Actions pipeline to run. This will bring up the Admin Server.

Pay attention to the application logs. The boot process usually takes around 5 minutes. The service is stable when the EC2 shows a healthy service **AND** Weblogic shows a healthy server with an **OK** status. To verify in Weblogic, browse to **Environments** > **Servers** and correlate the active servers to the IPs of the currently stable servers in the **MANAGED** EC2 Loadbalancers Target Group.

## Deploy Composites

With the application stable. Deploy the application Composites. Connect to the single running **Managed Server** via the SSM console and execute:

```bash
sudo docker container ls
```

You will be shown a list of running containers, I.E:

```bash
# CONTAINER ID   IMAGE                                                           COMMAND                  CREATED             STATUS                       PORTS     NAMES
# b4cef7645cdf   374269020027.dkr.ecr.eu-west-2.amazonaws.com/soa-managed:latest   "/bin/sh -c /usr/loc…"   17 hours ago   Up 17 hours (healthy)             ecs-ccms-soa-managed-task-1-ccms-soa-managed-98ab9e8089fcbcfcd901
# eccf3782f3ab   amazon/amazon-ecs-pause:0.1.0                                     "/pause"                 17 hours ago   Up 17 hours                       ecs-ccms-soa-managed-task-1-internalecspause-88eb9ac29b91f68bd301
# 35fffa04cf76   amazon/amazon-ecs-agent:latest                                    "/agent"                 20 hours ago   Up 20 hours (healthy)             ecs-agent
```

Connect to the container running the `soa-managed` using it's **CONTAINER ID**:

```bash
sudo docker exec -it --tty b4cef7645cdf /bin/sh
```

Once connected to the container's console, execute the below:

```bash
cd /u01/oracle/user_projects/laa-ccms-app-soa/Scripts/
./prepare_env.sh $env #--dev, stg, tst or prod -- (stg should be used for Mod Platform preproduction. This is embedded in scripts for legacy reasons!!!)
./weblogic.sh update #--If an error is encountered here, there is likely an issue with a specific composite, debug this with a DBA and do not attempt to run the deploy!
./weblogic.sh deploy
```

If this process completes without errors, composites have successfully deployed to Weblogic.

## Scale Up

Once Composites are successfully deployed, in `application_variables.json`; increment `managed_app_count` to the desired number (incrementing by 1, committing and applying) until the desired number has been reached. This should be:

| Environment   | Count |
|---------------|-------|
| Prod          | 6     |
| Preproduction | 2     |
| Test          | 2     |
| Dev           | 2     |

## Create apply_user

This step should be undertaken by a DBA. A user needs to be manually created for the Apply team named **apply_user** and the password communicated to the Apply team through an appropriate channel. There is currently no mechanism to do this programmatically.
