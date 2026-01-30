terraform {
  required_providers {
    aws = {
      version = "~>6.21, != 5.86.0"
      source  = "hashicorp/aws"
    }
  }
  required_version = "~> 1.0"
}

locals {
  bucket_policy_v2 = var.cross_account_access_role != null ? [
    {
      sid    = "CrossAccountAccess"
      effect = "Allow"
      actions = [
        "s3:PutObject",
        "s3:PutObjectAcl",
      ]
      principals = {
        identifiers = ["arn:aws:iam::${var.cross_account_access_role.account_number}:role/${var.cross_account_access_role.role_name}"]
        type        = "AWS"
      }
    }
  ] : []
  cross_account_bucket_policy = var.cross_account ? [
    {
      sid    = "AllowCrossAccountWritesFromLambda"
      effect = "Allow"
      principals = {
        type        = "AWS"
        identifiers = ["arn:aws:iam::${var.cross_account_id}:role/AWSS3BucketReplication${var.data_feed}${var.order_type}"]
      }
      actions = [
        "s3:ReplicateObject",
        "s3:ReplicateTags",
        "s3:GetBucketVersioning",
        "s3:PutBucketVersioning",
        "s3:ObjectOwnerOverrideToBucketOwner"
      ]
      resources = ["${module.this-bucket.bucket.arn}/*", module.this-bucket.bucket.arn]
    }
  ] : []
  bucket_policy = flatten([local.cross_account_bucket_policy, local.bucket_policy_v2])
  kms_grant_mdss = var.cross_account_access_role != null ? {
    cross_account_access_role = {
      grantee_principal = nonsensitive("arn:aws:iam::${var.cross_account_access_role.account_number}:role/${var.cross_account_access_role.role_name}")
      operations = [
        "Encrypt",
        "GenerateDataKey",
      ]
    }
  } : {}
  kms_grants = var.cross_account ? merge(
    {
      cross_account_access = {
        grantee_principal = nonsensitive("arn:aws:iam::${var.cross_account_id}:role/AWSS3BucketReplication${var.data_feed}${var.order_type}")
        operations = [
          "Encrypt",
          "GenerateDataKey",
          "Decrypt"
        ]
      }
    },
    local.kms_grant_mdss
  ) : local.kms_grant_mdss
  kms_key_users = local.replication_enabled ? [
    aws_iam_role.process_landing_bucket_files.arn,
    aws_iam_role.replication_role[0].arn
  ] : [aws_iam_role.process_landing_bucket_files.arn]
}

data "aws_caller_identity" "current" {}

module "this-bucket" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=9facf9f"

  bucket_prefix      = "${var.local_bucket_prefix}-land-${var.data_feed}-${var.order_type}-"
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
        days = 30
      }

      noncurrent_version_transition = [
        {
          days          = 30
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = 90
      }
    }
  ]
  bucket_policy_v2 = local.bucket_policy

  tags = merge(
    var.local_tags,
    { order_type = var.order_type },
    { data_feed = var.data_feed }
  )
}

#-----------------------------------------------------------------------------------
# KMS - customer managed key for use with cross account data
#-----------------------------------------------------------------------------------

module "kms_key" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  aliases     = ["s3/landing_bucket_${var.data_feed}_${var.order_type}"]
  description = "${var.data_feed} ${var.order_type} landing bucket KMS key"

  # Give full access to key for root account, and lambda role ability to use.
  enable_default_policy = true
  key_users             = local.kms_key_users
  key_statements = var.cross_account ? [
    {
      sid    = "AllowS3ReplicationFromOtherAccount"
      effect = "Allow"
      principals = [
        {
          type = "AWS"
          identifiers = [
            "arn:aws:iam::${var.cross_account_id}:role/AWSS3BucketReplication${var.data_feed}${var.order_type}"
          ]
        }
      ]
      actions = [
        "kms:Encrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Decrypt",
      ]
      resources = ["*"]
    }
  ] : []

  deletion_window_in_days = 7

  # Grant external account role specific operations.
  # To view grants, need to use cli:
  # aws kms list-grants --region=eu-west-2 --key-id <key id>
  grants = local.kms_grants

  tags = merge(
    var.local_tags,
    { order_type = var.order_type },
    { data_feed = var.data_feed }
  )
}

#-----------------------------------------------------------------------------------
# Process landing bucket files - lambda triggers via SQS
#-----------------------------------------------------------------------------------

module "s3_to_lambda" {
  source               = "../sqs_s3_lambda_trigger"
  bucket               = module.this-bucket.bucket
  lambda_function_name = module.process_landing_bucket_files.lambda_function_name
  bucket_prefix        = var.local_bucket_prefix
}


resource "aws_s3_bucket_notification" "s3_notification_prefix_suffixes" {
  bucket = module.this-bucket.bucket.id

  queue {
    queue_arn = module.s3_to_lambda.sqs_queue.arn
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [module.s3_to_lambda]
}
#-----------------------------------------------------------------------------------
# Process landing bucket files - lambda
#-----------------------------------------------------------------------------------

module "process_landing_bucket_files" {
  source                         = "../lambdas"
  function_name                  = "process_landing_bucket_files_${var.data_feed}_${var.order_type}"
  image_name                     = "process_landing_bucket_files"
  is_image                       = true
  role_name                      = aws_iam_role.process_landing_bucket_files.name
  role_arn                       = aws_iam_role.process_landing_bucket_files.arn
  memory_size                    = 1024
  timeout                        = 900
  core_shared_services_id        = var.core_shared_services_id
  production_dev                 = var.production_dev
  security_group_ids             = var.security_group_ids
  subnet_ids                     = var.subnet_ids
  reserved_concurrent_executions = 1000
  environment_variables = {
    DESTINATION_BUCKET = var.received_files_bucket_id
  }
}

#-----------------------------------------------------------------------------------
# Process landing bucket files - lambda IAM role and policy
#-----------------------------------------------------------------------------------

resource "aws_iam_role" "process_landing_bucket_files" {
  name               = "process_landing_bucket_files_${var.data_feed}_${var.order_type}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "process_landing_bucket_files_s3_policy_document" {
  statement {
    sid    = "S3PermissionsForLandingBuckets"
    effect = "Allow"
    actions = [
      "s3:PutObjectTagging",
      "s3:GetObject",
      "s3:GetObjectTagging",
      "s3:DeleteObject"
    ]
    resources = [
      "${module.this-bucket.bucket.arn}/*",
    ]
  }

  statement {
    sid    = "S3PermissionsForReceivedFilesBucket"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectTagging"
    ]
    resources = [
      "arn:aws:s3:::${var.received_files_bucket_id}/*",
    ]
  }

  statement {
    sid    = "KMSDecryptObjects"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
    ]
    resources = [
      module.kms_key.key_arn,
    ]
  }
}



resource "aws_iam_policy" "process_landing_bucket_files_s3" {
  name        = "process_landing_bucket_files_s3_policy_${var.data_feed}_${var.order_type}"
  description = "Policy for Lambda to process files in ${var.data_feed} ${var.order_type} landing bucket"
  policy      = data.aws_iam_policy_document.process_landing_bucket_files_s3_policy_document.json
}

resource "aws_iam_role_policy_attachment" "process_landing_bucket_files_s3_policy_policy_attachment" {
  role       = aws_iam_role.process_landing_bucket_files.name
  policy_arn = aws_iam_policy.process_landing_bucket_files_s3.arn
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}
