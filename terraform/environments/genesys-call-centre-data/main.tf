module "s3_bucket_staging" {
  # source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v8.2.0"
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=11707a540d9ced11f8df4a8ed1547753dd3a0b7d"

  bucket_prefix      = "call-centre-staging"
  versioning_enabled = true

  # to disable ACLs in preference of BucketOwnership controls as per https://aws.amazon.com/blogs/aws/heads-up-amazon-s3-security-changes-are-coming-in-april-of-2023/ set:
  ownership_controls = "BucketOwnerEnforced"
  acl                = "private"

  # Refer to the below section "Replication" before enabling replication
  replication_enabled = false
  # Below variable and providers configuration is only relevant if 'replication_enabled' is set to true
  # replication_region                       = "eu-west-2"
  providers = {
    # Here we use the default provider Region for replication. Destination buckets can be within the same Region as the
    # source bucket. On the other hand, if you need to enable cross-region replication, please contact the Modernisation
    # Platform team to add a new provider for the additional Region.
    # Leave this provider block in even if you are not using replication
    aws.bucket-replication = aws
  }

  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
          }, {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      expiration = {
        days = 730
      }

      noncurrent_version_transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
          }, {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = 730
      }
    }
  ]

  tags = local.tags
}

resource "aws_guardduty_detector" "default" {
  enable     = var.aws_guardduty_detector_enable
  depends_on = [module.s3_bucket_staging]
}

resource "aws_guardduty_organization_configuration" "default" {
  # auto_enable = true
  auto_enable_organization_members = "ALL"
  detector_id                      = aws_guardduty_detector.default.id
}

resource "aws_guardduty_organization_admin_account" "default" {
  admin_account_id = var.aws_guardduty_organization_admin_account_id_string
  depends_on       = [aws_guardduty_detector.default]
}

resource "aws_guardduty_member" "default" {
  for_each                   = toset(var.aws_guardduty_organization_admin_account_id_list)
  account_id                 = each.key
  detector_id                = aws_guardduty_detector.default.id
  email                      = var.aws_guardduty_member_email
  invite                     = var.aws_guardduty_member_invite
  disable_email_notification = var.aws_guardduty_member_disable_email_notification
}

resource "aws_guardduty_publishing_destination" "default" {
  detector_id     = aws_guardduty_detector.default.id
  destination_arn = aws_s3_bucket.default.arn
  kms_key_arn     = aws_kms_key.s3.arn
  depends_on = [
    module.s3_bucket_staging,
    aws_s3_bucket_policy.default
  ]
}

resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  #checkov:skip=CKV2_AWS_67: "Ensure AWS S3 bucket encrypted with Customer Managed Key (CMK) has regular rotation"
  bucket = module.s3_bucket_staging.bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.sse_algorithm
      kms_master_key_id = (var.custom_kms_key != "") ? var.custom_kms_key : ""
    }
  }
}

resource "aws_s3_bucket_public_access_block" "default" {
  bucket                  = module.s3_bucket_staging.bucket.id
  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}

data "aws_iam_policy_document" "s3-assume-role-policy" {
  version = var.json_encode_decode_version
  statement {
    effect  = var.moj_aws_iam_policy_document_statement_effect
    actions = var.moj_aws_iam_policy_document_statement_actions

    principals {
      type        = var.moj_aws_iam_policy_document_principals_type
      identifiers = var.moj_aws_iam_policy_document_principals_identifiers
    }
  }
}

resource "aws_s3_bucket_policy" "default" {
  bucket = module.s3_bucket_staging.bucket.id
  policy = jsonencode({
    Version = var.json_encode_decode_version,
    Statement = [
      {
        Sid    = var.moj_aws_s3_bucket_policy_statement_sid,
        Effect = var.moj_aws_s3_bucket_policy_statement_effect,
        Principal = {
          Service : var.moj_aws_s3_bucket_policy_statement_principal_service
        },
        Action   = var.moj_aws_s3_bucket_policy_statement_action,
        Resource = "arn:aws:s3:::${aws_s3_bucket.default.id}/*"
      },
      {
        Sid    = var.bt_genesys_aws_s3_bucket_policy_statement_sid,
        Effect = var.bt_genesys_aws_s3_bucket_policy_statement_effect,
        Principal = {
          AWS = var.bt_genesys_aws_s3_bucket_policy_statement_principal_aws
        },
        Action   = var.bt_genesys_aws_s3_bucket_policy_statement_action,
        Resource = "arn:aws:s3:::${aws_s3_bucket.default.id}/*"
      }
    ]
  })
}