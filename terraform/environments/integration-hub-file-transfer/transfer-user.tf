resource "aws_transfer_user" "this" {
  for_each = { for k, v in local.transfer_server_users : k => v if contains(v.environments, local.environment) }

  server_id           = aws_transfer_server.this.id
  user_name           = each.key
  role                = module.transfer_user_role.arn
  policy              = data.aws_iam_policy_document.transfer_user_session.json
  home_directory_type = "LOGICAL"

  home_directory_mappings {
    entry  = "/"
    target = "/${module.s3_bucket["incoming"].s3_bucket_id}/${each.key}"
  }
}

data "aws_iam_policy_document" "transfer_user" {
  statement {
    sid    = "AllowKMS"
    effect = "Allow"
    actions = [
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Encrypt",
      "kms:DescribeKey",
      "kms:Decrypt",
    ]
    resources = [module.kms_s3_bucket["incoming"].key_arn]
  }

  statement {
    sid     = "AllowS3ListBucket"
    effect  = "Allow"
    actions = ["s3:ListBucket"]
    resources = [
      module.s3_bucket["incoming"].s3_bucket_arn
    ]
  }

  statement {
    sid    = "AllowS3LandingBucketObjectActions"
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:PutObject"
    ]
    resources = ["${module.s3_bucket["incoming"].s3_bucket_arn}/*"]
  }
}

data "aws_iam_policy_document" "transfer_user_session" {
  statement {
    sid    = "AllowKMS"
    effect = "Allow"
    actions = [
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Encrypt",
      "kms:DescribeKey",
      "kms:Decrypt",
    ]
    resources = [module.kms_s3_bucket["incoming"].key_arn]
  }

  statement {
    sid    = "AllowListOwnHomeDirectory"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket"
    ]
    resources = [
      module.s3_bucket["incoming"].s3_bucket_arn,
    ]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values = [
        "$${transfer:UserName}",
        "$${transfer:UserName}/",
        "$${transfer:UserName}/*",
      ]
    }
  }

  statement {
    sid    = "AllowUploadOnlyToHomeDirectory"
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:PutObject",
    ]
    resources = [
      "${module.s3_bucket["incoming"].s3_bucket_arn}/$${transfer:UserName}/*",
    ]
  }
}

module "transfer_user_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.6.1"

  name        = "${local.application_name}-transfer-user-policy"
  description = "AWS Transfer User policy"
  path        = "/"

  policy = data.aws_iam_policy_document.transfer_user.json

  tags = local.tags
}

module "transfer_user_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.6.1"

  name            = "${local.application_name}-transfer-user"
  description     = "AWS Transfer User role"
  use_name_prefix = true

  trust_policy_permissions = {
    AllowTransferService = {
      effect  = "Allow"
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "Service"
        identifiers = ["transfer.amazonaws.com"]
      }]
    }
  }

  policies = {
    transfer_user_policy = module.transfer_user_policy.arn
  }
}
