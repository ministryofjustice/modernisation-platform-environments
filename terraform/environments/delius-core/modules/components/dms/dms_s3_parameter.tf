# Since the DMS S3 bucket is generated with an arbitrary suffix, we need to store the name
# in a well known location so that other accounts may find it.   Therefore we create an
# SSM Parameter to store the bucket name.   It needs to be an Advanced Parameter so it
# may be shared with the other accounts involved in the replication.
resource "aws_ssm_parameter" "s3_bucket_dms_destination_name" {
  name        = "s3-bucket-dms-destination-name"
  description = "This parameter stores the location of the S3 Bucket for staging of DMS Replication data"
  type        = "SecureString"
  value       = module.s3_bucket_dms_destination.bucket.bucket
  tier        = "Advanced"
}
