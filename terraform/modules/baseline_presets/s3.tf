locals {

  requested_s3_iam_policies = var.options.s3_iam_policies != null ? {
    for key, value in local.s3_iam_policies : key => value if contains(var.options.s3_iam_policies, key)
  } : local.s3_iam_policies

  s3_environments_specific = {
    development = {
      db_backup_bucket_name    = coalesce(var.options.db_backup_bucket_name, substr("dev-${var.environment.application_name}-db-backup-bucket-", 0, 37))
      db_backup_bucket_policy  = [local.s3_bucket_policies.DevTestEnvironmentsReadOnlyAccessBucketPolicy]
      db_backup_lifecycle_rule = local.s3_lifecycle_rules[coalesce(var.options.db_backup_lifecycle_rule, "rman_backup_one_month")]
      s3_bucket_name           = coalesce(var.options.s3_bucket_name, "s3-bucket")
      s3_lifecycle_rule        = local.s3_lifecycle_rules["general_purpose_three_months"]
      shared_bucket_name       = substr("devtest-${var.environment.application_name}-", 0, 37)
      shared_bucket_policy     = [local.s3_bucket_policies.DevTestEnvironmentsWriteAndDeleteAccessBucketPolicy]
      shared_lifecycle_rule    = local.s3_lifecycle_rules["general_purpose_three_months"]
    }
    test = {
      db_backup_bucket_name    = coalesce(var.options.db_backup_bucket_name, substr("devtest-${var.environment.application_name}-db-backup-bucket-", 0, 37))
      db_backup_bucket_policy  = [local.s3_bucket_policies.DevTestEnvironmentsReadOnlyAccessBucketPolicy]
      db_backup_lifecycle_rule = local.s3_lifecycle_rules[coalesce(var.options.db_backup_lifecycle_rule, "rman_backup_one_month")]
      s3_bucket_name           = coalesce(var.options.s3_bucket_name, "s3-bucket")
      s3_lifecycle_rule        = local.s3_lifecycle_rules["general_purpose_three_months"]
      shared_bucket_name       = substr("devtest-${var.environment.application_name}-", 0, 37)
      shared_bucket_policy     = [local.s3_bucket_policies.DevTestEnvironmentsWriteAndDeleteAccessBucketPolicy]
      shared_lifecycle_rule    = local.s3_lifecycle_rules["general_purpose_three_months"]
    }
    preproduction = {
      db_backup_bucket_name    = coalesce(var.options.db_backup_bucket_name, substr("preprod-${var.environment.application_name}-db-backup-bucket-", 0, 37))
      db_backup_bucket_policy  = null
      db_backup_lifecycle_rule = local.s3_lifecycle_rules[coalesce(var.options.db_backup_lifecycle_rule, "rman_backup_one_month")]
      s3_bucket_name           = coalesce(var.options.s3_bucket_name, "s3-bucket")
      s3_lifecycle_rule        = local.s3_lifecycle_rules["general_purpose_three_months"]
      shared_bucket_name       = substr("prodpreprod-${var.environment.application_name}-", 0, 37)
      shared_bucket_policy     = [local.s3_bucket_policies.ProdPreprodEnvironmentsWriteAccessBucketPolicy]
      shared_lifecycle_rule    = local.s3_lifecycle_rules["general_purpose_three_months"]
    }
    production = {
      db_backup_bucket_name    = coalesce(var.options.db_backup_bucket_name, substr("prod-${var.environment.application_name}-db-backup-bucket-", 0, 37))
      db_backup_bucket_policy  = [var.options.db_backup_more_permissions ? local.s3_bucket_policies.ProdPreprodReadWriteDeleteBucketPolicy : local.s3_bucket_policies.ProdPreprodEnvironmentsReadOnlyAccessBucketPolicy]
      db_backup_lifecycle_rule = local.s3_lifecycle_rules[coalesce(var.options.db_backup_lifecycle_rule, "rman_backup_one_year")]
      s3_bucket_name           = coalesce(var.options.s3_bucket_name, "s3-bucket")
      s3_lifecycle_rule        = local.s3_lifecycle_rules["general_purpose_one_year"]
      shared_bucket_name       = substr("prodpreprod-${var.environment.application_name}-", 0, 37)
      shared_bucket_policy     = [local.s3_bucket_policies.ProdPreprodEnvironmentsWriteAccessBucketPolicy]
      shared_lifecycle_rule    = local.s3_lifecycle_rules["general_purpose_one_year"]
    }
  }
  s3_environment_specific = merge(local.s3_environments_specific[var.environment.environment], {
    software_bucket_name = coalesce(var.options.software_bucket_name, substr("${var.environment.application_name}-software", 0, 37))
    software_bucket_policy = [
      local.s3_bucket_policies.ImageBuilderWriteAccessBucketPolicy,
      local.s3_bucket_policies.AllEnvironmentsWriteAccessBucketPolicy,
    ]
  })

  s3_buckets_filter = flatten([
    var.options.enable_s3_db_backup_bucket ? [local.s3_environment_specific.db_backup_bucket_name] : [],
    var.options.enable_s3_bucket ? [local.s3_environment_specific.s3_bucket_name] : [],
    var.options.enable_s3_shared_bucket && contains(["test", "production"], var.environment.environment) ? [local.s3_environment_specific.shared_bucket_name] : [],
    var.options.enable_s3_software_bucket && var.environment.environment == "test" ? [local.s3_environment_specific.software_bucket_name] : []
  ])

  s3_buckets = {
    (local.s3_environment_specific.s3_bucket_name) = {
      iam_policies       = local.requested_s3_iam_policies
      lifecycle_rule     = [local.s3_environment_specific.s3_lifecycle_rule]
      ownership_controls = "BucketOwnerPreferred"
      tags = {
        backup = "false"
      }
    }
    (local.s3_environment_specific.db_backup_bucket_name) = {
      bucket_policy_v2   = local.s3_environment_specific.db_backup_bucket_policy
      custom_kms_key     = var.environment.kms_keys["general"].arn
      iam_policies       = local.requested_s3_iam_policies
      lifecycle_rule     = [local.s3_environment_specific.db_backup_lifecycle_rule]
      ownership_controls = "BucketOwnerPreferred"
      tags = {
        backup = "false"
      }
    }
    (local.s3_environment_specific.shared_bucket_name) = {
      bucket_policy_v2   = local.s3_environment_specific.shared_bucket_policy
      custom_kms_key     = var.environment.kms_keys["general"].arn
      iam_policies       = local.requested_s3_iam_policies
      lifecycle_rule     = [local.s3_environment_specific.shared_lifecycle_rule]
      ownership_controls = "BucketOwnerPreferred"
      tags = {
        backup = "false"
      }
    }
    (local.s3_environment_specific.software_bucket_name) = {
      bucket_policy_v2   = local.s3_environment_specific.software_bucket_policy
      custom_kms_key     = var.environment.kms_keys["general"].arn
      iam_policies       = local.requested_s3_iam_policies
      lifecycle_rule     = [local.s3_lifecycle_rules.software]
      ownership_controls = "BucketOwnerPreferred"
      tags = {
        backup = "false"
      }
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

  # STANDARD_IA: transition days must be >= 30
  # GLACIER:     minimum storage period of 90 days
  s3_lifecycle_rules = {

    # the default from modernisation-platform-terraform-s3-bucket module
    default = {
      enabled = "Enabled"
      id      = "main"
      prefix  = ""
      tags = {
        rule      = "log"
        autoclean = "true"
      }

      transition = [
        { days = 90, storage_class = "STANDARD_IA" },
        { days = 365, storage_class = "GLACIER" }
      ]
      expiration = { days = 730 }
      noncurrent_version_transition = [
        { days = 90, storage_class = "STANDARD_IA" },
        { days = 365, storage_class = "GLACIER" }
      ]
      noncurrent_version_expiration = { days = 730 }
    }

    general_purpose_three_months = {
      enabled = "Enabled"
      id      = "general_purpose_three_months"
      prefix  = ""
      tags = {
        rule      = "log"
        autoclean = "true"
      }

      transition                    = [{ days = 30, storage_class = "STANDARD_IA" }]
      expiration                    = { days = 90 }
      noncurrent_version_transition = []
      noncurrent_version_expiration = { days = 7 }
    }

    general_purpose_one_year = {
      enabled = "Enabled"
      id      = "general_purpose_one_year"
      prefix  = ""
      tags = {
        rule      = "log"
        autoclean = "true"
      }

      transition                    = [{ days = 30, storage_class = "STANDARD_IA" }]
      expiration                    = { days = 365 }
      noncurrent_version_transition = []
      noncurrent_version_expiration = { days = 7 }
    }


    ninety_day_standard_ia_ten_year_expiry = {
      enabled = "Enabled"
      id      = "ninety_day_standard_ia_ten_year_expiry"
      prefix  = ""
      tags = {
        rule      = "log"
        autoclean = "true"
      }

      transition = [{ days = 90, storage_class = "STANDARD_IA" }]
      expiration = { days = 3650 }
      noncurrent_version_transition = [
        { days = 90, storage_class = "STANDARD_IA" },
        { days = 365, storage_class = "GLACIER" },
      ]
      noncurrent_version_expiration = { days = 3650 }
    }

    rman_backup_one_month = {
      enabled = "Enabled"
      id      = "rman_backup_one_month"
      prefix  = ""
      tags = {
        rule      = "log"
        autoclean = "true"
      }

      transition                    = [{ days = 30, storage_class = "STANDARD_IA" }]
      expiration                    = { days = 60 } # rman backup should delete backups after 1 month anyway
      noncurrent_version_transition = []
      noncurrent_version_expiration = { days = 7 }
    }

    rman_backup_one_year = {
      enabled = "Enabled"
      id      = "rman_backup_one_year"
      prefix  = ""
      tags = {
        rule      = "log"
        autoclean = "true"
      }

      # rman backup cross-checks historic backups so don't use Glacier
      transition                    = [{ days = 30, storage_class = "STANDARD_IA" }]
      expiration                    = { days = 400 } # rman backup should delete backups after 1 year anyway
      noncurrent_version_transition = []
      noncurrent_version_expiration = { days = 7 }
    }

    software = {
      enabled = "Enabled"
      id      = "software"
      prefix  = ""
      tags = {
        rule      = "log"
        autoclean = "true"
      }

      transition                    = [{ days = 30, storage_class = "STANDARD_IA" }]
      expiration                    = { days = 36500 } # have to put something to keep terraform happy
      noncurrent_version_transition = [{ days = 30, storage_class = "GLACIER" }]
      noncurrent_version_expiration = { days = 365 }
    }
  }
}
