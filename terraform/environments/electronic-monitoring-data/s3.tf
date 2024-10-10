locals {
  environment_map = {
    "production"  = "prod"
    "test"        = "test"
    "development" = "dev"
    "default"     = ""
  }
  environment_shorthand = local.environment_map[local.environment]

  bucket_prefix = "emds-${local.environment_shorthand}"
}

# ------------------------------------------------------------------------
# Account S3 bucket log bucket
# ------------------------------------------------------------------------

module "s3-logging-bucket" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=f759060"

  bucket_prefix      = "${local.bucket_prefix}-bucket-logs-"
  versioning_enabled = true

  # to disable ACLs in preference of BucketOwnership controls as per https://aws.amazon.com/blogs/aws/heads-up-amazon-s3-security-changes-are-coming-in-april-of-2023/ set:
  ownership_controls = "BucketOwnerEnforced"

  # Refer to the below section "Replication" before enabling replication
  replication_enabled = false
  # Below two variables and providers configuration are only relevant if 'replication_enabled' is set to true
  # replication_region                       = "eu-west-2"
  # replication_role_arn                     = module.s3-bucket.role.arn
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

  tags = merge(local.tags, { resource-type = "logging" })
}

# ------------------------------------------------------------------------
# Metadata Store Bucket
# ------------------------------------------------------------------------

module "s3-metadata-bucket" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=f759060"

  bucket_prefix      = "${local.bucket_prefix}-metadata-"
  versioning_enabled = true

  # to disable ACLs in preference of BucketOwnership controls as per https://aws.amazon.com/blogs/aws/heads-up-amazon-s3-security-changes-are-coming-in-april-of-2023/ set:
  ownership_controls = "BucketOwnerEnforced"

  # Refer to the below section "Replication" before enabling replication
  replication_enabled = false
  # Below two variables and providers configuration are only relevant if 'replication_enabled' is set to true
  # replication_region                       = "eu-west-2"
  # replication_role_arn                     = module.s3-bucket.role.arn
  providers = {
    # Here we use the default provider Region for replication. Destination buckets can be within the same Region as the
    # source bucket. On the other hand, if you need to enable cross-region replication, please contact the Modernisation
    # Platform team to add a new provider for the additional Region.
    # Leave this provider block in even if you are not using replication
    aws.bucket-replication = aws
  }
  log_buckets = tomap({
    "log_bucket_name" : module.s3-logging-bucket.bucket.id,
    "log_bucket_arn" : module.s3-logging-bucket.bucket.arn,
    "log_bucket_policy" : module.s3-logging-bucket.bucket_policy.policy,
  })
  log_prefix                = "logs/${local.bucket_prefix}-metadata/"
  log_partition_date_source = "EventTime"

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

  tags = merge(local.tags, { Resource_Type = "metadata_store" })
}

# resource "aws_s3_bucket_notification" "send_metadata_to_ap_lambda" {
#   bucket = module.s3-metadata-bucket.bucket.id

#   lambda_function {
#     id                  = "metadata_bucket_notification"
#     lambda_function_arn = module.send_metadata_to_ap.lambda_function_arn
#     events              = ["s3:ObjectCreated:*"]
#   }

#   depends_on = [aws_lambda_permission.send_metadata_to_ap]
# }

# ----------------------------------
# Athena Query result storage bucket
# ----------------------------------

module "s3-athena-bucket" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=f759060"

  bucket_prefix      = "${local.bucket_prefix}-athena-query-results-"
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

  log_buckets = tomap({
    "log_bucket_name" : module.s3-logging-bucket.bucket.id,
    "log_bucket_arn" : module.s3-logging-bucket.bucket.arn,
    "log_bucket_policy" : module.s3-logging-bucket.bucket_policy.policy,
  })
  log_prefix                = "logs/${local.bucket_prefix}-athena-query-results/"
  log_partition_date_source = "EventTime"

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
          days          = 30
          storage_class = "STANDARD_IA"
          }, {
          days          = 90
          storage_class = "GLACIER"
        }
      ]

      expiration = {
        days = 365
      }

      noncurrent_version_transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
          }, {
          days          = 90
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = 365
      }
    }
  ]

  tags = local.tags
}

# ----------------------------------
# Unzipped Data Store and log bucket
# ----------------------------------

module "s3-unzipped-files-bucket" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=f759060"

  bucket_prefix      = "${local.bucket_prefix}-unzipped-files-"
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

  log_buckets = tomap({
    "log_bucket_name" : module.s3-logging-bucket.bucket.id,
    "log_bucket_arn" : module.s3-logging-bucket.bucket.arn,
    "log_bucket_policy" : module.s3-logging-bucket.bucket_policy.policy,
  })
  log_prefix = "logs/${local.bucket_prefix}-unzipped-files/"

  log_partition_date_source = "EventTime"

  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      expiration = {
        days = 7
      }
    }
  ]

  tags = local.tags
}

# ------------------------------------------------------------------------
# DMS Premigration Assessments bucket
# ------------------------------------------------------------------------

module "s3-dms-premigrate-assess-bucket" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=f759060"

  bucket_prefix      = "${local.bucket_prefix}-dms-premigrate-assess-"
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

  log_buckets = tomap({
    "log_bucket_name" : module.s3-logging-bucket.bucket.id,
    "log_bucket_arn" : module.s3-logging-bucket.bucket.arn,
    "log_bucket_policy" : module.s3-logging-bucket.bucket_policy.policy,
  })
  log_prefix                = "logs/${local.bucket_prefix}-dms-premigrate-assess/"
  log_partition_date_source = "EventTime"

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
          days          = 60
          storage_class = "STANDARD_IA"
          }, {
          days          = 90
          storage_class = "GLACIER"
        }
      ]

      expiration = {
        days = 120
      }

      noncurrent_version_transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
          }, {
          days          = 90
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = 365
      }
    }
  ]

  tags = local.tags
}

# ------------------------------------------------------------------------
# Unstructured directory structure as json bucket
# ------------------------------------------------------------------------

module "s3-json-directory-structure-bucket" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=f759060"

  bucket_prefix      = "${local.bucket_prefix}-json-directory-structure-"
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

  log_buckets = tomap({
    "log_bucket_name" : module.s3-logging-bucket.bucket.id,
    "log_bucket_arn" : module.s3-logging-bucket.bucket.arn,
    "log_bucket_policy" : module.s3-logging-bucket.bucket_policy.policy,
  })
  log_prefix                = "logs/${local.bucket_prefix}-json-directory-structure/"
  log_partition_date_source = "EventTime"

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
          days          = 365
          storage_class = "STANDARD_IA"
          }, {
          days          = 730
          storage_class = "GLACIER"
        }
      ]

      expiration = {
        days = 2190
      }

      noncurrent_version_transition = [
        {
          days          = 365
          storage_class = "STANDARD_IA"
          }, {
          days          = 730
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = 2190
      }
    }
  ]

  tags = local.tags
}

# ------------------------------------------------------------------------
# Main store bucket
# ------------------------------------------------------------------------

module "s3-data-bucket" {
  source             = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=f759060"
  bucket_prefix      = "${local.bucket_prefix}-data-"
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
  log_buckets = tomap({
    "log_bucket_name" : module.s3-logging-bucket.bucket.id,
    "log_bucket_arn" : module.s3-logging-bucket.bucket.arn,
    "log_bucket_policy" : module.s3-logging-bucket.bucket_policy.policy,
  })
  log_prefix                = "logs/${local.bucket_prefix}-data/"
  log_partition_date_source = "EventTime"

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
          days          = 183
          storage_class = "STANDARD_IA"
          }, {
          days          = 730
          storage_class = "GLACIER"
        }
      ]

      expiration = {
        days = 10000
      }

      noncurrent_version_transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
          }, {
          days          = 90
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = 365
      }
    }
  ]

  tags = local.tags
}

# ------------------------------------------------------------------------
# Landing buckets FMS
# ------------------------------------------------------------------------

module "s3-fms-general-landing-bucket" {
  source = "./modules/landing_bucket/"

  data_feed             = "fms"
  local_bucket_prefix   = local.bucket_prefix
  local_tags            = local.tags
  logging_bucket        = module.s3-logging-bucket
  order_type            = "general"
  s3_trigger_lambda_arn = module.process_landing_bucket_files.lambda_function_arn

  providers = {
    aws = aws
  }
}

module "s3-fms-general-landing-bucket-iam-user" {
  source = "./modules/landing_bucket_iam_user_access/"

  data_feed                 = "fms"
  landing_bucket_arn        = module.s3-fms-general-landing-bucket.bucket_arn
  local_bucket_prefix       = local.bucket_prefix
  local_tags                = local.tags
  order_type                = "general"
  rotation_lambda           = module.rotate_iam_key
  rotation_lambda_role_name = aws_iam_role.rotate_iam_keys.name
}

module "s3-fms-specials-landing-bucket" {
  source = "./modules/landing_bucket/"

  data_feed             = "fms"
  local_bucket_prefix   = local.bucket_prefix
  local_tags            = local.tags
  logging_bucket        = module.s3-logging-bucket
  order_type            = "specials"
  s3_trigger_lambda_arn = module.process_landing_bucket_files.lambda_function_arn

  providers = {
    aws = aws
  }
}

module "s3-fms-specials-landing-bucket-iam-user" {
  source = "./modules/landing_bucket_iam_user_access/"

  data_feed                 = "fms"
  landing_bucket_arn        = module.s3-fms-specials-landing-bucket.bucket_arn
  local_bucket_prefix       = local.bucket_prefix
  local_tags                = local.tags
  order_type                = "specials"
  rotation_lambda           = module.rotate_iam_key
  rotation_lambda_role_name = aws_iam_role.rotate_iam_keys.name
}

# ------------------------------------------------------------------------
# Landing bucket MDSS
# ------------------------------------------------------------------------

module "s3-mdss-general-landing-bucket" {
  source = "./modules/landing_bucket/"

  data_feed             = "mdss"
  local_bucket_prefix   = local.bucket_prefix
  local_tags            = local.tags
  logging_bucket        = module.s3-logging-bucket
  order_type            = "general"
  s3_trigger_lambda_arn = module.process_landing_bucket_files.lambda_function_arn

  providers = {
    aws = aws
  }
}

module "s3-mdss-ho-landing-bucket" {
  source = "./modules/landing_bucket/"

  data_feed             = "mdss"
  local_bucket_prefix   = local.bucket_prefix
  local_tags            = local.tags
  logging_bucket        = module.s3-logging-bucket
  order_type            = "ho"
  s3_trigger_lambda_arn = module.process_landing_bucket_files.lambda_function_arn

  providers = {
    aws = aws
  }
}

module "s3-mdss-specials-landing-bucket" {
  source = "./modules/landing_bucket/"

  data_feed             = "mdss"
  local_bucket_prefix   = local.bucket_prefix
  local_tags            = local.tags
  logging_bucket        = module.s3-logging-bucket
  order_type            = "specials"
  s3_trigger_lambda_arn = module.process_landing_bucket_files.lambda_function_arn

  providers = {
    aws = aws
  }
}

# ----------------------------------
# Virus scanning buckets
# ----------------------------------

module "s3-received-files-bucket" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=f759060"

  bucket_prefix      = "${local.bucket_prefix}-received-files-"
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

  log_buckets = tomap({
    "log_bucket_name" : module.s3-logging-bucket.bucket.id,
    "log_bucket_arn" : module.s3-logging-bucket.bucket.arn,
    "log_bucket_policy" : module.s3-logging-bucket.bucket_policy.policy,
  })
  log_prefix = "logs/${local.bucket_prefix}-received-files/"

  log_partition_date_source = "EventTime"

  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      expiration = {
        days = 90
      }
    }
  ]

  tags = local.tags
}

resource "aws_lambda_permission" "scan_received_files" {
  statement_id  = "AllowExecutionFromReceivedFilesS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = module.virus_scan_file.lambda_function_arn
  principal     = "s3.amazonaws.com"
  source_arn    = module.s3-received-files-bucket.bucket.arn
}

resource "aws_s3_bucket_notification" "scan_received_files" {
  bucket = module.s3-received-files-bucket.bucket.id

  lambda_function {
    lambda_function_arn = module.virus_scan_file.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.scan_received_files]
}

module "s3-quarantine-files-bucket" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=f759060"

  bucket_prefix      = "${local.bucket_prefix}-quarantined-files-"
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

  log_buckets = tomap({
    "log_bucket_name" : module.s3-logging-bucket.bucket.id,
    "log_bucket_arn" : module.s3-logging-bucket.bucket.arn,
    "log_bucket_policy" : module.s3-logging-bucket.bucket_policy.policy,
  })
  log_prefix = "logs/${local.bucket_prefix}-quarantined-files/"

  log_partition_date_source = "EventTime"

  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      expiration = {
        days = 90
      }
    }
  ]

  tags = local.tags
}

module "s3-clamav-definitions-bucket" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=f759060"

  bucket_prefix      = "${local.bucket_prefix}-clamav-definitions-"
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

  log_buckets = tomap({
    "log_bucket_name" : module.s3-logging-bucket.bucket.id,
    "log_bucket_arn" : module.s3-logging-bucket.bucket.arn,
    "log_bucket_policy" : module.s3-logging-bucket.bucket_policy.policy,
  })
  log_prefix = "logs/${local.bucket_prefix}-clamav-definitions/"

  log_partition_date_source = "EventTime"

  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      expiration = {
        days = 90
      }
    }
  ]

  tags = local.tags
}

# ------------------------------------------------------------------------
# DMS data validation bucket
# ------------------------------------------------------------------------
module "s3-dms-data-validation-bucket" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=f759060"

  bucket_prefix      = "${local.bucket_prefix}-dms-data-validation-"
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

  log_buckets = tomap({
    "log_bucket_name" : module.s3-logging-bucket.bucket.id,
    "log_bucket_arn" : module.s3-logging-bucket.bucket.arn,
    "log_bucket_policy" : module.s3-logging-bucket.bucket_policy.policy,
  })
  log_prefix                = "logs/${local.bucket_prefix}-dms-data-validation/"
  log_partition_date_source = "EventTime"

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
          days          = 60
          storage_class = "STANDARD_IA"
          }, {
          days          = 90
          storage_class = "GLACIER"
        }
      ]

      expiration = {
        days = 120
      }

      noncurrent_version_transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
          }, {
          days          = 90
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = 365
      }
    }
  ]

  tags = local.tags
}

# ------------------------------------------------------------------------
# Glue job script store bucket
# ------------------------------------------------------------------------

module "s3-glue-job-script-bucket" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=f759060"

  bucket_prefix      = "${local.bucket_prefix}-glue-job-store-"
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

  log_buckets = tomap({
    "log_bucket_name" : module.s3-logging-bucket.bucket.id,
    "log_bucket_arn" : module.s3-logging-bucket.bucket.arn,
    "log_bucket_policy" : module.s3-logging-bucket.bucket_policy.policy,
  })
  log_prefix                = "logs/${local.bucket_prefix}-glue-job-store/"
  log_partition_date_source = "EventTime"

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
          days          = 60
          storage_class = "STANDARD_IA"
          }, {
          days          = 90
          storage_class = "GLACIER"
        }
      ]

      expiration = {
        days = 120
      }

      noncurrent_version_transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
          }, {
          days          = 90
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = 365
      }
    }
  ]

  tags = local.tags
}

# ------------------------------------------------------------------------
# DMS target  bucket
# ------------------------------------------------------------------------


module "s3-dms-target-store-bucket" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=f759060"

  bucket_prefix      = "${local.bucket_prefix}-dms-rds-to-parquet-"
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

  log_buckets = tomap({
    "log_bucket_name" : module.s3-logging-bucket.bucket.id,
    "log_bucket_arn" : module.s3-logging-bucket.bucket.arn,
    "log_bucket_policy" : module.s3-logging-bucket.bucket_policy.policy,
  })
  log_prefix                = "logs/dms-target-store/"
  log_partition_date_source = "EventTime"

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
          days          = 365
          storage_class = "STANDARD_IA"
          }, {
          days          = 700
          storage_class = "GLACIER"
        }
      ]

      expiration = {
        days = 1000
      }

      noncurrent_version_transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
          }, {
          days          = 90
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = 365
      }
    }
  ]

  tags = local.tags
}

## temp set up for old s3 bucket
#trivy:ignore:AVD-AWS-0088
#trivy:ignore:AVD-AWS-0090
#trivy:ignore:AVD-AWS-0132
#trivy:ignore:s3-bucket-logging
#tfsec:ignore:aws-s3-enable-bucket-logging
#tfsec:ignore:aws-s3-enable-versioning
resource "aws_s3_bucket" "data_store" {
  #checkov:skip:CKV_AWS_145
  #checkov:skip:CKV_AWS_144
  #checkov:skip:CKV_AWS_21
  #checkov:skip:CKV2_AWS_65
  #checkov:skip:CKV2_AWS_62
  #checkov:skip:CKV_AWS_18
  #checkov:skip:CKV2_AWS_61
  bucket_prefix = "em-data-store-"
  force_destroy = false
  tags = {
    "application"            = "electronic-monitoring-data"
    "business-unit"          = "HMPPS"
    "environment-name"       = "electronic-monitoring-data-production"
    "infrastructure-support" = "dataengineering@digital.justice.gov.uk"
    "is-production"          = "true"
    "owner"                  = "Data engineering: dataengineering@digital.justice.gov.uk"
    "source-code"            = "https://github.com/ministryofjustice/modernisation-platform-environments"
  }
}

resource "aws_s3_bucket_public_access_block" "data_store" {
  bucket                  = aws_s3_bucket.data_store.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "bucket" {
  bucket = aws_s3_bucket.data_store.id
  rule {
    object_ownership = "ObjectWriter"
  }
}

data "aws_iam_policy_document" "data_store_deny_all" {
  statement {
    sid     = "EnforceTLSv12orHigher"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.data_store.arn,
      "${aws_s3_bucket.data_store.arn}/*"

    ]
    principals {
      identifiers = ["*"]
      type        = "AWS"
    }
    condition {
      test     = "NumericLessThan"
      variable = "s3:TlsVersion"
      values   = [1.2]
    }
  }
}

resource "aws_s3_bucket_policy" "data_store" {
  bucket = aws_s3_bucket.data_store.id
  policy = data.aws_iam_policy_document.data_store_deny_all.json
}
