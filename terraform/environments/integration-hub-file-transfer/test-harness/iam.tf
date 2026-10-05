data "aws_iam_policy_document" "test-harness-trust" {
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
      values   = ["repo:ministryofjustice/integration-hub:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "test-harness" {
  count = local.create_test_harness ? 1 : 0

  name = "${local.application_name}-${local.component_name}-${local.environment}"

  assume_role_policy = data.aws_iam_policy_document.test-harness-trust[0].json
  tags               = local.tags
}

data "aws_iam_policy_document" "test-harness-permissions" {
  count = local.create_test_harness ? 1 : 0

  statement {
    sid     = "UploadSmokeTestFixture"
    effect  = "Allow"
    actions = ["s3:PutObject"]

    resources = [
      "${data.aws_s3_bucket.incoming[0].arn}/test-harness/direct-s3/*"
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
        "${data.aws_s3_bucket.incoming[0].arn}/test-harness/direct-s3/*"
      ]
    }
  }

  statement {
    sid       = "CheckSmokeTestDelivery"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [module.destination.s3_bucket_arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["delivered/direct-s3/*"]
    }
  }

  statement {
    sid       = "ReadDeliveredFixture"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${module.destination.s3_bucket_arn}/delivered/direct-s3/*"]
  }

  statement {
    sid       = "DecryptDeliveredFixture"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [module.destination-encryption.key_arn]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.eu-west-2.amazonaws.com"]
    }

    condition {
      test     = "ArnLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values   = ["${module.destination.s3_bucket_arn}/delivered/direct-s3/*"]
    }
  }
}

resource "aws_iam_role_policy" "test-harness-permissions" {
  count = local.create_test_harness ? 1 : 0

  name   = "pipeline-smoke-test"
  role   = aws_iam_role.test-harness[0].id
  policy = data.aws_iam_policy_document.test-harness-permissions[0].json
}