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
      values   = ["repo:ministryofjustice/integration-hub-downstream-mock-api:environment:${local.resource_application_name}-${local.environment}*"]
    }
  }
}

resource "aws_iam_role" "app_deploy" {
  name               = "${local.resource_name_prefix}-${local.environment}-app-deploy"
  assume_role_policy = data.aws_iam_policy_document.app_deploy_assume_role.json
  tags               = local.tags
}

data "aws_iam_policy_document" "app_deploy" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]
    resources = [aws_ecr_repository.application.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecs:DescribeClusters",
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:RegisterTaskDefinition",
      "ecs:UpdateService"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      aws_iam_role.ecs_task.arn,
      aws_iam_role.ecs_task_execution.arn
    ]
  }
}

resource "aws_iam_role_policy" "app_deploy" {
  name   = "${local.resource_name_prefix}-${local.environment}-app-deploy"
  role   = aws_iam_role.app_deploy.id
  policy = data.aws_iam_policy_document.app_deploy.json
}
