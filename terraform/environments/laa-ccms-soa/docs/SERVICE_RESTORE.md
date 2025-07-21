# CCMS-SOA Service Restoration

This document should serve as a detailed technical breakdown as to how to bring CCMS SOA (Service Oriented Architecture) online from a cold start. In all likelihood this will only ever need to be done in the event that:

1. A new environment needs to be created.
2. Some catastrophic event has led to the destruction of a previous deployment and a Disaster Recovery is taking place.

Whilst application backups would make a restoration easier, they are not essential. The data that passes through SOA is transient and SOA can be brought online with no backups.

## Pre-Requisite Dependencies (Before Building)

### Image Repository

An Image Repository will need to exist in advance to house the application images that will be pulled for SOA before any services can be expected to start.

In the current configuration, these already exist within MP, but in the event that a platform other than MP is ever used, repositories will need to be created and the images uploaded in advance.

Existing configurations are located [here](https://github.com/ministryofjustice/modernisation-platform/blob/main/terraform/environments/core-shared-services/ecr_repos.tf).

At present, the location of the existing images is:

- `374269020027.dkr.ecr.eu-west-2.amazonaws.com/soa-admin:<version>`
- `374269020027.dkr.ecr.eu-west-2.amazonaws.com/soa-managed:<version>`

In MP, permission is granted to pull these images by the ECR Control Plane, meaning that the ECS nodes have permissions to pull images from ECR.

### CCMS-EDRMS-TDS Database

Each environment requires access to TDS database, managed by CCMS-EDRMS (Electronic Documents and Record Management System). This database is essential for the SOA system to inject documents that are ultimately transmitted to NEC (Northgate).

In order for SOA to boot directly, this database must be available before attempting boot, and must be network accessible via both TCP and DNS from the SOA application.

### CCMS-EBS S3 Buckets

SOA depends on two external S3 buckets which are used for FTP integrations by a number of other CCMS applications and scheduled batch processes. At time of writing, these buckets are part of the [CCMS-EBS Infrastructure](https://github.com/ministryofjustice/modernisation-platform-environments/tree/main/terraform/environments/ccms-ebs). Whilst the buckets must exist at the time of the initial infrastructure creation, some configuration is needed within EBS before the application will work correctly (which is discussed later in this document).

A bucket must be created in the CCMS-EBS environments for both inbound and outbound processing, with the corresponding subdirectories. Whilst these S3 directory structure is not the responsibility of SOA, some additional checks are in place to ensure that they create if EBS has failed to ensure that they have created correctly.

## Infrastructure Deployment

### Apply Terraform and Populate Secrets

Complete the `application_variables.json` file as appropriate for the environment being deployed to, ensuring in particular that:

- The  `admin_app_count` and `managed_app_count` values are set to `0` (this will prevent any ECS services from booting).
- The `inbound_s3_bucket_name` and `outbound_s3_bucket_name` values are set as appropriate for the environment being configured (see the corresponding **EBS** environment to confirm).
- The `tds_db_endpoint` value is set as appropriate for the environment being configured (see the corresponding **EDRMS** environment to confirm).
- `managed_ami_image_id` and `admin_ami_image_id` values are set to `ami-0d6d764bbe794b8ca` which is the ECS optimised Amazon Linux. If this AMI is deprecated at the time of using this document, an equivalent ECS optimmised Amazon Linux should be used.

If unsure on suitable variables for a cold start, see the file `templates/_application_variables_starter.json`.

Once verified, commit.

In the **modernisation-platform-environemnts** Github Actions pipeline; Terraform will Plan and Apply for the relevant environments. When applying for the first time the apply will fail part way through due to missing Secret Values, this is to be expected. The Secrets themselves however will be created.

Log in to the AWS console for the relevant environment and populate the Secrets with appropriate Values, these are to be agreed with the relevant application teams that will be integrating with SOA as secrets need to be common between integrating services.

### Apply Terraform

With the secrets populated, commit again (once again ensuring that `admin_app_count` and `managed_app_count` are still set to `0`). In the Github Actions Pipeline, run Terraform Plan and Apply to bring up the remaining infrastructure.

### Configure External S3 Dependency

**NOTE**: This task needs to be undertaken in the [CCMS-EBS Infrastructure](https://github.com/ministryofjustice/modernisation-platform-environments/tree/main/terraform/environments/ccms-ebs) configurations, and not as part of the SOA configuration.

SOA's IAM configurations will now be created and ready for integration with EBS. The EBS S3 Buckets which are used for FTP integration need to have their policies configured in order to allow the appropriate SOA IAM roles to mount them. This cannot be done in advance as such a change cannot be done until the roles exist.

From SOA's perspective, these buckets are mounted to all **managed** servers at the EC2 level and implicitly exposed to running SOA containers as below:

| Bucket                           | EC2 Mount Point          | IAM Role                   |
|----------------------------------|--------------------------|----------------------------|
| laa-ccms-inbound-ENVIRONMENT-mp  | /home/ec2-user/Inbound   | ccms-soa-ec2-instance-role |
| laa-ccms-outbound-ENVIRONMENT-mp | /home/ec2-user/Outbound  | ccms-soa-ec2-instance-role |

Mounting is handled by the SOA EC2 boot script which is baked in the to the EC2 Autoscaling Group Launch Template. If these Buckets are not present, boot of the EC2 instances will succeed and containers will still start, but the boot script will fail to complete properly, leading to issues deploying some Composites later in the deployment process. To this end it is better to ensure that the Buckets are in place before attempting a deployment.

The IAM Role shown above must be given the following permissions on **BOTH** EBS S3 buckets:

```json
...
    "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:DeleteObject"
    ],
    "Resource": [
        "arn:aws:s3:::laa-ccms-inbound-ENVIRONMENT-mp",
        "arn:aws:s3:::laa-ccms-inbound-ENVIRONMENT-mp/*"
    ]
...
```

```json
...
    "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:DeleteObject"
    ],
    "Resource": [
        "arn:aws:s3:::laa-ccms-outbound-ENVIRONMENT-mp",
        "arn:aws:s3:::laa-ccms-outbound-ENVIRONMENT-mp/*"
    ]
...
```

Once the IAM/S3 integration is completed. Log in to the AWS console and **TERMINATE** any **managed** EC2 Instances. The Auto Scaling Group will start new instances which should mount the newly integrated S3 Buckets during boot.

### Configure the SOA Database

**NOTE**: These steps should be undertaken by a DBA.

**PRIOR TO THE BOOT OF SOA, ONLY THIS SQL STATEMENT SHOULD BE RUN. DOING ANYTHING ELSE WILL CORRUPT THE DATABASE**

When the Admin Server boots for the first time, the Oracle [RCU](https://docs.oracle.com/cd/E21764_01/doc.1111/e14259/overview.htm) will initiate the SOA-DB and create various components. If any of the components managed by the RCU are created manually, the application will find itself in a crash loop.

```bash
#--This fix is needed to allow RCU to execute. See https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Oracle.Resources.RCU.html for a technical breakdown.
EXECUTE rdsadmin.rdsadmin_util.grant_sys_object( p_obj_name => 'DBA_TABLESPACE_USAGE_METRICS', p_grantee => 'SOAPDB', p_privilege => 'SELECT', p_grant_option => true);
```

### Start the Admin Server

In `application_variables.json`; set `admin_app_count` to `1` and commit. Allow the Github Actions pipeline to run. This will bring up the Admin Server.

Pay attention to the application logs. The boot process can take up to 30 minutes, as part of the boot process the Oracle [RCU](https://docs.oracle.com/cd/E21764_01/doc.1111/e14259/overview.htm) will run and configure the SOA-DB database ready for use. The application should be ready for use when the weblogic console is available and can be logged in to at <https://ccms-soa-admin.laa-ENVIRONMENT.modernisation-platform.service.justice.gov.uk/console>.

### Start a Managed Server

In `application_variables.json`; set `managed_app_count` to `1` and commit. Allow the Github Actions pipeline to run. This will bring up the Admin Server.

Pay attention to the application logs. The boot process usually takes around 5 minutes. The service is stable when the EC2 shows a healthy service **AND** Weblogic shows a healthy server with an **OK** status. To verify in Weblogic, browse to **Environments** > **Servers** and correlate the active servers to the IPs of the currently stable servers in the **MANAGED** EC2 Loadbalancers Target Group.

## Configure and Deploy Composites

### Configure Composite Deployment File

Within the AWS console, browse to SSM and start a session on a **managed server** and browse to the EFS mount:

```bash
sudo su ec2-user
cd ~/efs/laa-ccms-app-soa/Scripts
```

Edit the script `build.properties.generator.sh` and update the inputs as indicated for all endpoints, ports and secret paths as relevant, these inputs are clearly named and are used to create connections to the backing databases, other SOA servers and external API services that SOA integrates with.

Executing this script will generate a configuration file used for deploying composites to SOA.

Execute the script with the name of your environment as an input parameter. For example for dev:

`./build.properties.generator.sh --env dev`.

Suitable inputs (for legacy reasons) to the `--env` argument are:

- dev
- tst
- stg
- prod

### Deploy Composites

From a **managed server**:

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

Connect to a `soa-managed` container using it's **CONTAINER ID**:

```bash
sudo docker exec -it --tty b4cef7645cdf /bin/sh
```

Once connected to the container's console, execute the below:

```bash
cd /u01/oracle/user_projects/laa-ccms-app-soa/Scripts
./prepare_env.sh $env #--dev, stg, tst or prod -- (stg should be used for Mod Platform preproduction. This is embedded in scripts for legacy reasons!!!)
./weblogic.sh update #--If an error is encountered here, there is likely an issue with a specific composite, debug this with a DBA and do not attempt to run the deploy until it is debugged!
./weblogic.sh deploy
```

If this process completes without errors, composites have successfully deployed to Weblogic.

## Post-Deployment Steps

### Managed Server Scale-Up

Once Composites are successfully deployed, in `application_variables.json`; increment `managed_app_count` to the desired number. Commit and allow the Github Actions pipeline to run.

The number of managed servers per environment is:

| Environment   | Count |
|---------------|-------|
| Prod          | 6     |
| Preproduction | 2     |
| Test          | 2     |
| Dev           | 2     |

### Create apply_user

**NOTE**: This step should be undertaken by a DBA.

A user needs to be manually created for the Apply team named **apply_user** and the password communicated to the Apply team through an appropriate channel. There is currently no mechanism to do this programmatically.
