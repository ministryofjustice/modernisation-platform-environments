# --- Common Assume Role Policy Document ---
data "aws_iam_policy_document" "assume_role" {
  statement {
    sid     = "AllowAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }
  }
}

# --- SFTP Server-Level Access Policy (if needed globally) ---
data "aws_iam_policy_document" "sftp_access" {
  statement {
    sid    = "AllowSftpFromWhitelistedIps"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "transfer:Describe*",
      "transfer:List*",
      "transfer:SendWorkflowStepState"
    ]

    resources = ["${module.aws_s3_landing.bucket.arn}/*"]
  }
}

resource "aws_iam_policy" "sftp_access_policy" {
  name   = "sftp-access-policy"
  policy = data.aws_iam_policy_document.sftp_access.json
}

resource "aws_iam_role" "sftp_role" {
  name               = "sftp-access-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "sftp_role_attachment" {
  role       = aws_iam_role.sftp_role.name
  policy_arn = aws_iam_policy.sftp_access_policy.arn
}

# --- S3 Replication IAM Resources (Production-only) ---
data "aws_iam_policy_document" "staging_replication" {
  count = local.is-production ? 1 : 0

  statement {
    sid    = "SourceBucketPermissions"
    effect = "Allow"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket"
    ]
    resources = [module.aws_s3_staging.bucket.arn]
  }

  statement {
    sid    = "SourceBucketObjectPermissions"
    effect = "Allow"
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
      "s3:ObjectOwnerOverrideToBucketOwner"
    ]
    resources = ["${module.aws_s3_staging.bucket.arn}/*"]
  }

  statement {
    sid    = "SourceBucketKMSKey"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [aws_kms_key.shared_kms_key.arn]
  }

  statement {
    sid    = "DestinationBucketPermissions"
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateTags",
      "s3:ReplicateDelete",
      "s3:ObjectOwnerOverrideToBucketOwner",
      "s3:GetObjectVersionTagging"
    ]
    resources = ["arn:aws:s3:::${local.environment_configuration.property_datahub_staging_egress_target_bucket}/*"]
  }

  statement {
    sid    = "DestinationBucketKMSKey"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:GenerateDataKey"
    ]
    resources = [local.environment_configuration.property_datahub_staging_egress_kms_arn]
  }
}

resource "aws_iam_policy" "staging_replication" {
  count = local.is-production ? 1 : 0

  name   = "property-datahub-staging-replication-policy"
  policy = data.aws_iam_policy_document.staging_replication[0].json
}

resource "aws_iam_role" "staging_replication" {
  count = local.is-production ? 1 : 0

  name               = "property-datahub-staging-replication"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "staging_replication" {
  count = local.is-production ? 1 : 0

  role       = aws_iam_role.staging_replication[0].name
  policy_arn = aws_iam_policy.staging_replication[0].arn
}
