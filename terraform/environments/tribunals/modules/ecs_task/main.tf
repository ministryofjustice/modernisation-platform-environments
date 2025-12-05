terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.20.0"
    }
  }
}

resource "aws_ecs_task_definition" "ecs_task_definition" {
  #checkov:skip=CKV_AWS_336:"Windows containers require write access to the filesystem"
  #checkov:skip=CKV_AWS_249:"Same role used for execution and task roles by application design"
  family             = "${var.app_name}Family"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_execution_role.arn
  requires_compatibilities = [
    "EC2",
  ]

  volume {
    name      = var.task_definition_volume
    host_path = "D:/storage/tribunals/${var.app_name}"
  }

  container_definitions = var.container_definition

  runtime_platform {
    operating_system_family = "WINDOWS_SERVER_2019_CORE"
    #   cpu_architecture        = "X86_64"
  }

  tags = merge(
    var.tags_common,
    {
      Name = "${var.app_name}-windows-task-definition"
    }
  )
}


# ECS task execution role data
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html
data "aws_iam_policy_document" "ecs_task_execution_role" {
  version = "2012-10-17"
  statement {
    sid    = ""
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"
      identifiers = [
        "ecs-tasks.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_policy" "ecs_task_execution_s3_policy" { #tfsec:ignore:aws-iam-no-policy-wildcards
  #checkov:skip=CKV_AWS_290:"Required broad permissions for S3 and ECS/ELB operations"
  #checkov:skip=CKV_AWS_355:"Some AWS services require * resource access"
  #checkov:skip=CKV_AWS_288:"S3 operations require broader access"
  name = "${var.app_name}-ecs-task-execution-s3-policy-2"
  tags = merge(
    var.tags_common,
    {
      Name = "${var.app_name}-ecs-task-execution-s3-policy-2"
    }
  )
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "kms:Decrypt",
        "kms:Encrypt",
        "kms:GenerateDataKey",
        "kms:ReEncrypt",
        "kms:DescribeKey",
        "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
        "elasticloadbalancing:DeregisterTargets",
        "elasticloadbalancing:Describe*",
        "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
        "elasticloadbalancing:RegisterTargets",
        "ec2:Describe*",
        "ec2:AuthorizeSecurityGroupIngress",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:CreateLogGroup"
      ],
      "Resource": ["*"]
    }
  ]
}
EOF
}


# ECS task execution role
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.app_name}-ecs-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_role.json
  tags = merge(
    var.tags_common,
    {
      Name = "${var.app_name}-ecs-task-execution-role"
    }
  )
}

# ECS task execution role policy attachment
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
resource "aws_iam_role_policy_attachment" "ecs_task_secrets_manager" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}
resource "aws_iam_role_policy_attachment" "ecs_task_s3_access" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_execution_s3_policy.arn
}

# Set up CloudWatch group and log stream and retain logs for 30 days
resource "aws_cloudwatch_log_group" "cloudwatch_group" {
  #checkov:skip=CKV_AWS_158:Skip KMS encryption check
  name              = "${var.app_name}-ecs-log-group"
  retention_in_days = 365
  tags = merge(
    var.tags_common,
    {
      Name = "${var.app_name}-ecs-log-group"
    }
  )
}

resource "aws_ecs_service" "ecs_service" {
  count           = var.is_ftp_app ? 0 : 1
  name            = var.app_name
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.ecs_task_definition.arn
  desired_count   = var.app_count
  launch_type     = "EC2"

  health_check_grace_period_seconds = 300

  load_balancer {
    target_group_arn = var.lb_tg_arn
    container_name   = "${var.app_name}-container"
    container_port   = var.server_port
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100
  force_new_deployment               = true

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:Role == Primary"
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution_role, aws_ecs_task_definition.ecs_task_definition, aws_cloudwatch_log_group.cloudwatch_group
  ]

  tags = merge(
    var.tags_common,
    {
      Name = "${var.app_name}-ecs-service"
    }
  )
}

// SFTP service
resource "aws_ecs_service" "ecs_service_sftp" {
  count           = var.is_ftp_app ? 1 : 0
  name            = var.app_name
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.ecs_task_definition.arn
  desired_count   = var.app_count
  launch_type     = "EC2"

  health_check_grace_period_seconds = 300

  load_balancer {
    target_group_arn = var.lb_tg_arn
    container_name   = "${var.app_name}-container"
    container_port   = var.server_port
  }

  # Additional load balancer for SFTP connections
  load_balancer {
    target_group_arn = var.sftp_lb_tg_arn
    container_name   = "${var.app_name}-container"
    container_port   = 22
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100
  force_new_deployment               = true

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:Role == Primary"
  }

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution_role, aws_ecs_task_definition.ecs_task_definition, aws_cloudwatch_log_group.cloudwatch_group
  ]

  tags = merge(
    var.tags_common,
    {
      Name = "${var.app_name}-ecs-service"
    }
  )
}

resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = var.appscaling_max_capacity
  min_capacity       = var.appscaling_min_capacity
  resource_id        = var.is_ftp_app ? "service/${var.cluster_name}/${aws_ecs_service.ecs_service_sftp[0].name}" : "service/${var.cluster_name}/${aws_ecs_service.ecs_service[0].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_target_cpu" {
  name               = "application-scaling-policy-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = var.ecs_scaling_cpu_threshold
  }
}

resource "aws_appautoscaling_policy" "ecs_target_memory" {
  name               = "application-scaling-policy-memory"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = var.ecs_scaling_mem_threshold
  }
}
