locals {

  iam_policy_statements_s3 = {


    # for image builder
    S3ReadWriteCoreSharedServicesProduction = [
      {
        sid    = "S3ReadWriteCoreSharedServicesProduction"
        effect = "Allow"
        actions = [
          "s3:Get*",
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
    ]

    S3ReadAllEnvironments = [
      {
        sid    = "S3ReadAllEnvironments"
        effect = "Allow"
        actions = [
          "s3:Get*",
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
    ]

    S3ReadOnlyPreprod = [
      {
        sid    = "S3ReadOnlyPreprod"
        effect = "Allow"
        actions = [
          "s3:Get*",
          "s3:ListBucket"
        ]
        principals = {
          type = "AWS"
          identifiers = [
            var.environment.account_root_arns["${var.environment.application_name}-preproduction"]
          ]
        }
      }
    ]

    S3ReadWriteDeleteProdPreprod = [
      {
        sid    = "S3WritePreprod"
        effect = "Allow"
        actions = [
          "s3:Get*",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:PutObjectTagging",
          "s3:DeleteObject",
          "s3:RestoreObject",
        ]
        principals = {
          type = "AWS"
          identifiers = [for account_name in var.environment.prodpreprod_account_names :
            var.environment.account_root_arns[account_name]
          ]
        }
      }
    ]

    S3ReadWriteAllEnvironments = [
      {
        sid    = "S3ReadWriteAllEnvironments"
        effect = "Allow"
        actions = [
          "s3:Get*",
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
    ]

    S3ReadProdPreprod = [
      {
        sid    = "S3ReadProdPreprod"
        effect = "Allow"
        actions = [
          "s3:Get*",
          "s3:ListBucket",
        ]
        principals = {
          type = "AWS"
          identifiers = [for account_name in var.environment.prodpreprod_account_names :
            var.environment.account_root_arns[account_name]
          ]
        }
      }
    ]

    S3ReadWriteProdPreprod = [
      {
        sid    = "S3ReadWriteProdPreprod"
        effect = "Allow"
        actions = [
          "s3:Get*",
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
    ]

    S3ReadWriteDeleteAllEnvironments = [
      {
        sid    = "S3ReadWriteDeleteAllEnvironments"
        effect = "Allow"
        actions = [
          "s3:Get*",
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
    ]

    S3ReadDevTest = [
      {
        sid    = "S3ReadDevTest"
        effect = "Allow"
        actions = [
          "s3:Get*",
          "s3:ListBucket",
        ]
        principals = {
          type = "AWS"
          identifiers = [for account_name in var.environment.devtest_account_names :
            var.environment.account_root_arns[account_name]
          ]
        }
      }
    ]

    S3ReadWriteDeleteDevTest = [
      {
        sid    = "S3ReadWriteDeleteDevTest"
        effect = "Allow"
        actions = [
          "s3:Get*",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:PutObjectTagging",
          "s3:DeleteObject",
          "s3:RestoreObject",
        ]
        principals = {
          type = "AWS"
          identifiers = [for account_name in var.environment.devtest_account_names :
            var.environment.account_root_arns[account_name]
          ]
        }
      }
    ]

    S3ReadDev = [
      {
        sid    = "S3ReadDev"
        effect = "Allow"
        actions = [
          "s3:Get*",
          "s3:ListBucket"
        ]
        principals = {
          type = "AWS"
          identifiers = [
            try(var.environment.account_root_arns["${var.environment.application_name}-development"], "${var.environment.application_name}-not-found")
          ]
        }
      }
    ]

    S3Read = [
      {
        effect = "Allow"
        actions = [
          "s3:Get*",
          "s3:ListBucket",
        ]
      }
    ]
    S3Write = [
      {
        effect = "Allow"
        actions = [
          "s3:Get*",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:PutObjectTagging",
          "s3:RestoreObject",
        ]
      }
    ]
    S3ReadWriteDelete = [
      {
        effect = "Allow"
        actions = [
          "s3:Get*",
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

}
