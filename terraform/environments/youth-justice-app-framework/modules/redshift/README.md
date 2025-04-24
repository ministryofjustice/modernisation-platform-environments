# AWS Redshift Terraform module

Terraform module which creates Redshift Serverless resources on AWS.

Version using version.txt file for now, we will move to remote modules and git refs later

## Cutover ##

Cutover involves creating a manual snapshot in the source account, making the snapshot available to the destination account, restoring the snapshot on the destination account, generating a new admin password and saving it in the redshift secret.

### Crete a Manual Snapshot ###
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

### Generate admin Passwordd and store in Secret ###
1. In the AWS Management Console for the destination account, on the `Namespace`, and from the `Actions` menu select `click on the`Total snapshots` link to view the `Snapshots`.
2. Select `Generate a password` and `Show password` then copy the password to the clipboard beofre `Save changes`.
3. In `AWS Secrets Manager`, select secret `yjaf/<env>/resshift-servless/`, `Retrieve secret value`, `Edit`, paste the password into the passowrd field value and `Save`.





