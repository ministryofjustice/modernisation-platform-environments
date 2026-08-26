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
1. Whenever the Postgress database is restored from the old account the postgres and redshift_readonly user passwords need to be reset. Copy the password from the corresponding old to new secret specified below.

| Account | Old Secret | New Secret |
| ------- | ---------- | ---------- |
| postgres | `AuroraPostgres`| `yjafrds01-cluster-db-postgres-password` |
| read-only |`<env>/yjaf/rds` (e.g. `preprod/yjaf/rds`) |`yjafrds01-cluster-db-redshift_readonly-password` |


2. Afrer copying the password as descripbed in step *1* use the `Rotation` function to reset it. While in the Secret select the `Rotation` tab and `Rotate secret immediatly`. Ti will be scheduled to later on the same day.


### Recreate the External Schemas ###
1. Ensure you have the folowing informaition for the destination account:
    - Postgres Read only URI
    - ARN of the AMI Redshift role created for the YJB Team with name `Redshift-Serverless-YJB-Team`.
    - ARN of the Secrret created to hold the redshift read only credentials with name `yjafrds01-cluster-db-redshift_readonly-password`.

2. In the AWS Management Console for the destination account, launch `Redshift query editor v2`. This can be done using the `Query data` link on the `Amazon Redshift Serverless` `Namespace configuration` page.
3. On environments, except production, create a user for the IAM role used by the YJB team by running the following command:
    `CREATE USER "IAMR:redshift-serverless-yjb-reporting-moj_ap" PASSWORD DISABLE`
4. Run script `recreate_external_schemas.sql` to recreate the External Schemas.

**Note:** The above script will remove aout 130 Materialise Views that are dependant on the Externl Schemas (directly or indirectly).

### Recreate Views ###
This is to be done in two tranches reflecting the priority of creation.

First recreate the Views in schemas `stg`, `yjb_asses_plus` and `yjb_case_reporting` by running the following scripts in the order listed:

- `recreate_stg_views_pt1.sql`
- `recreate_stg_views_pt2.sql`
- `recreate_case_reporting_views_pt1.sql`
- `recreate_case_reporting_views_pt2.sql`
- `permissions_case_reporting_views.sql`


When all other Cutover acvities are complete recreate the remaining views for `jjb_ianda_team`, `yjb_asses_plus` and `yjb_ckpi_case_level` by running the following scripts in the order listed:

- `recreate_ianda_team_views_pt1.sql`
- `recreate_ianda_team_views_pt2.sql`
- `recreate_ianda_team_views_pt3.sql`
- `permissions_ianda_team_views.sql`
- `recreate_asset_plus_views.sql`
- `recreate_kpi_case_level_views_pt1.sql`
- `recreate_kpi_case_level_views_pt2.sql`
- `recreate_kpi_case_level_views_pt3.sql`
- `recreate_kpi_case_level_views_pt4.sql`
- `recreate_kpi_case_level_views_pt5.sql`
- `recreate_kpi_case_level_views_pt6.sql`
- `recreate_kpi_case_level_views_pt7.sql`
- `recreate_kpi_case_level_views_pt8.sql`
- `permissions__kpi_case_level_views.sql`
