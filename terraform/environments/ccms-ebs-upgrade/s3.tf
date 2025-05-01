# S3 Bucket - Artefacts
module "s3-bucket" { #tfsec:ignore:aws-s3-enable-versioning
  # v8.2.0 = https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket/commit/52a40b0dd18aaef0d7c5565d93cc8997aad79636
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=52a40b0dd18aaef0d7c5565d93cc8997aad79636"

  bucket_name = local.artefact_bucket_name
  #  bucket_prefix      = "s3-bucket-example"
  versioning_enabled = false
  bucket_policy      = [data.aws_iam_policy_document.artefacts_s3_policy.json]

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
    { Name = lower(format("s3-bucket-%s-%s", local.application_name, local.environment)) }
  )
}

resource "aws_s3_bucket_notification" "artefact_bucket_notification" {
  bucket = module.s3-bucket.bucket.id

  topic {
    topic_arn     = aws_sns_topic.s3_topic.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".log"
  }
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

# S3 Bucket - Logging
module "s3-bucket-logging" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v7.0.0"

  bucket_name        = local.logging_bucket_name
  versioning_enabled = false
  bucket_policy      = [data.aws_iam_policy_document.logging_s3_policy.json]

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
    { Name = lower(format("s3-%s-%s-logging", local.application_name, local.environment)) }
  )
}

resource "aws_s3_bucket_notification" "logging_bucket_notification" {
  bucket = module.s3-bucket-logging.bucket.id

  topic {
    topic_arn     = aws_sns_topic.s3_topic.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".log"
  }
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

# S3 Bucket - R-sync
module "s3-bucket-dbbackup" {
  # v8.2.0 = https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket/commit/52a40b0dd18aaef0d7c5565d93cc8997aad79636
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=52a40b0dd18aaef0d7c5565d93cc8997aad79636"

  bucket_name        = local.rsync_bucket_name
  versioning_enabled = false
  bucket_policy      = [data.aws_iam_policy_document.dbbackup_s3_policy.json]

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
    { Name = lower(format("s3-%s-%s-dbbackup", local.application_name, local.environment)) }
  )
}

resource "aws_s3_bucket_notification" "dbbackup_bucket_notification" {
  bucket = module.s3-bucket-dbbackup.bucket.id

  topic {
    topic_arn     = aws_sns_topic.s3_topic.arn
    events        = ["s3:ObjectCreated:*"]
    filter_suffix = ".log"
  }
}

data "aws_iam_policy_document" "dbbackup_s3_policy" {
  statement {
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${local.environment_management.account_ids["core-shared-services-production"]}:root",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/developer"
      ]
    }
    actions = [
      "s3:PutObject"
    ]
    resources = ["${module.s3-bucket-dbbackup.bucket.arn}/*"]
  }
}

resource "aws_s3_bucket" "ccms_ebs_shared" {
  bucket = "${local.application_name}-${local.environment}-shared"
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

# Development
moved {
  from = module.s3-bucket.aws_s3_bucket_logging.default["ccms-ebs-upgrade-development-logging"]
  to   = module.s3-bucket.aws_s3_bucket_logging.default_single_name["ccms-ebs-upgrade-development-logging"]
}

moved {
  from = module.s3-bucket-artefacts.aws_s3_bucket_logging.default["ccms-ebs-upgrade-development-logging"]
  to   = module.s3-bucket-artefacts.aws_s3_bucket_logging.default_single_name["ccms-ebs-upgrade-development-logging"]
}

moved {
  from = module.s3-bucket-dbbackup.aws_s3_bucket_logging.default["ccms-ebs-upgrade-development-logging"]
  to   = module.s3-bucket-dbbackup.aws_s3_bucket_logging.default_single_name["ccms-ebs-upgrade-development-logging"]
}

# Test
moved {
  from = module.s3-bucket.aws_s3_bucket_logging.default["ccms-ebs-upgrade-test-logging"]
  to   = module.s3-bucket.aws_s3_bucket_logging.default_single_name["ccms-ebs-upgrade-test-logging"]
}

moved {
  from = module.s3-bucket-artefacts.aws_s3_bucket_logging.default["ccms-ebs-upgrade-test-logging"]
  to   = module.s3-bucket-artefacts.aws_s3_bucket_logging.default_single_name["ccms-ebs-upgrade-test-logging"]
}

moved {
  from = module.s3-bucket-dbbackup.aws_s3_bucket_logging.default["ccms-ebs-upgrade-test-logging"]
  to   = module.s3-bucket-dbbackup.aws_s3_bucket_logging.default_single_name["ccms-ebs-upgrade-test-logging"]
}
