locals {

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
        "s3:PutObject",
        "s3:PutObjectAcl",
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

    AllEnvironmentsWriteAccessBucketPolicy = {
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:ListBucket",
        "s3:PutObject",
        "s3:PutObjectAcl",
      ]
      principals = {
        type = "AWS"
        identifiers = [for account_name in var.environment.account_names :
          var.environment.account_root_arns[account_name]
        ]
      }
    }

    AllEnvironmentsWriteAndDeleteAccessBucketPolicy = {
      effect = "Allow"
      actions = [
        "s3:GetObject",
        "s3:ListBucket",
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:DeleteObject",
      ]
      principals = {
        type = "AWS"
        identifiers = [for account_name in var.environment.account_names :
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
          "s3:ListBucket",
        ]
      }
    ]
    EC2S3BucketWriteAccessPolicy = [
      {
        effect = "Allow"
        actions = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:PutObjectAcl",
        ]
      }
    ]
    EC2S3BucketWriteAndDeleteAccessPolicy = [
      {
        effect = "Allow"
        actions = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:DeleteObject",
        ]
      }
    ]
  }
}
