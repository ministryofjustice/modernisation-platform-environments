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

# Create a resource share to allow sharing of the SSM parameter containing the bucket name
resource "aws_ram_resource_share" "ssm_parameter_share_for_dms_bucket_name" {
  name = "ssm-parameter-share-for-dms-bucket-name"
}

# Associate the SSM Parameter with this resource share
resource "aws_ram_resource_association" "ssm_parameter_share_for_dms_bucket_name" {
  resource_share_arn = aws_ram_resource_share.ssm_parameter_share_for_dms_bucket_name.arn
  resource_arn       = aws_ssm_parameter.s3_bucket_dms_destination_name.arn
}

# We need to share the parameter with any remote clients associated with this account
# and any remote repository associated with this account
resource "aws_ram_principal_association" "ssm_parameter_share_for_dms_bucket_name" {
  for_each           = toset(concat(var.dms_config.client_account_arns,local.dms_repository_account_id))
  resource_share_arn = aws_ram_resource_share.ssm_parameter_share_for_dms_bucket_name.arn
  principal          = each.value
}

