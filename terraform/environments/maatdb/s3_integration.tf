# S3 buckets for MAATDB

# These are build from the local bucket_names and IAM resources whether the variable build_s3 is true.
# These support integration between MAATDB RDS and S3 for use by outbound ftp jobs.

locals {

  ftp_directions = ["inbound", "outbound"]

  expiration_json = local.is-production ? "{}" : jsonencode({
    days                         = 7
    expired_object_delete_marker = false
  })

}

module "s3_bucket" {
  for_each = local.build_s3 ? toset(local.ftp_directions) : toset([])
  source   = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=474f27a3f9bf542a8826c76fb049cc84b5cf136f"

  bucket_prefix       = "${local.application_name}-${local.environment}-ftp-${each.key}"
  versioning_enabled  = false
  force_destroy       = false
  replication_enabled = false
  replication_region  = local.region
  ownership_controls  = "BucketOwnerEnforced"
  custom_kms_key      = local.laa_general_kms_arn

  providers = {
    aws.bucket-replication = aws
  }

  lifecycle_rule = [
    {
      id      = local.is-production ? "main" : "main-nonprod"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = local.is-production ? "false" : "true"
      }

      # Decode to a map. In prod this becomes {}, so the module skips the block.
      expiration = jsondecode(local.expiration_json)

      noncurrent_version_expiration = {
        days = local.is-production ? 31 : 7
      }

      transition = local.is-production ? [
        {
          days          = 90
          storage_class = "STANDARD_IA"
        },
        {
          days          = 180
          storage_class = "GLACIER"
        }
      ] : []
    }
  ]


  tags = merge(local.tags, {
    Name = "${local.application_name}-${local.environment}-ftp-${each.key}"
  })
}

# Bucket policy

resource "aws_s3_bucket_policy" "ftp_user_and_lambda_access" {
  for_each = local.build_s3 ? module.s3_bucket : {}
  bucket   = each.value.bucket.bucket
  policy   = data.aws_iam_policy_document.bucket_policy[each.key].json
}

data "aws_iam_policy_document" "bucket_policy" {
  for_each = local.build_s3 ? module.s3_bucket : {}

  dynamic "statement" {
    for_each = length(aws_iam_role.ftp_lambda_role) > 0 ? [1] : []

    content {
      sid    = "AllowLambdaBucketAccess"
      effect = "Allow"

      principals {
        type        = "AWS"
        identifiers = [aws_iam_role.ftp_lambda_role[0].arn]
      }

      actions = [
        "s3:GetObject",
        "s3:DeleteObject"
      ]

      resources = [
        "${each.value.bucket.arn}/*"
      ]
    }
  }

  dynamic "statement" {
    for_each = length(aws_iam_role.ftp_lambda_role) > 0 ? [1] : []

    content {
      sid    = "AllowLambdaListBucket"
      effect = "Allow"

      principals {
        type        = "AWS"
        identifiers = [aws_iam_role.ftp_lambda_role[0].arn]
      }

      actions = [
        "s3:ListBucket"
      ]

      resources = [
        each.value.bucket.arn
      ]
    }
  }

  dynamic "statement" {
    for_each = length(aws_iam_user.ftp_user) > 0 ? [1] : []

    content {
      sid    = "AllowFTPUserObjectAccess"
      effect = "Allow"

      principals {
        type        = "AWS"
        identifiers = [aws_iam_user.ftp_user[0].arn]
      }

      actions = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:GetObjectVersion",
        "s3:DeleteObjectVersion"
      ]

      resources = [
        "${each.value.bucket.arn}/*"
      ]
    }
  }

  dynamic "statement" {
    for_each = length(aws_iam_user.ftp_user) > 0 ? [1] : []

    content {
      sid    = "AllowFTPUserBucketAccess"
      effect = "Allow"

      principals {
        type        = "AWS"
        identifiers = [aws_iam_user.ftp_user[0].arn]
      }

      actions = [
        "s3:GetBucketPolicy",
        "s3:ListBucket"
      ]

      resources = [
        each.value.bucket.arn
      ]
    }
  }
}



# FTP IAM User

resource "aws_iam_user" "ftp_user" {
  #checkov:skip=CKV_AWS_273:"IAM user required for backwards compatibility with existing solution"
  count = local.build_s3 ? 1 : 0
  name  = "${local.application_name}-ftp-user"
  tags = merge(
    local.tags,
    {
      Name = "${local.application_name}-ftp-user"
    }
  )
}

resource "aws_iam_access_key" "ftp_user_key" {
  count = local.build_s3 ? 1 : 0
  user  = aws_iam_user.ftp_user[0].name
}

# Secrets Manager to capture the access key

resource "aws_secretsmanager_secret" "s3ftp_access_key_secret" {
  #checkov:skip=CKV_AWS_149:"Secret to be manually rotated"
  #checkov:skip=CKV2_AWS_57:"Secret to be manually rotated"
  count = local.build_s3 ? 1 : 0
  name  = "s3ftp-user-access-key"
  tags = merge(
    local.tags,
    {
      Name = "s3ftp-user-access-key"
    }
  )
}

resource "aws_secretsmanager_secret_version" "s3ftp_access_key_secret_version" {
  count     = local.build_s3 ? 1 : 0
  secret_id = aws_secretsmanager_secret.s3ftp_access_key_secret[0].id
  secret_string = jsonencode({
    IAM_ACCESS_KEY_ID     = aws_iam_access_key.ftp_user_key[0].id
    IAM_SECRET_ACCESS_KEY = aws_iam_access_key.ftp_user_key[0].secret
  })
}

# IAM Policy for FTP User (access to all buckets)

resource "aws_iam_user_policy" "ftp_user_policy" {
  #checkov:skip=CKV_AWS_40:"IAM user required for backwards compatibility with existing solution"
  count  = local.build_s3 ? 1 : 0
  name   = "${local.application_name}-FTPUserPolicy"
  user   = aws_iam_user.ftp_user[0].name
  policy = data.aws_iam_policy_document.ftp_user_policy.json
}

data "aws_iam_policy_document" "ftp_user_policy" {
  statement {
    sid    = "S3BucketAccess"
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketPolicy",
      "s3:ListBucket",
      "s3:PutObject"
    ]
    resources = flatten([
      for bucket in values(module.s3_bucket) : [
        bucket.bucket.arn,
        "${bucket.bucket.arn}/*"
      ]
    ])
  }
  statement {
    sid    = "KMSPermissions"
    effect = "Allow"
    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt",
      "kms:Encrypt"
    ]
    resources = [local.laa_general_kms_arn]
  }
}







