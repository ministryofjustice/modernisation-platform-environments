locals {

  devtest_or_prodpreprod = var.environment.environment == "development" || var.environment.environment == "test" ? "devtest" : "prodpreprod"
  shared_s3_name_prefix  = substr("${local.devtest_or_prodpreprod}-${var.environment.application_name}-", 0, 37)

  requested_s3_iam_policies = var.options.s3_iam_policies != null ? {
    for key, value in local.s3_iam_policies : key => value if contains(var.options.s3_iam_policies, key)
  } : local.s3_iam_policies

  s3_buckets = merge(

    # if enable_shared_s3 set, create a bucket in test and production which can be used by dev and test / preprod and prod respectively
    var.options.enable_shared_s3 && var.environment.environment == "production" ? {
      (local.shared_s3_name_prefix) = {
        bucket_policy_v2 = [
          local.s3_bucket_policies.ImageBuilderWriteAccessBucketPolicy,
          local.s3_bucket_policies.ProdPreprodEnvironmentsWriteAccessBucketPolicy
        ]
        custom_kms_key = var.environment.kms_keys["general"].arn
        iam_policies   = local.requested_s3_iam_policies
      }
    } : {},
    var.options.enable_shared_s3 && var.environment.environment == "test" ? {
      (local.shared_s3_name_prefix) = {
        bucket_policy_v2 = [
          local.s3_bucket_policies.ImageBuilderWriteAccessBucketPolicy,
          local.s3_bucket_policies.DevTestEnvironmentsWriteAndDeleteAccessBucketPolicy
        ]
        custom_kms_key = var.environment.kms_keys["general"].arn
        iam_policies   = local.requested_s3_iam_policies
      }
    } : {},

    # If db_backup_s3 enabled, create db_backups in all environments.
    # Dev and Test can both access each other: Preprod can access prod but not vice-versa
    var.options.db_backup_s3 && var.environment.environment == "production" && !var.options.db_backup_more_permissions ? { "prod-${var.environment.application_name}-db-backup-bucket-" = {
      bucket_policy_v2 = [
        local.s3_bucket_policies.PreprodReadOnlyAccessBucketPolicy,
      ]
      custom_kms_key = var.environment.kms_keys["general"].arn
      iam_policies   = local.requested_s3_iam_policies
    } } : {},
    var.options.db_backup_s3 && var.environment.environment == "production" && var.options.db_backup_more_permissions ? { "prod-${var.environment.application_name}-db-backup-bucket-" = {
      bucket_policy_v2 = [
        local.s3_bucket_policies.ProdPreprodReadWriteDeleteBucketPolicy
      ]
      custom_kms_key = var.environment.kms_keys["general"].arn
      iam_policies   = local.requested_s3_iam_policies
    } } : {},
    var.options.db_backup_s3 && var.environment.environment == "preproduction" ? { "preprod-${var.environment.application_name}-db-backup-bucket-" = {
      custom_kms_key = var.environment.kms_keys["general"].arn
      iam_policies   = local.s3_iam_policies
    } } : {},
    var.options.db_backup_s3 && var.environment.environment == "test" ? { "devtest-${var.environment.application_name}-db-backup-bucket-" = {
      bucket_policy_v2 = [
        local.s3_bucket_policies.DevTestEnvironmentsReadOnlyAccessBucketPolicy
      ]
      custom_kms_key = var.environment.kms_keys["general"].arn
      iam_policies   = local.requested_s3_iam_policies
    } } : {},
    var.options.db_backup_s3 && var.environment.environment == "development" ? { "dev-${var.environment.application_name}-db-backup-bucket-" = {
      bucket_policy_v2 = [
        local.s3_bucket_policies.DevTestEnvironmentsReadOnlyAccessBucketPolicy
      ]
      custom_kms_key = var.environment.kms_keys["general"].arn
      iam_policies   = local.requested_s3_iam_policies
    } } : {},
  )

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
