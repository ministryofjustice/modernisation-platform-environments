# S3 Terraform module

Terraform module which creates s3 buckets on AWS.

Version using version.txt file for now, we will move to remote modules and git refs later

# Inputs

- **bucket_name**: (list(string)) Names of s3 buckets that are not to be replicated from the old environments.
- **transfer_bucket_name**: (Optional) (list(string)) Names of S3 buckets that are to be transferred as is from the old environments.
- **archive_bucket_name**: (Optional) (list(string)) Names of S3 buckets that are to repliccated to an archive bucket.
- **project_name**: (string) Project name
- **environment_name**: (string) Environment name
- **tags**: (Optional) (map(any)) Tags to apply to resources, where applicable.
- **ownership_controls**: (string) Bucket Ownership Controls - for use WITH acl var above options are 'BucketOwnerPreferred' or 'ObjectWriter'. To disable ACLs and use new AWS recommended controls set this to 'BucketOwnerEnforced' and which will disabled ACLs and ignore var.acl. Default: "ObjectWriter".
- **acl**: (string) Use canned ACL on the bucket instead of BucketOwnerEnforced ownership controls. var.ownership_controls must be set to corresponding value below. Default: private.
- **log_bucket**: (string) Bucket to send logs to. It must already exist.
- **allow_replication**: (bool) Used to indicate that policy should be assigned to enable replication from the equivelent old account. Default: false
- **s3_source_account**: (Optional) (string) Source account from whch s3 buckets may be replicated."

# Outputs

None

# Bucket Replication

## Replication Scripts

A set of scripts have been written to facilitate setup of Replication from the old to new environments as follows:

- **`replication-configuration.json.template`**: Defines the required replication configuraiton. Has place holders for the destination account number and bucket name.
- **`manifest-generator.json.template`**: Defins the maifest to be used for a job to copy the current contens of each bucket. Has place holders for the source account number and bucket name.
- **`replication.sh`**: Must be called with 4 parameters: source bucket name, source account number , destination bucket name and destination account number. It will instantiate the above templates, enable versinong on the source bucket, create a replication rule on the source bucket and create a job to copy the buckets current contents.
- **`replicate-all-<env>.sh`**: A version of this file exists for each version that has been rprpolulated with parameters for each bucket to be replicated.

Before running `replicate-all-<env>.sh` short term credentials must first be generated for the source account and used to populate the standard aws cli envirnment variables.

## Manuall Action after running the Scripts

Bucket `preprod preprod-redshift-serverless-yjb-reporting` did not replicate automatically after running the above scripts. It was necessary to Edit the Replication rule and select `Replicate objects encrypted with AWS Key Management Service (AWS KMS)` with Key `aws\s3`. After which a new Replicaation batch job was successfuly in replicaing all objects in the bucket.

It is assumed that this will also be necessary when replicating production buckets.
