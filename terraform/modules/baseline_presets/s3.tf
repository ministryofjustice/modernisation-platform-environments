locals {

  s3_buckets = merge(
    var.options.enable_shared_s3 && var.environment.environment == "production" ? { "prodpreprod-${var.environment.application_name}-" = {
      bucket_policy_v2 = [
        local.s3_bucket_policies.ImageBuilderWriteAccessBucketPolicy,
        local.s3_bucket_policies.ProdPreprodEnvironmentsWriteAccessBucketPolicy
      ]
      iam_policies = local.s3_iam_policies
    } } : {},
    var.options.enable_shared_s3 && var.environment.environment == "test" ? { "devtest-${var.environment.application_name}-" = {
      bucket_policy_v2 = [
        local.s3_bucket_policies.ImageBuilderWriteAccessBucketPolicy,
        local.s3_bucket_policies.DevTestEnvironmentsWriteAndDeleteAccessBucketPolicy
      ]
      iam_policies = local.s3_iam_policies
    } } : {},
    var.options.db_backup_s3 && var.environment.environment == "production" ? { "prod-${var.environment.application_name}-db-backup-bucket-" = {
      bucket_policy_v2 = [
        local.s3_bucket_policies.PreprodReadOnlyAccessBucketPolicy
      ]
      iam_policies = local.s3_iam_policies
    } } : {},
    var.options.db_backup_s3 && var.environment.environment == "preproduction" ? { "preprod-${var.environment.application_name}-db-backup-bucket-" = {
      bucket_policy_v2 = [
        local.s3_bucket_policies.ProdPreprodEnvironmentsWriteAccessBucketPolicy
      ]
      iam_policies = local.s3_iam_policies
    } } : {},
    var.options.db_backup_s3 && var.options.enable_shared_s3 && var.environment.environment == "test" ? { "devtest-${var.environment.application_name}-db-backup-bucket-" = {
      bucket_policy_v2 = [
        local.s3_bucket_policies.DevTestEnvironmentsWriteAndDeleteAccessBucketPolicy
      ]
      iam_policies = local.s3_iam_policies
    } } : {}
  )

  s3_bucket_policies = {

    ImageBuilderReadOnlyAccessBucketPolicy = {
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:ListBucket"
      ]
      principals = {
        type = "AWS"
        identifiers = [
          var.environment.account_root_arns["core-shared-services-production"]
        ]
      }
    }

    ImageBuilderWriteAccessBucketPolicy = {
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:GetObjectTagging",
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:PutObjectTagging",
        "s3:ListBucket"
      ]
      principals = {
        type = "AWS"
        identifiers = [
          var.environment.account_root_arns["core-shared-services-production"]
        ]
      }
    }

    AllEnvironmentsReadOnlyAccessBucketPolicy = {
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:GetObjectTagging",
        "s3:ListBucket"
      ]
      principals = {
        type = "AWS"
        identifiers = [
          for account_name in var.environment.account_names :
          var.environment.account_root_arns[account_name]
        ]
      }
    }

    PreprodReadOnlyAccessBucketPolicy = {
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:GetObjectTagging",
        "s3:ListBucket"
      ]
      principals = {
        type = "AWS"
        identifiers = [
          var.environment.account_root_arns["${var.environment.application_name}-preproduction"]
        ]
      }
    }

    AllEnvironmentsWriteAccessBucketPolicy = {
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:GetObjectTagging",
        "s3:ListBucket",
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:PutObjectTagging",
        "s3:RestoreObject",
      ]
      principals = {
        type = "AWS"
        identifiers = [for account_name in var.environment.account_names :
          var.environment.account_root_arns[account_name]
        ]
      }
    }

    ProdPreprodEnvironmentsReadOnlyAccessBucketPolicy = {
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:GetObjectTagging",
        "s3:ListBucket",
      ]
      principals = {
        type = "AWS"
        identifiers = [for account_name in var.environment.prodpreprod_account_names :
          var.environment.account_root_arns[account_name]
        ]
      }
    }

    ProdPreprodEnvironmentsWriteAccessBucketPolicy = {
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:GetObjectTagging",
        "s3:ListBucket",
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:PutObjectTagging",
        "s3:RestoreObject",
      ]
      principals = {
        type = "AWS"
        identifiers = [for account_name in var.environment.prodpreprod_account_names :
          var.environment.account_root_arns[account_name]
        ]
      }
    }

    AllEnvironmentsWriteAndDeleteAccessBucketPolicy = {
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:GetObjectTagging",
        "s3:ListBucket",
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:PutObjectTagging",
        "s3:DeleteObject",
        "s3:RestoreObject",
      ]
      principals = {
        type = "AWS"
        identifiers = [for account_name in var.environment.account_names :
          var.environment.account_root_arns[account_name]
        ]
      }
    }

    DevTestEnvironmentsReadOnlyAccessBucketPolicy = {
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:GetObjectTagging",
        "s3:ListBucket",
      ]
      principals = {
        type = "AWS"
        identifiers = [for account_name in var.environment.devtest_account_names :
          var.environment.account_root_arns[account_name]
        ]
      }
    }

    DevTestEnvironmentsWriteAndDeleteAccessBucketPolicy = {
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:GetObjectTagging",
        "s3:ListBucket",
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:PutObjectTagging",
        "s3:DeleteObject",
        "s3:DeleteObjectVersion",
        "s3:RestoreObject",
      ]
      principals = {
        type = "AWS"
        identifiers = [for account_name in var.environment.devtest_account_names :
          var.environment.account_root_arns[account_name]
        ]
      }
    }
  }

  s3_iam_policies = {
    EC2S3BucketReadOnlyAccessPolicy = [
      {
        effect = "Allow"
        actions = [
          "s3:GetObject",
          "s3:GetObjectTagging",
          "s3:ListBucket",
        ]
      }
    ]
    EC2S3BucketWriteAccessPolicy = [
      {
        effect = "Allow"
        actions = [
          "s3:GetObject",
          "s3:GetObjectTagging",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:PutObjectTagging",
          "s3:RestoreObject",
        ]
      }
    ]
    EC2S3BucketWriteAndDeleteAccessPolicy = [
      {
        effect = "Allow"
        actions = [
          "s3:GetObject",
          "s3:GetObjectTagging",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:PutObjectTagging",
          "s3:DeleteObject",
          "s3:RestoreObject",
        ]
      }
    ]
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
