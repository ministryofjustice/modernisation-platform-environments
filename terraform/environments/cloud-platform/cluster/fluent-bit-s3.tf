## Shared log-archive S3 bucket.
##
## Built here (#8430) but shared: Fluent Bit (#8419) writes application logs
## under logs/, and the Auto Mode vended-logs deliveries below write under
## auto-mode/. One bucket, one policy, so we touch the policy once.
##
## TODO(#8419): confirm final bucket name with Dave. Convention discussed with Tom
## is container-platform-{business-unit}-{environment}-fluentbit. This component
## only knows terraform.workspace (cluster_name), not a separate BU/env split, so
## the name below is a placeholder derived from the workspace environment. Tom has
## confirmed the -fluentbit suffix is fine.
locals {
  log_archive_bucket_name = "container-platform-${local.workspace_environment}-fluentbit"
}

resource "aws_s3_bucket" "log_archive" {
  bucket = local.log_archive_bucket_name

  tags = merge(local.tags, { Name = local.log_archive_bucket_name })
}

resource "aws_s3_bucket_public_access_block" "log_archive" {
  bucket = aws_s3_bucket.log_archive.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "log_archive" {
  bucket = aws_s3_bucket.log_archive.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "log_archive" {
  bucket = aws_s3_bucket.log_archive.id

  versioning_configuration {
    status = "Enabled"
  }
}

## TODO: SSE-S3 for the PoC. If we move to SSE-KMS, the key policy must also allow
## delivery.logs.amazonaws.com (kms:GenerateDataKey / kms:Decrypt) or vended-logs
## delivery to S3 fails.
resource "aws_s3_bucket_server_side_encryption_configuration" "log_archive" {
  bucket = aws_s3_bucket.log_archive.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "log_archive" {
  bucket = aws_s3_bucket.log_archive.id

  rule {
    id     = "archive-then-expire"
    status = "Enabled"

    filter {}

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    ## TODO: confirm retention with the team. 365 days is a placeholder.
    expiration {
      days = 365
    }
  }
}

## Bucket policy — two writers from the start (agreed with Tom), so #8419 needs no
## rework:
##   - Auto Mode vended logs: delivery.logs.amazonaws.com writes under auto-mode/.
##   - Fluent Bit: writes under logs/ via its Pod Identity role (added by #8419).
data "aws_iam_policy_document" "log_archive" {
  ## Vended-logs delivery service. The /aws/vendedlogs/ auto-grant is CloudWatch
  ## only — S3 needs this stated explicitly (per AWS docs, AWS-logs-infrastructure-V2-S3).
  ##
  ## NOTE: the object key is AWSLogs/<account>/.../auto-mode/<type>/... — AWS
  ## prepends its own AWSLogs/ prefix ahead of our suffix_path, so PutObject cannot
  ## be scoped to auto-mode/* alone. Scoped to AWSLogs/<account>/* to stay tighter
  ## than the whole bucket while covering everything the delivery service writes.
  statement {
    sid    = "AllowVendedLogsDeliveryWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.log_archive.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    ## Per AWS docs the SourceArn form for the bucket policy is
    ## arn:aws:logs:<region>:<account>:*
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid    = "AllowVendedLogsDeliveryAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl", "s3:ListBucket"]
    resources = [aws_s3_bucket.log_archive.arn]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  ## TODO(#8419): add the Fluent Bit writer statement here (its Pod Identity role
  ## -> s3:PutObject on ${bucket}/logs/*) when the Fluent Bit work lands, so both
  ## writers share this one policy.
}

resource "aws_s3_bucket_policy" "log_archive" {
  bucket = aws_s3_bucket.log_archive.id
  policy = data.aws_iam_policy_document.log_archive.json
}
