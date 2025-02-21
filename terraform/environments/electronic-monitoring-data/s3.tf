locals {
  bucket_prefix = "emds-${local.environment_shorthand}"

  mdss_supplier_account_mapping = {
    "production"    = null
    "preproduction" = null
    "test" = {
      "account_number" = 173142358744
      "role_name"      = "dev-datatransfer-lambda-role"
    }
    "development" = {
      "account_number" = 173142358744
      "role_name"      = "dev-datatransfer-lambda-role"
    }
  }

  buckets_to_log = [
    # [ bucket id, bucket arn ]
    [module.s3-metadata-bucket.bucket.id, module.s3-metadata-bucket.bucket.arn],
    [module.s3-athena-bucket.bucket.id, module.s3-athena-bucket.bucket.arn],
    [module.s3-unzipped-files-bucket.bucket.id, module.s3-unzipped-files-bucket.bucket.arn],
    [module.s3-dms-premigrate-assess-bucket.bucket.id, module.s3-dms-premigrate-assess-bucket.bucket.arn],
    [module.s3-json-directory-structure-bucket.bucket.id, module.s3-json-directory-structure-bucket.bucket.arn],
    [module.s3-data-bucket.bucket.id, module.s3-data-bucket.bucket.arn],
    [module.s3-fms-general-landing-bucket.bucket_id, module.s3-fms-general-landing-bucket.bucket_arn],
    [module.s3-fms-specials-landing-bucket.bucket_id, module.s3-fms-specials-landing-bucket.bucket_arn],
    [module.s3-mdss-general-landing-bucket.bucket_id, module.s3-mdss-general-landing-bucket.bucket_arn],
    [module.s3-mdss-ho-landing-bucket.bucket_id, module.s3-mdss-ho-landing-bucket.bucket_arn],
    [module.s3-mdss-specials-landing-bucket.bucket_id, module.s3-mdss-specials-landing-bucket.bucket_arn],
    [module.s3-p1-export-bucket.bucket_id, module.s3-p1-export-bucket.bucket_arn],
    [module.s3-serco-export-bucket.bucket_id, module.s3-serco-export-bucket.bucket_arn],
    [module.s3-received-files-bucket.bucket.id, module.s3-received-files-bucket.bucket.arn],
    [module.s3-quarantine-files-bucket.bucket.id, module.s3-quarantine-files-bucket.bucket.arn],
    [module.s3-clamav-definitions-bucket.bucket.id, module.s3-clamav-definitions-bucket.bucket.arn],
    [module.s3-dms-data-validation-bucket.bucket.id, module.s3-dms-data-validation-bucket.bucket.arn],
    [module.s3-glue-job-script-bucket.bucket.id, module.s3-glue-job-script-bucket.bucket.arn],
    [module.s3-dms-target-store-bucket.bucket.id, module.s3-dms-target-store-bucket.bucket.arn],
    [module.s3-create-a-derived-table-bucket.bucket.id, module.s3-create-a-derived-table-bucket.bucket.arn],
    [module.s3-raw-formatted-data-bucket.bucket.id, module.s3-raw-formatted-data-bucket.bucket.arn],
  ]
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

  bucket_policy = [
    data.aws_iam_policy_document.log_bucket_policy.json
  ]
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

data "aws_iam_policy_document" "log_bucket_policy" {
  statement {
    sid    = "AllowS3Logging"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }

    actions = ["s3:PutObject"]

    resources = ["${module.s3-logging-bucket.bucket.arn}/*"]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [for bucket_arn in local.buckets_to_log : bucket_arn[1]]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_s3_bucket_logging" "s3_buckets_logging" {
  for_each = { for bucket in local.buckets_to_log : bucket[0] => bucket }

  bucket = each.value[0]

  target_bucket = module.s3-logging-bucket.bucket.id
  target_prefix = "logs/"
  target_object_key_format {
    partitioned_prefix {
      partition_date_source = "EventTime"
    }
  }
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

  bucket_prefix      = local.is-preproduction ? "emds-p-prod-json-directory-structure-" : "${local.bucket_prefix}-json-directory-structure-"
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

  data_feed  = "fms"
  order_type = "general"

  core_shared_services_id  = local.environment_management.account_ids["core-shared-services-production"]
  local_bucket_prefix      = local.bucket_prefix
  local_tags               = local.tags
  logging_bucket           = module.s3-logging-bucket
  production_dev           = local.is-production ? "prod" : "dev"
  received_files_bucket_id = module.s3-received-files-bucket.bucket.id
  security_group_ids       = [aws_security_group.lambda_generic.id]
  subnet_ids               = data.aws_subnets.shared-public.ids

  providers = {
    aws = aws
  }
}

module "s3-fms-general-landing-bucket-iam-user" {
  source = "./modules/landing_bucket_iam_user_access/"

  data_feed  = "fms"
  order_type = "general"

  landing_bucket_arn        = module.s3-fms-general-landing-bucket.bucket_arn
  local_bucket_prefix       = local.bucket_prefix
  local_tags                = local.tags
  rotation_lambda           = module.rotate_iam_key
  rotation_lambda_role_name = aws_iam_role.rotate_iam_keys.name
}

module "s3-fms-specials-landing-bucket" {
  source = "./modules/landing_bucket/"

  data_feed  = "fms"
  order_type = "specials"

  core_shared_services_id  = local.environment_management.account_ids["core-shared-services-production"]
  local_bucket_prefix      = local.bucket_prefix
  local_tags               = local.tags
  logging_bucket           = module.s3-logging-bucket
  production_dev           = local.is-production ? "prod" : "dev"
  received_files_bucket_id = module.s3-received-files-bucket.bucket.id
  security_group_ids       = [aws_security_group.lambda_generic.id]
  subnet_ids               = data.aws_subnets.shared-public.ids

  providers = {
    aws = aws
  }
}

module "s3-fms-specials-landing-bucket-iam-user" {
  source = "./modules/landing_bucket_iam_user_access/"

  data_feed  = "fms"
  order_type = "specials"

  landing_bucket_arn        = module.s3-fms-specials-landing-bucket.bucket_arn
  local_bucket_prefix       = local.bucket_prefix
  local_tags                = local.tags
  rotation_lambda           = module.rotate_iam_key
  rotation_lambda_role_name = aws_iam_role.rotate_iam_keys.name
}

# ------------------------------------------------------------------------
# Landing bucket MDSS
# ------------------------------------------------------------------------

module "s3-mdss-general-landing-bucket" {
  source = "./modules/landing_bucket/"

  data_feed  = "mdss"
  order_type = "general"

  core_shared_services_id   = local.environment_management.account_ids["core-shared-services-production"]
  cross_account_access_role = local.mdss_supplier_account_mapping[local.environment]
  local_bucket_prefix       = local.bucket_prefix
  local_tags                = local.tags
  logging_bucket            = module.s3-logging-bucket
  production_dev            = local.is-production ? "prod" : "dev"
  received_files_bucket_id  = module.s3-received-files-bucket.bucket.id
  subnet_ids                = data.aws_subnets.shared-public.ids
  security_group_ids        = [aws_security_group.lambda_generic.id]

  providers = {
    aws = aws
  }
}

module "s3-mdss-ho-landing-bucket" {
  source = "./modules/landing_bucket/"

  data_feed  = "mdss"
  order_type = "ho"

  core_shared_services_id   = local.environment_management.account_ids["core-shared-services-production"]
  cross_account_access_role = local.mdss_supplier_account_mapping[local.environment]
  local_bucket_prefix       = local.bucket_prefix
  local_tags                = local.tags
  logging_bucket            = module.s3-logging-bucket
  production_dev            = local.is-production ? "prod" : "dev"
  received_files_bucket_id  = module.s3-received-files-bucket.bucket.id
  security_group_ids        = [aws_security_group.lambda_generic.id]
  subnet_ids                = data.aws_subnets.shared-public.ids

  providers = {
    aws = aws
  }
}

module "s3-mdss-specials-landing-bucket" {
  source = "./modules/landing_bucket/"

  data_feed  = "mdss"
  order_type = "specials"

  core_shared_services_id   = local.environment_management.account_ids["core-shared-services-production"]
  cross_account_access_role = local.mdss_supplier_account_mapping[local.environment]
  local_bucket_prefix       = local.bucket_prefix
  local_tags                = local.tags
  logging_bucket            = module.s3-logging-bucket
  production_dev            = local.is-production ? "prod" : "dev"
  received_files_bucket_id  = module.s3-received-files-bucket.bucket.id
  security_group_ids        = [aws_security_group.lambda_generic.id]
  subnet_ids                = data.aws_subnets.shared-public.ids

  providers = {
    aws = aws
  }
}

# ------------------------------------------------------------------------
# Export buckets
# ------------------------------------------------------------------------

module "s3-p1-export-bucket" {
  source = "./modules/export_bucket_push/"

  core_shared_services_id = local.environment_management.account_ids["core-shared-services-production"]
  destination_bucket_id   = "tct-339712706964-prearrivals"
  export_destination      = "p1"
  local_bucket_prefix     = local.bucket_prefix
  local_tags              = local.tags
  logging_bucket          = module.s3-logging-bucket
  production_dev          = local.is-production ? "prod" : "dev"
  security_group_ids      = [aws_security_group.lambda_generic.id]
  subnet_ids              = data.aws_subnets.shared-public.ids

  providers = {
    aws = aws
  }
}

module "s3-serco-export-bucket" {
  source = "./modules/export_bucket_presigned_url/"

  allowed_ips         = ["137.83.234.77/32"]
  export_destination  = "serco-historic"
  local_bucket_prefix = local.bucket_prefix
  local_tags          = local.tags
  logging_bucket      = module.s3-logging-bucket

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
  #checkov:skip=CKV_AWS_145
  #checkov:skip=CKV_AWS_144
  #checkov:skip=CKV2_AWS_65
  #checkov:skip=CKV2_AWS_62
  #checkov:skip=CKV_AWS_18
  #checkov:skip=CKV2_AWS_61
  bucket_prefix = "em-data-store-"
  #checkov:skip=CKV_AWS_21:Legacy bucket to be deleted
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
  #checkov:skip=CKV2_AWS_65
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



module "s3-create-a-derived-table-bucket" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=f759060"

  bucket_name        = "${local.bucket_prefix}-cadt"
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


# ------------------------------------------------------------------------
# Raw converted store bucket
# ------------------------------------------------------------------------

module "s3-raw-formatted-data-bucket" {
  source             = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=f759060"
  bucket_prefix      = "${local.bucket_prefix}-raw-formatted-data-"
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
