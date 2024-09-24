locals {
  environment_map = {
    "production"  = "prod"
    "test"        = "test"
    "development" = "dev"
  }
  environment_shorthand = lookup(local.environment_map, local.environment)

  bucket_prefix = "emds-${local.environment_shorthand}"

  live_feed_levels = {
    1 = "general"
    2 = "special"
    3 = "home office"
  }
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
}

# ------------------------------------------------------------------------
# Landing buckets FMS
# ------------------------------------------------------------------------

module "s3-fms-general-landing-bucket" {
  source = "./modulbucket/"

  data_feed = "fms"
  local_tags = local.tags
  logging_bucket = module.s3-logging-bucket
  order_type = "general"
  supplier_account_id = 123
}

module "s3-fms-specials-landing-bucket" {
  source = "./modules/landing_bucket/"

  data_feed = "fms"
  local_tags = local.tags
  logging_bucket = module.s3-logging-bucket
  order_type = "specials"
  supplier_account_id = 123
}

# ------------------------------------------------------------------------
# Landing bucket MDSS
# ------------------------------------------------------------------------

module "s3-mdss-general-landing-bucket" {
  source = "./modules/landing_bucket/"

  data_feed = "mdss"
  local_tags = local.tags
  logging_bucket = module.s3-logging-bucket
  order_type = "general"
  supplier_account_id = 123
}

module "s3-mdss-ho-landing-bucket" {
  source = "./modules/landing_bucket/"

  data_feed = "mdss"
  local_tags = local.tags
  logging_bucket = module.s3-logging-bucket
  order_type = "ho"
  supplier_account_id = 123
}

module "s3-mdss-specials-landing-bucket" {
  source = "./modules/landing_bucket/"

  data_feed = "mdss"
  local_tags = local.tags
  logging_bucket = module.s3-logging-bucket
  order_type = "specials"
  supplier_account_id = 123
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

