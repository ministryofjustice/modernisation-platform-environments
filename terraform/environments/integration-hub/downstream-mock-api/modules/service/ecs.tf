resource "aws_ecr_repository" "application" {
  name                 = local.resource_application_name
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = var.kms_key_arn
  }

  tags = local.tags
}

resource "aws_ecr_lifecycle_policy" "application" {
  repository = aws_ecr_repository.application.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Retain the 20 most recent images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 20
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/aws/ecs/${local.resource_name_prefix}"
  kms_key_id        = module.kms_cloudwatch_logs.key_arn
  retention_in_days = 365
  tags              = local.tags
}

resource "aws_ecs_cluster" "service" {
  name = local.resource_name_prefix

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = local.tags
}

data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ecs_task_execution" {
  name               = "${local.resource_name_prefix}-${local.environment}-exec"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_managed" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_task_execution_secret_access" {
  name = "${local.resource_name_prefix}-${local.environment}-exec-secrets"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          module.downstream_basic_auth_secret.secret_arn
        ]
      }
    ]
  })
}

resource "aws_iam_role" "ecs_task" {
  name               = "${local.resource_name_prefix}-${local.environment}-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
  tags               = local.tags
}

resource "aws_iam_role_policy" "ecs_task_ssm_exec" {
  name = "${local.resource_name_prefix}-${local.environment}-task-ssm"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_ecs_task_definition" "service" {
  family                   = local.resource_name_prefix
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = tostring(local.service_configuration.task_cpu)
  memory                   = tostring(local.service_configuration.task_memory)
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name                   = local.resource_application_name,
      image                  = "${aws_ecr_repository.application.repository_url}:${local.service_configuration.bootstrap_image_tag}",
      essential              = true,
      readonlyRootFilesystem = true,
      user                   = "0",
      mountPoints = [
        {
          sourceVolume  = "tmp",
          containerPath = "/tmp",
          readOnly      = false
        }
      ],
      portMappings = [
        {
          containerPort = local.service_configuration.container_port,
          hostPort      = local.service_configuration.container_port,
          protocol      = "tcp"
        }
      ],
      environment = [
        {
          name  = "SERVER_PORT",
          value = tostring(local.service_configuration.container_port)
        }
      ],
      secrets = [
        {
          name      = "DOWNSTREAM_MOCK_BASIC_AUTH_USERNAME",
          valueFrom = "${module.downstream_basic_auth_secret.secret_arn}:username::"
        },
        {
          name      = "DOWNSTREAM_MOCK_BASIC_AUTH_PASSWORD",
          valueFrom = "${module.downstream_basic_auth_secret.secret_arn}:password::"
        }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name,
          awslogs-region        = var.region,
          awslogs-stream-prefix = "app"
        }
      }
    }
  ])

  volume {
    name = "tmp"
  }

  tags = local.tags
}

data "aws_ecs_task_definition" "service_latest" {
  task_definition = aws_ecs_task_definition.service.family

  depends_on = [aws_ecs_task_definition.service]
}

resource "aws_ecs_service" "service" {
  name                              = local.resource_name_prefix
  cluster                           = aws_ecs_cluster.service.id
  task_definition                   = data.aws_ecs_task_definition.service_latest.arn
  desired_count                     = local.service_configuration.desired_count
  launch_type                       = "FARGATE"
  enable_execute_command            = true
  health_check_grace_period_seconds = 60
  force_new_deployment              = true

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_service.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.service.arn
    container_name   = local.resource_application_name
    container_port   = local.service_configuration.container_port
  }

  depends_on = [aws_lb_listener.service]

  tags = local.tags
}
