#------------------------------------------------------------------------------
# S3 Bucket for DPR Application IAAC
#------------------------------------------------------------------------------
#tfsec:ignore:AWS002 tfsec:ignore:AWS098
resource "aws_s3_bucket" "storage" { # TBC "application_tf_state" should be generic
  count = var.create_s3 ? 1 : 0

  #checkov:skip=CKV_AWS_18
  #checkov:skip=CKV_AWS_144
  #checkov:skip=CKV2_AWS_6
  bucket = var.name

  lifecycle {
    prevent_destroy = false
  }

  tags = var.tags
}

resource "aws_s3_bucket_public_access_block" "storage" {
  bucket = aws_s3_bucket.storage[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  count  = var.enable_lifecycle ? 1 : 0
  bucket = aws_s3_bucket.storage[0].id
  rule {
    id     = var.name
    status = "Enabled"

    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 365
      storage_class   = "GLACIER"
    }

    transition {
      days          = 60
      storage_class = "STANDARD_IA"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.storage[0].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.custom_kms_key
    }
  }
}

resource "aws_sqs_queue_policy" "allow_sqs_access" {
  count = var.create_notification_queue ? 1 : 0

  queue_url = aws_sqs_queue.notification_queue[0].id
  policy    = data.aws_iam_policy_document.allow_sqs_access[0].json
}

data "aws_iam_policy_document" "allow_sqs_access" {
  count = var.create_notification_queue ? 1 : 0
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = ["SQS:SendMessage"]

    resources = [aws_sqs_queue.notification_queue[0].arn]
  }
}

resource "aws_sqs_queue" "notification_queue" {
  count = var.create_notification_queue ? 1 : 0

  name                      = var.s3_notification_name
  message_retention_seconds = var.sqs_msg_retention_seconds
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  count  = var.create_notification_queue ? 1 : 0
  bucket = aws_s3_bucket.storage[0].id

  queue {
    queue_arn     = aws_sqs_queue.notification_queue[0].arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = var.filter_prefix
  }
}

resource "aws_s3_bucket_versioning" "version" {
  count = var.enable_s3_versioning ? 1 : 0

  bucket = aws_s3_bucket.storage[0].id
  versioning_configuration {
    status = var.enable_versioning_config
  }
}

resource "aws_s3_bucket_policy" "cloud_trail" {
  count  = var.create_s3 && var.cloudtrail_access_policy ? 1 : 0

  bucket = aws_s3_bucket.storage[0].id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "cloud-trail-policy",
  "Statement": [
    {
      "Sid": "Access",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "s3:*",
      "Resource" : [
        "${aws_s3_bucket.storage[0].arn}/*",
        "${aws_s3_bucket.storage[0].arn}"              
      ]
    }
  ]
}
POLICY

 depends_on = [aws_s3_bucket.storage]
}