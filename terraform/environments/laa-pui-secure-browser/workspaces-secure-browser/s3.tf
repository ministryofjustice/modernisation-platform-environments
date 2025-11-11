### S3 BUCKET FOR WORKSPACES WEB SESSION LOGGING

module "s3_bucket_workspacesweb_session_logs" {
  count = local.create_resources ? 1 : 0

  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket        = "laa-workspacesweb-session-logs-${random_string.bucket_suffix[0].result}"
  force_destroy = true

  # Versioning
  versioning = {
    enabled = true
  }

  # Server side encryption with KMS
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.workspacesweb_session_logs[0].arn
      }
    }
  }

  # Public access block
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # Lifecycle configuration
  lifecycle_rule = [{
    id     = "session_logs_lifecycle"
    status = "Enabled"

    expiration = {
      days = 365
    }

    noncurrent_version_expiration = {
      days = 30
    }
  }]

  # Bucket policy using the IAM policy document
  attach_policy = true
  policy        = data.aws_iam_policy_document.s3_bucket_policy[0].json

  tags = merge(
    local.tags,
    {
      Name = "laa-workspacesweb-session-logs"
    }
  )
}

resource "random_string" "bucket_suffix" {
  count = local.create_resources ? 1 : 0

  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_notification" "s3_bucket_workspacesweb_session_logs" {
  count  = local.create_resources ? 1 : 0
  bucket = module.s3_bucket_workspacesweb_session_logs[0].s3_bucket_id
  queue {
    id            = module.sqs_s3_notifications[0].queue_name
    queue_arn     = module.sqs_s3_notifications[0].queue_arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "workspaces-web-logs/*"
  }
}

data "aws_iam_policy_document" "s3_bucket_policy" {
  count = local.create_resources ? 1 : 0

  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["workspaces-web.amazonaws.com"]
    }
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::laa-workspacesweb-session-logs-${random_string.bucket_suffix[0].result}",
      "arn:aws:s3:::laa-workspacesweb-session-logs-${random_string.bucket_suffix[0].result}/*"
    ]
  }
}
