#------------------------------------------------------------------------------
# S3 Bucket - Artefacts
#------------------------------------------------------------------------------
module "s3-bucket" { #tfsec:ignore:aws-s3-enable-versioning
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.2.0"

  bucket_name = local.artefact_bucket_name
  #  bucket_prefix      = "s3-bucket-example"
  versioning_enabled = false
  bucket_policy      = [data.aws_iam_policy_document.artefacts_s3_policy.json]

  # Refer to the below section "Replication" before enabling replication
  replication_enabled = false
  # Below three variables and providers configuration are only relevant if 'replication_enabled' is set to true
  replication_region                       = "eu-west-2"
  versioning_enabled_on_replication_bucket = false
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
    { Name = lower(format("s3-bucket-%s-%s", local.application_name, local.environment)) }
  )
}

data "aws_iam_policy_document" "artefacts_s3_policy" {
  statement {
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/developer",
        "arn:aws:iam::${local.environment_management.account_ids["core-shared-services-production"]}:root"
      ]
    }
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${local.artefact_bucket_name}/*"]
  }
}

#------------------------------------------------------------------------------
# S3 Bucket - Logging
#------------------------------------------------------------------------------
module "s3-bucket-logging" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.2.0"

  bucket_name        = local.logging_bucket_name
  versioning_enabled = false
  bucket_policy      = [data.aws_iam_policy_document.logging_s3_policy.json]

  # Refer to the below section "Replication" before enabling replication
  replication_enabled = false
  # Below three variables and providers configuration are only relevant if 'replication_enabled' is set to true
  replication_region                       = "eu-west-2"
  versioning_enabled_on_replication_bucket = false
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
    { Name = lower(format("s3-%s-%s-logging", local.application_name, local.environment)) }
  )
}

data "aws_iam_policy_document" "logging_s3_policy" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::652711504416:root"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${module.s3-bucket-logging.bucket.arn}/*"]
  }
}


#------------------------------------------------------------------------------
# S3 Bucket - R-sync
#------------------------------------------------------------------------------
module "s3-bucket-db-backup" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.2.0"

  bucket_name        = local.rsync_bucket_name
  versioning_enabled = false
  bucket_policy = [
    data.aws_iam_policy_document.rsync_s3_policy.json,
    data.aws_iam_policy_document.deny_http_s3_policy.json
  ]

  # Refer to the below section "Replication" before enabling replication
  replication_enabled = false
  # Below three variables and providers configuration are only relevant if 'replication_enabled' is set to true
  replication_region                       = "eu-west-2"
  versioning_enabled_on_replication_bucket = false
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
    { Name = lower(format("s3-%s-%s-db-backup", local.application_name, local.environment)) }
  )
}

data "aws_iam_policy_document" "rsync_s3_policy" {
  statement {
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/developer",
        "arn:aws:iam::${local.environment_management.account_ids["core-shared-services-production"]}:root"
      ]
    }
    actions   = ["s3:PutObject"]
    resources = ["${module.s3-bucket-db-backup.bucket.arn}/*"]
  }
}

data "aws_iam_policy_document" "deny_http_s3_policy" {
  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["s3:*"]
    resources = ["${module.s3-bucket-db-backup.bucket.arn}/"]
    effect    = "Deny"
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}
