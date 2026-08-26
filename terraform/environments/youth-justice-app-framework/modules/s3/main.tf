resource "aws_s3_bucket" "default" {
  #checkov:skip=CKV_AWS_145
  #checkov:skip=CKV_AWS_144
  #checkov:skip=CKV2_AWS_61:  "lift and shift" todo fix later
  #checkov:skip=CKV2_AWS_62:  "lift and shift"
  for_each = toset(local.bucket_name_all)
  bucket   = each.value
  tags     = local.all_tags
}

resource "aws_s3_bucket_ownership_controls" "default" {
  for_each = toset(local.bucket_name_all)
  bucket   = aws_s3_bucket.default[each.value].id
  rule {
    object_ownership = var.ownership_controls
  }
}

resource "aws_s3_bucket_acl" "default" {
  for_each = toset(local.bucket_name_all)
  bucket   = aws_s3_bucket.default[each.value].id
  acl      = var.acl
  depends_on = [
    aws_s3_bucket_ownership_controls.default
  ]
}

resource "aws_s3_bucket_public_access_block" "default" {
  for_each                = toset(local.bucket_name_all)
  bucket                  = aws_s3_bucket.default[each.value].bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "default" {
  for_each = toset(local.bucket_name_all)
  bucket   = aws_s3_bucket.default[each.value].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "default" {
  for_each = var.log_bucket != null ? toset(local.bucket_name_all) : []
  bucket   = aws_s3_bucket.default[each.value].id

  target_bucket = var.log_bucket
  target_prefix = aws_s3_bucket.default[each.value].bucket
}


resource "aws_s3_bucket_policy" "logging" {
  for_each = var.add_log_policy == true ? toset(local.bucket_name_all) : []
  bucket   = aws_s3_bucket.default[each.value].id


  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "PolicyForS3AccessLoggingBucket",
  "Statement": [
		{
			"Sid": "Permissions to receive s3 access logs",
			"Effect": "Allow",
			"Principal": { "Service": "logging.s3.amazonaws.com"},
			"Action": "s3:PutObject",
			"Resource": "arn:aws:s3:::${each.value}/*"
		}
	]
}
  POLICY

}

resource "aws_s3_bucket_policy" "default" {
  for_each = var.allow_replication == true ? toset(local.bucket_name_allow_replication) : []
  bucket   = aws_s3_bucket.default[each.value].id


  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "PolicyForDestinationBucket",
  "Statement": [
		{
			"Sid": "Permissions to check replication result",
			"Effect": "Allow",
			"Principal": { "AWS": "arn:aws:iam::${var.s3_source_account}:role/admin"},
			"Action": [
				"s3:List*"
			],
			"Resource": [
				"arn:aws:s3:::${each.value}",
				"arn:aws:s3:::${each.value}/*"
			]
		},
		{
			"Sid": "Permissions on objects and buckets",
			"Effect": "Allow",
			"Principal": { "AWS": "arn:aws:iam::${var.s3_source_account}:role/cross-account-bucket-replication-role"},
			"Action": [
				"s3:List*",
				"s3:GetBucketVersioning",
				"s3:PutBucketVersioning",
				"s3:ReplicateDelete",
				"s3:ReplicateObject"
			],
			"Resource": [
				"arn:aws:s3:::${each.value}",
				"arn:aws:s3:::${each.value}/*"
			]
		},
		{
			"Sid": "Permission to override bucket owner",
			"Effect": "Allow",
			"Principal": {
				"AWS": "arn:aws:iam::${var.s3_source_account}:role/cross-account-bucket-replication-role"
			},
			"Action": "s3:ObjectOwnerOverrideToBucketOwner",
			"Resource": "arn:aws:s3:::${each.value}/*"
		}
	]
}

  POLICY

}
#trivy:ignore:AVD-AWS-0132 todo fix later
resource "aws_s3_bucket_server_side_encryption_configuration" "bucket" {
  #checkov:skip=CKV_AWS_145
  for_each = toset(local.bucket_name_all)
  bucket   = aws_s3_bucket.default[each.value].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
  # TODO Set prevent_destroy to true to stop Terraform destroying this resource in the future if required
  lifecycle {
    prevent_destroy = false
  }
}
