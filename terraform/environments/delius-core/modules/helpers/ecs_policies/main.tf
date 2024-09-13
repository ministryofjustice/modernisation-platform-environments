data "aws_iam_policy_document" "task" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "task" {
  name               = "${var.env_name}-${var.service_name}-ecs-task"
  assume_role_policy = data.aws_iam_policy_document.task.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "task_actions" {
  for_each = var.extra_task_role_policies
  name     = "${var.env_name}-${var.service_name}-ecs-task-actions-${each.key}"
  policy   = each.value.json
  role     = aws_iam_role.task.id
}

data "aws_iam_policy_document" "ecs_service" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "service" {
  name               = "${var.env_name}-${var.service_name}-ecs-service"
  assume_role_policy = data.aws_iam_policy_document.ecs_service.json
  tags               = var.tags
}

data "aws_iam_policy_document" "service_policy" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = concat([
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "ec2:Describe*",
      "ec2:AuthorizeSecurityGroupIngress",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets"
    ], var.extra_service_role_allow_statements)
  }
}

resource "aws_iam_role_policy" "service_policy" {
  name   = "${var.env_name}-${var.service_name}-service"
  policy = data.aws_iam_policy_document.service_policy.json
  role   = aws_iam_role.service.id
}

data "aws_iam_policy_document" "ssm_exec" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
  }
}

resource "aws_iam_role_policy" "ssm_exec" {
  name   = "${var.env_name}-${var.service_name}-service-ssm-exec"
  policy = data.aws_iam_policy_document.ssm_exec.json
  role   = aws_iam_role.task.id
}

# IAM role that the Amazon ECS container agent and the Docker daemon can assume
data "aws_iam_policy_document" "ecs_task_exec" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}
resource "aws_iam_role_policy" "exec_actions" {
  for_each = var.extra_task_exec_role_policies
  name     = "${var.env_name}-${var.service_name}-ecs-task-exec-${each.key}"
  policy   = each.value.json
  role     = aws_iam_role.task_exec.id
}

data "aws_iam_policy_document" "task_exec" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ssm:GetParameters",
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "secretsmanager:GetSecretValue",
      "kms:Decrypt",
    ]
  }
}

resource "aws_iam_role_policy" "task_exec" {
  name   = "${var.env_name}-${var.service_name}-task-exec"
  policy = data.aws_iam_policy_document.task_exec.json
  role   = aws_iam_role.task_exec.id
}


resource "aws_iam_role" "task_exec" {
  name               = "${var.env_name}-${var.service_name}-ecs-task-exec"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_exec.json
  tags               = var.tags
}
