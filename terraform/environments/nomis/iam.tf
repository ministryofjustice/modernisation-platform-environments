####################
# SSM Token Rotator
####################

resource "aws_iam_role" "sas_token_rotator" {
  count              = local.is-production || local.is-preproduction ? 1 : 0
  name               = "sas-token-rotator"
  assume_role_policy = data.aws_iam_policy_document.sas_token_rotator_role.json
  tags               = local.tags
}

data "aws_iam_policy_document" "sas_token_rotator_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"]
    }
    condition {
      test     = "StringEquals"
      values   = ["sts.amazonaws.com"]
      variable = "token.actions.githubusercontent.com:aud"
    }
    condition {
      test     = "StringLike"
      values   = ["repo:ministryofjustice/dso-modernisation-platform-automation:*"]
      variable = "token.actions.githubusercontent.com:sub"
    }
  }
}

data "aws_iam_policy_document" "sas_token_rotator" {
  statement {
    sid    = "RotateSecrets"
    effect = "Allow"
    actions = [
      "ssm:PutParameter",
    ]
    resources = [
      "arn:aws:ssm:*:*:parameter/azure/*",
    ]
  }
  statement {
    sid    = "EncryptSecrets"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
    ]
    resources = [
      data.aws_kms_key.general_shared.arn,
    ]
  }
}

resource "aws_iam_policy" "sas_token_rotator" {
  count       = local.is-production || local.is-preproduction ? 1 : 0
  name        = "sas_token_rotator"
  description = "Allows updating of secrets in SSM"
  policy      = data.aws_iam_policy_document.sas_token_rotator.json
}

resource "aws_iam_role_policy_attachment" "sas_token_rotator" {
  count      = local.is-production || local.is-preproduction ? 1 : 0
  policy_arn = aws_iam_policy.sas_token_rotator[0].arn
  role       = aws_iam_role.sas_token_rotator[0].name
}
