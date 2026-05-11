resource "aws_cloudwatch_log_group" "transfer" {
  name_prefix = "transfer_test_"

  tags = local.tags
}

data "aws_iam_policy_document" "transfer_user_access" {
  statement {
    sid    = "AllowListingOfUserFolder"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]
    resources = [module.s3_bucket["unscanned"].s3_bucket_arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values = [
        random_pet.transfer_user.id,
        "${random_pet.transfer_user.id}/*",
      ]
    }
  }

  statement {
    sid    = "HomeDirObjectAccess"
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:GetObject",
      "s3:GetObjectTagging",
      "s3:GetObjectVersion",
      "s3:GetObjectVersionTagging",
      "s3:PutObject",
      "s3:PutObjectTagging",
      "s3:PutObjectVersionTagging",
    ]
    resources = ["${module.s3_bucket["unscanned"].s3_bucket_arn}/${random_pet.transfer_user.id}/*"]
  }

  statement {
    sid    = "HomeDirKmsAccess"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:ReEncrypt*",
    ]
    resources = [module.kms_s3_bucket["unscanned"].key_arn]
  }
}

data "aws_iam_policy_document" "transfer_user_session" {
  statement {
    sid    = "AllowListingOfUserFolder"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
    ]
    resources = [module.s3_bucket["unscanned"].s3_bucket_arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values = [
        "$${transfer:UserName}",
        "$${transfer:UserName}/*",
      ]
    }
  }

  statement {
    sid    = "HomeDirObjectAccess"
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:GetObject",
      "s3:GetObjectTagging",
      "s3:GetObjectVersion",
      "s3:GetObjectVersionTagging",
      "s3:PutObject",
      "s3:PutObjectTagging",
      "s3:PutObjectVersionTagging",
    ]
    resources = ["arn:aws:s3:::${module.s3_bucket["unscanned"].s3_bucket_id}/$${transfer:UserName}/*"]
  }
}

module "transfer_logging_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.6.0"

  use_name_prefix = false
  name            = local.iam_configuration.transfer_role_name

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
    transfer_logging_access = "arn:aws:iam::aws:policy/service-role/AWSTransferLoggingAccess"
  }

  tags = local.tags
}

module "transfer_user_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.6.0"

  name        = local.iam_configuration.transfer_policy_name
  description = "AWS Transfer user access policy"
  path        = "/"

  policy = data.aws_iam_policy_document.transfer_user_access.json

  tags = local.tags
}

module "transfer_user_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.6.0"

  use_name_prefix = false
  name            = "${local.iam_configuration.transfer_role_name}-user"

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
    transfer_user_access = module.transfer_user_policy.arn
  }

  tags = local.tags
}

resource "aws_transfer_server" "transfer" {
  domain                 = "S3"
  endpoint_type          = "PUBLIC"
  identity_provider_type = "SERVICE_MANAGED"
  logging_role           = module.transfer_logging_role.arn
  protocols              = ["SFTP"]
  security_policy_name   = "TransferSecurityPolicy-2025-03"
  structured_log_destinations = [
    "${aws_cloudwatch_log_group.transfer.arn}:*"
  ]

  tags = local.tags
}

resource "aws_transfer_user" "transfer_user" {
  server_id = aws_transfer_server.transfer.id
  user_name = random_pet.transfer_user.id
  role      = module.transfer_user_role.arn
  policy    = data.aws_iam_policy_document.transfer_user_session.json

  home_directory_type = "LOGICAL"

  home_directory_mappings {
    entry  = "/"
    target = "/${module.s3_bucket["unscanned"].s3_bucket_id}/$${transfer:UserName}"
  }

  tags = local.tags
}

resource "aws_transfer_ssh_key" "transfer_user" {
  body      = trimspace(jsondecode(data.aws_secretsmanager_secret_version.secrets_transfer_user_ssh_keys.secret_string)[random_pet.transfer_user.id].key)
  server_id = aws_transfer_server.transfer.id
  user_name = random_pet.transfer_user.id
}

resource "random_pet" "transfer_user" {
  length    = 3
  separator = "-"
}
