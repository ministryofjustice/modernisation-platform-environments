locals {

  requested_s3_iam_policies = var.options.s3_iam_policies != null ? {
    for key, value in local.s3_iam_policies : key => value if contains(var.options.s3_iam_policies, key)
  } : local.s3_iam_policies

  s3_environments_specific = {
    development = {
      db_backup_bucket_name   = coalesce(var.options.db_backup_bucket_name, substr("dev-${var.environment.application_name}-db-backup-bucket-", 0, 37))
      db_backup_bucket_policy = [local.s3_bucket_policies.DevTestEnvironmentsReadOnlyAccessBucketPolicy]
      shared_bucket_name      = substr("devtest-${var.environment.application_name}-", 0, 37)
      shared_bucket_policy = [
        local.s3_bucket_policies.ImageBuilderWriteAccessBucketPolicy,
        local.s3_bucket_policies.DevTestEnvironmentsWriteAndDeleteAccessBucketPolicy,
      ]
    }
    test = {
      db_backup_bucket_name   = coalesce(var.options.db_backup_bucket_name, substr("devtest-${var.environment.application_name}-db-backup-bucket-", 0, 37))
      db_backup_bucket_policy = [local.s3_bucket_policies.DevTestEnvironmentsReadOnlyAccessBucketPolicy]
      shared_bucket_name      = substr("devtest-${var.environment.application_name}-", 0, 37)
      shared_bucket_policy = [
        local.s3_bucket_policies.ImageBuilderWriteAccessBucketPolicy,
        local.s3_bucket_policies.DevTestEnvironmentsWriteAndDeleteAccessBucketPolicy,
      ]
    }
    preproduction = {
      db_backup_bucket_name   = coalesce(var.options.db_backup_bucket_name, substr("preprod-${var.environment.application_name}-db-backup-bucket-", 0, 37))
      db_backup_bucket_policy = null
      shared_bucket_name      = substr("prodpreprod-${var.environment.application_name}-", 0, 37)
      shared_bucket_policy = [
        local.s3_bucket_policies.ImageBuilderWriteAccessBucketPolicy,
        local.s3_bucket_policies.ProdPreprodEnvironmentsWriteAccessBucketPolicy,
      ]
    }
    production = {
      db_backup_bucket_name   = coalesce(var.options.db_backup_bucket_name, substr("prod-${var.environment.application_name}-db-backup-bucket", 0, 37))
      db_backup_bucket_policy = [var.options.db_backup_more_permissions ? local.s3_bucket_policies.ProdPreprodReadWriteDeleteBucketPolicy : local.s3_bucket_policies.ProdPreprodEnvironmentsReadOnlyAccessBucketPolicy]
      shared_bucket_name      = substr("prodpreprod-${var.environment.application_name}-", 0, 37)
      shared_bucket_policy = [
        local.s3_bucket_policies.ImageBuilderWriteAccessBucketPolicy,
        local.s3_bucket_policies.ProdPreprodEnvironmentsWriteAccessBucketPolicy,
      ]
    }
  }
  s3_environment_specific = local.s3_environments_specific[var.environment.environment]

  s3_buckets_filter = flatten([
    var.options.enable_s3_db_backup_bucket ? [local.s3_environment_specific.db_backup_bucket_name] : [],
    var.options.enable_s3_bucket ? ["s3-bucket"] : [],
    var.options.enable_s3_shared_bucket && contains(["test", "production"], var.environment.environment) ? [local.s3_environment_specific.shared_bucket_name] : [],
  ])

  s3_buckets = {
    s3-bucket = {
      iam_policies   = local.requested_s3_iam_policies
      lifecycle_rule = [local.s3_lifecycle_rules.default]
    }
    (local.s3_environment_specific.db_backup_bucket_name) = {
      bucket_policy_v2 = local.s3_environment_specific.db_backup_bucket_policy
      custom_kms_key   = var.environment.kms_keys["general"].arn
      iam_policies     = local.requested_s3_iam_policies
      lifecycle_rule   = [local.s3_lifecycle_rules.default]
    }
    (local.s3_environment_specific.shared_bucket_name) = {
      bucket_policy_v2 = local.s3_environment_specific.shared_bucket_policy
      custom_kms_key   = var.environment.kms_keys["general"].arn
      iam_policies     = local.requested_s3_iam_policies
      lifecycle_rule   = [local.s3_lifecycle_rules.default]
    }
  }

  s3_bucket_policies = {
    ImageBuilderWriteAccessBucketPolicy                 = local.iam_policy_statements_s3.S3ReadWriteCoreSharedServicesProduction[0]
    AllEnvironmentsReadOnlyAccessBucketPolicy           = local.iam_policy_statements_s3.S3ReadAllEnvironments[0]
    PreprodReadOnlyAccessBucketPolicy                   = local.iam_policy_statements_s3.S3ReadOnlyPreprod[0]
    ProdPreprodReadWriteDeleteBucketPolicy              = local.iam_policy_statements_s3.S3ReadWriteDeleteProdPreprod[0]
    AllEnvironmentsWriteAccessBucketPolicy              = local.iam_policy_statements_s3.S3ReadWriteAllEnvironments[0]
    ProdPreprodEnvironmentsReadOnlyAccessBucketPolicy   = local.iam_policy_statements_s3.S3ReadProdPreprod[0]
    ProdPreprodEnvironmentsWriteAccessBucketPolicy      = local.iam_policy_statements_s3.S3ReadWriteProdPreprod[0]
    AllEnvironmentsWriteAndDeleteAccessBucketPolicy     = local.iam_policy_statements_s3.S3ReadWriteDeleteAllEnvironments[0]
    DevTestEnvironmentsReadOnlyAccessBucketPolicy       = local.iam_policy_statements_s3.S3ReadDevTest[0]
    DevTestEnvironmentsWriteAndDeleteAccessBucketPolicy = local.iam_policy_statements_s3.S3ReadWriteDeleteDevTest[0]
    DevelopmentReadOnlyAccessBucketPolicy               = local.iam_policy_statements_s3.S3ReadDev[0]
  }

  s3_iam_policies = {
    EC2S3BucketReadOnlyAccessPolicy       = local.iam_policy_statements_s3.S3Read
    EC2S3BucketWriteAccessPolicy          = local.iam_policy_statements_s3.S3Write
    EC2S3BucketWriteAndDeleteAccessPolicy = local.iam_policy_statements_s3.S3ReadWriteDelete
  }

  s3_lifecycle_rules = {

    default = {
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
        },
        {
          days          = 365
          storage_class = "GLACIER"
        }
      ]
      noncurrent_version_expiration = {
        days = 730
      }
    }

    ninety_day_standard_ia_ten_year_expiry = {
      id      = "ninety_day_standard_ia_ten_year_expiry"
      enabled = "Enabled"
      prefix  = ""
      tags = {
        rule      = "log"
        autoclean = "true"
      }
      transition = [{
        days          = 90
        storage_class = "STANDARD_IA"
      }]
      expiration = {
        days = 3650
      }
      noncurrent_version_transition = [{
        days          = 90
        storage_class = "STANDARD_IA"
        }, {
        days          = 365
        storage_class = "GLACIER"
      }]
      noncurrent_version_expiration = {
        days = 3650
      }
    }
  }
}
