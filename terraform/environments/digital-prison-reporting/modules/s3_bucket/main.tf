#------------------------------------------------------------------------------
# S3 Bucket for DPR Application IAAC
#------------------------------------------------------------------------------
#tfsec:ignore:AWS002 tfsec:ignore:AWS098
resource "aws_s3_bucket" "storage" { # TBC "application_tf_state" should be generic
  count = var.create_s3 ? 1 : 0

  #checkov:skip=CKV_AWS_18
  #checkov:skip=CKV_AWS_144
  #checkov:skip=CKV2_AWS_6
  #checkov:skip=CKV_AWS_21:”Not all S3 bucket requires versioning enabaled"

  bucket = var.name

  lifecycle {
    prevent_destroy = false
  }

  tags = var.tags
}

resource "aws_s3_bucket_public_access_block" "storage" {

  #checkov:skip=CKV_AWS_300:TODO Will be addressed as part of https://dsdmoj.atlassian.net/browse/DPR2-1083

  bucket = aws_s3_bucket.storage[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Resource to define S3 bucket lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  #checkov:skip=CKV_AWS_300: "Ensure S3 lifecycle configuration sets period for aborting failed uploads"
  # Enable the lifecycle configuration only if the variable `enable_lifecycle` is true
  count  = var.enable_lifecycle ? 1 : 0
  bucket = aws_s3_bucket.storage[0].id

  # Main lifecycle rule for standard categories (short_term, long_term, temporary)
  rule {
    id     = var.name
    status = "Enabled"

    # Short-Term Retention Policy
    # - Transitions objects to STANDARD_IA after 30 days (cost-effective storage for infrequent access).
    # - Deletes objects after 90 days.
    dynamic "transition" {
      for_each = var.lifecycle_category == "short_term" ? [{ days = 30, storage_class = "STANDARD_IA" }] : []
      content {
        days          = transition.value.days
        storage_class = transition.value.storage_class
      }
    }

    dynamic "expiration" {
      for_each = var.lifecycle_category == "short_term" ? [{ days = 90 }] : (
      var.lifecycle_category == "temporary" ? [{ days = 30 }] : [])
      content {
        days = expiration.value.days
      }
    }

    # Long-Term Retention Policy
    # - Transitions objects to progressively cheaper storage classes:
    #   - STANDARD_IA after 60 days.
    #   - GLACIER after 180 days.
    #   - DEEP_ARCHIVE after 365 days.
    # - Does not delete objects (no expiration).
    dynamic "transition" {
      for_each = var.lifecycle_category == "long_term" ? [
        { days = 60, storage_class = "STANDARD_IA" },
        { days = 180, storage_class = "GLACIER" },
        { days = 365, storage_class = "DEEP_ARCHIVE" }
      ] : []
      content {
        days          = transition.value.days
        storage_class = transition.value.storage_class
      }
    }
  }

  # Dynamic rule for custom expiration rules
  # - Allows adding additional lifecycle policies dynamically using the `override_expiration_rules` variable.
  # - Each custom rule is defined with:
  #   - A unique prefix to filter objects (e.g., "reports/", "dpr/").
  #   - An expiration time in days for objects under that prefix.
  # - The `id` for each rule is derived dynamically based on the prefix (slashes `/` are replaced with dashes `-` for compatibility).
  # - Rules are enabled or disabled based on the `enable_lifecycle_expiration` variable.
  dynamic "rule" {
    for_each = var.override_expiration_rules
    content {
      # Generate rule ID without worrying about trailing slashes in the prefix
      id     = "${var.name}-${rule.value.prefix}"
      status = var.enable_lifecycle_expiration ? "Enabled" : "Disabled"

      filter {
        # Append '/' directly in the filter block to ensure proper prefix format
        prefix = "${rule.value.prefix}/"
      }

      expiration {
        days = rule.value.days
      }
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
    bucket_key_enabled = var.bucket_key
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
  count = var.create_s3 && var.cloudtrail_access_policy ? 1 : 0

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


# S3 bucket lambda trigger
resource "aws_s3_bucket_notification" "aws-lambda-trigger" {
  count  = var.create_s3 && var.enable_notification ? 1 : 0
  bucket = aws_s3_bucket.storage[0].id

  dynamic "lambda_function" {
    for_each = var.bucket_notifications != null ? [true] : []
    content {
      lambda_function_arn = lookup(var.bucket_notifications, "lambda_function_arn", null)
      events              = lookup(var.bucket_notifications, "events", null)
      filter_prefix       = lookup(var.bucket_notifications, "filter_prefix", null)
      filter_suffix       = lookup(var.bucket_notifications, "filter_suffix", null)
    }
  }

  depends_on = [var.dependency_lambda]
}