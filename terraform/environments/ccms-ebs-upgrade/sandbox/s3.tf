# S3 Bucket - Artefacts
module "s3-bucket" { #tfsec:ignore:aws-s3-enable-versioning
  # v8.2.0 = https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket/commit/52a40b0dd18aaef0d7c5565d93cc8997aad79636
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=52a40b0dd18aaef0d7c5565d93cc8997aad79636"

  bucket_name        = local.artefact_bucket_name
  versioning_enabled = false
  bucket_policy = [jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        "Sid" : "DenyInsecureTransport",
        "Effect" : "Deny",
        "Principal" : "*",
        "Action" : "s3:*",
        "Resource" : [
          module.s3-bucket.bucket.arn,
          "${module.s3-bucket.bucket.arn}/*"
        ],
        "Condition" : {
          "Bool" : {
            "aws:SecureTransport" : "false"
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/developer",
            "arn:aws:iam::${local.environment_management.account_ids["core-shared-services-production"]}:root"
          ]
        }
        Action   = "s3:GetObject"
        Resource = "arn:aws:s3:::${local.artefact_bucket_name}/*"
      },
      {
        "Sid" = "RestrictToTLSRequestsOnly",
        "Action" : "s3:*",
        "Effect" : "Deny",
        "Resource" : [
          module.s3-bucket.bucket.arn,
          "${module.s3-bucket.bucket.arn}/*"
        ],
        "Condition" : {
          "Bool" : {
            "aws:SecureTransport" : "false"
          },
          "NumericLessThan" : {
            "aws:TLSVersion" : "1.2"
          }
        },
        "Principal" : "*"
      }
    ]
  })]

  log_bucket = local.logging_bucket_name
  log_prefix = "s3access/${local.artefact_bucket_name}"

  # Refer to the below section "Replication" before enabling replication
  replication_enabled = false
  # Below three variables and providers configuration are only relevant if 'replication_enabled' is set to true
  replication_region = "eu-west-2"
  # replication_role_arn                     = module.s3-bucket-replication-role.role.arn
  providers = {
    # Here we use the default provider Region for replication. Destination buckets can be within the same Region as the
    # source bucket. On the other hand, if you need to enable cross-region replication, please contact the Modernisation
    # Platform team to add a new provider for the additional Region.
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

  tags = merge(local.tags,
    { Name = local.artefact_bucket_name }
  )
}

# resource "aws_s3_bucket_notification" "artefact_bucket_notification" {
#   bucket = module.s3-bucket.bucket.id

#   topic {
#     topic_arn     = aws_sns_topic.s3_topic.arn
#     events        = ["s3:ObjectCreated:*"]
#     filter_suffix = ".log"
#   }
# }

# S3 Bucket - Logging
module "s3-bucket-logging" {
  # v8.2.0 = https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket/commit/52a40b0dd18aaef0d7c5565d93cc8997aad79636
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=52a40b0dd18aaef0d7c5565d93cc8997aad79636"

  bucket_name        = local.logging_bucket_name
  versioning_enabled = false
  bucket_policy = [jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        "Sid" : "DenyInsecureTransport",
        "Effect" : "Deny",
        "Principal" : "*",
        "Action" : "s3:*",
        "Resource" : [
          module.s3-bucket-logging.bucket.arn,
          "${module.s3-bucket-logging.bucket.arn}/*"
        ],
        "Condition" : {
          "Bool" : {
            "aws:SecureTransport" : "false"
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::652711504416:root"
        }
        Action   = "s3:PutObject"
        Resource = "${module.s3-bucket-logging.bucket.arn}/*"
      },
      {
        "Sid" = "RestrictToTLSRequestsOnly",
        "Action" : "s3:*",
        "Effect" : "Deny",
        "Resource" : [
          module.s3-bucket-logging.bucket.arn,
          "${module.s3-bucket-logging.bucket.arn}/*"
        ],
        "Condition" : {
          "Bool" : {
            "aws:SecureTransport" : "false"
          },
          "NumericLessThan" : {
            "aws:TLSVersion" : "1.2"
          }
        },
        "Principal" : "*"
      }
    ]
  })]

  log_bucket = local.logging_bucket_name
  log_prefix = "s3access/${local.logging_bucket_name}"

  # Refer to the below section "Replication" before enabling replication
  replication_enabled = false
  # Below three variables and providers configuration are only relevant if 'replication_enabled' is set to true
  replication_region = "eu-west-2"
  # replication_role_arn                     = module.s3-bucket-replication-role.role.arn
  providers = {
    # Here we use the default provider Region for replication. Destination buckets can be within the same Region as the
    # source bucket. On the other hand, if you need to enable cross-region replication, please contact the Modernisation
    # Platform team to add a new provider for the additional Region.
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

  tags = merge(local.tags,
    { Name = local.logging_bucket_name }
  )
}

# resource "aws_s3_bucket_notification" "logging_bucket_notification" {
#   bucket = module.s3-bucket-logging.bucket.id

#   topic {
#     topic_arn     = aws_sns_topic.s3_topic.arn
#     events        = ["s3:ObjectCreated:*"]
#     filter_suffix = ".log"
#   }
# }

# S3 Bucket - R-sync
module "s3-bucket-dbbackup" {
  # v8.2.0 = https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket/commit/52a40b0dd18aaef0d7c5565d93cc8997aad79636
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=52a40b0dd18aaef0d7c5565d93cc8997aad79636"

  bucket_name        = local.rsync_bucket_name
  versioning_enabled = false
  bucket_policy = [jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        "Sid" : "DenyInsecureTransport",
        "Effect" : "Deny",
        "Principal" : "*",
        "Action" : "s3:*",
        "Resource" : [
          module.s3-bucket-dbbackup.bucket.arn,
          "${module.s3-bucket-dbbackup.bucket.arn}/*"
        ],
        "Condition" : {
          "Bool" : {
            "aws:SecureTransport" : "false"
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${local.environment_management.account_ids["core-shared-services-production"]}:root",
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/developer"
          ]
        }
        Action   = "s3:PutObject"
        Resource = "${module.s3-bucket-dbbackup.bucket.arn}/*"
      },
      {
        "Sid" = "RestrictToTLSRequestsOnly",
        "Action" : "s3:*",
        "Effect" : "Deny",
        "Resource" : [
          module.s3-bucket-dbbackup.bucket.arn,
          "${module.s3-bucket-dbbackup.bucket.arn}/*"
        ],
        "Condition" : {
          "Bool" : {
            "aws:SecureTransport" : "false"
          },
          "NumericLessThan" : {
            "aws:TLSVersion" : "1.2"
          }
        },
        "Principal" : "*"
      }
    ]
  })]

  log_bucket = local.logging_bucket_name
  log_prefix = "s3access/${local.rsync_bucket_name}"

  # Refer to the below section "Replication" before enabling replication
  replication_enabled = false
  # Below three variables and providers configuration are only relevant if 'replication_enabled' is set to true
  replication_region = "eu-west-2"
  # replication_role_arn                     = module.s3-bucket-replication-role.role.arn
  providers = {
    # Here we use the default provider Region for replication. Destination buckets can be within the same Region as the
    # source bucket. On the other hand, if you need to enable cross-region replication, please contact the Modernisation
    # Platform team to add a new provider for the additional Region.
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

  tags = merge(local.tags,
    { Name = local.rsync_bucket_name }
  )
}

# resource "aws_s3_bucket_notification" "dbbackup_bucket_notification" {
#   bucket = module.s3-bucket-dbbackup.bucket.id

#   topic {
#     topic_arn     = aws_sns_topic.s3_topic.arn
#     events        = ["s3:ObjectCreated:*"]
#     filter_suffix = ".log"
#   }
# }

resource "aws_s3_bucket" "ccms_ebs_shared" {
  bucket = "ccms-ebs-${local.component_name}-shared"
}

resource "aws_s3_bucket_public_access_block" "ccms_ebs_shared" {
  bucket                  = aws_s3_bucket.ccms_ebs_shared.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "ccms_ebs_shared" {
  bucket = aws_s3_bucket.ccms_ebs_shared.id

  versioning_configuration {
    status = "Enabled"
  }
}

data "aws_iam_policy_document" "shared_bucket_secure_transport" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.ccms_ebs_shared.arn,
      "${aws_s3_bucket.ccms_ebs_shared.arn}/*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "shared_bucket_secure_transport" {
  bucket = aws_s3_bucket.ccms_ebs_shared.id
  policy = data.aws_iam_policy_document.shared_bucket_secure_transport.json
}

# Development

moved {
  from = module.s3-bucket.aws_s3_bucket_logging.default["ccms-ebs-sandbox-logging"]
  to   = module.s3-bucket.aws_s3_bucket_logging.default_single_name["ccms-ebs-sandbox-logging"]
}

moved {
  from = module.s3-bucket-logging.aws_s3_bucket_logging.default["ccms-ebs-sandbox-logging"]
  to   = module.s3-bucket-logging.aws_s3_bucket_logging.default_single_name["ccms-ebs-sandbox-logging"]
}

moved {
  from = module.s3-bucket-dbbackup.aws_s3_bucket_logging.default["ccms-ebs-sandbox-logging"]
  to   = module.s3-bucket-dbbackup.aws_s3_bucket_logging.default_single_name["ccms-ebs-sandbox-logging"]
}
