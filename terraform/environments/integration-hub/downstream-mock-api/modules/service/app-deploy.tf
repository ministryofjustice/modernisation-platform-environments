data "aws_iam_policy_document" "app_deploy_assume_role" {
  #checkov:skip=CKV_AWS_358:MoJ customises the OIDC subject with immutable organisation and repository IDs; the exact environment subject is safer than Checkov's expected default GitHub format
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${var.account_id}:oidc-provider/token.actions.githubusercontent.com"]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:ministryofjustice@2203574/integration-hub-downstream-mock-api@1337550338:environment:${local.resource_application_name}-${local.environment}"
      ]
    }
  }
}

resource "aws_iam_role" "app_deploy" {
  name               = "${local.resource_name_prefix}-${local.environment}-app-deploy"
  assume_role_policy = data.aws_iam_policy_document.app_deploy_assume_role.json
  tags               = local.tags
}

data "aws_iam_policy_document" "app_deploy" {
  #checkov:skip=CKV_AWS_111:ECR authentication and ECS task registration require wildcard resources; deployment access is limited by the OIDC trust policy
  #checkov:skip=CKV_AWS_356:ECR authentication and ECS task registration do not support resource-level permissions
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
    ]
    resources = [aws_ecs_cluster.service.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecs:DescribeServices",
      "ecs:UpdateService"
    ]
    resources = [aws_ecs_service.service.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecs:DescribeTaskDefinition"
    ]
    resources = ["arn:aws:ecs:${var.region}:${var.account_id}:task-definition/${aws_ecs_task_definition.service.family}:*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecs:RegisterTaskDefinition"
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
