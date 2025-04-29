# AWS Redshift Terraform module

Terraform module which creates Redshift Serverless resources on AWS.

Version using version.txt file for now, we will move to remote modules and git refs later

## Cutover ##

Cutover involves creating a manual snapshot in the source account, making the snapshot available to the destination account, restoring the snapshot on the destination account, generating a new admin password and saving it in the redshift secret.

### Create a Manual Snapshot ###
1. In the AWS Management Console for the source account, on the `Servless dashboard`, click on the `Total snapshots` link to view the `Snapshots`.
2. Select `Create snapshot`.
3. Enter details for the snapshot:
    - Select the namaspace (there will only be one).
    - Enter a identifier (e.g. 'replaformming')
    - Select a retention period.
    - Click `Create`.
4. Wait to the snapshort creation activity to be completed.

### Share the Cluster Snapshot ###
 In the AWS Management Console for the source account, on the `Servless dashboard`, click on the `Total snapshots` link to view the `Snapshots`.
2. Select Snapshot to be shared and from the `Actions` menu select `Manage access`.
3. Under `Provide access to servless accounts`, select `Add AWS account`, enter the destination account number and `Save changes`.
4. There is likle to be a delay before it becomes available in the other account.

As, currently, the default AWS key is used for encryption, permissions are not needed to enable the destination account decrypt the snapshot.

### Restore the Cluster from the Snapshot ###
1. In the AWS Management Console for the destination account, on the `Servless dashboard`, click on the `Total snapshots` link to view the `Snapshots`.
2. Select the shared snapshot and from the `Actions` menu select `Restore to servless namespace`.
3. Select the namaspace (there should only be one), leave `Manage admin credentials in AWS Secrets Manager` unchecked and `Restore`.
4. Confirm that you want to replace all databases in your namespace.
4. Wait to the snapshort restore to complete.

### Copy account passwords from old to new secrets ###
1. In the AWS Management Console for the destination account, on the `Namespace`, and from the `Actions` menu select `click on the`Total snapshots` link to view the `Snapshots`.
2. Select `Generate a password` and `Show password` then copy the password to the clipboard beofre `Save changes`.
3. In `AWS Secrets Manager`, select secret `yjaf/<env>/resshift-servless/`, `Retrieve secret value`, `Edit`, paste the password into the passowrd field value and `Save`.

### Recreate the External Schemas ###
1. Ensure you have the folowing informaition for the destination account:
    - Postgres Read only URI
    - ARN of the AMI Redshift role created for the YJB Team with name `Redshift-Serverless-YJB-Team`.
    - ARN of the Secrret created to hold the redshift read only crednetials with name `yjafrds01-cluster-db-redshift_readonly-password`.

2. In the AWS Management Console for the destination account, launch `Redshift query editor v2`. This can be done using the `Quryy data` link on the `Amazon Redshift Serverless` `Namespace configuration` page.
3. On environments, except production, create a user for the IAM role used by the YJB team but running the following command:
    `CREATE USER "IAMR:redshift-serverless-yjb-reporting-moj_ap" PASSWORD DISABLE`
4. Generate Definitions for materalised views that refernt external schema `yjb_case_reporting_stg` using the command below and save them to file `<env>_mv_before.sql`.
    `select view_definition from information_schema.views where view_definition like '%yjb_case_reporting_stg%' order by table_name`
5. Run script `recreate_external_schemas.sql` to recreate the External Schemas.
6. They above script will fail to remove and recreate `yjb_case_reporting_stg` due to the materalised views. First check that script `recreate_views.sql` contna definition to all the affected materalised views. The drop `yjb_case_reporting_stg` manula and rerun that section of the script to recreate it.





