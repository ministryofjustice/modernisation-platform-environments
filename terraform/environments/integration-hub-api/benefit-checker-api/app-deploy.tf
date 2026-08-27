data "aws_iam_policy_document" "app_deploy_assume_role" {
  count = local.create_service ? 1 : 0

  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:ministryofjustice/integration-hub-api-platform:environment:integration-hub-api-benefit-checker-api-${local.environment}*"]
    }
  }
}

resource "aws_iam_role" "app_deploy" {
  count = local.create_service ? 1 : 0

  name               = "${local.application_name}-${local.component_name}-${local.environment}-app-deploy"
  assume_role_policy = data.aws_iam_policy_document.app_deploy_assume_role[0].json
  tags               = local.tags
}

data "aws_iam_policy_document" "app_deploy" {
  count = local.create_service ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "lambda:GetFunction",
      "lambda:GetFunctionConfiguration",
      "lambda:UpdateFunctionCode",
    ]
    resources = [
      module.lambda_benefit_orchestrator[0].lambda_function_arn,
      module.lambda_api_authorizer[0].lambda_function_arn,
    ]
  }
}

resource "aws_iam_role_policy" "app_deploy" {
  count = local.create_service ? 1 : 0

  name   = "${local.application_name}-${local.component_name}-${local.environment}-app-deploy"
  role   = aws_iam_role.app_deploy[0].id
  policy = data.aws_iam_policy_document.app_deploy[0].json
}
