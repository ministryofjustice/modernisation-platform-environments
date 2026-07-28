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
    sid    = "AllowS3ListBucket"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]
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
  for_each = local.environment_transfer_server_users

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
    sid       = "AllowGetBucketLocation"
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation"]
    resources = [module.s3_bucket["incoming"].s3_bucket_arn]
  }

  statement {
    sid     = "AllowListOwnHomeDirectory"
    effect  = "Allow"
    actions = ["s3:ListBucket"]
    resources = [
      module.s3_bucket["incoming"].s3_bucket_arn,
    ]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values = [
        trimprefix(each.value.home_directory_target, "/"),
        "${trimprefix(each.value.home_directory_target, "/")}/",
        "${trimprefix(each.value.home_directory_target, "/")}/*",
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
      "${module.s3_bucket["incoming"].s3_bucket_arn}/${trimprefix(each.value.home_directory_target, "/")}/*",
    ]
  }
}

module "iam_policy_transfer_user" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.6.1"

  name        = "${local.environment}-transfer-user-policy"
  description = "AWS Transfer User policy"
  path        = "/"

  policy = data.aws_iam_policy_document.transfer_user.json

  tags = local.tags
}

module "iam_role_transfer_user" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.6.1"

  name            = "${local.environment}-transfer-user"
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
    transfer_user_policy = module.iam_policy_transfer_user.arn
  }
}

module "iam_role_transfer" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.6.1"

  create          = true
  use_name_prefix = true
  name            = "transfer-logging"

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
    transfer_logging = "arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"
  }

  tags = local.tags
}