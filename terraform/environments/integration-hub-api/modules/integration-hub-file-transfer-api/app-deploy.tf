data "aws_iam_policy_document" "app_deploy_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${local.account_id}:oidc-provider/token.actions.githubusercontent.com"]
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
      values   = ["repo:ministryofjustice/integration-hub-file-transfer-api:environment:${local.resource_application_name}-${var.environment}*"]
    }
  }
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

module "app_deploy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.8.0"

  name            = "${local.resource_name_prefix}-app-deploy"
  use_name_prefix = false
  tags            = var.tags

  source_trust_policy_documents = [data.aws_iam_policy_document.app_deploy_assume_role.json]

  create_inline_policy           = true
  source_inline_policy_documents = [data.aws_iam_policy_document.app_deploy.json]
}