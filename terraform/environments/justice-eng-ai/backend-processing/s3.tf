data "aws_iam_roles" "account" {}

data "aws_iam_role" "account" {
  for_each = data.aws_iam_roles.account.names

  name = each.value
}

locals {
  ecs_task_roles = {
    for name, role in data.aws_iam_role.account : name => role
    if anytrue([
      for statement in jsondecode(role.assume_role_policy).Statement :
      statement.Effect == "Allow" &&
      contains(flatten([try(statement.Principal.Service, [])]), "ecs-tasks.amazonaws.com") &&
      contains(flatten([statement.Action]), "sts:AssumeRole")
    ])
  }
}

resource "aws_kms_key" "staging_bucket" {
  description             = "Encrypt objects in the staging bucket"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  tags                    = local.tags
}

module "staging_bucket" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=81230d03816f140ae912454815ec531d7cbe2c8e"

  providers = {
    aws.bucket-replication = aws
  }

  bucket_prefix       = "${local.application_name}-staging-bucket-"
  versioning_enabled  = true
  ownership_controls  = "BucketOwnerEnforced"
  replication_enabled = false
  sse_algorithm       = "aws:kms"
  custom_kms_key      = aws_kms_key.staging_bucket.arn

  lifecycle_rule = [
    {
      id                                     = "abort-incomplete-multipart-uploads"
      enabled                                = "Enabled"
      prefix                                 = ""
      abort_incomplete_multipart_upload_days = 7
    }
  ]

  bucket_policy_v2 = length(local.ecs_task_roles) > 0 ? [
    {
      effect = "Allow"
      actions = [
        "s3:GetBucketLocation",
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject",
      ]
      principals = {
        type        = "AWS"
        identifiers = [for role in local.ecs_task_roles : role.arn]
      }
      conditions = [
        {
          test     = "StringEquals"
          variable = "aws:PrincipalAccount"
          values   = [data.aws_caller_identity.current.account_id]
        }
      ]
    }
  ] : []

  tags = local.tags
}

data "aws_iam_policy_document" "ecs_staging_bucket_kms" {
  statement {
    effect    = "Allow"
    actions   = ["kms:Decrypt", "kms:GenerateDataKey"]
    resources = [aws_kms_key.staging_bucket.arn]

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${data.aws_region.current.region}.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values   = [module.staging_bucket.bucket.arn, "${module.staging_bucket.bucket.arn}/*"]
    }
  }
}

resource "aws_iam_role_policy" "ecs_staging_bucket_kms" {
  for_each = local.ecs_task_roles

  name   = "${local.application_name}-ecs-staging-bucket-kms"
  role   = each.value.name
  policy = data.aws_iam_policy_document.ecs_staging_bucket_kms.json
}
