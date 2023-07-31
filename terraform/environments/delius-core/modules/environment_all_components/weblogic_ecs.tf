resource "aws_security_group" "weblogic" {
  name        = "${var.env_name}-weblogic-sg"
  description = "Security group for the ${var.env_name} weblogic service"
  vpc_id      = var.account_info.vpc_id
  tags        = local.tags
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "weblogic_allow_all_egress" {
  description       = "Allow all outbound traffic to any IPv4 address"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ldap.id
}

resource "aws_security_group_rule" "weblogic_alb" {
  description       = "Allow inbound traffic from VPC"
  type              = "ingress"
  from_port         = var.weblogic_config.frontend_container_port
  to_port           = var.weblogic_config.frontend_container_port
  protocol          = "TCP"
  security_group_id = aws_security_group.ldap.id
  cidr_blocks       = [var.network_config.shared_vpc_cidr]
}

resource "aws_cloudwatch_log_group" "weblogic" {
  name              = "${var.env_name}-weblogic-ecs"
  retention_in_days = 30
}


data "aws_iam_policy_document" "weblogic_ecs_task" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "weblogic_ecs_task" {
  name               = "${var.env_name}-weblogic-task"
  assume_role_policy = data.aws_iam_policy_document.weblogic_ecs_task.json
  tags               = local.tags
}

data "aws_iam_policy_document" "weblogic_ecs_service" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "weblogic_ecs_service" {
  name               = "${var.env_name}-weblogic-service"
  assume_role_policy = data.aws_iam_policy_document.weblogic_ecs_service.json
  tags               = local.tags
}

data "aws_iam_policy_document" "weblogic_ecs_service_policy" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "ec2:Describe*",
      "ec2:AuthorizeSecurityGroupIngress",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets"
    ]
  }
}

resource "aws_iam_role_policy" "weblogic_ecs_service" {
  name   = "${var.env_name}-weblogic-service"
  policy = data.aws_iam_policy_document.weblogic_ecs_service_policy.json
  role   = aws_iam_role.weblogic_ecs_service.id
}

data "aws_iam_policy_document" "weblogic_ecs_ssm_exec" {
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

resource "aws_iam_role_policy" "weblogic_ecs_ssm_exec" {
  name   = "${var.env_name}-ldap-service-ssm-exec"
  policy = data.aws_iam_policy_document.weblogic_ecs_service.json
  role   = aws_iam_role.weblogic_ecs_task.id
}

# IAM role that the Amazon ECS container agent and the Docker daemon can assume
data "aws_iam_policy_document" "weblogic_ecs_task_exec" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "weblogic_ecs_exec" {
  name               = "${var.env_name}-weblogic-task-exec"
  assume_role_policy = data.aws_iam_policy_document.weblogic_ecs_task_exec.json
  tags               = local.tags
}

data "aws_iam_policy_document" "weblogic_ecs_exec" {
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
      "secretsmanager:GetSecretValue"
    ]
  }
}

resource "aws_iam_role_policy" "weblogic_ecs_exec" {
  name   = "${var.env_name}-weblogic-task-exec"
  policy = data.aws_iam_policy_document.weblogic_ecs_exec.json
  role   = aws_iam_role.weblogic_ecs_exec.id
}


# Pre-req - CloudWatch log group
# By default, server-side-encryption is used
resource "aws_cloudwatch_log_group" "delius_core_frontend_log_group" {
  name              = var.weblogic_config.frontend_fully_qualified_name
  retention_in_days = 7
  tags              = local.tags
}
