data "aws_s3_bucket" "clean" {
  bucket = "${local.application_name}-${local.environment}-clean"
}

data "aws_kms_key" "clean" {
  key_id = local.clean_kms_key_alias
}

data "aws_iam_policy_document" "delivery" {
  for_each = local.push_to_sftp_entries

  statement {
    sid       = "ReadConfiguredSourceVersion"
    effect    = "Allow"
    actions   = ["s3:GetObjectVersion"]
    resources = ["${data.aws_s3_bucket.clean.arn}/${each.value.identity}${each.value.source_prefix}*"]
  }

  statement {
    sid       = "DecryptConfiguredSource"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [data.aws_kms_key.clean.arn]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.eu-west-2.amazonaws.com"]
    }

    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values = [
        data.aws_s3_bucket.clean.arn,
        "${data.aws_s3_bucket.clean.arn}/${each.value.identity}${each.value.source_prefix}*",
      ]
    }
  }

  statement {
    sid       = "ReadPrivateKey"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [module.secrets_private_key[each.key].secret_arn]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["true"]
    }
  }

  statement {
    sid       = "DecryptPrivateKey"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [module.kms_credentials.key_arn]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["secretsmanager.eu-west-2.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:EncryptionContext:SecretARN"
      values   = [module.secrets_private_key[each.key].secret_arn]
    }
  }
}

module "iam_policy_delivery" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.8.2"

  for_each = local.push_to_sftp_entries

  name        = local.delivery_resource_names[each.key]
  description = "Read one clean source prefix and its SFTP private key"
  policy      = data.aws_iam_policy_document.delivery[each.key].json

  tags = local.tags
}

module "iam_role_delivery" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.8.2"

  for_each = local.push_to_sftp_entries

  create          = true
  use_name_prefix = false
  name            = local.delivery_resource_names[each.key]

  trust_policy_permissions = {
    AllowPushToSftpLambda = {
      effect  = "Allow"
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "AWS"
        identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
      }]
      condition = [{
        test     = "ArnEquals"
        variable = "aws:PrincipalArn"
        values   = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.lambda_role_name}"]
      }]
    }
  }

  policies = { delivery = module.iam_policy_delivery[each.key].arn }

  tags = local.tags
}

data "aws_iam_policy_document" "public_key_reader" {
  for_each = local.push_to_sftp_entries

  statement {
    sid       = "ReadPublicKey"
    effect    = "Allow"
    actions   = ["secretsmanager:DescribeSecret", "secretsmanager:GetSecretValue"]
    resources = [module.secrets_public_key[each.key].secret_arn]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["true"]
    }
  }

  statement {
    sid       = "DecryptPublicKey"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [module.kms_credentials.key_arn]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["secretsmanager.eu-west-2.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:EncryptionContext:SecretARN"
      values   = [module.secrets_public_key[each.key].secret_arn]
    }
  }
}

module "iam_policy_public_key_reader" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.8.2"

  for_each = local.push_to_sftp_entries

  name        = "${local.delivery_resource_names[each.key]}-public-key-reader"
  description = "Read only the SFTP client public key for recipient onboarding"
  policy      = data.aws_iam_policy_document.public_key_reader[each.key].json

  tags = local.tags
}

data "aws_iam_policy_document" "key_custodian" {
  for_each = local.push_to_sftp_entries

  statement {
    sid    = "ManageKeyVersions"
    effect = "Allow"
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
      "secretsmanager:ListSecretVersionIds",
      "secretsmanager:PutSecretValue",
      "secretsmanager:UpdateSecretVersionStage",
    ]
    resources = [
      module.secrets_private_key[each.key].secret_arn,
      module.secrets_public_key[each.key].secret_arn,
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["true"]
    }
  }

  statement {
    sid       = "EncryptAndDecryptKeyVersions"
    effect    = "Allow"
    actions   = ["kms:Decrypt", "kms:GenerateDataKey"]
    resources = [module.kms_credentials.key_arn]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["secretsmanager.eu-west-2.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:EncryptionContext:SecretARN"
      values = [
        module.secrets_private_key[each.key].secret_arn,
        module.secrets_public_key[each.key].secret_arn,
      ]
    }
  }
}

module "iam_policy_key_custodian" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.8.2"

  for_each = local.push_to_sftp_entries

  name        = "${local.delivery_resource_names[each.key]}-key-custodian"
  description = "Populate and manually rotate one SFTP keypair; attach only to approved custodians"
  policy      = data.aws_iam_policy_document.key_custodian[each.key].json

  tags = local.tags
}