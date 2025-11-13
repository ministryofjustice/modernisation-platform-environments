# S3 Bucket - Artefacts
module "s3-bucket" { #tfsec:ignore:aws-s3-enable-versioning
  # v8.2.0 = https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket/commit/52a40b0dd18aaef0d7c5565d93cc8997aad79636
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=52a40b0dd18aaef0d7c5565d93cc8997aad79636"

  bucket_name = local.artefact_bucket_name
  #  bucket_prefix      = "s3-bucket-example"
  versioning_enabled = true
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
          days          = local.application_data.accounts[local.environment].s3_lifecycle_days_transition_current_standard
          storage_class = "STANDARD_IA"
          }, {
          days          = local.application_data.accounts[local.environment].s3_lifecycle_days_transition_current_glacier
          storage_class = "GLACIER"
        }
      ]

      expiration = {
        days = local.application_data.accounts[local.environment].s3_lifecycle_days_expiration_current
      }

      noncurrent_version_transition = [
        {
          days          = local.application_data.accounts[local.environment].s3_lifecycle_days_transition_noncurrent_standard
          storage_class = "STANDARD_IA"
          }, {
          days          = local.application_data.accounts[local.environment].s3_lifecycle_days_transition_noncurrent_glacier
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = local.application_data.accounts[local.environment].s3_lifecycle_days_expiration_noncurrent
      }

      abort_incomplete_multipart_upload_days = local.application_data.accounts[local.environment].s3_lifecycle_days_abort_incomplete_multipart_upload_days
    }
  ]

  tags = merge(local.tags,
    { Name = lower(format("s3-bucket-%s-%s", local.application_name, local.environment)) }
  )
}

resource "aws_s3_bucket_notification" "artefact_bucket_notification" {
  bucket      = module.s3-bucket.bucket.id
  eventbridge = true
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
  # v8.2.0 = https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket/commit/52a40b0dd18aaef0d7c5565d93cc8997aad79636
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=52a40b0dd18aaef0d7c5565d93cc8997aad79636"

  bucket_name        = local.logging_bucket_name
  versioning_enabled = true
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
          days          = local.application_data.accounts[local.environment].s3_lifecycle_days_transition_current_standard
          storage_class = "STANDARD_IA"
          }, {
          days          = local.application_data.accounts[local.environment].s3_lifecycle_days_transition_current_glacier
          storage_class = "GLACIER"
        }
      ]

      expiration = {
        days = local.application_data.accounts[local.environment].s3_lifecycle_days_expiration_current
      }

      noncurrent_version_transition = [
        {
          days          = local.application_data.accounts[local.environment].s3_lifecycle_days_transition_noncurrent_standard
          storage_class = "STANDARD_IA"
          }, {
          days          = local.application_data.accounts[local.environment].s3_lifecycle_days_transition_noncurrent_glacier
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = local.application_data.accounts[local.environment].s3_lifecycle_days_expiration_noncurrent
      }

      abort_incomplete_multipart_upload_days = local.application_data.accounts[local.environment].s3_lifecycle_days_abort_incomplete_multipart_upload_days
    }
  ]

  tags = merge(local.tags,
    { Name = lower(format("s3-%s-%s-logging", local.application_name, local.environment)) }
  )
}

resource "aws_s3_bucket_notification" "logging_bucket_notification" {
  bucket      = module.s3-bucket-logging.bucket.id
  eventbridge = true
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
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::ccms-ebs-${local.environment}-logging/*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = ["${data.aws_caller_identity.current.account_id}"]
    }
  }
}

# S3 Bucket - R-sync
module "s3-bucket-dbbackup" {
  # v8.2.0 = https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket/commit/52a40b0dd18aaef0d7c5565d93cc8997aad79636
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=52a40b0dd18aaef0d7c5565d93cc8997aad79636"

  bucket_name        = local.rsync_bucket_name
  versioning_enabled = true
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
          days          = local.application_data.accounts[local.environment].s3_lifecycle_days_transition_current_standard
          storage_class = "STANDARD_IA"
          }, {
          days          = local.application_data.accounts[local.environment].s3_lifecycle_days_transition_current_glacier
          storage_class = "GLACIER"
        }
      ]

      expiration = {
        days = local.application_data.accounts[local.environment].s3_lifecycle_days_expiration_current
      }

      noncurrent_version_transition = [
        {
          days          = local.application_data.accounts[local.environment].s3_lifecycle_days_transition_noncurrent_standard
          storage_class = "STANDARD_IA"
          }, {
          days          = local.application_data.accounts[local.environment].s3_lifecycle_days_transition_noncurrent_glacier
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = local.application_data.accounts[local.environment].s3_lifecycle_days_expiration_noncurrent
      }

      abort_incomplete_multipart_upload_days = local.application_data.accounts[local.environment].s3_lifecycle_days_abort_incomplete_multipart_upload_days
    }
  ]

  tags = merge(local.tags,
    { Name = lower(format("s3-%s-%s-dbbackup", local.application_name, local.environment)) }
  )
}

resource "aws_s3_bucket_notification" "dbbackup_bucket_notification" {
  bucket      = module.s3-bucket-dbbackup.bucket.id
  eventbridge = true
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
#For shared bucket lifecycle rule is not needed as it host lambda application source code
resource "aws_s3_bucket" "ccms_ebs_shared" {
  bucket = "${local.application_name}-${local.environment}-shared"
  
  tags = merge(local.tags,
    {
      Name        = "${local.application_name}-${local.environment}-shared"
    }
  )

}


resource "aws_s3_object" "folder" {
  bucket = aws_s3_bucket.ccms_ebs_shared.bucket
  for_each = {
    for index, name in local.lambda_folder_name :
    name => index == 0 ? "${name}/" : "lambda_delivery/${name}/"
  }

  key = each.value

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



# S3 Bucket for Payment Load

resource "aws_s3_bucket" "lambda_payment_load" {
  bucket = "${local.application_name}-${local.environment}-payment-load"
  
  tags = merge(local.tags,
    {
      Name        = "${local.application_name}-${local.environment}-payment-load"
    }
  ) 
}

resource "aws_s3_bucket_public_access_block" "lambda_payment_load" {
  bucket                  = aws_s3_bucket.lambda_payment_load.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "lambda_payment_load" {
  bucket = aws_s3_bucket.lambda_payment_load.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Lifecycle configuration: expire current objects and noncurrent versions after 30 days
resource "aws_s3_bucket_lifecycle_configuration" "lambda_payment_load_lifecycle" {

  bucket = aws_s3_bucket.lambda_payment_load.id

  # One lifecycle rule per prefix
  rule {
    id = "expire-${aws_s3_bucket.lambda_payment_load.id}-${local.application_data.accounts[local.environment].s3_lifecycle_days_expiration_current}d"
    status = "Enabled"

    filter {
      prefix = ""
    }
    
    expiration {
      days = local.application_data.accounts[local.environment].s3_lifecycle_days_expiration_current
    }

    noncurrent_version_transition {
      noncurrent_days = local.application_data.accounts[local.environment].s3_lifecycle_days_transition_noncurrent_standard
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = local.application_data.accounts[local.environment].s3_lifecycle_days_transition_noncurrent_glacier
      storage_class   = "GLACIER"
    }
    noncurrent_version_expiration {
      noncurrent_days = local.application_data.accounts[local.environment].s3_lifecycle_days_expiration_noncurrent
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = local.application_data.accounts[local.environment].s3_lifecycle_days_abort_incomplete_multipart_upload_days
    }

  }

}

# Development
moved {
  from = module.s3-bucket.aws_s3_bucket_logging.default["ccms-ebs-development-logging"]
  to   = module.s3-bucket.aws_s3_bucket_logging.default_single_name["ccms-ebs-development-logging"]
}

moved {
  from = module.s3-bucket-dbbackup.aws_s3_bucket_logging.default["ccms-ebs-development-logging"]
  to   = module.s3-bucket-dbbackup.aws_s3_bucket_logging.default_single_name["ccms-ebs-development-logging"]
}

moved {
  from = module.s3-bucket-logging.aws_s3_bucket_logging.default["ccms-ebs-development-logging"]
  to   = module.s3-bucket-logging.aws_s3_bucket_logging.default_single_name["ccms-ebs-development-logging"]
}

# Test
moved {
  from = module.s3-bucket.aws_s3_bucket_logging.default["ccms-ebs-test-logging"]
  to   = module.s3-bucket.aws_s3_bucket_logging.default_single_name["ccms-ebs-test-logging"]
}

moved {
  from = module.s3-bucket-dbbackup.aws_s3_bucket_logging.default["ccms-ebs-test-logging"]
  to   = module.s3-bucket-dbbackup.aws_s3_bucket_logging.default_single_name["ccms-ebs-test-logging"]
}

moved {
  from = module.s3-bucket-logging.aws_s3_bucket_logging.default["ccms-ebs-test-logging"]
  to   = module.s3-bucket-logging.aws_s3_bucket_logging.default_single_name["ccms-ebs-test-logging"]
}

# Preproduction
moved {
  from = module.s3-bucket.aws_s3_bucket_logging.default["ccms-ebs-preproduction-logging"]
  to   = module.s3-bucket.aws_s3_bucket_logging.default_single_name["ccms-ebs-preproduction-logging"]
}

moved {
  from = module.s3-bucket-dbbackup.aws_s3_bucket_logging.default["ccms-ebs-preproduction-logging"]
  to   = module.s3-bucket-dbbackup.aws_s3_bucket_logging.default_single_name["ccms-ebs-preproduction-logging"]
}

moved {
  from = module.s3-bucket-logging.aws_s3_bucket_logging.default["ccms-ebs-preproduction-logging"]
  to   = module.s3-bucket-logging.aws_s3_bucket_logging.default_single_name["ccms-ebs-preproduction-logging"]
}

# Production
moved {
  from = module.s3-bucket.aws_s3_bucket_logging.default["ccms-ebs-production-logging"]
  to   = module.s3-bucket.aws_s3_bucket_logging.default_single_name["ccms-ebs-production-logging"]
}

moved {
  from = module.s3-bucket-dbbackup.aws_s3_bucket_logging.default["ccms-ebs-production-logging"]
  to   = module.s3-bucket-dbbackup.aws_s3_bucket_logging.default_single_name["ccms-ebs-production-logging"]
}

moved {
  from = module.s3-bucket-logging.aws_s3_bucket_logging.default["ccms-ebs-production-logging"]
  to   = module.s3-bucket-logging.aws_s3_bucket_logging.default_single_name["ccms-ebs-production-logging"]
}
