# When S3 buckets are created for S3 they have a known prefix but known date-dependent suffix.
# Therefore to get the exact name of the S3 bucket in the account used for the audit respository
# we need to use the AWS CLI to get a list of all the buckets there and get the first one
# where the name prefix matche what we expect.
data "external" "bucket_matching_prefix" {
  program = ["bash","${path.module}/get_repository_bucket.sh",local.dms_s3_repository_bucket.prefix,local.dms_s3_repository_bucket.account_id]
}


output "bucket_matching_prefix" {
  value = data.external.bucket_matching_prefix.result
}

resource "aws_dms_endpoint" "dms_audit_target_endpoint_s3" {
  endpoint_id   = "dms-audit-target-endpoint-s3"
  endpoint_type = "target"
  engine_name   = "s3"

  s3_settings {
    bucket_name             = data.external.bucket_matching_prefix.result.bucket_name
    service_access_role_arn = aws_iam_role.dms-vpc-role.arn
    data_format             = "csv"
  }
}