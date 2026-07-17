data "aws_iam_policy_document" "app_deploy_assume_role" {
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
      values   = ["repo:ministryofjustice/integration-hub-file-transfer-api:environment:${local.resource_application_name}-${local.environment}*"]
    }
  }
}

resource "aws_iam_role" "app_deploy" {
  name               = "${local.resource_name_prefix}-app-deploy"
  assume_role_policy = data.aws_iam_policy_document.app_deploy_assume_role.json

  tags = local.tags
}

data "aws_iam_policy_document" "app_deploy" {
  statement {
    effect = "Allow"
    actions = [
      "lambda:GetFunction",
      "lambda:GetFunctionConfiguration",
      "lambda:UpdateFunctionCode",
    ]
    resources = [
      module.lambda_api_authorizer.lambda_function_arn,
      module.lambda_api_docs.lambda_function_arn,
      module.lambda_upload_ticket.lambda_function_arn,
    ]
  }
}

resource "aws_iam_role_policy" "app_deploy" {
  name   = "${local.resource_name_prefix}-app-deploy"
  role   = aws_iam_role.app_deploy.id
  policy = data.aws_iam_policy_document.app_deploy.json
}
