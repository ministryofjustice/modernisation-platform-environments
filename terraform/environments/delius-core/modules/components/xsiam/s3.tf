### XSIAM FIREHOSE ###
module "xsiam_s3_bucket" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=76321e50b20f5c0d918cd45bdcf0b62049f5baf1" # v10.1.0

  providers = {
    aws.bucket-replication = aws.bucket-replication
  }

  sse_algorithm       = "AES256"
  bucket_prefix       = "${var.env_name}-xsiam-firehose-backup"
  replication_enabled = false
  versioning_enabled  = var.s3_versioning
  force_destroy       = var.force_destroy_bucket
  lifecycle_rule      = var.access_logs_lifecycle_rule

  bucket_policy_v2 = [{
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:AbortMultipartUpload",
      "s3:GetObject",
      "s3:PutObject",
    ]
    principals = {
      type        = "AWS"
      identifiers = [aws_iam_role.firehose_xsiam.arn]
    }
  }]
  tags = { backup = false }
}