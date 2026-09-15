locals {
  litellm_port           = 4000
  litellm_bedrock_region = "eu-west-1"
  litellm_vars           = local.application_data.accounts[local.environment]

  litellm_bedrock_models = [
    "eu.anthropic.claude-fable-5",
    "eu.anthropic.claude-opus-5",
    "eu.anthropic.claude-sonnet-5",
    "eu.anthropic.claude-opus-4-8",
    "eu.anthropic.claude-opus-4-6-v1",
    "eu.anthropic.claude-sonnet-4-6",
    "eu.anthropic.claude-opus-4-5-20251101-v1:0",
    "eu.anthropic.claude-sonnet-4-5-20250929-v1:0",
    "eu.anthropic.claude-haiku-4-5-20251001-v1:0",
  ]

  # model_name matches the Bedrock model ID so /bedrock/model/{id}/... requests resolve to a router model for cost tracking
  litellm_config = {
    model_list = [
      for model in local.litellm_bedrock_models : {
        model_name = model
        litellm_params = {
          model           = "bedrock/${model}"
          aws_region_name = local.litellm_bedrock_region
        }
      }
    ]
    general_settings = {
      master_key = "os.environ/LITELLM_MASTER_KEY"
    }
    litellm_settings = {
      turn_off_message_logging = true
    }
  }
}

resource "aws_ecs_cluster" "litellm" {
  name = "litellm-gateway"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_cloudwatch_log_group" "litellm" {
  #checkov:skip=CKV_AWS_158: "Ensure that Cloudwatch Log Group is encrypted using KMS CMK"
  #checkov:skip=CKV_AWS_338: "Ensure CloudWatch log groups retains logs for at least 1 year"
  name              = "/ecs/litellm-gateway"
  retention_in_days = 30
}

resource "aws_security_group" "litellm_task" {
  name_prefix = "litellm-task-"
  description = "LiteLLM gateway tasks"
  vpc_id      = data.aws_vpc.shared.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "litellm_task_from_alb" {
  security_group_id            = aws_security_group.litellm_task.id
  description                  = "LiteLLM from load balancer"
  referenced_security_group_id = aws_security_group.litellm_alb.id
  from_port                    = local.litellm_port
  to_port                      = local.litellm_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "litellm_task_https" {
  security_group_id = aws_security_group.litellm_task.id
  description       = "Bedrock, image registry and AWS APIs"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "litellm_task_db" {
  security_group_id            = aws_security_group.litellm_task.id
  description                  = "Postgres"
  referenced_security_group_id = aws_security_group.litellm_db.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

data "aws_iam_policy_document" "ecs_tasks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "litellm_execution" {
  name               = "litellm-gateway-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json
}

data "aws_iam_policy_document" "litellm_execution" {
  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.litellm.arn}:*"]
  }

  statement {
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      aws_secretsmanager_secret.litellm_master_key.arn,
      aws_secretsmanager_secret.litellm_salt_key.arn,
      aws_secretsmanager_secret.litellm_db_password.arn,
    ]
  }
}

resource "aws_iam_role_policy" "litellm_execution" {
  name   = "litellm-gateway-execution"
  role   = aws_iam_role.litellm_execution.id
  policy = data.aws_iam_policy_document.litellm_execution.json
}

resource "aws_iam_role" "litellm_task" {
  name               = "litellm-gateway-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json
}

# LiteLLM does not enforce per-key model restrictions on Bedrock passthrough, so this policy is the effective model allowlist
data "aws_iam_policy_document" "litellm_task" {
  statement {
    sid = "BedrockInvokeAnthropic"
    actions = [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream",
      "bedrock:CountTokens",
    ]
    resources = [
      "arn:aws:bedrock:*::foundation-model/anthropic.claude-*",
      "arn:aws:bedrock:*:${data.aws_caller_identity.current.account_id}:inference-profile/eu.anthropic.claude-*",
    ]
  }

  statement {
    sid = "EcsExec"
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "litellm_task" {
  name   = "litellm-gateway-task"
  role   = aws_iam_role.litellm_task.id
  policy = data.aws_iam_policy_document.litellm_task.json
}

resource "aws_ecs_task_definition" "litellm" {
  family                   = "litellm-gateway"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = local.litellm_vars.litellm_task_cpu
  memory                   = local.litellm_vars.litellm_task_memory
  execution_role_arn       = aws_iam_role.litellm_execution.arn
  task_role_arn            = aws_iam_role.litellm_task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name      = "litellm"
      image     = "ghcr.io/berriai/litellm-database:${local.litellm_vars.litellm_image_tag}"
      essential = true

      entryPoint = ["sh", "-c"]
      command = [
        "printf '%s' \"$LITELLM_CONFIG_YAML\" > /tmp/config.yaml && exec docker/prod_entrypoint.sh --port ${local.litellm_port} --config /tmp/config.yaml"
      ]

      portMappings = [
        {
          containerPort = local.litellm_port
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "LITELLM_CONFIG_YAML", value = yamlencode(local.litellm_config) },
        { name = "LITELLM_MODE", value = "PRODUCTION" },
        { name = "PROXY_BASE_URL", value = "https://${local.litellm_hostname}" },
        { name = "AWS_REGION_NAME", value = local.litellm_bedrock_region },
        { name = "DATABASE_HOST", value = aws_db_instance.litellm.address },
        { name = "DATABASE_PORT", value = tostring(aws_db_instance.litellm.port) },
        { name = "DATABASE_USERNAME", value = aws_db_instance.litellm.username },
        { name = "DATABASE_NAME", value = aws_db_instance.litellm.db_name },
      ]

      secrets = [
        { name = "LITELLM_MASTER_KEY", valueFrom = aws_secretsmanager_secret.litellm_master_key.arn },
        { name = "LITELLM_SALT_KEY", valueFrom = aws_secretsmanager_secret.litellm_salt_key.arn },
        { name = "DATABASE_PASSWORD", valueFrom = aws_secretsmanager_secret.litellm_db_password.arn },
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.litellm.name
          "awslogs-region"        = data.aws_region.current.region
          "awslogs-stream-prefix" = "litellm"
        }
      }
    }
  ])

  depends_on = [
    aws_secretsmanager_secret_version.litellm_master_key,
    aws_secretsmanager_secret_version.litellm_salt_key,
    aws_secretsmanager_secret_version.litellm_db_password,
  ]
}

resource "aws_ecs_service" "litellm" {
  name                              = "litellm-gateway"
  cluster                           = aws_ecs_cluster.litellm.id
  task_definition                   = aws_ecs_task_definition.litellm.arn
  launch_type                       = "FARGATE"
  desired_count                     = local.litellm_vars.litellm_desired_count
  enable_execute_command            = true
  health_check_grace_period_seconds = 300

  network_configuration {
    subnets          = data.aws_subnets.shared-private.ids
    security_groups  = [aws_security_group.litellm_task.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.litellm.arn
    container_name   = "litellm"
    container_port   = local.litellm_port
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  depends_on = [aws_lb_listener.litellm_https]
}
