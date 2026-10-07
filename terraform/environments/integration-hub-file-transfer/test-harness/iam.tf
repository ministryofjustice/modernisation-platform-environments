data "aws_iam_policy_document" "test_harness_trust" {
  count = local.create_test_harness ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:ministryofjustice/integration-hub:environment:smoke-test"]
    }
  }
}

module "iam_role_test_harness" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.8.2"

  create          = local.create_test_harness
  use_name_prefix = false
  name            = local.test_harness_iam_name

  source_trust_policy_documents = local.test_harness_trust_policy_documents

  policies = {
    smoke_test = module.iam_policy_test_harness.arn
  }

  tags = local.tags
}

data "aws_iam_policy_document" "test_harness_permissions" {
  count = local.create_test_harness ? 1 : 0

  statement {
    sid     = "UploadSmokeTestFixture"
    effect  = "Allow"
    actions = ["s3:PutObject"]

    resources = [
      "${data.aws_s3_bucket.incoming[0].arn}/${local.incoming_prefix}*"
    ]
  }

  statement {
    sid       = "EncryptSmokeTestFixture"
    effect    = "Allow"
    actions   = ["kms:GenerateDataKey"]
    resources = [data.aws_kms_key.incoming[0].arn]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.eu-west-2.amazonaws.com"]
    }

    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values = [
        "${data.aws_s3_bucket.incoming[0].arn}/${local.incoming_prefix}*"
      ]
    }
  }

  statement {
    sid       = "CheckSmokeTestDelivery"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [module.s3_test_harness.s3_bucket_arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["${local.destination_prefix}*"]
    }
  }

  statement {
    sid       = "ReadDeliveredFixture"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${module.s3_test_harness.s3_bucket_arn}/${local.destination_prefix}*"]
  }

  statement {
    sid       = "DecryptDeliveredFixture"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [module.kms_test_harness.key_arn]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.eu-west-2.amazonaws.com"]
    }

    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values   = ["${module.s3_test_harness.s3_bucket_arn}/${local.destination_prefix}*"]
    }
  }
}

module "iam_policy_test_harness" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.8.2"

  create      = local.create_test_harness
  name        = local.test_harness_iam_name
  description = "Upload and verify Integration Hub repository smoke-test fixtures"
  policy      = local.create_test_harness ? data.aws_iam_policy_document.test_harness_permissions[0].json : null

  tags = local.tags
}