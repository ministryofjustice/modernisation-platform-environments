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

